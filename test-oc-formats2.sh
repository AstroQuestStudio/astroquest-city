#!/bin/bash
SID=$(curl -s -X POST -H "Content-Type: application/json" \
  http://127.0.0.1:4096/session \
  --data-binary '{"workspace":"/opt/aq-app/opencode/workspace"}' | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])")
echo "Session: $SID"

echo "=== Try with model object ==="
curl -s -X POST -H "Content-Type: application/json" \
  "http://127.0.0.1:4096/session/$SID/message" \
  --data-binary '{"parts":[{"type":"text","text":"List files"}],"agent":"plan","model":{"providerID":"aq-litellm","modelID":"tier-6-ouvrier"}}' | head -c 400
echo
echo

echo "=== Try without agent, just parts ==="
curl -s -X POST -H "Content-Type: application/json" \
  "http://127.0.0.1:4096/session/$SID/message" \
  --data-binary '{"parts":[{"type":"text","text":"List files"}]}' | head -c 400
echo
echo

echo "=== Try with system prompt format ==="
curl -s -X POST -H "Content-Type: application/json" \
  "http://127.0.0.1:4096/session/$SID/message" \
  --data-binary '{"agent":"plan","parts":[{"type":"text","text":"List files in /opt/aq-app/opencode/workspace"}]}' | head -c 400
echo
echo

echo "=== Test prompt_async instead of message ==="
curl -s -X POST -H "Content-Type: application/json" \
  "http://127.0.0.1:4096/session/$SID/prompt_async" \
  --data-binary '{"agent":"plan","parts":[{"type":"text","text":"Hello"}]}' | head -c 400
echo