#!/bin/bash
echo "=== TEST OpenCode API ==="

echo ""
echo "--- 1. Configs (providers) ---"
curl -s http://127.0.0.1:4096/config | python3 -m json.tool 2>&1 | head -30

echo ""
echo "--- 2. List files in workspace ---"
curl -s "http://127.0.0.1:4096/file?path=/opt/aq-app/opencode/workspace" | head -c 400
echo

echo ""
echo "--- 3. Read hello.ts ---"
curl -s "http://127.0.0.1:4096/file/content?path=/opt/aq-app/opencode/workspace/hello.ts"
echo

echo ""
echo "--- 4. List providers/models ---"
curl -s http://127.0.0.1:4096/config/providers | python3 -m json.tool 2>&1 | head -30