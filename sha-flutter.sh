#!/usr/bin/env bash
# =============================================================================
# sha-flutter — Install, switch, and remove Flutter versions on Linux Mint
# Usage: sha-flutter [command] [version]
# =============================================================================

set -euo pipefail

# ── Version ───────────────────────────────────────────────────────────────────
SHA_FLUTTER_VERSION="1.0.0"
REPO_RAW="https://raw.githubusercontent.com/mshariqq/sha-flutter/main/sha-flutter.sh"
REPO_API="https://api.github.com/repos/mshariqq/sha-flutter/releases/latest"

# ── Config ────────────────────────────────────────────────────────────────────
FLUTTER_BASE_DIR="${FLUTTER_BASE_DIR:-$HOME/.flutter-versions}"
FLUTTER_SYMLINK="$HOME/.local/flutter"
FLUTTER_BIN_LINK="$HOME/.local/bin/flutter"
FLUTTER_DART_LINK="$HOME/.local/bin/dart"
FLUTTER_STORAGE_BASE="https://storage.googleapis.com/flutter_infra_release/releases"
RELEASES_JSON_URL="$FLUTTER_STORAGE_BASE/releases_linux.json"
RELEASES_CACHE="$FLUTTER_BASE_DIR/.releases_cache.json"
CACHE_TTL=3600   # seconds — re-fetch release list after 1 hour

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}${BOLD}[sha-flutter]${RESET} $*"; }
success() { echo -e "${GREEN}✔ $*${RESET}"; }
warn()    { echo -e "${YELLOW}⚠ $*${RESET}"; }
error()   { echo -e "${RED}✖ $*${RESET}" >&2; exit 1; }

# ── Helpers ───────────────────────────────────────────────────────────────────
require() {
    for cmd in "$@"; do
        command -v "$cmd" &>/dev/null || error "Required tool '$cmd' not found. Install it first."
    done
}

ensure_dirs() {
    mkdir -p "$FLUTTER_BASE_DIR" "$HOME/.local/bin"
}

# Fetch and cache the official Flutter releases JSON
fetch_releases() {
    local now
    now=$(date +%s)
    if [[ -f "$RELEASES_CACHE" ]]; then
        local mtime
        mtime=$(stat -c %Y "$RELEASES_CACHE" 2>/dev/null || echo 0)
        if (( now - mtime < CACHE_TTL )); then
            return 0
        fi
    fi
    info "Fetching Flutter release list…"
    curl -fsSL "$RELEASES_JSON_URL" -o "$RELEASES_CACHE" \
        || error "Could not download Flutter release list. Check your internet connection."
}

# Return the archive filename for a given version string (e.g. 3.19.6)
resolve_archive() {
    local version="$1"
    fetch_releases
    local archive
    archive=$(jq -r --arg v "$version" \
        '.releases[] | select(.version == $v) | .archive' \
        "$RELEASES_CACHE" | head -1)
    [[ -z "$archive" || "$archive" == "null" ]] && \
        error "Version '$version' not found. Run 'sha-flutter list' to see available versions."
    echo "$archive"
}

active_version() {
    if [[ -L "$FLUTTER_SYMLINK" && -x "$FLUTTER_SYMLINK/bin/flutter" ]]; then
        "$FLUTTER_SYMLINK/bin/flutter" --version 2>/dev/null | awk '/Flutter/ {print $2}' || echo "unknown"
    else
        echo "none"
    fi
}

# ── Commands ──────────────────────────────────────────────────────────────────

cmd_list() {
    local channel="${1:-stable}"
    fetch_releases
    info "Available Flutter versions (channel: $channel) — latest 30:"
    echo ""
    jq -r --arg ch "$channel" \
        '[.releases[] | select(.channel == $ch)] | .[0:30][] |
         "  \(.version)  [\(.channel)]  \(.release_date[:10])"' \
        "$RELEASES_CACHE" \
    || error "Failed to parse releases."
    echo ""
    echo -e "  ${YELLOW}Tip:${RESET} Use 'sha-flutter list beta' or 'list dev' for other channels."
    echo -e "  ${YELLOW}Tip:${RESET} Use 'sha-flutter search 3.19' to filter by prefix."
}

cmd_search() {
    local query="${1:-}"
    [[ -z "$query" ]] && error "Usage: sha-flutter search <version-prefix>  e.g. search 3.19"
    fetch_releases
    info "Searching for Flutter versions matching '$query':"
    echo ""
    jq -r --arg q "$query" \
        '.releases[] | select(.version | startswith($q)) |
         "  \(.version)  [\(.channel)]  \(.release_date[:10])"' \
        "$RELEASES_CACHE" | sort -V | uniq \
    || error "Search failed."
}

cmd_install() {
    local version="${1:-}"
    [[ -z "$version" ]] && error "Usage: sha-flutter install <version>  e.g. install 3.22.0"

    local dest="$FLUTTER_BASE_DIR/$version"

    if [[ -d "$dest" ]]; then
        warn "Flutter $version is already installed at $dest"
        read -rp "Switch to it anyway? [y/N] " yn
        [[ "$yn" =~ ^[Yy]$ ]] && cmd_use "$version" || exit 0
        return
    fi

    local archive
    archive=$(resolve_archive "$version")
    local url="$FLUTTER_STORAGE_BASE/$archive"
    local tarball="$FLUTTER_BASE_DIR/$(basename "$archive")"

    info "Downloading Flutter $version…"
    info "URL: $url"
    curl -L --progress-bar "$url" -o "$tarball" \
        || error "Download failed."

    info "Extracting…"
    mkdir -p "$dest"
    tar xf "$tarball" --strip-components=1 -C "$dest" \
        || error "Extraction failed."
    rm -f "$tarball"

    success "Flutter $version installed to $dest"
    cmd_use "$version"
}

cmd_use() {
    local version="${1:-}"
    [[ -z "$version" ]] && error "Usage: sha-flutter use <version>"

    local dest="$FLUTTER_BASE_DIR/$version"
    [[ -d "$dest" ]] || error "Flutter $version is not installed. Run: sha-flutter install $version"

    info "Switching active Flutter to $version…"
    ln -sfn "$dest" "$FLUTTER_SYMLINK"
    ln -sfn "$FLUTTER_SYMLINK/bin/flutter" "$FLUTTER_BIN_LINK"
    ln -sfn "$FLUTTER_SYMLINK/bin/dart"    "$FLUTTER_DART_LINK"

    success "Active Flutter → $version"
    _check_path_hint
}

cmd_current() {
    local ver
    ver=$(active_version)
    if [[ "$ver" == "none" ]]; then
        warn "No active Flutter version set."
    else
        success "Active Flutter version: $ver"
        echo -e "  Symlink : $FLUTTER_SYMLINK"
        echo -e "  flutter : $(command -v flutter 2>/dev/null || echo '(not in PATH)')"
    fi
}

cmd_installed() {
    info "Installed Flutter versions:"
    echo ""
    local active
    active=$(active_version)
    local found=0
    for d in "$FLUTTER_BASE_DIR"/*/; do
        [[ -x "$d/bin/flutter" ]] || continue
        local v
        v=$(basename "$d")
        found=1
        if [[ "$v" == "$active" ]]; then
            echo -e "  ${GREEN}▶ $v  (active)${RESET}"
        else
            echo -e "    $v"
        fi
    done
    [[ $found -eq 0 ]] && warn "No Flutter versions installed yet."
    echo ""
}

cmd_remove() {
    local version="${1:-}"
    [[ -z "$version" ]] && error "Usage: sha-flutter remove <version>"

    local dest="$FLUTTER_BASE_DIR/$version"
    [[ -d "$dest" ]] || error "Flutter $version is not installed."

    local active
    active=$(active_version)
    if [[ "$version" == "$active" ]]; then
        warn "You are about to remove the currently ACTIVE version ($version)."
    fi

    read -rp "Remove Flutter $version at $dest? [y/N] " yn
    [[ "$yn" =~ ^[Yy]$ ]] || { info "Cancelled."; exit 0; }

    rm -rf "$dest"
    success "Removed Flutter $version"

    if [[ "$version" == "$active" ]]; then
        rm -f "$FLUTTER_SYMLINK" "$FLUTTER_BIN_LINK" "$FLUTTER_DART_LINK"
        warn "Active version removed. Run 'sha-flutter use <version>' to switch to another."
        cmd_installed
    fi
}

cmd_purge() {
    warn "This will REMOVE ALL installed Flutter versions and the sha-flutter data directory."
    warn "Directory: $FLUTTER_BASE_DIR"
    read -rp "Are you absolutely sure? Type 'yes' to confirm: " yn
    [[ "$yn" == "yes" ]] || { info "Cancelled."; exit 0; }
    rm -rf "$FLUTTER_BASE_DIR" "$FLUTTER_SYMLINK" "$FLUTTER_BIN_LINK" "$FLUTTER_DART_LINK"
    success "All Flutter versions purged."
}

cmd_version() {
    echo -e "${CYAN}${BOLD}sha-flutter${RESET} version ${BOLD}v${SHA_FLUTTER_VERSION}${RESET}"
    echo -e "  Repo : https://github.com/mshariqq/sha-flutter"
    echo -e "  By   : Muhammed Shariq Ahmed — https://mshariqq.github.io/mshariqq/"
}

cmd_self_update() {
    info "Checking for updates…"

    local latest_version
    latest_version=$(curl -fsSL "$REPO_API" 2>/dev/null \
        | grep '"tag_name"' \
        | sed -E 's/.*"tag_name": *"v?([^"]+)".*/\1/')

    if [[ -z "$latest_version" ]]; then
        error "Could not fetch latest version info. Check your internet connection."
    fi

    if [[ "$latest_version" == "$SHA_FLUTTER_VERSION" ]]; then
        success "Already up to date — v${SHA_FLUTTER_VERSION}"
        return 0
    fi

    info "New version available: ${BOLD}v${latest_version}${RESET}  (you have v${SHA_FLUTTER_VERSION})"
    read -rp "Update now? [y/N] " yn
    [[ "$yn" =~ ^[Yy]$ ]] || { info "Cancelled."; exit 0; }

    local install_path
    install_path=$(command -v sha-flutter 2>/dev/null || echo "/usr/local/bin/sha-flutter")

    info "Downloading v${latest_version}…"
    local tmp
    tmp=$(mktemp)
    curl -fsSL "$REPO_RAW" -o "$tmp" || error "Download failed."
    chmod +x "$tmp"

    if [[ -w "$install_path" ]]; then
        mv "$tmp" "$install_path"
    else
        info "Need sudo to write to $install_path"
        sudo mv "$tmp" "$install_path"
    fi

    success "sha-flutter updated to v${latest_version} 🎉"
    info "Run 'sha-flutter help' to see what's new."
}

_check_path_hint() {
    if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
        echo ""
        warn "~/.local/bin is not in your PATH."
        echo -e "  Add this to your ~/.bashrc or ~/.zshrc and restart your terminal:"
        echo -e "  ${BOLD}export PATH=\"\$HOME/.local/bin:\$PATH\"${RESET}"
    fi
}

cmd_help() {
    local DIVIDER="${CYAN}$(printf '%.0s─' {1..60})${RESET}"

    echo ""
    echo -e "${BOLD}${CYAN}  ███████╗██╗  ██╗ █████╗     ███████╗██╗     ██╗   ██╗████████╗████████╗███████╗██████╗ ${RESET}"
    echo -e "${BOLD}${CYAN}  ██╔════╝██║  ██║██╔══██╗    ██╔════╝██║     ██║   ██║╚══██╔══╝╚══██╔══╝██╔════╝██╔══██╗${RESET}"
    echo -e "${BOLD}${CYAN}  ███████╗███████║███████║    █████╗  ██║     ██║   ██║   ██║      ██║   █████╗  ██████╔╝${RESET}"
    echo -e "${BOLD}${CYAN}  ╚════██║██╔══██║██╔══██║    ██╔══╝  ██║     ██║   ██║   ██║      ██║   ██╔══╝  ██╔══██╗${RESET}"
    echo -e "${BOLD}${CYAN}  ███████║██║  ██║██║  ██║    ██║     ███████╗╚██████╔╝   ██║      ██║   ███████╗██║  ██║${RESET}"
    echo -e "${BOLD}${CYAN}  ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝    ╚═╝     ╚══════╝ ╚═════╝    ╚═╝      ╚═╝   ╚══════╝╚═╝  ╚═╝${RESET}"
    echo ""
    echo -e "  ${BOLD}Flutter Version Manager for Linux Mint${RESET}  —  like ondrej/php, but for Flutter"
    echo ""
    echo -e "$DIVIDER"
    echo ""
    echo -e "  ${BOLD}USAGE${RESET}"
    echo -e "    ${CYAN}sha-flutter${RESET} <command> [argument]"
    echo ""
    echo -e "$DIVIDER"
    echo ""
    echo -e "  ${BOLD}COMMANDS${RESET}"
    echo ""
    # Header row
    printf "  ${BOLD}%-32s  %s${RESET}\n" "Command" "What it does"
    printf "  ${YELLOW}%-32s  %s${RESET}\n" "──────────────────────────────" "──────────────────────────────────────────"
    # Commands
    printf "  ${CYAN}%-32s${RESET}  %s\n"  "sha-flutter list"              "Browse available stable versions"
    printf "  ${CYAN}%-32s${RESET}  %s\n"  "sha-flutter list beta"         "Browse beta / dev versions"
    printf "  ${CYAN}%-32s${RESET}  %s\n"  "sha-flutter search 3.22"       "Filter versions by prefix"
    printf "  ${CYAN}%-32s${RESET}  %s\n"  "sha-flutter install 3.22.0"    "Download & install a version"
    printf "  ${CYAN}%-32s${RESET}  %s\n"  "sha-flutter use 3.19.6"        "Switch active version"
    printf "  ${CYAN}%-32s${RESET}  %s\n"  "sha-flutter current"           "Show what's active"
    printf "  ${CYAN}%-32s${RESET}  %s\n"  "sha-flutter installed"         "List all installed versions"
    printf "  ${CYAN}%-32s${RESET}  %s\n"  "sha-flutter remove 3.19.6"     "Delete a specific version"
    printf "  ${CYAN}%-32s${RESET}  %s\n"  "sha-flutter purge"             "Remove ALL versions & manager data"
    printf "  ${CYAN}%-32s${RESET}  %s\n"  "sha-flutter help"              "Show this help message"
    printf "  ${CYAN}%-32s${RESET}  %s\n"  "sha-flutter version"           "Show installed sha-flutter version"
    printf "  ${CYAN}%-32s${RESET}  %s\n"  "sha-flutter self-update"       "Update sha-flutter to latest release"
    echo ""
    echo -e "$DIVIDER"
    echo ""
    echo -e "  ${BOLD}EXAMPLES${RESET}"
    echo ""
    echo -e "    ${GREEN}\$${RESET} sha-flutter list"
    echo -e "    ${GREEN}\$${RESET} sha-flutter list beta"
    echo -e "    ${GREEN}\$${RESET} sha-flutter search 3.22"
    echo -e "    ${GREEN}\$${RESET} sha-flutter install 3.22.0"
    echo -e "    ${GREEN}\$${RESET} sha-flutter use 3.19.6"
    echo -e "    ${GREEN}\$${RESET} sha-flutter installed"
    echo -e "    ${GREEN}\$${RESET} sha-flutter remove 3.19.6"
    echo -e "    ${GREEN}\$${RESET} sha-flutter purge"
    echo ""
    echo -e "$DIVIDER"
    echo ""
    echo -e "  ${BOLD}ENVIRONMENT${RESET}"
    echo -e "    ${CYAN}FLUTTER_BASE_DIR${RESET}   Override install root  (default: ${BOLD}~/.flutter-versions${RESET})"
    echo ""
    echo -e "$DIVIDER"
    echo ""
    echo -e "  ${YELLOW}Tip:${RESET} Versions are stored in ${BOLD}~/.flutter-versions/<version>/${RESET}"
    echo -e "  ${YELLOW}Tip:${RESET} Active version is symlinked at ${BOLD}~/.local/bin/flutter${RESET}"
    echo ""
}

# ── Entry point ───────────────────────────────────────────────────────────────
require curl tar jq

ensure_dirs

case "${1:-help}" in
    list)      cmd_list      "${2:-stable}" ;;
    search)    cmd_search    "${2:-}" ;;
    install)   cmd_install   "${2:-}" ;;
    use)       cmd_use       "${2:-}" ;;
    current)   cmd_current ;;
    installed) cmd_installed ;;
    remove|uninstall) cmd_remove "${2:-}" ;;
    purge)       cmd_purge ;;
    version|--version|-v) cmd_version ;;
    self-update|update)   cmd_self_update ;;
    help|--help|-h) cmd_help ;;
    *) error "Unknown command '${1}'. Run 'sha-flutter help'." ;;
esac
