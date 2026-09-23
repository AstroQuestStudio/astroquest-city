# Gemini Models Verified (2026-09-23)

Tests run live against the user's AQ. auth keys (`AQ.Ab8RN6...`).

| Model id | Status | Notes |
|---|---|---|
| `gemini-flash-lite-latest` | ✅ **200 OK** | **FREE, recommended for tier-9-flash** |
| `gemini-3.5-flash` | ✅ **200 OK** | **FREE, latest flagship Flash, recommended for tier-8** |
| `gemma-4-26b-a4b-it` | ✅ 200 OK | FREE, lightweight open model |
| `gemma-4-31b-it` | ✅ 200 OK | FREE, similar to 26b |
| `gemini-flash-latest` | ⚠️ 503 (transient) | exists, server hiccup |
| `gemini-3.1-pro-preview` | ⚠️ 429 (rate-limited) | paid tier preview |
| `gemini-3-pro-image` | ⚠️ 429 (rate-limited) | image model, paid tier |
| `gemini-2.5-flash` | ❌ **404 Not Found** | **deprecated in AQ. key projects** |
| `gemini-2.5-pro` | ❌ **404 Not Found** | **deprecated in AQ. key projects** |

## Root cause of previous 401/404 errors

The user generated Gemini API keys via AI Studio starting June 2026 — Google transitioned to the new **AQ.** (auth) key format. These keys are bound to a Google Cloud project (`projects/776496219739`) and only have access to a subset of models:
- New stable models (3.5-flash, gemini-flash-lite-latest, gemma-4)
- ❌ NOT the older 2.5-flash / 2.5-pro — those 404 even with a valid key

The local proxy was correctly passing the key in `?key=` query (not Bearer, which is what AQ. keys require), but pointing at `gemini-2.5-flash` → 404.

## Fix shipped: fallback chains

Each tier now has an ordered fallback chain of (provider, model) candidates. If model A returns 401/403/429/5xx or a network error, we try model B, etc. The chain always ends with a paid fallback (`minimax:M3`) so the city **never goes silent**.

Example for `tier-8-opus-reflection` (CEO strategy):
1. `nvidia/nemotron-3-ultra-550b-a55b` (1M ctx hybrid MoE)
2. `nvidia/z-ai/glm-5-3-flash` (multimodal MoE)
3. `nvidia/moonshotai/kimi-k3` (2.8T MoE)
4. `gemini/gemini-3.5-flash` (FREE AQ. key works)
6. `gemini/gemma-4-31b-it` (FREE AQ. key works)
7. `minimax/MiniMax-M3` (paid ultimate fallback)