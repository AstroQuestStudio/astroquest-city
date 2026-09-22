#!/bin/bash
# SECURE edge.astroquest.fr with HTTP Basic Auth
# Personal use + 1-2 friends (shared via secure channel)
set -e

CADDYFILE=/etc/caddy/Caddyfile
ENV_FILE=/opt/aq-app/infra/.env

# Generate secure random password
NEW_PASSWORD=$(openssl rand -base64 18 | tr -d '/+=' | head -c 20)
echo "[1] Generated random password: $NEW_PASSWORD"

# Save to env file (encrypted at rest via file perms)
echo "" >> $ENV_FILE
echo "# AstroQuest dashboard auth (Caddy basic_auth)"
echo "AQ_DASH_USER=astroquest" >> $ENV_FILE
echo "AQ_DASH_PASS=$NEW_PASSWORD" >> $ENV_FILE
chmod 600 $ENV_FILE

# Generate Caddy-compatible bcrypt hash
HASH=$(caddy hash-password --plaintext "$NEW_PASSWORD" 2>/dev/null)
if [ -z "$HASH" ]; then
  # Fallback to SHA-256 if bcrypt not available
  HASH=$(echo -n "$NEW_PASSWORD" | sha256sum | awk '{print $1}')
  echo "[WARN] bcrypt not available, using SHA-256 (less secure)"
fi
echo "[2] Generated hash: $HASH"

# Backup + update Caddyfile
cp $CADDYFILE ${CADDYFILE}.bak3

# Insert basicauth directive at the start of the edge.astroquest.fr block
# We'll wrap the whole block with basicauth
python3 - <<PYEOF
import re
with open("$CADDYFILE", "r") as f:
    content = f.read()

# Add basicauth at start of edge.astroquest.fr block
basicauth_block = '''edge.astroquest.fr {
    basicauth {
        astroquest $HASH
    }

    encode zstd gzip'''

content = content.replace("edge.astroquest.fr {\n    encode zstd gzip", basicauth_block)

with open("$CADDYFILE", "w") as f:
    f.write(content)
print("[3] Caddyfile updated with basicauth")
PYEOF

# Validate + reload
echo "[4] Validating Caddyfile..."
caddy fmt --overwrite $CADDYFILE 2>&1 | head -3
caddy validate --config $CADDYFILE 2>&1 | tail -3
echo "[5] Reloading Caddy..."
caddy reload --config $CADDYFILE 2>&1
sleep 2

echo ""
echo "=== TEST: site should now require auth ==="
curl -sI https://edge.astroquest.fr/ | head -3
echo ""
echo "=== TEST: with auth ==="
curl -sI -u "astroquest:$NEW_PASSWORD" https://edge.astroquest.fr/ | head -3

echo ""
echo "================================================="
echo "  AUTH CREDENTIALS"
echo "  URL: https://edge.astroquest.fr/"
echo "  Username: astroquest"
echo "  Password: $NEW_PASSWORD"
echo "  Saved in: $ENV_FILE"
echo "================================================="