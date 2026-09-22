#!/bin/bash
echo "=== 5x ceo-recherche via /aq-api/api ==="
for i in 1 2 3 4 5; do
  echo ""
  echo "--- run $i ---"
  time curl -s -X POST -H "Content-Type: application/json" \
    "https://edge.astroquest.fr/aq-api/api/agents/ceo-recherche/run" \
    --data-binary '{"prompt":"Combien de planetes dans le systeme solaire?"}' | head -c 300
  echo
done

echo ""
echo "=== Test direct backend (127.0.0.1) ceo-recherche ==="
time curl -s -X POST -H "Content-Type: application/json" \
  http://127.0.0.1:8787/api/agents/ceo-recherche/run \
  --data-binary '{"prompt":"Combien de planetes?"}' | head -c 400
echo
echo ""
echo "=== Backend logs errors (last 50) ==="
docker logs aq-backend --tail 50 2>&1 | grep -v "agent_state_change" | tail -30