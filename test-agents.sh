#!/bin/bash
echo "=== TEST worker-search ==="
curl -s -X POST -H "Content-Type: application/json" \
  http://127.0.0.1:8787/api/agents/worker-search/run \
  --data-binary '{"prompt":"Combien de planetes dans le systeme solaire?"}'
echo
echo "=== TEST worker-format ==="
curl -s -X POST -H "Content-Type: application/json" \
  http://127.0.0.1:8787/api/agents/worker-format/run \
  --data-binary '{"prompt":"Format this JSON: {a:1,b:2}"}'
echo
echo "=== TEST mgr-code ==="
curl -s -X POST -H "Content-Type: application/json" \
  http://127.0.0.1:8787/api/agents/mgr-code/run \
  --data-binary '{"prompt":"Ecris une fonction TypeScript qui calcule la factorielle"}'
echo
echo "=== BACKEND LOGS ==="
docker logs aq-backend --tail 10 2>&1 | tail -8