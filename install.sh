#!/usr/bin/env bash
# =============================================================================
# sha-flutter — Installer
# curl -fsSL https://raw.githubusercontent.com/mshariqq/sha-flutter/main/install.sh | bash
# =============================================================================

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}${BOLD}[sha-flutter installer]${RESET} $*"; }
success() { echo -e "${GREEN}✔ $*${RESET}"; }
warn()    { echo -e "${YELLOW}⚠ $*${RESET}"; }
error()   { echo -e "${RED}✖ $*${RESET}" >&2; exit 1; }

INSTALL_DIR="/usr/local/bin"
BINARY="$INSTALL_DIR/sha-flutter"
RAW_URL="https://raw.githubusercontent.com/mshariqq/sha-flutter/main/sha-flutter.sh"

echo ""
echo -e "${BOLD}${CYAN}  Installing sha-flutter — Flutter Version Manager${RESET}"
echo -e "  By Muhammed Shariq Ahmed — https://mshariqq.github.io/mshariqq/"
echo ""

# ── Check dependencies ────────────────────────────────────────────────────────
MISSING=()
for dep in curl tar jq; do
    command -v "$dep" &>/dev/null || MISSING+=("$dep")
done

if [[ ${#MISSING[@]} -gt 0 ]]; then
    warn "Missing dependencies: ${MISSING[*]}"
    info "Installing them now (requires sudo)…"
    sudo apt-get update -qq
    sudo apt-get install -y "${MISSING[@]}"
    success "Dependencies installed."
fi

# ── Download sha-flutter ──────────────────────────────────────────────────────
info "Downloading sha-flutter…"
TMP=$(mktemp)
curl -fsSL "$RAW_URL" -o "$TMP" || error "Download failed. Check your internet connection."
chmod +x "$TMP"

# ── Install ───────────────────────────────────────────────────────────────────
info "Installing to $BINARY (requires sudo)…"
sudo mv "$TMP" "$BINARY"

# ── PATH check ────────────────────────────────────────────────────────────────
if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
    warn "$INSTALL_DIR is not in your PATH — but it usually is on Linux Mint."
fi

echo ""
success "sha-flutter installed successfully! 🎉"
echo ""
echo -e "  Get started:"
echo -e "    ${CYAN}sha-flutter help${RESET}             — see all commands"
echo -e "    ${CYAN}sha-flutter list${RESET}             — browse Flutter versions"
echo -e "    ${CYAN}sha-flutter install 3.22.0${RESET}   — install a version"
echo ""
echo -e "  Repo : https://github.com/mshariqq/sha-flutter"
echo ""
