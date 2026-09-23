// ============================================================
// ao-relay — AstroQuest City Cloudflare Worker
// Multi-IP relay for LLM providers (Groq / Gemini / NVIDIA / minimax).
// Each request to this worker exits CF at a different edge IP,
// bypassing per-IP rate limits at the upstream provider.
// ============================================================

export interface Env {
  GROQ_KEYS_JSON: string;   // JSON array of gsk_…
  GEMINI_KEYS_JSON: string; // JSON array of AQ.Ab…
  NVIDIA_KEYS_JSON: string; // JSON array of nvapi-…
  MINIMAX_KEY: string;       // single sk-cp-…
  RELAY_AUTH_TOKEN: string;  // bearer to gate the relay
  RELAY_VERSION: string;
  LOG_VERBOSE: string;
  MAX_RETRIES_PER_TIER: string;
}

// ------------ Provider config -----------------------------------
interface ProviderConfig {
  baseUrl: string;
  pathPrefix: string;
  authScheme: "bearer" | "query";
  parseKeys(envKey: string): string[];
}

const PROVIDERS: Record<string, ProviderConfig> = {
  groq: {
    baseUrl: "https://api.groq.com/openai/v1",
    pathPrefix: "/groq",
    authScheme: "bearer",
    parseKeys: (envKey: string) => safeParse<string[]>(envKey, []),
  },
  gemini: {
    baseUrl: "https://generativelanguage.googleapis.com/v1beta",
    pathPrefix: "/gemini",
    authScheme: "query", // AQ. keys need ?key= query
    parseKeys: (envKey: string) => safeParse<string[]>(envKey, []),
  },
  nvidia: {
    baseUrl: "https://integrate.api.nvidia.com/v1",
    pathPrefix: "/nvidia",
    authScheme: "bearer",
    parseKeys: (envKey: string) => safeParse<string[]>(envKey, []),
  },
  minimax: {
    baseUrl: "https://api.minimax.io/v1",
    pathPrefix: "/minimax",
    authScheme: "bearer",
    parseKeys: (envKey: string) => {
      const v = envKey?.trim();
      return v && v.length > 0 ? [v] : [];
    },
  },
};

// Per-provider round-robin counters (Workers are stateless so this is per-isolate,
// good enough — Cloudflare distributes isolates across the edge).
const RR_COUNTERS: Record<string, number> = {
  groq: 0,
  gemini: 0,
  nvidia: 0,
  minimax: 0,
};

function safeParse<T>(s: string, fallback: T): T {
  try {
    return JSON.parse(s);
  } catch {
    return fallback;
  }
}

// ------------ Main fetch handler --------------------------------
export default {
  async fetch(request: Request, env: Env, _ctx: ExecutionContext): Promise<Response> {
    const url = new URL(request.url);

    // ---- CORS preflight -------------------------------------------------
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders() });
    }

    // ---- Health endpoint --------------------------------------------
    if (url.pathname === "/health" || url.pathname === "/") {
      return jsonResponse({
        ok: true,
        service: "ao-relay",
        version: env.RELAY_VERSION ?? "unknown",
        providers: Object.keys(PROVIDERS),
        time: new Date().toISOString(),
      });
    }

    // ---- Auth gate ---------------------------------------------------
    const authHeader = request.headers.get("Authorization") ?? "";
    const expected = `Bearer ${env.RELAY_AUTH_TOKEN ?? ""}`;
    if (!env.RELAY_AUTH_TOKEN || authHeader !== expected) {
      return jsonResponse({ error: "unauthorized" }, 401);
    }

    // ---- Route to provider ------------------------------------------
    const providerName = url.pathname.split("/")[1]?.toLowerCase();
    const provider = PROVIDERS[providerName];
    if (!provider) {
      return jsonResponse(
        {
          error: "unknown provider",
          hint: "use /groq/* | /gemini/* | /nvidia/* | /minimax/*",
        },
        404,
      );
    }

    const keys = provider.parseKeys(
      providerName === "groq"
        ? env.GROQ_KEYS_JSON
        : providerName === "gemini"
          ? env.GEMINI_KEYS_JSON
          : providerName === "nvidia"
            ? env.NVIDIA_KEYS_JSON
            : env.MINIMAX_KEY,
    );

    if (keys.length === 0) {
      return jsonResponse(
        {
          error: `no keys configured for provider "${providerName}". Set the secret with: wrangler secret put ${providerName.toUpperCase()}_KEYS_JSON`,
        },
        503,
      );
    }

    const maxRetries = Math.min(keys.length, parseInt(env.MAX_RETRIES_PER_TIER ?? "6", 10));
    const upstreamPath = url.pathname.replace(provider.pathPrefix, "");
    const upstreamUrl = `${provider.baseUrl}${upstreamPath}${url.search}`;

    return await tryProviders({
      provider: providerName,
      providerCfg: provider,
      keys,
      maxRetries,
      upstreamUrl,
      request,
      log: env.LOG_VERBOSE === "true",
    });
  },
};

async function tryProviders(opts: {
  provider: string;
  providerCfg: ProviderConfig;
  keys: string[];
  maxRetries: number;
  upstreamUrl: string;
  request: Request;
  log: boolean;
}): Promise<Response> {
  const { provider, providerCfg, keys, maxRetries, upstreamUrl, request, log } = opts;

  let lastError: { status: number; body: string } | null = null;
  const attemptedKeys: string[] = [];

  for (let i = 0; i < maxRetries; i++) {
    // Pick next key in round-robin, skipping any we just tried
    const idx = (RR_COUNTERS[provider] + i) % keys.length;
    const key = keys[idx];
    attemptedKeys.push(maskKey(key));

    // Build upstream request
    const upstreamHeaders = new Headers(request.headers);
    upstreamHeaders.delete("Authorization");
    upstreamHeaders.delete("Host");

    let finalUrl = upstreamUrl;
    if (providerCfg.authScheme === "bearer") {
      upstreamHeaders.set("Authorization", `Bearer ${key}`);
    } else if (providerCfg.authScheme === "query") {
      // For Gemini: append ?key=AQ.Ab… to the URL
      const u = new URL(upstreamUrl);
      // Preserve existing query, then add/replace `key`
      u.searchParams.set("key", key);
      finalUrl = u.toString();
    }

    let upstreamResp: Response;
    try {
      upstreamResp = await fetch(finalUrl, {
        method: request.method,
        headers: upstreamHeaders,
        body: request.body,
        // @ts-ignore — Cloudflare-specific
        cf: { cacheTtl: 0, cacheEverything: false },
      });
    } catch (err) {
      lastError = { status: 502, body: `network error: ${String(err)}` };
      if (log) console.warn(`[${provider}] network err on key ${maskKey(key)}: ${err}`);
      continue;
    }

    const status = upstreamResp.status;

    // Success
    if (status >= 200 && status < 300) {
      RR_COUNTERS[provider] = (idx + 1) % keys.length;
      const responseHeaders = new Headers(upstreamResp.headers);
      // CORS
      responseHeaders.set("Access-Control-Allow-Origin", "*");
      responseHeaders.set("Access-Control-Allow-Headers", "*");
      // Relay metadata
      responseHeaders.set("X-AO-Relay-Served-By", `${provider}::${maskKey(key)}`);
      responseHeaders.set("X-AO-Relay-Attempts", String(i + 1));
      responseHeaders.set("X-AO-Relay-Edge-IP", upstreamResp.headers.get("cf-meta-ip") ?? "n/a");

      if (log) {
        console.log(`[${provider}] OK key=${maskKey(key)} attempt=${i + 1}/${maxRetries}`);
      }
      return new Response(upstreamResp.body, {
        status,
        headers: responseHeaders,
      });
    }

    // 400 = client bug (bad request body) — don't retry, surface to caller
    if (status === 400) {
      const body = await upstreamResp.text();
      return new Response(body, { status: 400, headers: corsHeaders() });
    }

    // 401 / 403 / 429 / 5xx → try next key
    const body = await upstreamResp.text();
    lastError = { status, body };
    if (log) {
      console.warn(
        `[${provider}] retryable err ${status} key=${maskKey(key)} attempt=${i + 1}/${maxRetries}: ${body.slice(0, 200)}`,
      );
    }
    // continue to next key
  }

  RR_COUNTERS[provider] = (RR_COUNTERS[provider] + 1) % keys.length;
  return jsonResponse(
    {
      error: `all ${maxRetries} attempts failed`,
      provider,
      attempted_keys: attemptedKeys,
      last_status: lastError?.status ?? null,
      last_body: (lastError?.body ?? "").slice(0, 400),
    },
    lastError?.status ?? 502,
  );
}

// ------------ Utils ----------------------------------------------
function maskKey(k: string): string {
  if (!k || k.length < 12) return "***";
  return `${k.slice(0, 6)}…${k.slice(-4)}`;
}

function corsHeaders(): Headers {
  return new Headers({
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
    "Access-Control-Allow-Headers": "Authorization, Content-Type",
    "Access-Control-Max-Age": "86400",
  });
}

function jsonResponse(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "Content-Type": "application/json",
      ...Object.fromEntries(corsHeaders()),
    },
  });
}