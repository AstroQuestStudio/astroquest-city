// ============================================================
// AQ MCP Server — JSON-RPC 2.0 over HTTP
// Exposes AstroQuest City tools to MCP clients (Cline, Claude Code, OpenHands).
// Listens on http://127.0.0.1:6789
// ============================================================

import express from "express";

const PORT = parseInt(process.env.AQ_MCP_PORT ?? "6789");
const AQ_PROXY = process.env.AQ_PROXY ?? "http://127.0.0.1:4000";
const AQ_PROXY_AUTH = process.env.AQ_PROXY_AUTH ?? "Bearer sk-aq-local";

// === Tool definitions =====================================
interface MCPTool {
  name: string;
  description: string;
  inputSchema: {
    type: "object";
    properties: Record<string, unknown>;
    required?: string[];
  };
}

const TOOLS: MCPTool[] = [
  {
    name: "cortex_query",
    description: "Search the Cortex pre-indexed codebase for symbols, functions, or text. Returns ranked matches with file:line refs. 90% token savings vs raw grep.",
    inputSchema: {
      type: "object",
      properties: {
        query: { type: "string", description: "Search query (function name, symbol, text)" },
        limit: { type: "number", description: "Max results (default 10)" },
      },
      required: ["query"],
    },
  },
  {
    name: "cortex_explain",
    description: "Explain a code symbol or function by name — returns docstring + summary + first usage.",
    inputSchema: {
      type: "object",
      properties: {
        symbol: { type: "string", description: "Symbol name to explain" },
      },
      required: ["symbol"],
    },
  },
  {
    name: "cortex_files",
    description: "List indexed files in the workspace (path filter optional).",
    inputSchema: {
      type: "object",
      properties: {
        path_glob: { type: "string", description: "Glob pattern to filter" },
      },
    },
  },
  {
    name: "git_status",
    description: "Show git status (branch, staged/unstaged, recent commits).",
    inputSchema: { type: "object", properties: {} },
  },
  {
    name: "git_diff",
    description: "Show git diff (staged by default, or specify --staged or --branch).",
    inputSchema: {
      type: "object",
      properties: {
        staged: { type: "boolean", description: "Show staged diff instead of unstaged" },
        branch: { type: "string", description: "Diff against this branch" },
      },
    },
  },
  {
    name: "task_create",
    description: "Create a new agent task (auto-routed to the best tier via Smart Router). Returns task_id.",
    inputSchema: {
      type: "object",
      properties: {
        prompt: { type: "string", description: "The natural-language task description" },
        tier: { type: "string", description: "Override tier (else 'auto')" },
      },
      required: ["prompt"],
    },
  },
  {
    name: "task_list",
    description: "List recent tasks (status filter optional).",
    inputSchema: {
      type: "object",
      properties: {
        status: {
          type: "string",
          enum: ["todo", "running", "done", "failed", "cancelled"],
          description: "Filter by status",
        },
      },
    },
  },
  {
    name: "task_get",
    description: "Get full task details (prompt, tier, result, error, tokens, latency) by id.",
    inputSchema: {
      type: "object",
      properties: { id: { type: "string", description: "Task id (e.g. task-0001)" } },
      required: ["id"],
    },
  },
  {
    name: "auto_chat",
    description: "Call the LLM through the Smart Tier Auto-Router. Provide messages, get a response. Tier is auto-picked from prompt content.",
    inputSchema: {
      type: "object",
      properties: {
        messages: {
          type: "array",
          description: "OpenAI-style messages array [{role, content}, ...]",
          items: {
            type: "object",
            properties: {
              role: { type: "string", enum: ["system", "user", "assistant"] },
              content: { type: "string" },
            },
          },
        },
        max_tokens: { type: "number" },
        temperature: { type: "number" },
      },
      required: ["messages"],
    },
  },
  {
    name: "worktree_create",
    description: "Create a git worktree for an agent task (each task runs in isolation).",
    inputSchema: {
      type: "object",
      properties: {
        task_id: { type: "string", description: "Task id to bind worktree to" },
        branch: { type: "string", description: "Override branch name" },
      },
      required: ["task_id"],
    },
  },
  {
    name: "list_tiers",
    description: "List all available model tiers with their fallback chain (so the agent can see what models are available).",
    inputSchema: { type: "object", properties: {} },
  },
];

// === Tool implementations ================================

async function callAQ(path: string, init?: RequestInit) {
  const r = await fetch(`${AQ_PROXY}${path}`, {
    ...init,
    headers: {
      "Content-Type": "application/json",
      Authorization: AQ_PROXY_AUTH,
      ...(init?.headers ?? {}),
    },
  });
  if (!r.ok) {
    const t = await r.text();
    throw new Error(`AQ proxy ${r.status}: ${t.slice(0, 300)}`);
  }
  return r.json();
}

async function exec(cmd: string, args: string[]): Promise<string> {
  // Use Bun.spawn if available (much faster), else fall back to child_process
  if (typeof (globalThis as any).Bun !== "undefined" && typeof (globalThis as any).Bun.spawn === "function") {
    const p = (globalThis as any).Bun.spawn({ cmd, args, stdout: "pipe", stderr: "pipe" });
    const out = await new Response(p.stdout).text();
    const err = await new Response(p.stderr).text();
    await p.exited;
    if (p.exitCode !== 0) throw new Error(`${cmd} ${args.join(" ")} failed: ${err}`);
    return out;
  }
  // Node fallback
  const { spawn } = await import("node:child_process");
  return await new Promise((resolve, reject) => {
    const p = spawn(cmd, args);
    let out = "";
    let err = "";
    p.stdout.on("data", (d) => (out += d.toString()));
    p.stderr.on("data", (d) => (err += d.toString()));
    p.on("close", (code) => {
      if (code !== 0) reject(new Error(`${cmd} ${args.join(" ")} failed: ${err}`));
      else resolve(out);
    });
    p.on("error", reject);
  });
}

async function toolCortexQuery(args: { query: string; limit?: number }): Promise<unknown> {
  // Tauri-side: invoke('cortex_query', { query, limit })
  // Since we can't call Tauri IPC from this Bun server, we shell out to cortex.exe
  const limit = args.limit ?? 10;
  const home = process.env.USERPROFILE ?? process.env.HOME ?? ".";
  const cortexExe = `${home}\\.cortex\\bin\\cortex.exe`;
  try {
    const out = await exec(cortexExe, ["query", args.query, "--limit", String(limit)]);
    return { output: out.trim() };
  } catch (e) {
    return { error: String(e), hint: "cortex binary not available; install via Cortex skill" };
  }
}

async function toolCortexExplain(args: { symbol: string }): Promise<unknown> {
  const home = process.env.USERPROFILE ?? process.env.HOME ?? ".";
  const cortexExe = `${home}\\.cortex\\bin\\cortex.exe`;
  try {
    const out = await exec(cortexExe, ["explain", args.symbol]);
    return { output: out.trim() };
  } catch (e) {
    return { error: String(e) };
  }
}

async function toolCortexFiles(args: { path_glob?: string }): Promise<unknown> {
  const home = process.env.USERPROFILE ?? process.env.HOME ?? ".";
  const cortexExe = `${home}\\.cortex\\bin\\cortex.exe`;
  const argv = ["files"];
  if (args.path_glob) argv.push("--path", args.path_glob);
  try {
    const out = await exec(cortexExe, argv);
    return { output: out.trim() };
  } catch (e) {
    return { error: String(e) };
  }
}

async function toolGitStatus(): Promise<unknown> {
  const branch = (await exec("git", ["rev-parse", "--abbrev-ref", "HEAD"])).trim();
  const status = (await exec("git", ["status", "--short"])).trim();
  const log = (await exec("git", ["log", "--oneline", "-10"])).trim();
  return { branch, status, recent_commits: log };
}

async function toolGitDiff(args: { staged?: boolean; branch?: string }): Promise<unknown> {
  const argv = ["diff"];
  if (args.staged) argv.push("--staged");
  if (args.branch) argv.push(args.branch);
  const diff = (await exec("git", argv)).trim();
  return { diff: diff.slice(0, 5000), truncated: diff.length > 5000 };
}

async function toolTaskCreate(args: { prompt: string; tier?: string }): Promise<unknown> {
  const r = await callAQ("/v1/tasks", {
    method: "POST",
    body: JSON.stringify({ prompt: args.prompt, tier: args.tier ?? "auto" }),
  });
  return r;
}

async function toolTaskList(args: { status?: string }): Promise<unknown> {
  const q = args.status ? `?status=${args.status}` : "";
  const r = await callAQ(`/v1/tasks${q}`);
  return r;
}

async function toolTaskGet(args: { id: string }): Promise<unknown> {
  const r = await callAQ(`/v1/tasks/${args.id}`);
  return r;
}

async function toolAutoChat(args: {
  messages: { role: string; content: string }[];
  max_tokens?: number;
  temperature?: number;
}): Promise<unknown> {
  const r = await callAQ("/v1/auto/chat/completions", {
    method: "POST",
    body: JSON.stringify(args),
  });
  return r;
}

async function toolWorktreeCreate(args: { task_id: string; branch?: string }): Promise<unknown> {
  // POST /v1/worktrees/<task_id>
  const r = await callAQ(`/v1/worktrees/${args.task_id}`, {
    method: "POST",
    body: JSON.stringify({ branch: args.branch }),
  });
  return r;
}

async function toolListTiers(): Promise<unknown> {
  const r = await callAQ("/v1/models");
  return r;
}

const TOOL_IMPLS: Record<string, (args: any) => Promise<unknown>> = {
  cortex_query: toolCortexQuery,
  cortex_explain: toolCortexExplain,
  cortex_files: toolCortexFiles,
  git_status: toolGitStatus,
  git_diff: toolGitDiff,
  task_create: toolTaskCreate,
  task_list: toolTaskList,
  task_get: toolTaskGet,
  auto_chat: toolAutoChat,
  worktree_create: toolWorktreeCreate,
  list_tiers: toolListTiers,
};

// === JSON-RPC 2.0 dispatcher ==============================

interface JsonRpcRequest {
  jsonrpc: "2.0";
  id: number | string;
  method: string;
  params?: unknown;
}

interface JsonRpcResponse {
  jsonrpc: "2.0";
  id: number | string | null;
  result?: unknown;
  error?: { code: number; message: string; data?: unknown };
}

function jsonRpc(id: number | string | null, result?: unknown, error?: { code: number; message: string; data?: unknown }): JsonRpcResponse {
  const r: JsonRpcResponse = { jsonrpc: "2.0", id };
  if (error) r.error = error;
  else r.result = result;
  return r;
}

async function handleRpc(req: JsonRpcRequest): Promise<JsonRpcResponse> {
  try {
    switch (req.method) {
      case "initialize":
        return jsonRpc(req.id, {
          protocolVersion: "2024-11-05",
          serverInfo: { name: "aq-mcp-server", version: "0.1.0" },
          capabilities: { tools: {} },
        });
      case "tools/list":
        return jsonRpc(req.id, { tools: TOOLS });
      case "tools/call": {
        const params = req.params as { name: string; arguments?: Record<string, unknown> } | undefined;
        if (!params?.name) return jsonRpc(req.id, null, { code: -32602, message: "missing tool name" });
        const impl = TOOL_IMPLS[params.name];
        if (!impl) return jsonRpc(req.id, null, { code: -32601, message: `unknown tool: ${params.name}` });
        const result = await impl(params.arguments ?? {});
        return jsonRpc(req.id, {
          content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
          isError: false,
        });
      }
      case "notifications/initialized":
        // Client notification — ignore but acknowledge
        return jsonRpc(req.id, {});
      case "ping":
        return jsonRpc(req.id, {});
      default:
        return jsonRpc(req.id, null, { code: -32601, message: `unknown method: ${req.method}` });
    }
  } catch (e) {
    return jsonRpc(req.id, null, { code: -32000, message: String(e) });
  }
}

// === Express server =======================================

const app = express();
app.use(express.json({ limit: "10mb" }));

app.get("/health", (_req, res) => {
  res.json({ ok: true, service: "aq-mcp-server", version: "0.1.0", tools: TOOLS.length });
});

app.get("/tools", (_req, res) => {
  res.json({ tools: TOOLS });
});

app.post("/mcp", async (req, res) => {
  const body = req.body as JsonRpcRequest | JsonRpcRequest[];
  if (Array.isArray(body)) {
    const results = await Promise.all(body.map(handleRpc));
    res.json(results);
  } else {
    res.json(await handleRpc(body));
  }
});

// Convenience: single-tool call shortcut (not standard MCP, but handy for curl)
app.post("/call/:tool", async (req, res) => {
  const name = req.params.tool;
  const impl = TOOL_IMPLS[name];
  if (!impl) return res.status(404).json({ error: `unknown tool: ${name}` });
  try {
    const result = await impl(req.body ?? {});
    res.json(result);
  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
});

app.listen(PORT, () => {
  console.log(`[aq-mcp] listening on http://127.0.0.1:${PORT}`);
  console.log(`[aq-mcp] ${TOOLS.length} tools exposed: ${TOOLS.map((t) => t.name).join(", ")}`);
  console.log(`[aq-mcp] AQ proxy = ${AQ_PROXY}`);
});