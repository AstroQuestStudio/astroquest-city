# AstroQuest City — Roadmap stratégique

**Validé le 2026-09-23** — pivot majeur : on construit **l'Agent OS parfait** (Cline/Agetor-like) AVANT de finaliser la couche de viz Autopolis.

---

## 🎯 Vision

**AstroQuest City = un Jarvis/Ultron local-first**
- Tauri + R3F (3D viz) — LA COUCHE DE VIZ (Phase 3, plus tard)
- Opencode CLI — LE MOTEUR (déjà installé ✅)
- Cortex pre-index — LA MÉMOIRE (90% token savings ✅)
- Multi-provider fallback — LA RÉSILIENCE (✅ livré)
- Cloudflare Worker `ao-relay` — LA MULTI-IDENTITÉ (✅ livré)
- Per-user API keys — LA SOUVERAINETÉ (✅ livré)

L'utilisateur final tape juste une intention en langage naturel, AQ choisit tout seul quel(s) agent(s) appeler, quel tier utiliser, fallback si quota, viz 3D en prime.

---

## 📐 Architecture cible (post-Phase 1)

```
┌──────────────────────────────────────────────────────────────┐
│  AQ OS UI (Tauri cockpit — minimal & fonctionnel)            │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────────┐ │
│  │ Code     │ │ KB       │ │ Dev      │ │ Smart tier       │ │
│  │ panel    │ │ panel    │ │ playground│ │ (auto-routing)  │ │
│  │ (chat)   │ │ (Cortex) │ │ (shell)  │ │                  │ │
│  └──────────┘ └──────────┘ └──────────┘ └──────────────────┘ │
└──────────────────────────────────────────────────────────────┘
                                  ↓
   ┌─────────────────── Local Proxy :4000 ─────────────────────┐
   │ • Smart Tier Auto-Router                                     │
   │ • Fallback Chains (per tier, 4-6 candidates)                 │
   │ • Round-robin keys (Groq×21, Gemini×12, NVIDIA pool)          │
   │ • Optional Cloudflare Worker ao-relay (multi-IP)             │
   └──────────────────────────────────────────────────────────────┘
                                  ↓
   ┌──── Groq ────┐ ┌── Gemini AQ ──┐ ┌─── NVIDIA NIM ───┐ ┌─ minimax ─┐
   │  free tier   │ │  free tier     │ │  free tier       │ │  paid M3  │
   └──────────────┘ └────────────────┘ └──────────────────┘ └───────────┘
```

---

## 🗓️ Phase 1 — Agent OS Core (semaines 1-3) ← **ON EST ICI**

**Objectif** : cockpit utilisable, agents fonctionnent, fallback robuste, mémoire persistante.

### 1.A. **Fix legacy Cockpit UI** ✅ LIVRÉ (commit `f97fa46` / `d64995e`)
- Ajout des 7 aliases pour les anciens noms du Cockpit UI (`ceo-strategie`, `ceo-recherche`, `mgr-code`, `worker-search`, `worker-format`, `code-builder`, `code-planner`)
- 22 tiers au total (15 modernes + 7 aliases)
- Chaque alias a son propre fallback chain

### 1.B. **Smart Tier Auto-Router** ← **PROCHAINE ÉTAPE** (2-3h)
L'utilisateur tape juste une intention → AQ analyse le prompt (longueur + mots-clés) et route vers le bon tier automatiquement.

**Algorithme de scoring :**
```rust
fn smart_route(prompt: &str) -> &'static str {
    let len = prompt.len();
    let keywords_strategy = ["roadmap", "vision", "strategy", "architect"];
    let keywords_code = ["function", "class", "implement", "fix", "refactor"];
    let keywords_search = ["search", "find", "where", "how does"];
    let keywords_format = ["format", "lint", "prettier", "style"];

    if keywords_strategy.iter().any(|k| prompt.contains(k)) { "tier-8-opus-reflection" }
    else if len > 2000 { "tier-8-opus-reflection" } // long prompt = thinking tier
    else if keywords_format.iter().any(|k| prompt.contains(k)) { "tier-3-formatteur" }
    else if keywords_search.iter().any(|k| prompt.contains(k)) { "tier-4-groq" }
    else if keywords_code.iter().any(|k| prompt.contains(k)) { "tier-7-constructeur" }
    else { "tier-6-ouvrier" } // default: balanced agentic
}
```

**Livrable** : endpoint `/v1/auto/chat/completions` qui auto-route, plus flag `auto=true` sur `/v1/chat/completions`.

### 1.C. **`aq-tasks.json` SQLite-style task queue** (1h)
Chaque tâche = `{id, prompt, tier, status, branch, worktree, started_at, finished_at, result, cost_tokens}`. Persisté dans `~/.aq/tasks.json`. Le cockpit affiche la liste.

### 1.D. **Git worktrees manager** (2h)
- Commande Rust : `git worktree add ../wt-<task-id> -b aq/<task-id>`
- Chaque agent task = 1 worktree isolé, mergé sur validation user
- Évite les conflits entre agents parallèles

### 1.E. **Kanban UI simple** (3h)
Sidebar Tauri avec 3 colonnes : **Todo / Running / Done**. Click sur une carte → ouvre le détail (prompt, tier utilisé, output, branch, cost).

### 1.F. **MCP server scaffold** (3h)
Serveur MCP local sur port 6789 qui expose :
- `cortex_query` — search indexé
- `cortex_files` — file lister
- `git_status`, `git_diff` — repo state
- `agent_run` — spawn agent task
- Compatible avec Cline, OpenHands, Claude Code

### 1.G. **Cline CLI intégration** (1h)
Optionnel : `npm install -g @anthropic-ai/cline` ou installer le binaire. Config pour pointer vers notre proxy local. Cline devient un client parmi d'autres.

### 1.H. **Context epochs** (1h)
Compaction auto de l'historique : tous les 10 messages, on résume via tier-3-formatteur et on stocke. Évite la saturation du prompt.

### 1.I. **Test 50 agents en parallèle** (3h)
Stress test : lancer 50 agents en parallèle sur des tasks courtes (format/grep/lint), mesurer throughput, latence, fail rate. Ajuster le rate-limiting du proxy si besoin.

---

## 🗓️ Phase 2 — Robustification + Intégrations (semaines 4-6)

### 2.A. **LiteLLM config.yaml sur VPS3**
On suit la philosophie LiteLLM (un YAML declaratif pour le routing) mais on garde notre impl Rust qui est 10× plus rapide qu'un proxy Python. Le YAML est généré depuis `~/.aq/keys.json`.

### 2.B. **Obsidian RAG plugin**
Indexation locale du vault Obsidian via FAISS/Chroma. Cline/AQ peuvent consulter les notes pertinentes.

### 2.C. **Roblox Studio MCP**
Plugin Lua + serveur MCP pour modifier des scripts Roblox depuis les agents. Worktree dédié par projet Roblox.

### 2.D. **VPS pool (Plan B)**
3-5 VPS Hetzner CX22 (€4.50/mois) en reverse-proxy vers LiteLLM VPS3. AQ round-robin sur 5 IPs fixes en plus des millions CF.

### 2.E. **P2P mutualisation entre potes (Plan F)**
Si 1-2 potes rejoignent AQ, leurs PC partagent leurs quotas. Un agent distribué pourrait toucher ~84 clés Groq depuis 4 IPs différentes.

### 2.F. **Token economy observability**
Tracking des tokens par tier/agent dans `~/.aq/tokens.jsonl`. Visualisation simple en CLI ou dans le cockpit.

---

## 🗓️ Phase 3 — Autopolis City viz (semaines 7+)

### 3.A. **Réactiver la viz 3D**
- Departments (Logements/Académie/Labo/Atelier/Bibliothèque/Tour CEO/Studio)
- Citizens-agents qui se déplacent entre les bâtiments selon leur état
- Sparks visuels quand un agent travaille
- Le 3D devient une **viz de la Phase 1+2**, pas l'inverse

### 3.B. **Studio Créatif multimodal**
- tier-studio-image (Llama-3.2-90B-Vision, muse-glimmer-30b, paligemma)
- tier-studio-video (cosmos3-nano-reasoner)
- Génération d'images via Imagen 3 (Gemini), Veo 3.1 Lite (vidéo), Lyria 3 (musique)

### 3.C. **CEO Mode "Vibes"**
"Décris ce que tu veux" → orchestrator dispatch sur les bons agents → viz 3D en temps réel.

### 3.D. **VPS static frontend**
Le bundle `apps/city/dist/` est déployé sur VPS3 via Caddy, accessible depuis n'importe où (avec auth basique). L'utilisateur peut voir sa ville de n'importe quel device.

---

## 🎯 Décisions clés (validées 2026-09-23)

| Question | Décision |
|---|---|
| Cible Phase 1 | **AQ OS core** (Cline/Agetor-like), pas de viz 3D |
| Viz 3D Autopolis | Phase 3, désactivée pour l'instant |
| Smart Tier Router | Le prompt décide du tier (pas l'utilisateur) |
| Git worktrees | Isolation par task, mergé sur validation |
| Cline intégration | Backend optionnel (npm i -g cline) |
| LiteLLM | Notre impl Rust + philosophie YAML |
| Multi-IP | Cloudflare Worker `ao-relay` ✅ |

---

## 📊 Métriques de succès Phase 1

- [ ] **0 "Failed to fetch"** dans le cockpit UI après 24h
- [ ] **Smart router hit rate 80%+** (le bon tier est choisi sans intervention user)
- [ ] **Fallback success rate 99%+** (si primary échoue, fallback répond <5s)
- [ ] **50 agents en parallèle** sans saturation du proxy
- [ ] **Context epochs** limitent la taille du prompt à <10k tokens même après 50 messages
- [ ] **MCP server** répond aux tools `cortex_query`, `git_status`, `agent_run`

---

## 🚀 Quick wins pour la première semaine

1. ✅ Aliases legacy (fait)
2. ⏳ Smart Tier Router (2h)
3. ⏳ `aq-coder.ps1` — wrapper qui permet à Mavis de coder via AQ (économise le plan MiniMax)
4. ⏳ Test live de tous les 22 tiers depuis le Cockpit
5. ⏳ Task queue SQLite simple + Kanban sidebar
6. ⏳ Git worktrees manager

---

## 🔗 Liens utiles

- Repo: https://github.com/AstroQuestStudio/astroquest-city
- VPS3 (relay + LiteLLM): 46.224.170.108
- App Tauri: `apps/city/src-tauri/target/release/create-tauri-react.exe`
- Local proxy: `http://127.0.0.1:4000`
- OpenCode CLI: `http://127.0.0.1:4097`
- Cloudflare Worker: `apps/relay-cf/` (à déployer)
- Cortex binary: `C:\Users\trufa\Cortex\target\release\cortex.exe`
- Gemini AQ keys test: `C:\Users\trufa\Downloads\gemini api keys.txt`
- Groq keys: `C:\Users\trufa\Downloads\keys.txt`
- NVIDIA keys: `C:\Users\trufa\Downloads\nvidia api keys.txt`

---

## 📅 Timeline résumée

```
Semaine 1 (now):     ━━━━━━━━━━ Phase 1.A-C (fix + smart router + task queue)
Semaine 2:           ━━━━━━━━━━ Phase 1.D-F (worktrees + kanban + MCP)
Semaine 3:           ━━━━━━━━━━ Phase 1.G-I (Cline + epochs + stress test)
Semaine 4-6:         ━━━━━━━━━━ Phase 2.A-F (robustif + VPS pool + Obsidian)
Semaine 7+:          ━━━━━━━━━━ Phase 3.A-D (viz 3D + Studio + Vibes mode)
```