#!/usr/bin/env bash
# Cross-machine dotfiles installer.
# Installs GNU Stow, backs up existing configs, and symlinks every package.
#
# Usage:
#   ./install.sh                  # install all packages
#   ./install.sh claude codex     # install only specified packages
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

PACKAGES_ALL=(claude codex gemini zsh git tmux yazi)
if [[ $# -gt 0 ]]; then
  PACKAGES=("$@")
else
  PACKAGES=("${PACKAGES_ALL[@]}")
fi

log() { printf "\033[1;34m==>\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[warn]\033[0m %s\n" "$*"; }
err() { printf "\033[1;31m[err]\033[0m %s\n" "$*" >&2; }

# --- 1. Ensure stow is installed ---
if ! command -v stow >/dev/null 2>&1; then
  log "GNU Stow not found — installing…"
  if [[ "$(uname)" == "Darwin" ]]; then
    if ! command -v brew >/dev/null; then
      err "Homebrew required on macOS. Install from https://brew.sh"
      exit 1
    fi
    brew install stow
  elif command -v apt-get >/dev/null; then
    sudo apt-get update && sudo apt-get install -y stow
  else
    err "Please install GNU Stow manually for this OS."
    exit 1
  fi
fi

# --- 2. Backup existing targets ---
backup_if_exists() {
  local target="$1"
  if [[ -e "$target" && ! -L "$target" ]]; then
    mkdir -p "$BACKUP_DIR"
    local rel="${target#$HOME/}"
    local dest="$BACKUP_DIR/$rel"
    mkdir -p "$(dirname "$dest")"
    mv "$target" "$dest"
    warn "backed up $target -> $dest"
  fi
}

# Pre-backup: each package's top-level files only (not ~/.claude as a whole —
# we want to keep runtime dirs like sessions/, projects/, skills/ intact)
for pkg in "${PACKAGES[@]}"; do
  case "$pkg" in
    claude)
      backup_if_exists "$HOME/.claude/settings.json"
      backup_if_exists "$HOME/.claude/mcp.json"
      ;;
    codex)
      backup_if_exists "$HOME/.codex/config.toml"
      backup_if_exists "$HOME/.codex/hooks.json"
      ;;
    gemini)
      backup_if_exists "$HOME/.gemini/settings.json"
      backup_if_exists "$HOME/.gemini/GEMINI.md"
      ;;
    zsh)
      backup_if_exists "$HOME/.zshrc"
      backup_if_exists "$HOME/.zprofile"
      backup_if_exists "$HOME/.p10k.zsh"
      ;;
    git) backup_if_exists "$HOME/.gitconfig" ;;
    tmux) backup_if_exists "$HOME/.tmux.conf" ;;
    yazi)
      backup_if_exists "$HOME/.config/yazi/keymap.toml"
      backup_if_exists "$HOME/.config/yazi/package.toml"
      ;;
  esac
done

# --- 3. Stow each package ---
cd "$DOTFILES_DIR"
for pkg in "${PACKAGES[@]}"; do
  if [[ ! -d "$pkg" ]]; then
    warn "package '$pkg' not found — skipping"
    continue
  fi
  log "stow: $pkg -> \$HOME"
  stow -t "$HOME" --no-folding --restow "$pkg"
done

log "Done. Backups (if any): $BACKUP_DIR"
echo
echo "Next: run ./scripts/bootstrap.sh to install skills (yuanbo-skills + third-party)."
