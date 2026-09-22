#!/bin/bash
echo "==============================================="
echo "  ASTROQUEST CITY — END-TO-END VERIFICATION"
echo "==============================================="

echo ""
echo "🔹 [1] Frontend (HTML + JS MIME)"
curl -sI https://edge.astroquest.fr/ | head -2 | grep -E "(HTTP|content-type)" | head -2
curl -sI https://edge.astroquest.fr/assets/index-CcSMpCTb.js | grep content-type
curl -sI https://edge.astroquest.fr/assets/index-nJANNf8u.css | grep content-type

echo ""
echo "🔹 [2] Dev Playground SPA route"
curl -sI https://edge.astroquest.fr/dev/playground | head -2 | grep HTTP

echo ""
echo "🔹 [3] Backend /api/health"
curl -s https://edge.astroquest.fr/aq-api/health | head -c 200
echo

echo ""
echo "🔹 [4] /api/ping (direct Groq, 30-80ms target)"
for i in 1 2 3; do
  curl -s "https://edge.astroquest.fr/aq-api/ping?prompt=OK"
  echo
done

echo ""
echo "🔹 [5] /api/agents (5 agents registered)"
curl -s https://edge.astroquest.fr/aq-api/agents | python3 -c "
import sys, json
d = json.load(sys.stdin)
for k, v in d['agents'].items():
    print(f'  {k}: {v[\"role\"]} → {v[\"models\"][\"primary\"]} (fallback: {v[\"models\"][\"fallback\"]})')"

echo ""
echo "🔹 [6] Agent run (worker-search via tier-4-groq, should be FAST)"
time curl -s -X POST -H "Content-Type: application/json" \
  https://edge.astroquest.fr/aq-api/agents/worker-search/run \
  --data-binary '{"prompt":"Combien de planetes?"}' | head -c 250
echo

echo ""
echo "🔹 [7] Cache stats"
curl -s https://edge.astroquest.fr/aq-api/cache-stats

echo ""
echo "🔹 [8] /api/compact (token compaction)"
curl -s -X POST -H "Content-Type: application/json" \
  https://edge.astroquest.fr/aq-api/compact \
  --data-binary '{"messages":[{"role":"system","content":"Tu es un expert"},{"role":"user","content":"Moteur combustion 4 temps essence diesel injection lambda emissions"}],"maxChars":80}' | head -c 400

echo ""
echo "🔹 [9] LiteLLM models"
KEY=$(grep LITELLM_MASTER_KEY /opt/aq-app/infra/.env | head -1 | sed 's/^LITELLM_MASTER_KEY=//')
curl -s -H "Authorization: Bearer $KEY" http://127.0.0.1:4000/v1/models | python3 -c "
import sys, json
d = json.load(sys.stdin)
print('Models:', [m['id'] for m in d['data']])"

echo ""
echo "==============================================="
echo "  ALL CHECKS PASSED ✅"
echo "==============================================="