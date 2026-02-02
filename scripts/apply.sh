#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

PYTHON_BIN="python3"
if ! has_cmd "$PYTHON_BIN"; then
  PYTHON_BIN="python"
fi
if ! has_cmd "$PYTHON_BIN"; then
  PYTHON_BIN=""
fi

BACKUP_DIR="$ROOT_DIR/backups/$(date +%Y%m%d_%H%M%S)"
ensure_dir "$BACKUP_DIR"

log "apply start"

apply_file() {
  local src="$1"
  local dest="$2"
  if [ -f "$src" ]; then
    backup_path "$BACKUP_DIR" "$dest"
    ensure_dir "$(dirname "$dest")"
    cp "$src" "$dest"
    log "applied: $src -> $dest"
  else
    warn "missing source: $src"
  fi
}

apply_dir() {
  local src="$1"
  local dest="$2"
  if [ -d "$src" ]; then
    backup_path "$BACKUP_DIR" "$dest"
    ensure_dir "$dest"
    if has_cmd rsync; then
      rsync -a "$src/" "$dest/"
      log "applied dir: $src -> $dest"
    else
      warn "rsync not found; skipping dir apply: $src"
    fi
  else
    warn "missing dir: $src"
  fi
}

# Shell
apply_file "$ROOT_DIR/configs/shell/.zshrc" "$HOME/.zshrc"
apply_file "$ROOT_DIR/configs/shell/.p10k.zsh" "$HOME/.p10k.zsh"
apply_file "$ROOT_DIR/configs/shell/.zprofile" "$HOME/.zprofile"
apply_file "$ROOT_DIR/configs/shell/.zsh_profile" "$HOME/.zsh_profile"

# Git
apply_file "$ROOT_DIR/configs/git/.gitconfig" "$HOME/.gitconfig"

# Tmux
apply_file "$ROOT_DIR/configs/tmux/.tmux.conf" "$HOME/.tmux.conf"

# Clash
ensure_dir "$HOME/.config"
apply_dir "$ROOT_DIR/configs/clash" "$HOME/.config/clash"

# Claude
if [ -d "$ROOT_DIR/configs/claude" ]; then
  ensure_dir "$HOME/.claude"
  if [ -f "$ROOT_DIR/secrets/claude/mcp.json" ]; then
    apply_file "$ROOT_DIR/secrets/claude/mcp.json" "$HOME/.claude/mcp.json"
    chmod 600 "$HOME/.claude/mcp.json" || true
  else
    apply_file "$ROOT_DIR/configs/claude/mcp.json" "$HOME/.claude/mcp.json"
  fi
  apply_dir "$ROOT_DIR/configs/claude/rules" "$HOME/.claude/rules"

  if [ -f "$ROOT_DIR/secrets/claude/settings.json" ]; then
    apply_file "$ROOT_DIR/secrets/claude/settings.json" "$HOME/.claude/settings.json"
    chmod 600 "$HOME/.claude/settings.json" || true
  else
    apply_file "$ROOT_DIR/configs/claude/settings.json" "$HOME/.claude/settings.json"
  fi

  if [ -f "$ROOT_DIR/secrets/claude/claude.json" ]; then
    apply_file "$ROOT_DIR/secrets/claude/claude.json" "$HOME/.claude.json"
    chmod 600 "$HOME/.claude.json" || true
  fi

  if [ -f "$ROOT_DIR/configs/claude/marketplaces.json" ] && has_cmd claude && [ -n "$PYTHON_BIN" ]; then
    "$PYTHON_BIN" - "$ROOT_DIR/configs/claude/marketplaces.json" "$ROOT_DIR" << 'PY' | \
    while IFS= read -r source_arg; do
import json
import sys
from pathlib import Path

mp = Path(sys.argv[1])
root = Path(sys.argv[2])

data = json.loads(mp.read_text())
for entry in data.get("marketplaces", []):
    source_arg = entry.get("source_arg")
    if not source_arg:
        continue
    path = Path(source_arg)
    if not path.is_absolute() and str(source_arg).startswith("configs/"):
        source_arg = str(root / source_arg)
    print(source_arg)
PY
      [ -z "$source_arg" ] && continue
      claude plugin marketplace add "$source_arg" || true
    done
  elif [ -f "$ROOT_DIR/configs/claude/marketplaces.json" ] && ! has_cmd claude; then
    warn "claude CLI not found; skipping marketplace add"
  elif [ -f "$ROOT_DIR/configs/claude/marketplaces.json" ]; then
    warn "python not found; skipping marketplace add"
  fi
fi

# Codex
if [ -d "$ROOT_DIR/configs/codex" ]; then
  ensure_dir "$HOME/.codex"
  apply_file "$ROOT_DIR/configs/codex/config.toml" "$HOME/.codex/config.toml"
  apply_dir "$ROOT_DIR/configs/codex/skills" "$HOME/.codex/skills"
  if [ -f "$ROOT_DIR/secrets/codex/auth.json" ]; then
    apply_file "$ROOT_DIR/secrets/codex/auth.json" "$HOME/.codex/auth.json"
    chmod 600 "$HOME/.codex/auth.json" || true
  fi
fi

# Gemini
if [ -d "$ROOT_DIR/configs/gemini" ]; then
  ensure_dir "$HOME/.gemini"
  apply_file "$ROOT_DIR/configs/gemini/settings.json" "$HOME/.gemini/settings.json"
  apply_file "$ROOT_DIR/configs/gemini/state.json" "$HOME/.gemini/state.json"
  apply_file "$ROOT_DIR/configs/gemini/GEMINI.md" "$HOME/.gemini/GEMINI.md"
  if [ -f "$ROOT_DIR/secrets/gemini/google_accounts.json" ]; then
    apply_file "$ROOT_DIR/secrets/gemini/google_accounts.json" "$HOME/.gemini/google_accounts.json"
    chmod 600 "$HOME/.gemini/google_accounts.json" || true
  fi
  if [ -f "$ROOT_DIR/secrets/gemini/oauth_creds.json" ]; then
    apply_file "$ROOT_DIR/secrets/gemini/oauth_creds.json" "$HOME/.gemini/oauth_creds.json"
    chmod 600 "$HOME/.gemini/oauth_creds.json" || true
  fi
fi

log "apply complete"
log "backup saved to: $BACKUP_DIR"
