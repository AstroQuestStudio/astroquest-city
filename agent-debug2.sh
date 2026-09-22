#!/bin/bash
echo "=== TEST ALL AGENTS via /aq-api/api/agents/ ==="

for agent in ceo-strategie ceo-recherche mgr-code worker-search worker-format; do
  echo ""
  echo "--- $agent ---"
  time curl -s -X POST -H "Content-Type: application/json" \
    "https://edge.astroquest.fr/aq-api/api/agents/$agent/run" \
    --data-binary '{"prompt":"Combien de planetes dans le systeme solaire?"}' | head -c 400
  echo
done

echo ""
echo "=== Also direct backend access (127.0.0.1) ==="
for agent in ceo-strategie worker-search; do
  echo "--- $agent ---"
  time curl -s -X POST -H "Content-Type: application/json" \
    "http://127.0.0.1:8787/api/agents/$agent/run" \
    --data-binary '{"prompt":"Combien de planetes dans le systeme solaire?"}' | head -c 300
  echo
done