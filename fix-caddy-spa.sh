#!/bin/bash
# Update Caddyfile to add /dev/* and /playground as SPA fallback routes
# (vue-router / react-router need index.html for client-side routing)

set -e

CADDYFILE=/etc/caddy/Caddyfile

# Backup
cp "$CADDYFILE" "${CADDYFILE}.bak.$(date +%Y%m%d-%H%M%S)"

# Use sed to update the SPA fallback line
# Old: @aq_fe_spa path /not-a-real-file-* /ceo/* /projects/*
# New: add /dev/* /playground/*
sed -i 's|@aq_fe_spa path /not-a-real-file-\* /ceo/\* /projects/\*|@aq_fe_spa path /not-a-real-file-* /ceo/* /projects/* /dev/* /playground/*|' "$CADDYFILE"

# Verify
echo "=== Updated Caddyfile (relevant section) ==="
grep -n "aq_fe_spa" "$CADDYFILE"

# Reload Caddy (graceful, no downtime)
echo "=== Reloading Caddy ==="
caddy reload --config "$CADDYFILE" --adapter "" 2>&1 || systemctl reload caddy

# Wait + test
sleep 3
echo "=== Test /dev/playground ==="
curl -sI https://edge.astroquest.fr/dev/playground | head -3
echo "=== Test /playground ==="
curl -sI https://edge.astroquest.fr/playground | head -3