#!/bin/bash
echo "=== /api/opencode/health ==="
curl -s https://edge.astroquest.fr/aq-api/api/opencode/health
echo
echo
echo "=== /api/opencode/workspace ==="
curl -s https://edge.astroquest.fr/aq-api/api/opencode/workspace
echo
echo
echo "=== /api/agents (filter opencodeAgent) ==="
curl -s https://edge.astroquest.fr/aq-api/api/agents | python3 <<'EOF'
import sys, json
d = json.load(sys.stdin)
for k, v in d["agents"].items():
    oc = v.get("opencodeAgent", "-")
    print(f"  {k}: role={v['role']} opencodeAgent={oc}")
EOF
echo
echo "=== /api/opencode/files ==="
curl -s https://edge.astroquest.fr/aq-api/api/opencode/files | head -c 500