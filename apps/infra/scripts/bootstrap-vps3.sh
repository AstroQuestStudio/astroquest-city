#!/usr/bin/env bash
# ============================================================
# AstroQuest City — Bootstrap VPS3 (Hetzner)
# - Installe Docker (idempotent)
# - Nettoie le cron /opt/aq legacy (qui échoue)
# - Prépare les dossiers
# Usage : ssh root@vps3 'bash -s' < bootstrap-vps3.sh
# ============================================================
set -euo pipefail

log() { echo "[$(date +%H:%M:%S)] $*"; }

log "=== AstroQuest City — bootstrap VPS3 ==="

# === 1. Installation Docker (idempotent) ===
if ! command -v docker >/dev/null 2>&1; then
  log "→ Install Docker via le script officiel"
  curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
  sh /tmp/get-docker.sh
  log "✓ Docker installé"
else
  log "→ Docker déjà installé : $(docker --version)"
fi

# === 2. Activer Docker Compose v2 (plugin) ===
if ! docker compose version >/dev/null 2>&1; then
  log "→ Install docker-compose-plugin"
  apt-get update -qq
  apt-get install -y docker-compose-plugin
fi
log "✓ docker compose : $(docker compose version)"

# === 3. Nettoyer le cron legacy /opt/aq qui échoue ===
log "→ Nettoyage du cron /opt/aq (legacy)"
CRON_TMP=$(mktemp)
crontab -l 2>/dev/null > "$CRON_TMP" || true
# Supprime toutes les lignes mentionnant /opt/aq
grep -v '/opt/aq' "$CRON_TMP" > "${CRON_TMP}.new" || true
mv "${CRON_TMP}.new" "$CRON_TMP"
crontab "$CRON_TMP"
rm -f "$CRON_TMP"
log "✓ Cron nettoyé (lignes /opt/aq supprimées)"

# === 4. Dossiers AstroQuest ===
log "→ Préparer /opt/aq-app (nouveau code)"
mkdir -p /opt/aq-app/{infra,logs}
chown -R root:root /opt/aq-app

log "→ Préparer /opt/aq-data (DB, Redis data)"
mkdir -p /opt/aq-data/{postgres,redis,litellm}
chown -R root:root /opt/aq-data

log "=== Bootstrap VPS3 terminé ==="
log ""
log "Prochaines étapes :"
log "  1. Copier apps/infra/docker-compose.yml sur le VPS"
log "  2. Copier apps/infra/litellm/config.yaml sur le VPS"
log "  3. Créer .env avec les clés (via setup-keys.sh)"
log "  4. Lancer : cd /opt/aq-app/infra && docker compose up -d"