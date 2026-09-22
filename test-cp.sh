#!/bin/bash
echo "=== TEST code-planner ==="
time curl -s --max-time 30 -X POST -H "Content-Type: application/json" \
  http://127.0.0.1:8787/api/agents/code-planner/run \
  --data-binary '{"prompt":"Liste les fichiers du projet en 2 phrases."}' | head -c 800