#!/bin/bash
KEY=$(grep LITELLM_MASTER_KEY /opt/aq-app/infra/.env | head -1 | sed 's/^LITELLM_MASTER_KEY=//')

echo "=== TEST tier-4-groq ==="
time curl -s -X POST -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  http://127.0.0.1:4000/v1/chat/completions \
  -d '{"model":"tier-4-groq","messages":[{"role":"user","content":"Reponds juste OK"}],"max_tokens":15}' | head -c 500
echo
echo "=== TEST tier-3-formatteur ==="
time curl -s -X POST -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  http://127.0.0.1:4000/v1/chat/completions \
  -d '{"model":"tier-3-formatteur","messages":[{"role":"user","content":"Reponds juste OK"}],"max_tokens":15}' | head -c 500
echo
echo "=== TEST agent ceo-strategie via backend ==="
curl -s -X POST -H "Content-Type: application/json" \
  http://127.0.0.1:8787/api/agents/ceo-strategie/run \
  --data-binary '{"prompt":"Combien de planetes dans le systeme solaire?"}'
echo
echo "=== TEST agent worker-search (cheap) ==="
curl -s -X POST -H "Content-Type: application/json" \
  http://127.0.0.1:8787/api/agents/worker-search/run \
  --data-binary '{"prompt":"Combien de planetes dans le systeme solaire?"}'