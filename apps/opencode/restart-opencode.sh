#!/bin/bash
# Properly daemonize opencode (detach from parent shell)
set -e

pkill -9 -f "opencode serve" 2>/dev/null || true
sleep 2

cd /opt/aq-app/opencode/workspace

# Use setsid to fully detach from controlling terminal/session
setsid /root/.opencode/bin/opencode serve \
  --port 4096 --hostname 0.0.0.0 \
  < /dev/null > /var/log/opencode.log 2>&1 &

disown
sleep 1
echo "[OK] opencode restarted, PID=$!"