#!/usr/bin/env bash
# ============================================================
# AstroQuest City — Injecte les 21 clés Groq dans apps/infra/.env
# Usage : bash setup-keys.sh
# Lit le fichier keys.txt (depuis C:\Users\trufa\Downloads\)
# ============================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ENV_FILE="$REPO_ROOT/apps/infra/.env"
KEYS_FILE="${KEYS_FILE:-/c/Users/trufa/Downloads/keys.txt}"

if [[ ! -f "$KEYS_FILE" ]]; then
  echo "❌ Fichier de clés introuvable : $KEYS_FILE"
  echo "   Définis la variable d'env KEYS_FILE avec le bon chemin."
  exit 1
fi

if [[ ! -f "$ENV_FILE" ]]; then
  echo "❌ Fichier .env absent : $ENV_FILE"
  echo "   Lance d'abord : cp $ENV_FILE.example $ENV_FILE"
  exit 1
fi

echo "→ Lecture des clés depuis $KEYS_FILE"
# Format attendu : "groq 1 : gsk_..." une par ligne
mapfile -t LINES < "$KEYS_FILE"

INDEX=0
for LINE in "${LINES[@]}"; do
  LINE="$(echo "$LINE" | xargs)"  # trim
  [[ -z "$LINE" ]] && continue
  # Extraction après le ':'
  KEY="$(echo "$LINE" | sed -E 's/^groq[[:space:]]+[0-9]+[[:space:]]*[:：][[:space:]]*//')"
  if [[ -z "$KEY" || "$KEY" == "$LINE" ]]; then
    echo "⚠️  Ligne ignorée (format inattendu) : $LINE"
    continue
  fi
  INDEX=$((INDEX+1))
  PAD=$(printf "%02d" "$INDEX")
  VAR="GROQ_KEY_${PAD}"
  # Remplace la ligne GROQ_KEY_NN=gsk_XXXXXX dans .env
  # Utilise sed -i pour compatibilité GNU/BSD
  if sed --version >/dev/null 2>&1; then
    SED_INPLACE=(-i)
  else
    SED_INPLACE=(-i '')
  fi
  sed "${SED_INPLACE[@]}" "s|^${VAR}=.*|${VAR}=${KEY}|" "$ENV_FILE"
  echo "  ✓ ${VAR} injectée"
done

if [[ "$INDEX" -ne 21 ]]; then
  echo "⚠️  Seulement $INDEX clés injectées (attendu : 21)"
fi

echo ""
echo "✅ ${INDEX} clés Groq injectées dans $ENV_FILE"
echo "   Tu peux maintenant lancer : cd $REPO_ROOT/apps/infra && docker compose up -d"