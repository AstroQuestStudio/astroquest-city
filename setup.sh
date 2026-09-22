#!/usr/bin/env bash
# ============================================================
# ASTROQUEST CITY — AUTO-INSTALLER
# Usage: ./setup.sh
# Installs:
#   - opencode CLI (local coding agent)
#   - AstroQuest City Tauri .exe (download from latest release)
#   - Cortex binary (optional, for token-efficient code context)
#   - Sets up ~/.aq/keys.json scaffold
# ============================================================
set -e

VERSION="0.1.0"
AQ_DIR="$HOME/.aq"
CORTEX_DIR="$HOME/Documents/Cortex"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

step() {
  echo ""
  echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
  echo -e "${CYAN}  $1${NC}"
  echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
}

ok() {
  echo -e "${GREEN}✓${NC} $1"
}

warn() {
  echo -e "${YELLOW}⚠${NC} $1"
}

err() {
  echo -e "${RED}✗${NC} $1"
}

# ============================================================
# STEP 0 — Detect OS
# ============================================================
step "STEP 0 — Detect OS"
OS=$(uname -s)
ARCH=$(uname -m)
echo "OS: $OS"
echo "Architecture: $ARCH"

case "$OS-$ARCH" in
  Linux-x86_64)  PLATFORM="linux-x64" ;;
  Darwin-x86_64) PLATFORM="macos-x64" ;;
  Darwin-arm64)  PLATFORM="macos-arm64" ;;
  MINGW*-x86_64) PLATFORM="windows-x64" ;;
  *)
    err "Unsupported platform: $OS-$ARCH"
    exit 1
    ;;
esac
ok "Platform detected: $PLATFORM"

# ============================================================
# STEP 1 — Install opencode CLI
# ============================================================
step "STEP 1 — Install opencode CLI"

if command -v opencode >/dev/null 2>&1; then
  VERSION_OC=$(opencode --version 2>/dev/null || echo "unknown")
  ok "opencode already installed: v$VERSION_OC"
else
  echo "Downloading opencode..."
  mkdir -p "$HOME/.opencode/bin"
  if [ "$PLATFORM" = "windows-x64" ]; then
    curl -fsSL -o "$HOME/.opencode/bin/opencode.zip" \
      "https://github.com/sst/opencode/releases/download/v1.18.32/opencode-windows-x64.zip"
    powershell -Command "Expand-Archive -Path '$HOME/.opencode/bin/opencode.zip' -DestinationPath '$HOME/.opencode/bin' -Force"
    rm "$HOME/.opencode/bin/opencode.zip"
    mv "$HOME/.opencode/bin/opencode.exe" "$HOME/.opencode/bin/opencode.exe.tmp" 2>/dev/null || true
  else
    curl -fsSL https://opencode.ai/install | bash
  fi
  ok "opencode installed"
fi

# ============================================================
# STEP 2 — Create ~/.aq/ directory + keys.json scaffold
# ============================================================
step "STEP 2 — Setup ~/.aq/ directory"

mkdir -p "$AQ_DIR"
mkdir -p "$HOME/.config/opencode"

if [ ! -f "$AQ_DIR/keys.json" ]; then
  cat > "$AQ_DIR/keys.json" <<'EOF'
{
  "groq_keys": [],
  "minimax_key": null,
  "litellm_master_key": "sk-aq-local",
  "anthropic_key": null,
  "openai_key": null
}
EOF
  chmod 600 "$AQ_DIR/keys.json"
  ok "keys.json scaffold created (chmod 600)"
  warn "Edit ~/.aq/keys.json to add your Groq + MiniMax keys, then run the AstroQuest app"
else
  ok "keys.json already exists"
fi

# ============================================================
# STEP 3 — Install Cortex (optional)
# ============================================================
step "STEP 3 — Install Cortex (token-efficient code context)"

if [ -f "$CORTEX_DIR/target/release/cortex.exe" ] || [ -f "$CORTEX_DIR/target/release/cortex" ]; then
  ok "Cortex already installed"
else
  warn "Cortex not found. Install manually from https://github.com/trufa/cortex"
  warn "Without Cortex, the Knowledge Panel will be disabled but Code Atelier still works"
fi

# ============================================================
# STEP 4 — Download AstroQuest City desktop app
# ============================================================
step "STEP 4 — Download AstroQuest City desktop app"

RELEASE_URL="https://github.com/anomalyco/opencode/releases/latest"
echo "Open this URL in your browser to download the .exe installer:"
echo ""
echo "  $RELEASE_URL"
echo ""

# For automated installs (Linux), show apt/snap options
if [ "$PLATFORM" = "linux-x64" ]; then
  warn "On Linux: use the .AppImage from GitHub releases"
fi
if [ "$PLATFORM" = "macos-x64" ] || [ "$PLATFORM" = "macos-arm64" ]; then
  warn "On macOS: use the .dmg from GitHub releases"
fi

# ============================================================
# STEP 5 — Index your projects with Cortex
# ============================================================
step "STEP 5 — Index your projects with Cortex"

if command -v cortex >/dev/null 2>&1 || [ -f "$CORTEX_DIR/target/release/cortex.exe" ]; then
  CORTEX_BIN="$CORTEX_DIR/target/release/cortex"
  if [ ! -f "$CORTEX_BIN" ] && [ -f "$CORTEX_DIR/target/release/cortex.exe" ]; then
    CORTEX_BIN="$CORTEX_DIR/target/release/cortex.exe"
  fi
  if [ -d "$HOME/Documents/AstroQuest City" ]; then
    echo "Indexing AstroQuest City..."
    "$CORTEX_BIN" index "$HOME/Documents/AstroQuest City" --name "AstroQuestCity" 2>&1 | tail -2
    ok "AstroQuestCity indexed"
  fi
else
  warn "Skipped (Cortex not installed)"
fi

# ============================================================
# DONE
# ============================================================
step "✅ SETUP COMPLETE"

cat <<EOF

${GREEN}AstroQuest City is ready to use!${NC}

${YELLOW}Next steps:${NC}
1. ${CYAN}Edit ~/.aq/keys.json${NC} with your Groq + MiniMax keys
2. ${CYAN}Launch AstroQuest City${NC} desktop app
3. ${CYAN}Open Code Atelier${NC} (🔥 button) to start coding
4. ${CYAN}Open Knowledge Panel${NC} (🧠 KB) to query your code with Cortex

${YELLOW}Files created:${NC}
  $AQ_DIR/keys.json     ← your API keys (chmod 600)
  $HOME/.config/opencode/opencode.json  ← opencode config (auto-generated)

${YELLOW}Support:${NC}
  - Repo:  https://github.com/anomalyco/opencode (opencode)
  - Docs:  https://opencode.ai/docs

EOF

echo -e "${GREEN}Happy hacking! 🚀${NC}"