#!/bin/bash
echo "=== Test direct LiteLLM tier-6-ouvrier ==="
KEY=$(grep LITELLM_MASTER_KEY /opt/aq-app/infra/.env | head -1 | sed 's/^LITELLM_MASTER_KEY=//')
time curl -s -X POST -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  http://127.0.0.1:4000/v1/chat/completions \
  --data-binary '{"model":"tier-6-ouvrier","messages":[{"role":"user","content":"Combien de planetes?"}],"max_tokens":50,"reasoning_effort":"low"}' | head -c 500
echo
echo ""
echo "=== Test direct LiteLLM tier-6-ouvrier SANS reasoning_effort ==="
time curl -s -X POST -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  http://127.0.0.1:4000/v1/chat/completions \
  --data-binary '{"model":"tier-6-ouvrier","messages":[{"role":"user","content":"Combien de planetes?"}],"max_tokens":50}' | head -c 500
echo
echo ""
echo "=== Test direct MiniMax API tier-6-ouvrier (raw) ==="
MINIMAX_KEY=$(grep ^MINIMAX_API_KEY /opt/aq-app/infra/.env | head -1 | sed 's/^MINIMAX_API_KEY=//')
time curl -s -X POST -H "Authorization: Bearer $MINIMAX_KEY" -H "Content-Type: application/json" \
  https://api.minimax.io/v1/chat/completions \
  --data-binary '{"model":"MiniMax-M2.7","messages":[{"role":"user","content":"Combien de planetes?"}],"max_tokens":50,"reasoning_effort":"low"}' | head -c 500
echo
echo ""
echo "=== BACKEND LOGS last 30 ==="
docker logs aq-backend --tail 30 2>&1 | tail -30