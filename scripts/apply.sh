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

# Parse command line arguments
MODULES=""
while [ $# -gt 0 ]; do
  case "$1" in
    --modules=*)
      MODULES="${1#*=}"
      shift
      ;;
    --modules)
      MODULES="$2"
      shift 2
      ;;
    *)
      warn "unknown option: $1"
      shift
      ;;
  esac
done

# Function to check if a module should be applied
should_apply_module() {
  local module="$1"
  # If no modules specified, apply all
  if [ -z "$MODULES" ]; then
    return 0
  fi
  # Check if module is in the comma-separated list
  if [[ ",$MODULES," == *",$module,"* ]]; then
    return 0
  fi
  return 1
}

log "apply start"

SECRET_ENV_FILE="$HOME/.config/secret-env"

load_secret_env() {
  if [ -f "$SECRET_ENV_FILE" ]; then
    set -a
    # shellcheck disable=SC1090
    source "$SECRET_ENV_FILE"
    set +a
  fi
}

ensure_secret_env_key() {
  local key="$1"
  ensure_dir "$(dirname "$SECRET_ENV_FILE")"
  touch "$SECRET_ENV_FILE"
  chmod 600 "$SECRET_ENV_FILE" || true

  if ! grep -q "^${key}=" "$SECRET_ENV_FILE" 2>/dev/null; then
    read -r -s -p "Enter ${key}: " value
    printf "\n"
    printf "%s=%s\n" "$key" "$value" >> "$SECRET_ENV_FILE"
  fi
}

needs_notion_key=0
if [ -f "$ROOT_DIR/configs/claude/mcp.json" ] && grep -q "NOTION_API_KEY" "$ROOT_DIR/configs/claude/mcp.json"; then
  needs_notion_key=1
fi
if [ -f "$ROOT_DIR/configs/codex/config.toml" ] && grep -q "NOTION_API_KEY" "$ROOT_DIR/configs/codex/config.toml"; then
  needs_notion_key=1
fi

if [ "$needs_notion_key" -eq 1 ]; then
  ensure_secret_env_key "NOTION_API_KEY"
fi
load_secret_env

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
if should_apply_module "shell"; then
  apply_file "$ROOT_DIR/configs/shell/.zshrc" "$HOME/.zshrc"
  apply_file "$ROOT_DIR/configs/shell/.p10k.zsh" "$HOME/.p10k.zsh"
  apply_file "$ROOT_DIR/configs/shell/.zprofile" "$HOME/.zprofile"
  apply_file "$ROOT_DIR/configs/shell/.zsh_profile" "$HOME/.zsh_profile"
fi

# Git
if should_apply_module "git"; then
  apply_file "$ROOT_DIR/configs/git/.gitconfig" "$HOME/.gitconfig"
fi

# Tmux
if should_apply_module "tmux"; then
  apply_file "$ROOT_DIR/configs/tmux/.tmux.conf" "$HOME/.tmux.conf"
fi

# Claude
if should_apply_module "claude" && [ -d "$ROOT_DIR/configs/claude" ]; then
  ensure_dir "$HOME/.claude"
  if [ -f "$ROOT_DIR/secrets/claude/mcp.json" ]; then
    apply_file "$ROOT_DIR/secrets/claude/mcp.json" "$HOME/.claude/mcp.json"
    chmod 600 "$HOME/.claude/mcp.json" || true
  else
    apply_file "$ROOT_DIR/configs/claude/mcp.json" "$HOME/.claude/mcp.json"
  fi
  if [ -f "$HOME/.claude/mcp.json" ] && [ -n "$PYTHON_BIN" ]; then
    "$PYTHON_BIN" - "$HOME/.claude/mcp.json" << 'PY'
import json
import os
import sys
from pathlib import Path

path = Path(sys.argv[1])
data = json.loads(path.read_text())

changed = False
mcp_servers = data.get("mcpServers")
if isinstance(mcp_servers, dict):
    for server in mcp_servers.values():
        if not isinstance(server, dict):
            continue
        env = server.get("env")
        if not isinstance(env, dict):
            continue
        for key, value in list(env.items()):
            if value == "<redacted>" and os.environ.get(key):
                env[key] = os.environ[key]
                changed = True

if changed:
    path.write_text(json.dumps(data, indent=2) + "\n")
PY
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
if should_apply_module "codex" && [ -d "$ROOT_DIR/configs/codex" ]; then
  ensure_dir "$HOME/.codex"
  if [ -f "$ROOT_DIR/secrets/codex/config.toml" ]; then
    apply_file "$ROOT_DIR/secrets/codex/config.toml" "$HOME/.codex/config.toml"
    chmod 600 "$HOME/.codex/config.toml" || true
  else
    apply_file "$ROOT_DIR/configs/codex/config.toml" "$HOME/.codex/config.toml"
  fi
  if [ -f "$HOME/.codex/config.toml" ] && [ -n "$PYTHON_BIN" ]; then
    "$PYTHON_BIN" - "$HOME/.codex/config.toml" << 'PY'
import os
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text()

def replace_redacted(line: str) -> str:
    m = re.match(r'^(\\s*[^#\\s=]+)\\s*=\\s*\"(.*)\"\\s*$', line)
    if not m:
        return line
    key, value = m.group(1), m.group(2)
    if value != "<redacted>":
        return line
    env_val = os.environ.get(key)
    if env_val:
        return f'{key} = \"{env_val}\"'
    return line

new_text = "\\n".join(replace_redacted(line) for line in text.splitlines()) + "\\n"
path.write_text(new_text)
PY
  fi
  apply_dir "$ROOT_DIR/configs/codex/skills" "$HOME/.codex/skills"
  if [ -f "$ROOT_DIR/secrets/codex/auth.json" ]; then
    apply_file "$ROOT_DIR/secrets/codex/auth.json" "$HOME/.codex/auth.json"
    chmod 600 "$HOME/.codex/auth.json" || true
  fi
fi

# Gemini
if should_apply_module "gemini" && [ -d "$ROOT_DIR/configs/gemini" ]; then
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
