# 🏙️ AstroQuest City

> **A "Jarvis / Ultron"-style AI agent cockpit, local-first, run on YOUR PC.**

[![Tauri](https://img.shields.io/badge/Tauri-2.11-FFC131?logo=tauri)](https://tauri.app)
[![React](https://img.shields.io/badge/React-19-61DAFB?logo=react)](https://react.dev)
[![R3F](https://img.shields.io/badge/React_Three_Fiber-9-000?logo=three.js)](https://r3f.docs.pmnd.rs)
[![Rust](https://img.shields.io/badge/Rust-1.85-DEA584?logo=rust)](https://rust-lang.org)
[![OpenCode](https://img.shields.io/badge/OpenCode-1.18-000)](https://github.com/anomalyco/opencode)

---

## 🌟 Vision

**AstroQuest City** is a local-first AI agent cockpit that turns your computer into a living, breathing **3D city** of AI agents — CEOs, managers, workers, coders — that you can **see working in real-time**, talk to via **voice**, and deploy to **edit files, run commands, install packages**, all powered by **21+ parallel LLM workers** using your own API keys.

> Inspired by [Autopolis.city](https://autopolis.city) and the open-source Jarvis/Ultron trend.
> Built on the shoulders of **OpenCode CLI** (anomalyco, 209k stars) and a personal tool called **Cortex** (Rust code context engine, 90% token savings).

---

## 🎬 What it does

```
                          ┌─────────────────────────────┐
                          │   🏙️ ASTROQUEST CITY (Tauri) │
                          └─────────────────────────────┘
                                       │
        ┌──────────────────────────────┼──────────────────────────────┐
        │                              │                              │
   🔥 Code Atelier              🧠 Knowledge Panel           🔑 Settings
   (OpenCode local CLI)         (Cortex queries)             (Your API keys)
        │                              │                              │
        │       ┌──────────────────────┴──────────────────────┐       │
        │       │                                             │       │
        │       ▼                                             ▼       │
        │  ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐  │
        │  │ CEO     │───▶│ Worker  │    │ Search  │    │ Format  │  │
        │  │ Strat.  │    │ Code    │    │ Worker  │    │ Worker  │  │
        │  └─────────┘    └─────────┘    └─────────┘    └─────────┘  │
        │       │              │              │              │     │
        │       ▼              ▼              ▼              ▼     │
        │  ┌───────────────────────────────────────────────────────┐ │
        │  │ Local LLM Proxy  127.0.0.1:4000  (Rust std::net)     │ │
        │  │  → Groq gpt-oss-20b (FREE)                            │ │
        │  │  → Groq gpt-oss-120b ×21 keys (round-robin)         │ │
        │  │  → MiniMax M3 / M2.7 (Token Plan)                     │ │
        │  └───────────────────────────────────────────────────────┘ │
        └─────────────────────────────────────────────────────────────────┘
```

**In short**: OpenCode reads/writes/edits files on your PC, Cortex answers "where is X in this codebase" with 90% fewer tokens, your 21 Groq keys + MiniMax Token Plan run in parallel through a local Rust proxy. Everything runs **offline** (no API keys leak to anyone but the upstream providers).

---

## 🚀 Features

### 🖥️ **Tauri Desktop App** (Windows / macOS / Linux)
- Native window, blazing fast (no Electron)
- Spawns `opencode serve` + local LLM proxy at launch
- File system access, native dialogs, OS notifications
- Offline-first: no internet required for the app shell

### 🔥 **Code Atelier** (powered by OpenCode CLI)
- Chat with `build` agent (can read, edit, run code)
- Chat with `plan` agent (read-only analysis)
- Native folder picker → choose any local repo
- File browser + live file viewer
- **Shell tab** (Tauri only): run any command on your PC with full history

### 🧠 **Knowledge Panel** (powered by Cortex)
- **query** — semantic + BM25 search (FR ↔ EN)
- **explain** — get callers/relations without reading the file
- **grep** — literal text search, gitignore-aware
- **files** — find files by name fragment
- Saves ~90% of tokens vs reading files in full

### 🔑 **Per-User API Keys** (local-only)
- Stored in `~/.aq/keys.json` (chmod 600 on Unix)
- **Never sent to VPS, never sent anywhere** — only used to talk to Groq/MiniMax directly
- Manage pool of up to **21+ Groq keys** + MiniMax Token Plan + optional Anthropic/OpenAI
- Regenerate opencode config on save

### 🏙️ **3D City Visualization** (R3F + drei + postprocessing)
- **CeoTower** (helipad + antenna + gold halo) for CEO agents
- **WorkerHut** for worker agents
- **CodeAtelier** (forge + chimney + sparks + animated hammer) for opencode agents
- **DelegationArrow** with particle flow between buildings
- **VoiceOrb** at center (Ultron-style, pulses when you speak)
- **NPCSpawner** (16 patrolling NPCs)
- **AgentLabel** (billboard text with state) + **ActivityBurst** (particles around active agents)
- Bloom + ChromaticAberration + Vignette post-processing

### 🎤 **Voice Input** (Ultron-style)
- Web Speech API (browser) + native mic access (Tauri)
- Wake word: **"astro"** (e.g. "astro ping", "astro lance all", "astro stop")
- TTS feedback via speech synthesis

### 🌐 **Multi-PC Sync** (optional)
- VPS3 acts as WebSocket relay between your PCs and 1-2 friends
- **State sync only** — your API keys never leave your machine
- Each friend has their own keys, their own agents, their own armory

### 🛡️ **Security**
- `edge.astroquest.fr` is **HTTP basic_auth protected**
- All Tauri IPC commands require local execution
- API keys: chmod 600, never logged, never transmitted

---

## 📁 Project structure

```
AstroQuest City/
├── apps/
│   ├── city/                  # Tauri + React 3D cockpit (THE APP)
│   │   ├── src/
│   │   │   ├── features/
│   │   │   │   ├── city-scene/        # R3F 3D scene (city, agents, NPCs)
│   │   │   │   ├── city-dashboard/    # Main HUD with WS sync, tests, voice
│   │   │   │   ├── code-panel/        # OpenCode chat + shell tabs
│   │   │   │   ├── knowledge-panel/   # Cortex queries
│   │   │   │   ├── settings-panel/    # Your API keys
│   │   │   │   └── dev-playground/    # Debug all endpoints
│   │   │   ├── lib/
│   │   │   │   ├── use-websocket.ts    # WS sync
│   │   │   │   ├── use-voice.ts        # Voice hook (Ultron-style)
│   │   │   │   └── use-tauri.ts        # IPC bridge
│   │   │   └── config/env.ts
│   │   └── src-tauri/
│   │       └── src/
│   │           ├── main.rs            # IPC commands + setup
│   │           ├── opencode.rs        # Spawn/manage opencode CLI
│   │           ├── cortex.rs          # Cortex binary wrapper
│   │           ├── keys.rs            # Local API key store
│   │           └── local_proxy.rs     # HTTP proxy Groq/MiniMax
│   ├── backend/               # Bun + Hono backend (VPS only)
│   │   └── src/index.ts       # WS + REST + agent registry + opencode bridge
│   ├── infra/                 # LiteLLM stack (docker-compose)
│   │   └── litellm/
│   │       └── config.yaml    # 6 tiers: tier-7-constructeur, tier-7-fast,
│   │                           # tier-6-ouvrier, tier-6-fast,
│   │                           # tier-4-groq (21 keys), tier-3-formatteur
│   └── sim-core-ref/          # Legacy sim-core (reference)
├── opencode/                 # OpenCode CLI config + workspace
│   ├── opencode.json          # Provider config (auto-regenerated from user keys)
│   └── workspace/            # Test repo for opencode
├── setup.sh                   # One-line auto-installer
├── import-keys.ps1            # Import your keys.txt + minimax to ~/.aq/keys.json
├── deploy-frontend.ps1        # Build + SCP + chmod 755 for web
├── start-prod.bat              # Launch release .exe cleanly
└── docs/
    ├── MODELS.md              # Full model reference (Groq + MiniMax)
    └── ARCHITECTURE.md        # (WIP) Deep dive
```

---

## ⚡ Quick start

### 🖥️ **For your PC (recommended — fully local)**

1. **Install dependencies**
   - [Rust](https://rustup.rs)
   - [Bun](https://bun.sh) (only for web deployment, not needed for desktop)
   - [Visual Studio Build Tools 2022](https://visualstudio.microsoft.com/downloads/) (Windows: with "Desktop C++ workload")
   - [opencode CLI](https://opencode.ai) (auto-installed by setup.sh)
   - [Cortex](https://github.com/yourname/cortex) (optional but recommended)

2. **Run auto-installer**
   ```bash
   git clone https://github.com/YOURUSER/astroquest-city.git
   cd astroquest-city
   ./setup.sh
   ```

3. **Configure your API keys**
   ```powershell
   .\import-keys.ps1
   # Reads keys.txt + minimax token, writes ~/.aq/keys.json
   ```

4. **Build & launch**
   ```bash
   cd apps/city
   npm install
   cd src-tauri && cargo build --release
   # OR just double-click the Desktop shortcut
   ```

5. **Open Code Atelier** → pick a folder → start chatting with your agents

### 🌐 **For web access (optional, uses VPS3 as relay)**

```bash
# Deploy the frontend to your VPS
cd apps/city
npm run build
./deploy-frontend.ps1

# Then visit https://edge.astroquest.fr/ (auth required)
# Credentials are in /opt/aq-app/infra/.env
```

---

## 🧠 The "Autopolis" idea

> *"A living city where you see your AI agents working — and you can talk to them."*

Inspired by [Autopolis.city](https://autopolis.city), AstroQuest City is built around the idea that **managing AI agents should feel like watching a city come to life**:

| Autopolis concept | AstroQuest City implementation |
|---|---|
| Buildings | CEO towers, worker huts, code forges |
| Traffic | Delegation arrows with particle flow |
| Citizens | Patrolling NPCs, agent avatars |
| City pulse | Bloom + vignette post-processing |
| Day/night | Dynamic lighting, neon emissive windows |
| Talk to city | Voice orb at center, Web Speech API |
| CEO strategy | Top-tier buildings with helipad + antenna |
| Workers | Smaller buildings, hot when busy |
| Code Atelier | 3D forge with chimney, sparks, animated hammer |

The user is the **mayor**: they see the city at a glance, can drill into any building, speak commands, and watch the city pulse with activity.

---

## 🏛️ Architecture in detail

### Tier routing (smart)

```
Tier 3 (gpt-oss-20b)      → trivial, format       → 300ms, FREE
Tier 4 (gpt-oss-120b ×21) → code, search, chat    → 350ms, FREE
Tier 6 (MiniMax M2.7)     → rephrasing, planning   → 1s
Tier 7-fast (MiniMax M3)  → complex, code refactor  → 5-8s
```

The frontend router picks the right tier based on prompt length + complexity keywords. If you pass 200 chars or words like "refactor/architect/design/analyze/debug", it picks Tier 7. Otherwise Tier 4.

### Local LLM proxy (Rust, std::net)

Listens on `127.0.0.1:4000`:
- `POST /v1/chat/completions` → forwards to Groq or MiniMax based on `model` field
- `GET /v1/models` → returns the 5 available tiers
- `GET /health` → liveness check
- **Round-robin** on Groq keys for parallel throughput (up to 21 in flight)

OpenCode points its provider at `http://127.0.0.1:4000/v1` so all agent calls go through this proxy using **your local keys**.

### Cortex integration

Cortex is a Rust tool the user already has. AstroQuest City invokes it via:
- `cortex query "<question>"` — semantic + BM25 search, returns symbols with `file:line`
- `cortex explain "<symbol>"` — returns callers/callees/relations without reading the file
- `cortex grep "<text>"` — literal search, gitignore-aware
- `cortex files "<name>"` — find file by name fragment
- `cortex list` — list indexed projects

This shaves **~90% of tokens** vs reading them in full.

---

## 📦 OpenCode CLI integration

We use OpenCode CLI (by anomalyco, https://github.com/anomalyco/opencode) as the local coding engine:
- Spawned by Tauri on app launch (`opencode serve --port 4097`)
- Workspace defaults to `~/Documents`
- Two built-in agents: `build` (can edit) and `plan` (read-only)
- Talks to our local LLM proxy via `provider.aq-litellm` in its config

OpenCode provides the OpenAI-compatible HTTP API (`/global/health`, `/session`, `/session/:id/message`, etc.) which we wrap in Tauri IPC commands.

---

## 🔐 Security & privacy

- **edge.astroquest.fr** is HTTP basic_auth (user/pass in `infra/.env`)
- Your API keys are stored in `~/.aq/keys.json` with `chmod 600`
- The local proxy only talks to **Groq** and **MiniMax** directly (HTTPS)
- The VPS never sees your API keys (only multi-PC state sync)
- Tauri apps spawn their own processes; no shared state between users
- Multi-PC sync is **opt-in** per project/agent

---

## 🛠️ Development

### Run Tauri in dev mode (hot-reload frontend)

```bash
cd apps/city
npm run tauri dev
```

This starts the Vite dev server + Rust in debug mode (will use `devUrl`).

### Build production Tauri release

```bash
cd apps/city
cd src-tauri && cargo build --release
# OR with bundle (.msi / .dmg / .AppImage)
cd src-tauri && cargo tauri build
```

The release binary is at `apps/city/src-tauri/target/release/create-tauri-react.exe` (~16 MB, includes the bundled `dist/`).

### Deploy web frontend

```bash
cd apps/city
npm run build
cd ../.. && powershell deploy-frontend.ps1
```

Builds `dist/`, SCPs to VPS3 at `/var/www/aq/`, fixes permissions (`chmod 755`), and Caddy serves it at `https://edge.astroquest.fr/`.

---

## 🤝 Contributing

This is currently a **personal project** for the author (MiniMax002233) and 1-2 friends. If you want to use it:

1. Clone the repo
2. Run `./setup.sh`
3. Add your own API keys via `import-keys.ps1`
4. Build your own .exe

Each user has their own:
- API keys (21 Groq + MiniMax Token Plan)
- Local LiteLLM proxy config
- OpenCode CLI workspace
- Tauri app instance

The VPS is just a relay for state sync — not a single point of failure for you.

---

## 📜 License

MIT (with no warranty). Use at your own risk. You are responsible for your own API key usage and costs.

---

## 🙏 Acknowledgments

- **[OpenCode CLI](https://github.com/anomalyco/opencode)** — the open-source Claude Code alternative that powers the coding agents
- **[Cortex](https://github.com/)** — the Rust code context engine that gives 90% token savings
- **[Autopolis.city](https://autopolis.city)** — the inspiration for the 3D agent city metaphor
- **[LiteLLM](https://github.com/BerriAI/litellm)** — the OpenAI-compatible proxy used on VPS3 for web fallback
- **[Tauri](https://tauri.app) + [React Three Fiber](https://r3f.docs.pmnd.rs)** — for the 3D city UI that runs on every PC
- **[Groq](https://console.groq.com)** — the free tier that makes 21-key parallel possible
- **[MiniMax](https://platform.MiniMax.io)** — the M2.7 / M3 models for heavy reasoning

---

## 📌 Roadmap

- [x] Per-user API keys (local-only)
- [x] Local LLM proxy with round-robin
- [x] OpenCode CLI integration (build + plan agents)
- [x] Cortex knowledge panel
- [x] 3D city with CEO/manager/worker/code-builder hierarchy
- [x] Voice input with wake word "astro"
- [x] WebSocket multi-PC sync
- [x] HTTP basic_auth on web
- [x] Tauri release build with bundled dist
- [ ] Cortex auto-context injection before each agent task
- [ ] 40 agents in parallel (worker pool)
- [ ] Persistent task queue (SQLite) — tasks survive app close
- [ ] File watcher daemon (Rust) — edits trigger 3D sparks
- [ ] Vibes mode UI — "describe what you want" → orchestrator dispatches
- [ ] Tauri bundle .msi installer for distribution
- [ ] Multi-PC auth tokens for friend invitations
- [ ] Adaptive context summary (auto-summarize >500k tokens)
- [ ] Shared knowledge base between friends (opt-in per project)
- [ ] System tray for quick access
- [ ] Background tasks (cron-like scheduler)
- [ ] Auto-PR creation (push to GitHub from agents)

---

> *Built for one developer (me) and 1-2 friends. Not for the public. But if you read this far and want to run your own local AI agent army, the door is open.* 🚀