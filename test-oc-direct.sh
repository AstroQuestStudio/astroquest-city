#!/bin/bash
echo "=== Test opencode session create ==="
SESS=$(curl -s -X POST -H "Content-Type: application/json" \
  http://127.0.0.1:4096/session \
  --data-binary '{"workspace":"/opt/aq-app/opencode/workspace"}')
echo "$SESS"
SID=$(echo "$SESS" | python3 -c "import sys, json; print(json.load(sys.stdin).get('id',''))")
echo "Session ID: $SID"
echo
echo "=== Test opencode message with plan agent ==="
curl -sv -X POST -H "Content-Type: application/json" \
  "http://127.0.0.1:4096/session/$SID/message" \
  --data-binary '{"agent":"plan","parts":[{"type":"text","text":"Hello, what can you do?"}]}' 2>&1 | tail -30