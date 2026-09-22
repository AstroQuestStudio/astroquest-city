# 📚 Modèles LLM disponibles par provider

> Référence complète des modèles testables sur la stack AstroQuest City.
> Source : docs officielles (septembre 2026).

---

## 🔵 Groq — Free tier (notre moteur volume)

### Production

| Modèle | ID LiteLLM | Context | RPM | TPM | TPM/jour | Prix/1M in | Prix/1M out | Speed | Capacités |
|---|---|---|---|---|---|---|---|---|---|
| **GPT OSS 120B** ⭐ | `groq/openai/gpt-oss-120b` | 131 072 | 30 | 8K | 200K | $0.15 | $0.60 | 500 TPS | reasoning, tool use, JSON, prompt caching |
| **GPT OSS 20B** ⭐ | `groq/openai/gpt-oss-20b` | 131 072 | 30 | 8K | 200K | $0.075 | $0.30 | 1 000 TPS | reasoning, tool use, JSON, prompt caching |
| **GPT OSS Safeguard 20B** | `groq/openai/gpt-oss-safeguard-20b` | 131 072 | 30 | 8K | 200K | $0.075 | $0.30 | — | safety filtering |
| **Llama 3.1 8B Instant** | `groq/llama-3.1-8b-instant` | 131 072 | 30 | 6K | 500K | $0.05 | $0.08 | 560-840 TPS | vitesse brute |
| **Llama 4 Scout 17Bx16E** | `groq/meta-llama/llama-4-scout-17b-16e-instruct` | 131 072 | 30 | 30K | 500K | $0.11 | $0.34 | 600 TPS | **vision (5 images)**, tool use |
| **Qwen 3.8 27B** | `groq/qwen/qwen3.8-27b` | 131 042 | 30 | 8K | 200K | $0.80 | $4.00 | — | coding, multilingue |
| **Qwen 3.6 27B** | `groq/qwen/qwen3.6-27b` | 131 072 | 30 | 8K | 200K | $0.60 | $3.00 | — | coding, multilingue |
| **Kimi K2** | `groq/moonshotai/kimi-k2-instruct-0905` | 262 144 | 60 | 10K | 300K | $1.00 | $3.00 | — | long context, agentic |

### ⚠️ Payant uniquement (plus sur free tier)

| Modèle | ID LiteLLM | Note |
|---|---|---|
| Llama 3.3 70B | `groq/llama-3.3-70b-versatile` | Retiré du free le **16/08/2026** |

### ❌ Décommissionnés

| Modèle | Date |
|---|---|
| `groq/compound` | 21/09/2026 |
| `groq/compound-mini` | 21/09/2026 |

---

## 🟣 MiniMax — Token Plan (Code Plan)

### Modèles LLM

| Modèle | ID LiteLLM | Context | Speed | Description |
|---|---|---|---|---|
| **MiniMax-M3** ⭐ | `minimax/MiniMax-M3` | **1 000 000** (512K garanti) | 100+ TPS | Latest, agentic reasoning, tool use, coding, long-context |
| **MiniMax-M2.7** ⭐ | `minimax/MiniMax-M2.7` | 204 800 | 60 TPS | Recursive self-improvement, generalist |
| **MiniMax-M2.7-highspeed** | `minimax/MiniMax-M2.7-highspeed` | 204 800 | 100 TPS | M2.7 plus rapide |
| **MiniMax-M2.5** | `minimax/MiniMax-M2.5` | 204 800 | 60 TPS | Generation precedente |
| **MiniMax-M2.5-highspeed** | `minimax/MiniMax-M2.5-highspeed` | 204 800 | 100 TPS | M2.5 plus rapide |

### Token Plans (mensuels)

| Plan | Prix | Calls / 5h (M2.7) | Calls / 5h (M2.7-highspeed) |
|---|---|---|---|
| **Plus** | $20/mois | 4 500 | 2 250 |
| **Max** ⭐ | $50/mois | 15 000 | 7 500 |
| **Ultra** | $120/mois | 29 077 | 14 538 |

### API

- Endpoint : `https://api.minimax.io/v1`
- Format LiteLLM : `minimax/MiniMax-M3` (PAS `openai/MiniMax-M3`)
- Auth : `Authorization: Bearer sk-cp-...`

---

## 🟢 Mistral — Experiment tier (optionnel, à venir)

- ~1 milliard de tokens/mois gratuit
- Opt-in data training
- Modèles : Mistral Large 2, Codestral, Pixtral

---

## 🟠 Cloudflare Workers AI (optionnel, à venir)

- 10 000 neurones/jour gratuit (pas de data training)
- Modèles : Llama 3.1 8B, Qwen 1.5, Mistral 7B
- Endpoint : `https://api.cloudflare.com/client/v4/accounts/{id}/ai/run/`

---

## 🟡 OpenRouter (optionnel, à venir)

- 20 RPM / 50 RPD gratuit
- Modèles : nombreux, agregateur multi-providers
- Endpoint : `https://openrouter.ai/api/v1`

---

## 🔴 Phase 2 (provider payants)

| Provider | Modèles | Quand activer |
|---|---|---|
| **Anthropic** | Claude Sonnet 4.5, Claude Opus 4.7 | Tier 8 (Urbaniste) + Tier 9 (Architecte) |
| **Google Gemini** | Gemini 2.5 Pro (2M context, multimodal) | Tier 9 alternatif (assets visuels) |
| **OpenAI** | GPT-5, o3 | Si besoin spécifique |

---

## 🎯 Stratégie AstroQuest City par Tier

| Tier | Modèle | Provider | Pourquoi |
|---|---|---|---|
| 9 | (à venir) | Claude Opus / Gemini Pro | Raisonnement avancé |
| 8 | (à venir) | Claude Sonnet | Code complexe |
| **7** | **MiniMax-M3** | MiniMax Token Plan | 1M context, agentic |
| **6** | **MiniMax-M2.7** | MiniMax Token Plan | Generalist, rapide |
| 5 | Mistral Large 2 | Mistral Experiment | QA (optionnel) |
| **4** | **21× GPT OSS 120B** | Groq free | Volume, 630 RPM total |
| **3** | **GPT OSS 20B** | Groq free | Format, 1 000 TPS |
| 2 | Ollama local | Ollama | RAG local (optionnel) |
| 1 | LiteLLM | — | Routing |

---

## 📝 Comment ajouter un provider

### Étape 1 — Stocker la clé

```powershell
powershell -File apps\infra\scripts\set-secret.ps1 -Key GEMINI_API_KEY -Value "AIza..."
```

### Étape 2 — Ajouter le bloc modèle dans `config.yaml`

Décommenter / ajouter (voir les blocs commentés en bas de `config.yaml`) :

```yaml
  - model_name: "tier-9-gemini"
    litellm_params:
      model: gemini/gemini-2.5-pro
      api_key: os.environ/GEMINI_API_KEY
      rpm: 10
      max_tokens: 8192
```

### Étape 3 — Recharger LiteLLM

```bash
ssh root@46.224.170.108 'cd /opt/aq-app/infra && docker compose restart litellm'
```

### Étape 4 — Tester

```bash
curl -k -X POST https://edge.astroquest.fr/litellm/v1/chat/completions \
  -H "Authorization: Bearer $(powershell -File apps\infra\scripts\show-env.ps1 -Key LITELLM_MASTER_KEY)" \
  -H "Content-Type: application/json" \
  -d '{"model":"tier-9-gemini","messages":[{"role":"user","content":"Salut"}]}'
```

---

## ⚡ Commandes utiles

```powershell
# Lister toutes les cles (masquees)
powershell -File apps\infra\scripts\show-env.ps1

# Afficher une cle complete
powershell -File apps\infra\scripts\show-env.ps1 -Key GEMINI_API_KEY

# Ajouter / mettre a jour une cle
powershell -File apps\infra\scripts\set-secret.ps1 -Key MA_CLE -Value "valeur"

# Retirer une cle
powershell -File apps\infra\scripts\unset-secret.ps1 -Key MA_CLE

# Ajouter une nouvelle cle Groq au-dela de 21
powershell -File apps\infra\scripts\add-groq-key.ps1 -Value "gsk_..."