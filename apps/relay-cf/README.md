# ao-relay — Cloudflare Worker for AstroQuest City

Multi-IP relay for free LLM providers (Groq / Gemini / NVIDIA / minimax).
Each request exits Cloudflare's edge at a different IP, so per-IP rate limits at the upstream provider become per-(IP×request) — orders of magnitude higher throughput.

## Why?

Groq / Gemini / NVIDIA limit free models per (IP, API key) tuple. With 21 Groq keys from your PC, you still get rate-limited because they all share your home IP. Routing through Cloudflare gives you ~millions of egress IPs that auto-rotate, multiplying your effective throughput.

## Architecture

```
┌──────────────┐        ┌────────────────────────┐        ┌─────────────────┐
│  AQ Client   │───────▶│  Cloudflare Worker     │───────▶│  Groq API       │ ← egress IP #1
│  (Tauri)     │        │  ao-relay              │        ├─────────────────┤
│              │        │                        │───────▶│  Gemini API     │ ← egress IP #2
│  has 21 keys │        │  rotates keys + IPs    │        ├─────────────────┤
│              │        │                        │───────▶│  NVIDIA NIM     │ ← egress IP #3
└──────────────┘        └────────────────────────┘        ├─────────────────┤
        ▲                         ▲                       │  minimax        │ ← egress IP #4
        │                         │                       └─────────────────┘
        │       secrets           │
        └─────── KV / Secrets ────┘
```

The Worker holds the user's API keys as `wrangler secret` values, so the keys never leave Cloudflare's edge (they're never sent to the AQ VPS or stored on disk). The AQ client just sends `Authorization: Bearer <RELAY_AUTH_TOKEN>` and the Worker handles key rotation.

## Setup (30 min)

### 1. Create a Cloudflare account
- https://dash.cloudflare.com/sign-up (no credit card)
- Verify email

### 2. Install wrangler locally
```bash
cd apps/relay-cf
npm install
npx wrangler login        # opens browser, links your CF account
```

### 3. Set secrets
```bash
# One-time setup: paste the JSON arrays of your keys
npx wrangler secret put GROQ_KEYS_JSON   # paste: ["gsk_abc","gsk_def",...]
npx wrangler secret put GEMINI_KEYS_JSON # paste: ["AQ.Ab8RN6...","AQ.Ab8RN6JK...",...]
npx wrangler secret put NVIDIA_KEYS_JSON # paste: ["nvapi-...","nvapi-...",...]
npx wrangler secret put MINIMAX_KEY       # paste: sk-cp-...
npx wrangler secret put RELAY_AUTH_TOKEN  # paste: any long random string (32+ chars)
```

Generate a strong token:
```bash
openssl rand -base64 48
```

### 4. Deploy
```bash
npx wrangler deploy
```

Output:
```
Published ao-relay (X.XX sec)
  https://ao-relay.<your-subdomain>.workers.dev
```

### 5. Test it
```bash
# Health
curl https://ao-relay.<subdomain>.workers.dev/health

# Chat completion via relay (Groq)
curl -X POST https://ao-relay.<subdomain>.workers.dev/groq/chat/completions \
  -H "Authorization: Bearer $RELAY_AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"model":"openai/gpt-oss-20b","messages":[{"role":"user","content":"Reply OK"}]}'
```

### 6. Wire into AQ's local_proxy.rs
Add the relay URL + auth token to `~/.aq/keys.json`:
```json
{
  "relay": {
    "url": "https://ao-relay.<subdomain>.workers.dev",
    "auth_token": "<your RELAY_AUTH_TOKEN>"
  }
}
```

Then update `local_proxy.rs` to call the relay when local round-robin hits 429.

## Security

- API keys stored only as CF secrets (encrypted at rest, never logged)
- Auth token gates every call; rotate via `wrangler secret put RELAY_AUTH_TOKEN` to invalidate
- Worker is publicly accessible but useless without the token
- Set up CF Access policies if you want IP allowlisting

## Observability

- `wrangler tail` — live log stream
- `wrangler deployments list` — version history
- Cloudflare dashboard → Workers & Pages → ao-relay → Logs

## Limits

- Free plan: 100,000 requests/day
- Paid plan: $5/mo for 10M requests
- Each request ≤ 30s CPU time on free plan (LLM APIs typically respond in <5s, so OK)

## Path convention

- `/groq/*` → `https://api.groq.com/openai/v1/*` (Bearer auth)
- `/gemini/*` → `https://generativelanguage.googleapis.com/v1beta/*` (uses ?key= query, no Bearer)
- `/nvidia/*` → `https://integrate.api.nvidia.com/v1/*` (Bearer auth)
- `/minimax/*` → `https://api.minimax.io/v1/*` (Bearer auth, single key)

The Worker automatically picks a random key from the pool for each request, tries up to MAX_RETRIES_PER_TIER, and surfaces the upstream response (or a structured error) back to the client.