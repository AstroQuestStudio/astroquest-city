#!/bin/bash
SID="ses_f35000547ffezk2wX3wpguuGvU"

echo "=== Try 1: just agent name ==="
curl -s -X POST -H "Content-Type: application/json" \
  "http://127.0.0.1:4096/session/$SID/message" \
  --data-binary '{"agent":"plan"}' | head -c 300
echo
echo
echo "=== Try 2: prompt field ==="
curl -s -X POST -H "Content-Type: application/json" \
  "http://127.0.0.1:4096/session/$SID/message" \
  --data-binary '{"agent":"plan","prompt":"Hello"}' | head -c 300
echo
echo
echo "=== Try 3: parts array with type=text ==="
curl -s -X POST -H "Content-Type: application/json" \
  "http://127.0.0.1:4096/session/$SID/message" \
  --data-binary '{"parts":[{"type":"text","text":"Hello"}]}' | head -c 300
echo
echo
echo "=== Try 4: parts array + agent ==="
curl -s -X POST -H "Content-Type: application/json" \
  "http://127.0.0.1:4096/session/$SID/message" \
  --data-binary '{"parts":[{"type":"text","text":"Hello"}],"agent":"plan"}' | head -c 300
echo
echo
echo "=== opencode logs full ==="
tail -80 /var/log/opencode.log 2>&1 | tail -40