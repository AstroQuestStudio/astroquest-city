# 🏙️ AstroQuest City — ROADMAP

> **Mission** : Créer un cockpit visuel ultime pour orchestrer une armée d'agents IA multi-providers, gratuit par défaut, aussi puissant (voire plus) que Claude Code en terminal — avec une ville 3D style "Classic Neon" qui prend vie sous tes yeux.
>
> **Inspiration visuelle** : [Autopolis.city](https://autopolis.city/) — 50 agents dans une ville néon contemplative.
> **Notre avantage** : 200+ agents, orchestrateur de code réel, multi-LLM, coût quasi-nul.

---

## 📑 Table des matières

1. [Vision & différenciation](#1-vision--différenciation)
2. [Direction artistique](#2-direction-artistique)
3. [Architecture technique](#3-architecture-technique)
4. [Stack détaillé](#4-stack-détaillé)
5. [Pyramide des 9 Tiers](#5-pyramide-des-9-tiers)
6. [Protocoles & formats](#6-protocoles--formats)
7. [Plan d'exécution 8 semaines](#7-plan-dexécution-8-semaines)
8. [KPIs de succès](#8-kpis-de-succès)
9. [Risques & mitigations](#9-risques--mitigations)
10. [Roadmap post-MVP (Phase 2+)](#10-roadmap-post-mvp-phase-2)
11. [TODOs immédiats](#11-todos-immédiats)
12. [Annexes](#12-annexes)

---

## 1. Vision & différenciation

### 1.1 Le problème
Aujourd'hui, développer avec l'IA = une console, un prompt, du texte qui défile. Pas de vision globale, pas de feedback visuel, pas de coordination multi-agents évidente. Coût élevé dès qu'on consomme sérieusement.

### 1.2 Notre réponse
Une **ville 3D temps réel** où chaque agent IA est un citoyen visible, chaque projet est un bâtiment qui monte, chaque requête est une animation. L'utilisateur devient un **maire** qui orchestre ses agents par la pensée, pas par des lignes de commande.

### 1.3 Pourquoi c'est "ultimate"
- **Multi-provider gratuit-first** : 21 clés Groq + MiniMax Token Plan + Mistral Experiment + Cloudflare Workers AI = volume énorme pour ~0 €
- **9 niveaux d'intelligence** : du micro-formatteur au Grand Architecte Claude Opus
- **JSON TaskSpec strict** : pas de dérive, les agents bon marché reçoivent des specs parfaites
- **Fallback transparent** : si une clé tombe en 429, la suivante prend le relais en ms
- **Local-first** : le PC ne tourne QUE quand tu cliques sur l'.exe
- **Persistance des projets** : les "CEO", skills, MCPs en pause sont sauvegardés et restaurables

### 1.4 Ce que ça fait de plus que Claude Code
| Fonctionnalité | Claude Code terminal | AstroQuest City |
|---|---|---|
| Vue d'ensemble des agents | ❌ | ✅ 200 agents animés |
| Multi-provider avec fallback | ❌ | ✅ Cascade déclarative |
| Coût optimisé | ⚠️ Compteur tokens | ✅ Routing intelligent |
| Projets en pause | ⚠️ Fichiers分散 | ✅ CEOs sauvegardés |
| Feedback visuel | ❌ Texte brut | ✅ Ville 3D |
| Indicateur de progression | ❌ | ✅ Bâtiments qui montent |
| Démarrage à la demande | ✅ | ✅ Sidecar s'éteint avec l'app |

---

## 2. Direction artistique

### 2.1 Référence : Autopolis.city
- Style **"Classic Neon"** : bleu nuit profond + accents néon vibrants
- Vue **3D isométrique** + caméra libre (rotation, zoom, pan)
- **Cycle jour/nuit** avec horloge visible (4:30 → Day 14)
- **Chapitres narratifs** : réveil, choix, croissance, lieux partagés
- Esthétique **cyberpunk contemplative** (pas aggressive, plus chill)

### 2.2 Notre palette
```
Background nuit    #0A0713   (bleu nuit profond)
Sol               #1A1230   (violet sombre)
Bâtiments           #2D1B4E   (violet néon)
Bâtiments actifs    #A855F7   (violet lumineux)
Agents Tier 9      #FFD700   (or — Grand Architecte)
Agents Tier 7-6    #3B82F6   (bleu — MiniMax)
Agents Tier 4      #10B981   (vert — Groq)
Agents Tier 3      #06B6D4   (cyan — formatteur)
Particules         #EC4899   (magenta — travail en cours)
Erreur/429         #EF4444   (rouge — saturation)
Succès             #22C55E   (vert clair — fichier validé)
```

### 2.3 Nos éléments visuels distinctifs
- **Casques colorés par Tier** : violet = Tier 9, bleu = Tier 7, vert = Tier 4, cyan = Tier 3
- **Caserne (Sleeping Quarter)** : bâtiment spécial pour les agents en 429 — animation "ZZZ"
- **Café Central (Shared Streets)** : lieu de rencontre, dropping de nouveaux CEOs
- **Chantiers (Scaffolding)** : bâtiments en construction avec échafaudages 3D
- **Fissures (Cracks)** : apparaissent si couverture de tests < 80%
- **Particules lumineuses** : autour des bâtiments actifs (travail en cours)
- **Mini-map** : en bas à droite, vue de dessus pour la navigation

### 2.4 Layout
```
┌─────────────────────────────────────────────────┐
│  HUD top : Heure ville · Tier actif · Coût jour │
├──────────────┬──────────────────────────────────┤
│              │                                  │
│  Sidebar G   │                                  │
│  · Projets   │       CityCanvas 3D              │
│  · CEOs      │       (R3F, 60 FPS)              │
│  · Skills    │                                  │
│  · MCPs      │                                  │
│              │                                  │
├──────────────┴──────────────────────────────────┤
│  Chat bas : prompts au CEO · logs WebSocket     │
│                                                  │
│  Mini-map                            Settings    │
└─────────────────────────────────────────────────┘
```

---

## 3. Architecture technique

### 3.1 Schéma global (validé)

```
┌─────────────────────────────────────────────────────────┐
│  Tauri 2.0 .exe (Windows) — AstroQuestCity.exe         │
│  ├─ React 18 + Vite + Tailwind + shadcn/ui             │
│  ├─ React Three Fiber + Three.js                       │
│  ├─ Zustand state, React Router                        │
│  └─ Tauri secure store (JWT)                           │
└─────────────────────┬───────────────────────────────────┘
                      │ HTTPS REST + WSS
            🌍 Internet (TLS 1.3)
┌─────────────────────▼───────────────────────────────────┐
│  VPS Hetzner CPX11 (Ubuntu 24.04 LTS)                  │
│  ├─ 🔒 Nginx reverse proxy + Let's Encrypt             │
│  ├─ 🟢 Bun + Hono  (port 8787)                         │
│  │    ├─ /api/tasks/dispatch                            │
│  │    ├─ /api/projects/*                                │
│  │    ├─ /ws (WebSocket events)                         │
│  │    └─ /health                                        │
│  ├─ 🔥 LiteLLM Proxy (port 4000)                       │
│  │    ├─ 21× Groq (round-robin)                         │
│  │    ├─ MiniMax M3 + M2.7                              │
│  │    ├─ Mistral Experiment                             │
│  │    ├─ Cloudflare Workers AI                          │
│  │    └─ (+ Gemini Pro, Claude — Phase 2)               │
│  ├─ 📦 Redis 7 (BullMQ queues)                         │
│  ├─ 🗄️  PostgreSQL 16 (LiteLLM virtual keys, logs)    │
│  └─ 📊 Prometheus + Grafana (optionnel S8)              │
└─────────────────────────────────────────────────────────┘
```

### 3.2 Flux d'une tâche

```
1. User clique sur un bâtiment dans la ville 3D
   OU tape un prompt dans le chat bas
        │
        ▼
2. Frontend → POST /api/tasks/dispatch
   body: { tier_hint, project_id, prompt }
        │
        ▼
3. Backend Bun → Agent Architecte (Tier 9 Claude Sonnet)
   └─ Génère un TaskSpec JSON strict
        │
        ▼
4. WorkflowManager → Router LiteLLM
   └─ Sélectionne le meilleur Tier dispo
        │
        ▼
5. LiteLLM → Provider choisi (ex: Groq Tier 4)
   └─ Fallback automatique si 429
        │
        ▼
6. Réponse → validation → écriture fichier (Tauri FS)
        │
        ▼
7. Événement WSS → frontend
   └─ L'agent concerné fait une animation
   └─ Le bâtiment monte d'un étage
   └─ La sidebar affiche le diff
```

### 3.3 Sécurité
- **VPS** : UFW (22, 80, 443) + Fail2Ban + SSH key only
- **API** : JWT signé avec LITELLM_MASTER_KEY (rotation mensuelle)
- **Tauri** : secure store chiffré (AES via OS keychain)
- **Pas de clés en clair** : tout transite par variables d'env + Doppler-like
- **HTTPS obligatoire** : HSTS, Let's Encrypt auto

---

## 4. Stack détaillé

### 4.1 Frontend (Tauri .exe)

| Technologie | Version | Rôle |
|---|---|---|
| **Tauri** | 2.x | Wrapper desktop, sidecar process |
| **React** | 18.x | UI framework |
| **Vite** | 5.x | Build tool |
| **TypeScript** | 5.x | Type safety |
| **Tailwind CSS** | 4.x | Styling |
| **shadcn/ui** | latest | Composants UI |
| **React Three Fiber** | 8.x | 3D React bindings |
| **Three.js** | 0.16x | 3D engine |
| **@react-three/drei** | latest | Helpers R3F (OrbitControls, etc.) |
| **@react-three/postprocessing** | latest | Bloom, glow néon |
| **Zustand** | 5.x | State management |
| **React Router** | 6.x | Navigation interne |
| **TanStack Query** | 5.x | HTTP caching |
| **react-hook-form** | 7.x | Formulaires |
| **Lucide icons** | latest | Iconographie |

### 4.2 Backend (Bun sur VPS)

| Technologie | Version | Rôle |
|---|---|---|
| **Bun** | 1.x | Runtime JS ultra rapide |
| **Hono** | 4.x | HTTP framework |
| **BullMQ** | 5.x | Queue Redis |
| **ws** | 8.x | WebSocket server |
| **Zod** | 3.x | Validation JSON (TaskSpec) |
| **Drizzle ORM** | latest | Accès PostgreSQL |
| **Pino** | 9.x | Logs structurés |

### 4.3 LLM Router (LiteLLM)

| Technologie | Version | Rôle |
|---|---|---|
| **LiteLLM** | 1.4x | Proxy OpenAI-compatible |
| **Python** | 3.12 | Runtime LiteLLM |
| **PostgreSQL** | 16 | Virtual keys, logs, budgets |
| **Redis** | 7 | Cache, rate-limit state |

### 4.4 Infra

| Technologie | Version | Rôle |
|---|---|---|
| **Hetzner Cloud** | CPX11 (2 vCPU, 2 GB RAM, 40 GB SSD) | Hébergement |
| **Ubuntu** | 24.04 LTS | OS |
| **Nginx** | 1.24 | Reverse proxy |
| **Let's Encrypt / Certbot** | latest | TLS auto |
| **UFW** | built-in | Firewall |
| **Fail2Ban** | latest | Anti-bruteforce |
| **Ansible** (optionnel) | latest | Provisioning automatisé |
| **GitHub Actions** | — | CI/CD (build .exe) |

---

## 5. Pyramide des 9 Tiers

### 5.1 Tableau détaillé (version 2026)

| Tier | Rôle | Provider principal | Fallback 1 | Fallback 2 | RPM cible | Coût |
|---|---|---|---|---|---|---|
| **9** | Grand Architecte | Claude Code Opus 3.7 (sub-process) | DeepSeek-R1 (OpenRouter free) | — | 10 | Payant |
| **8** | Urbaniste Tech Lead | Claude Code Sonnet 3.5 | Gemini Pro (paid) | — | 20 | Payant |
| **7** | Constructeur Lourd | **MiniMax M3** (Token Plan) | Qwen-2.5-Coder-32B (OpenRouter) | Llama-3.3-70B (Groq) | 30 | Token Plan |
| **6** | Ouvrier Rapide | **MiniMax M2.7** (Token Plan) | Groq compound-mini | Llama-3.3-70B (Groq) | 60 | Token Plan |
| **5** | QA / Tests | Mistral Large (Experiment) | Claude 3.5 Haiku | Llama-3.3-70B (Groq) | 40 | Gratuit |
| **4** | **Micro-Worker Pool** | **21× Groq Llama-3.3-70B** (round-robin) | Mistral Experiment | Gemini Flash | **630** (21×30) | Gratuit |
| **3** | Formatteur / Utility | Groq gpt-oss-20b | Cloudflare Workers AI | — | 100 | Gratuit |
| **2** | Scout / RAG Local | Ollama (qwen2.5-coder:7b) | Regex/fallback script | — | illimité | Gratuit (local) |
| **1** | Proxy Router | LiteLLM | Scripts regex maison | — | illimité | Gratuit |

### 5.2 Stratégie de fallback (LiteLLM `config.yaml`)

```yaml
litellm_settings:
  fallbacks:
    - tier-7-constructeur: [tier-6-ouvrier, tier-4-groq]
    - tier-6-ouvrier:      [tier-4-groq]
    - tier-5-qa:           [tier-4-groq]
    - tier-4-groq:         [tier-3-formatteur, mistral-exp]
  context_window_fallbacks:
    - tier-7-constructeur: [tier-4-groq]
  drop_params: true

router_settings:
  routing_strategy: simple-shuffle
  num_retries: 2
  timeout: 30
  allowed_fails: 3
  cooldown_time: 60
```

### 5.3 Comportement en cas de saturation
1. Un provider renvoie `429 Too Many Requests`
2. LiteLLM marque la clé en cooldown (60 sec)
3. La requête bascule sur le fallback suivant en < 100 ms
4. Côté ville 3D : l'agent concerné fait une animation "marche vers la Caserne" + icône "ZZZ"
5. Quand le cooldown est fini, l'agent reprend sa place et son bâtiment reprend

---

## 6. Protocoles & formats

### 6.1 `TaskSpec` JSON (Architecte → Worker)

```json
{
  "task_id": "TASK-2026-0042",
  "timestamp": 1758563524,
  "building_id": "bldg_auth_service",
  "target_filepath": "src/services/auth.service.ts",
  "tier_required": 7,
  "priority": "high | medium | low",
  "architecture_context": "Service d'authentification JWT avec verrous Redis.",
  "strict_dependencies": ["jsonwebtoken", "ioredis", "zod"],
  "interfaces_definition": "export interface UserPayload { id: string; role: string; }",
  "acceptance_criteria": [
    "Tests unitaires couvrant login, register, refresh (couverture > 85%)",
    "Pas d'utilisation de any TypeScript",
    "Erreurs typées via Result<T, E>"
  ],
  "instructions": [
    "Créer la classe AuthService avec méthodes login, register, refresh.",
    "Utiliser Zod pour valider les entrées.",
    "Gérer les erreurs avec Result personnalisé."
  ],
  "expected_output": "code_only | diff | full_file",
  "max_tokens": 4096
}
```

### 6.2 `CityState` WebSocket

```json
{
  "timestamp": 1758563524,
  "day_time": "Day 2 · 14:32",
  "buildings": [
    {
      "id": "bldg_auth",
      "name": "Service Auth",
      "position": [10, 0, -5],
      "level": 3,
      "max_level": 5,
      "status": "under_construction | operational | cracked | abandoned",
      "health_score": 95,
      "files": ["src/services/auth.service.ts", "src/services/auth.test.ts"]
    }
  ],
  "agents": [
    {
      "id": "agent_groq_03",
      "name": "Groq Worker #3",
      "tier": 4,
      "provider": "groq",
      "status": "working | idle | sleeping | traveling",
      "target_building_id": "bldg_auth",
      "position": [10.5, 0, -4.5]
    }
  ],
  "metrics": {
    "tokens_used_today": 1240500,
    "cost_today_usd": 0.42,
    "tasks_completed_today": 47,
    "tasks_failed_today": 2
  }
}
```

### 6.3 `WSSEvent` types

```typescript
type WSSEvent =
  | { type: "AGENT_ACTION"; payload: AgentAction }
  | { type: "BUILDING_UPDATE"; payload: BuildingUpdate }
  | { type: "TASK_COMPLETE"; payload: TaskComplete }
  | { type: "TASK_FAILED"; payload: TaskFailed }
  | { type: "PROVIDER_COOLDOWN"; payload: { provider: string; until: number } }
  | { type: "METRICS_TICK"; payload: Metrics };
```

---

## 7. Plan d'exécution 8 semaines

### Semaine 1 — Fondation MVP

**Objectif** : un `.exe` qui affiche une scène 3D vide et pingue le VPS.

| Jour | Tâche | Stack | Livrable |
|---|---|---|---|
| **J1** | Créer le monorepo (`apps/city/`, `apps/backend/`, `infra/`) | — | Structure commitée |
| **J1** | Init Tauri 2 + React + Vite + Tailwind | Tauri | `cargo tauri dev` qui ouvre une fenêtre vide |
| **J2** | Provision VPS Hetzner (besoin accès user) | Terraform/manuel | VPS Ubuntu accessible en SSH |
| **J2** | Script `bootstrap.sh` : UFW, Nginx, Certbot | Bash | VPS sécurisé, HTTPS OK |
| **J3** | Installer LiteLLM + Redis + PostgreSQL | Docker Compose | LiteLLM up, dashboard `/ui` accessible |
| **J3** | Écrire `config.yaml` LiteLLM avec 1 seul provider test (Mistral) | YAML | Premier appel LLM réussi |
| **J4** | Init backend Bun + Hono | Bun | `/health` répond 200 |
| **J4** | Premier endpoint `/api/tasks/dispatch` (echo) | Hono | Testable via curl |
| **J5** | Scène 3D minimale (sol + grille + 1 cube) | R3F | Ville vide affichée |
| **J5** | Bouton "Ping VPS" dans l'UI | React | Affiche "Backend OK" ou erreur |

**Critère de succès** : `.exe` boot < 5 sec, scène 3D affichée, ping VPS vert.

### Semaine 2 — LiteLLM opérationnel

**Objectif** : configurer les 21 Groq + premiers tests de saturation.

| Jour | Tâche | Livrable |
|---|---|---|
| **J6** | Script `setup-keys.sh` : injecter les 21 clés Groq dans `.env` | `.env` propre (gitignored) |
| **J6** | Configurer `config.yaml` avec les 21 entrées Groq (round-robin) | LiteLLM gère 21 backends |
| **J7** | Test de charge : 100 requêtes concurrentes | Vérifier que la répartition est uniforme |
| **J7** | Configurer les fallbacks Tier 4 → Tier 3 | Cascade déclarative active |
| **J8** | Ajouter Mistral Experiment + Cloudflare Workers AI | Tier 5 et Tier 3 opérationnels |
| **J8** | MiniMax M3 + M2.7 (Token Plan) | Tier 7 et Tier 6 opérationnels |
| **J9** | Intégrer Prometheus + Grafana (optionnel) | Dashboard coûts visible |
| **J9** | Backup automatisé PostgreSQL | Cron quotidien |

**Critère de succès** : 200 RPM possibles sur le pool, fallback transparent vérifié.

### Semaine 3 — Backend Bun complet

**Objectif** : tous les endpoints + WebSocket temps réel.

| Jour | Tâche | Livrable |
|---|---|---|
| **J10** | `POST /api/tasks/dispatch` complet (Zod validation) | Endpoint fonctionnel |
| **J10** | `GET /api/projects` lister les projets sauvegardés | Endpoint fonctionnel |
| **J11** | BullMQ : queue `tasks` + workers | Tâches async |
| **J11** | Logger Pino structuré | Logs JSON |
| **J12** | WebSocket `/ws` : broadcaster les events | Clients connectés reçoivent les events |
| **J12** | Heartbeat + reconnexion auto | Connexion résiliente |
| **J13** | Intégration Drizzle ORM + PostgreSQL | Persistance projets |
| **J14** | Tests d'intégration Bun | Couverture backend > 70% |

**Critère de succès** : un `curl POST` déclenche un événement WSS reçu par un client test.

### Semaine 4 — Orchestration 9 Tiers

**Objectif** : l'Architecte (Tier 9) découpe un brief en TaskSpec JSON valides.

| Jour | Tâche | Livrable |
|---|---|---|
| **J15** | Module `architect.ts` : appel LiteLLM avec prompt système strict | Sortie JSON parsée |
| **J15** | Schema Zod pour TaskSpec | Validation stricte |
| **J16** | Si Tier 9 indispo → fallback Tier 8 (Claude Sonnet) | Cascade automatique |
| **J16** | Génération multi-fichiers : 1 brief → N TaskSpec | Workflow complet |
| **J17** | Validation d'interfaces TypeScript inter-fichiers | Cohérence garantie |
| **J17** | Prompt few-shot pour améliorer la qualité | Sortie plus stable |
| **J18** | Limite tokens + retry sur JSON mal formé | Robustesse |
| **J19** | Tests E2E : brief → 3 fichiers générés | Validation du flow |

**Critère de succès** : un prompt en langage naturel produit 3 fichiers TS valides et cohérents.

### Semaine 5 — Ville 3D animée

**Objectif** : 200 agents InstancedMesh à 60 FPS, bâtiments dynamiques.

| Jour | Tâche | Livrable |
|---|---|---|
| **J20** | Composant `CityCanvas.tsx` : sol, grille, lumières | Base 3D |
| **J20** | Composant `AgentsMesh.tsx` : 200 instances | 200 agents visibles |
| **J21** | Composant `Building.tsx` : mesh modulaire + croissance | Bâtiments qui montent |
| **J21** | Système de particules (travail en cours) | Glow néon |
| **J22** | `useFrame` optimisé (object pooling, `frameloop="demand"`) | 60 FPS stables |
| **J22** | Mini-map bas-droite (vue de dessus) | Navigation |
| **J23** | Cycle jour/nuit + horloge | Ambiance Autopolis |
| **J23** | Caserne (Sleeping Quarter) + animation "ZZZ" | Feedback 429 |
| **J24** | Postprocessing : bloom, glow, scanlines | Esthétique "Classic Neon" |
| **J25** | OrbitControls + caméra isométrique | UX fluide |

**Critère de succès** : 200 agents bougent en temps réel selon les events WSS, 60 FPS maintenus.

### Semaine 6 — Génération de code réel

**Objectif** : les agents écrivent vraiment dans le filesystem.

| Jour | Tâche | Livrable |
|---|---|---|
| **J26** | Tauri `fs` plugin : permissions configurées | Lecture/écriture fichiers |
| **J26** | Backend : endpoint qui écrit un fichier via API | API fonctionnelle |
| **J27** | Workflow : TaskSpec → code → fichier écrit | E2E complet |
| **J27** | Validation TypeScript côté backend (`tsc --noEmit`) | Pas de code cassé |
| **J28** | Tier 5 lance les tests après écriture | Boucle qualité |
| **J28** | Si tests échouent → Tier 7 retry avec feedback | Auto-correction |
| **J29** | Diff visuel dans la sidebar (avant/après) | UX satisfaisante |
| **J30** | Bâtiment monte d'un étage par fichier validé | Visualisation |

**Critère de succès** : dire "Crée un service Auth JWT" → 3 fichiers TS apparaissent dans `projects/demo/`, tests passent, bâtiment à 3 étages.

### Semaine 7 — Persistance & "Vie IA"

**Objectif** : les CEO, skills, MCPs en pause sont sauvegardés et restaurables.

| Jour | Tâche | Livrable |
|---|---|---|
| **J31** | Schema DB : `projects`, `ceos`, `skills`, `mcps`, `sessions` | Migrations Drizzle |
| **J31** | UI "Créer un CEO" : nom, mission, Tier préféré | Formulaire |
| **J32** | Sidebar projets : créer/pause/reprendre | UX complète |
| **J32** | Système de tags pour les projets en pause | Organisation |
| **J33** | Drop de nouveaux CEOs dans le "Café Central" | Narration visuelle |
| **J33** | Historique des conversations par CEO | Mémoire |
| **J34** | Import/Export d'un CEO en JSON | Partage |
| **J35** | Restauration de session complète | "Hier j'étais sur X" |

**Critère de succès** : créer 3 CEOs, en pauser 2, quitter l'app, relancer → tout est restauré.

### Semaine 8 — Polish & Release

**Objectif** : un produit présentable, signé, distribuable.

| Jour | Tâche | Livrable |
|---|---|---|
| **J36** | Onboarding première utilisation (tour guidé) | UX accueillante |
| **J36** | Page "Settings" : clés API, providers, coûts | Configuration |
| **J37** | Auto-update Tauri (delta updates) | Mises à jour transparentes |
| **J37** | Signature de l'exe (certificat self-signed pour dev) | Sécurité Windows |
| **J38** | Documentation utilisateur (README + wiki) | Onboarding externe |
| **J38** | Build release sur GitHub Actions | CI/CD opérationnel |
| **J39** | Tests E2E Playwright | Couverture UI |
| **J40** | Annonce release v0.1 | 🎉 |

**Critère de succès** : `.exe` 35 MB, signé, installable, démarrage < 3 sec, fonctionnel end-to-end.

---

## 8. KPIs de succès

### 8.1 KPIs techniques
- **Performance** : 60 FPS stables avec 200 agents animés
- **Boot** : < 3 secondes du clic à la ville visible
- **Bundle size** : `.exe` < 40 MB
- **RAM idle** : < 100 MB
- **CPU idle** : < 2%

### 8.2 KPIs économiques
- **Coût mensuel infra** : < 5 €/mois (VPS)
- **Coût LLM en usage normal** : 0 € (free providers) à 30 €/mois (avec payants)
- **ROI** : > 10× vs Claude Code Max seul

### 8.3 KPIs fonctionnels
- **Tâches complétées/jour** : > 50
- **Taux de fallback réussi** : > 99%
- **Taux de validation Tier 9** : > 90% (TaskSpec valides du premier coup)
- **Uptime LiteLLM** : > 99%

### 8.4 KPIs sécurité
- **0 leak de clé API** : audit trimestriel
- **HTTPS uniquement** : HSTS, pas de HTTP en clair
- **UFW actif** : seuls 22, 80, 443 ouverts

---

## 9. Risques & mitigations

| Risque | Probabilité | Impact | Mitigation |
|---|---|---|---|
| **Tauri + WebGL instable** | Moyenne | Élevé | Tester sur 3 PC différents en S1, prévoir fallback Wails si bloquant |
| **Groq retire le free** | Élevée (déjà arrivé 16/08/2026) | Élevé | Mistral Experiment + Cloudflare en backup, multi-provider natif |
| **Ollama local trop lourd** | Élevée | Faible | Rendre Tier 2 désactivable, fallback regex Tier 1 |
| **MiniMax Token Plan saturé** | Moyenne | Moyen | Rate limiter maison + fallback Groq/Mistral |
| **VPS Hetzner indisponible** | Faible | Élevé | Snapshot hebdo, plan de bascule OVH |
| **Tauri build bug Windows** | Moyenne | Moyen | CI GitHub Actions qui build à chaque PR |
| **200 agents rament** | Moyenne | Élevé | `InstancedMesh` + `frameloop="demand"` + LOD si besoin |
| **Sécurité VPS compromise** | Faible | Critique | SSH key only, UFW, Fail2Ban, JWT rotation, audit logs |
| **Coûts providers dérapent** | Moyenne | Moyen | Budget par virtual key LiteLLM, alertes Prometheus |

---

## 10. Roadmap post-MVP (Phase 2+)

### Phase 2 (Mois 2-3) — Providers payants
- [ ] Ajouter Gemini Pro 1.5 (multimodal images/vidéo)
- [ ] Ajouter Claude Sonnet 3.5 / Opus 3.7 (Tier 8-9)
- [ ] Génération d'images via Gemini (assets visuels pour les bâtiments)
- [ ] Génération de musique via API (ambiance sonore de la ville)

### Phase 3 (Mois 4-5) — Collaboration
- [ ] Multi-utilisateurs : chacun son `.exe`, projets partagés sur le VPS
- [ ] Marketplace de CEOs / skills / MCPs
- [ ] Webhooks GitHub (push → ville réagit)
- [ ] Export d'un projet vers un repo GitHub

### Phase 4 (Mois 6+) — Plateforme
- [ ] Version mobile (Tauri iOS/Android)
- [ ] Site web démo publique (Vercel)
- [ ] Plugin Figma / VSCode
- [ ] API publique pour tiers
- [ ] Programme de "Citoyen" : d'autres IA rejoignent la ville

---

## 11. TODOs immédiats

À faire **avant** de toucher au code :

- [ ] **Utilisateur** : fournir l'accès SSH au VPS Hetzner (IP + clé privée ou user/password)
- [ ] **Utilisateur** : confirmer la clé API MiniMax (Token Plan) à injecter dans `.env`
- [ ] **Moi** : créer la structure monorepo
- [ ] **Moi** : init Tauri 2 + scène 3D minimale
- [ ] **Moi** : provision VPS (dès accès reçu)
- [ ] **Moi** : installer LiteLLM + Redis + PostgreSQL
- [ ] **Moi** : configurer les 21 clés Groq
- [ ] **Moi** : premier healthcheck E2E

### TODOs Semaine 1
- [ ] J1 : monorepo + Tauri init
- [ ] J2 : VPS provisionné + sécurisé
- [ ] J3 : LiteLLM up avec 1 provider test
- [ ] J4 : Backend Bun + endpoint echo
- [ ] J5 : Scène 3D + ping VPS
- [ ] **Checkpoint** : `.exe` qui affiche une ville vide et confirme que le VPS répond

---

## 12. Annexes

### A. Glossaire
- **CEO** : un orchestrateur de tâches dédié (équivalent d'un profil d'agent)
- **MCP** : Model Context Protocol (skills/outils pour les agents)
- **Tier** : niveau dans la pyramide d'intelligence (1 à 9)
- **TaskSpec** : JSON strict décrivant une tâche à effectuer
- **CityState** : état complet de la ville à un instant T
- **Sidecar** : process enfant lancé par Tauri (ici, Bun + LiteLLM)
- **Fallback** : provider de secours si le principal échoue
- **Cooldown** : période pendant laquelle une clé est mise au repos après 429

### B. Références externes
- [Autopolis.city](https://autopolis.city/) — inspiration visuelle
- [Tauri 2.0 docs](https://tauri.app/) — framework desktop
- [React Three Fiber](https://r3f.docs.pmnd.rs/) — 3D React
- [LiteLLM](https://docs.litellm.ai/) — proxy LLM
- [Bun](https://bun.sh/) — runtime JS
- [Hono](https://hono.dev/) — HTTP framework
- [BullMQ](https://docs.bullmq.io/) — queue Redis
- [Mistral Experiment](https://docs.mistral.ai/) — tier gratuit Mistral
- [Groq Cloud](https://console.groq.com/) — 21 clés API
- [Hetzner Cloud](https://www.hetzner.com/cloud) — hébergement VPS

### C. Variables d'environnement (`.env.example`)

```bash
# === LiteLLM ===
LITELLM_MASTER_KEY=sk-XXXXXX
LITELLM_SALT_KEY=sk-XXXXXX
DATABASE_URL=postgresql://litellm:XXX@localhost/litellm

# === Providers ===
MINIMAX_API_KEY=eyJXXXXXX
GROQ_KEY_01=gsk_XXXXXX
GROQ_KEY_02=gsk_XXXXXX
# ... jusqu'à GROQ_KEY_21
MISTRAL_API_KEY=XXXXXX
CLOUDFLARE_API_TOKEN=XXXXXX
CLOUDFLARE_ACCOUNT_ID=XXXXXX

# === Phase 2 (à venir) ===
GEMINI_API_KEY=
ANTHROPIC_API_KEY=

# === Backend Bun ===
JWT_SECRET=XXXXXX
API_PORT=8787
WS_PORT=8787

# === Tauri ===
VITE_API_BASE_URL=https://aqc.tondomaine.com
```

---

## 📜 Licence & philosophie

**Code** : MIT (open-source maximal)
**Données** : restent locales (PC + VPS), jamais revendues
**Philosophie** : l'IA doit être accessible, visuelle et gratuite-first. Le pouvoir aux utilisateurs, pas aux plateformes.

---

**Prochain milestone** : feu vert de l'utilisateur + accès VPS → J1 du plan.

> *"Une ville où 200 IA vivent et construisent pour toi."*