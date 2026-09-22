#!/bin/bash
echo "=== Test opencode CLI directly (not server) ==="
cd /opt/aq-app/opencode/workspace
echo 'export function greet(name: string): string { return "Hello, " + name + "!"; }' > hello.ts
timeout 25 /root/.opencode/bin/opencode run "List the files in this repo and add a comment to hello.ts" --print-logs --model aq-litellm:tier-4-groq 2>&1 | tail -40