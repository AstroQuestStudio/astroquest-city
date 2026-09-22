#!/bin/bash
echo "=== TEST ALL AGENTS via /aq-api ==="

for agent in ceo-strategie ceo-recherche mgr-code worker-search worker-format; do
  echo ""
  echo "--- $agent ---"
  time curl -s -X POST -H "Content-Type: application/json" \
    "https://edge.astroquest.fr/aq-api/agents/$agent/run" \
    --data-binary '{"prompt":"Combien de planetes dans le systeme solaire?"}' | head -c 400
  echo
done

echo ""
echo "=== BACKEND LOGS (last 20) ==="
docker logs aq-backend --tail 20 2>&1 | tail -20