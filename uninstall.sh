#!/usr/bin/env bash
# =============================================================================
# sha-flutter — Uninstaller
# =============================================================================

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}${BOLD}[sha-flutter uninstaller]${RESET} $*"; }
success() { echo -e "${GREEN}✔ $*${RESET}"; }
warn()    { echo -e "${YELLOW}⚠ $*${RESET}"; }

BINARY="/usr/local/bin/sha-flutter"
FLUTTER_BASE_DIR="${FLUTTER_BASE_DIR:-$HOME/.flutter-versions}"
FLUTTER_SYMLINK="$HOME/.local/flutter"
FLUTTER_BIN_LINK="$HOME/.local/bin/flutter"
FLUTTER_DART_LINK="$HOME/.local/bin/dart"

echo ""
warn "This will remove sha-flutter (the tool) from your system."
warn "Your installed Flutter versions in $FLUTTER_BASE_DIR will NOT be deleted."
echo ""
read -rp "Remove sha-flutter? [y/N] " yn
[[ "$yn" =~ ^[Yy]$ ]] || { info "Cancelled."; exit 0; }

[[ -f "$BINARY" ]]          && sudo rm -f "$BINARY"          && info "Removed $BINARY"
[[ -L "$FLUTTER_SYMLINK" ]] && rm -f "$FLUTTER_SYMLINK"      && info "Removed symlink $FLUTTER_SYMLINK"
[[ -L "$FLUTTER_BIN_LINK" ]] && rm -f "$FLUTTER_BIN_LINK"   && info "Removed $FLUTTER_BIN_LINK"
[[ -L "$FLUTTER_DART_LINK" ]] && rm -f "$FLUTTER_DART_LINK" && info "Removed $FLUTTER_DART_LINK"

echo ""
success "sha-flutter uninstalled."
echo ""
info "Your Flutter versions are still at: $FLUTTER_BASE_DIR"
info "To also delete them, run:  rm -rf $FLUTTER_BASE_DIR"
echo ""
