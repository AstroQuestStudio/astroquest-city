#!/bin/bash
# Setup + start OpenCode server on VPS3, wired to our LiteLLM
set -e

LITELLM_KEY=$(grep LITELLM_MASTER_KEY /opt/aq-app/infra/.env | head -1 | sed 's/^LITELLM_MASTER_KEY=//')
OPENCODE_DIR=/opt/aq-app/opencode
WORKSPACE_DIR=/opt/aq-app/opencode/workspace

# 1. Substitute API key in config
sed -i "s/REPLACE_WITH_LITELLM_KEY/${LITELLM_KEY}/g" $OPENCODE_DIR/opencode.json
echo "[OK] opencode.json patched"

# 2. Create workspace (without git)
mkdir -p $WORKSPACE_DIR
cd $WORKSPACE_DIR
cat > README.md <<'EOREADME'
# OpenCode Workspace (test repo for AstroQuest City)

Modifié par les agents opencode via AstroQuest City.
EOREADME
cat > hello.ts <<'EOHELLO'
// Fonction de demo — sera modifiée par l'agent opencode
export function greet(name: string): string {
  return "Hello, " + name + "!";
}
EOHELLO
cat > package.json <<'EOPKG'
{
  "name": "opencode-workspace",
  "version": "1.0.0",
  "type": "module",
  "main": "hello.ts"
}
EOPKG
echo "[OK] workspace ready at $WORKSPACE_DIR"

# 3. Stop existing opencode if running
pkill -f "opencode serve" 2>/dev/null || true
sleep 1

# 4. Launch opencode serve
echo "[..] starting opencode serve..."
cd $WORKSPACE_DIR
nohup /root/.opencode/bin/opencode serve --port 4096 --hostname 0.0.0.0 \
  --print-logs > /var/log/opencode.log 2>&1 &
OPENCODE_PID=$!
echo $OPENCODE_PID > /var/run/opencode.pid
sleep 5

# 5. Verify
echo ""
echo "=== opencode health ==="
curl -s http://127.0.0.1:4096/global/health
echo
echo "=== process ==="
ps -ef | grep -E "opencode.*serve" | grep -v grep
echo ""
echo "=== last logs ==="
tail -30 /var/log/opencode.log 2>&1 | tail -30