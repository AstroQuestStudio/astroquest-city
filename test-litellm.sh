#!/bin/bash
KEY=$(grep LITELLM_MASTER_KEY /opt/aq-app/infra/.env | head -1 | sed 's/^LITELLM_MASTER_KEY=//')
echo "KEY=$KEY"
echo "=== HEALTH ==="
curl -s -H "Authorization: Bearer $KEY" http://127.0.0.1:4000/health/liveliness
echo
echo "=== MODELS ==="
curl -s -H "Authorization: Bearer $KEY" http://127.0.0.1:4000/v1/models | head -c 2000
echo
echo "=== TEST tier-7-fast ==="
curl -s -X POST -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  http://127.0.0.1:4000/v1/chat/completions \
  -d '{"model":"tier-7-fast","messages":[{"role":"user","content":"Reponds juste OK en 1 mot"}],"max_tokens":15}'
echo
echo "=== TEST tier-6-ouvrier ==="
curl -s -X POST -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  http://127.0.0.1:4000/v1/chat/completions \
  -d '{"model":"tier-6-ouvrier","messages":[{"role":"user","content":"Reponds juste OK en 1 mot"}],"max_tokens":15}'