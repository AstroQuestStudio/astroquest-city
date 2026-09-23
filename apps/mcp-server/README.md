# AQ MCP Server

JSON-RPC 2.0 over HTTP server that exposes **AstroQuest City** tools to MCP clients
(Cline, Claude Code, OpenHands, any MCP-compatible agent).

## Tools exposed

| Tool | What it does |
|---|---|
| `cortex_query` | Search the Cortex pre-indexed codebase (90% token savings) |
| `cortex_explain` | Explain a code symbol by name |
| `cortex_files` | List indexed files (path glob filter) |
| `git_status` | Branch + staged/unstaged + recent commits |
| `git_diff` | Show staged or unstaged git diff |
| `task_create` | Spawn a new agent task (auto-routed tier) |
| `task_list` | List recent tasks (optional status filter) |
| `task_get` | Get full task details by id |
| `auto_chat` | Call the LLM via Smart Tier Auto-Router |
| `worktree_create` | Create an isolated git worktree for an agent task |
| `list_tiers` | Show all available model tiers + fallback chains |

## Setup

```bash
cd apps/mcp-server
bun install              # uses Bun (install via https://bun.sh if needed)
bun start                # listens on http://127.0.0.1:6789
```

Environment variables:
- `AQ_MCP_PORT` (default 6789)
- `AQ_PROXY` (default http://127.0.0.1:4000 — the AQ local proxy)
- `AQ_PROXY_AUTH` (default "Bearer sk-aq-local")

## Endpoints

- `GET /health` — service health
- `GET /tools` — tool list (non-RPC)
- `POST /mcp` — standard JSON-RPC 2.0 endpoint (initialize, tools/list, tools/call)
- `POST /call/:tool` — shortcut: call a tool directly with a JSON body

## Example (curl)

```bash
# List available tools
curl http://127.0.0.1:6789/tools

# Standard MCP initialize
curl -X POST http://127.0.0.1:6789/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}'

# Call a tool via JSON-RPC
curl -X POST http://127.0.0.1:6789/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0",
    "id":2,
    "method":"tools/call",
    "params":{"name":"auto_chat","arguments":{"messages":[{"role":"user","content":"Write a Rust hello world"}]}}
  }'

# Shortcut: call directly
curl -X POST http://127.0.0.1:6789/call/task_list -d '{}' -H "Content-Type: application/json"
```

## Wire with Cline / Claude Code

In your client's MCP config, add:

```json
{
  "mcpServers": {
    "aq": {
      "url": "http://127.0.0.1:6789/mcp",
      "transport": "http"
    }
  }
}
```

Then the agent can call `task_create`, `cortex_query`, `auto_chat`, etc. directly.