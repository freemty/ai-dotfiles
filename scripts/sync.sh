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

log "sync start"

# Shell
copy_file "$HOME/.zshrc" "$ROOT_DIR/configs/shell/.zshrc"
copy_file "$HOME/.p10k.zsh" "$ROOT_DIR/configs/shell/.p10k.zsh"
copy_file "$HOME/.zprofile" "$ROOT_DIR/configs/shell/.zprofile"
copy_file "$HOME/.zsh_profile" "$ROOT_DIR/configs/shell/.zsh_profile"

# Git
copy_file "$HOME/.gitconfig" "$ROOT_DIR/configs/git/.gitconfig"

# Tmux
copy_file "$HOME/.tmux.conf" "$ROOT_DIR/configs/tmux/.tmux.conf"

# Clash
mirror_dir "$HOME/.config/clash" "$ROOT_DIR/configs/clash"

# Claude
if [ -d "$HOME/.claude" ]; then
  if [ -f "$HOME/.claude/mcp.json" ]; then
    ensure_dir "$ROOT_DIR/secrets/claude"
    ensure_dir "$ROOT_DIR/configs/claude"

    if [ -n "$PYTHON_BIN" ]; then
      CLAUDE_MCP_SRC="$HOME/.claude/mcp.json" \
      CLAUDE_MCP_SECRET="$ROOT_DIR/secrets/claude/mcp.json" \
      CLAUDE_MCP_REDACTED="$ROOT_DIR/configs/claude/mcp.json" \
      "$PYTHON_BIN" - << 'PY'
import json
import os
from pathlib import Path

src = Path(os.environ["CLAUDE_MCP_SRC"])
secret = Path(os.environ["CLAUDE_MCP_SECRET"])
redacted_path = Path(os.environ["CLAUDE_MCP_REDACTED"])

data = json.loads(src.read_text())
secret.write_text(json.dumps(data, indent=2) + "\n")

def redact_value(key, value):
    key_upper = str(key).upper()
    if any(x in key_upper for x in ("TOKEN", "KEY", "SECRET", "PASSWORD")):
        return "<redacted>"
    return value

def redact_env(env):
    if not isinstance(env, dict):
        return env
    return {k: redact_value(k, v) for k, v in env.items()}

redacted = json.loads(src.read_text())
mcp_servers = redacted.get("mcpServers")
if isinstance(mcp_servers, dict):
    for _, server in mcp_servers.items():
        if isinstance(server, dict) and "env" in server:
            server["env"] = redact_env(server.get("env"))

redacted_path.write_text(json.dumps(redacted, indent=2) + "\n")
PY
      log "claude mcp: secret + redacted"
    else
      copy_file "$HOME/.claude/mcp.json" "$ROOT_DIR/secrets/claude/mcp.json"
      warn "python not found; skipped redacted mcp.json"
    fi
  fi
  mirror_dir "$HOME/.claude/rules" "$ROOT_DIR/configs/claude/rules"

  if [ -f "$HOME/.claude/settings.json" ]; then
    ensure_dir "$ROOT_DIR/secrets/claude"
    ensure_dir "$ROOT_DIR/configs/claude"

    if [ -n "$PYTHON_BIN" ]; then
      CLAUDE_SETTINGS_SRC="$HOME/.claude/settings.json" \
      CLAUDE_SETTINGS_SECRET="$ROOT_DIR/secrets/claude/settings.json" \
      CLAUDE_SETTINGS_REDACTED="$ROOT_DIR/configs/claude/settings.json" \
      "$PYTHON_BIN" - << 'PY'
import json
import os
from pathlib import Path

src = Path(os.environ["CLAUDE_SETTINGS_SRC"])
secret = Path(os.environ["CLAUDE_SETTINGS_SECRET"])
redacted_path = Path(os.environ["CLAUDE_SETTINGS_REDACTED"])

data = json.loads(src.read_text())

# Write full settings to secrets
secret.write_text(json.dumps(data, indent=2) + "\n")

# Redact likely secrets
redacted = json.loads(src.read_text())

env = redacted.get("env")
if isinstance(env, dict):
    cleaned = {}
    for k, v in env.items():
        key_upper = k.upper()
        if any(x in key_upper for x in ("TOKEN", "KEY", "SECRET", "PASSWORD")):
            cleaned[k] = "<redacted>"
        else:
            cleaned[k] = v
    redacted["env"] = cleaned

for k in list(redacted.keys()):
    key_upper = str(k).upper()
    if any(x in key_upper for x in ("TOKEN", "KEY", "SECRET", "PASSWORD")):
        redacted[k] = "<redacted>"

redacted_path.write_text(json.dumps(redacted, indent=2) + "\n")
PY
      log "claude settings: secret + redacted"
    else
      copy_file "$HOME/.claude/settings.json" "$ROOT_DIR/secrets/claude/settings.json"
      warn "python not found; skipped redacted settings"
    fi
  fi

  copy_file "$HOME/.claude.json" "$ROOT_DIR/secrets/claude/claude.json"

  if [ -f "$HOME/.claude/plugins/known_marketplaces.json" ]; then
    ensure_dir "$ROOT_DIR/configs/claude"
    ensure_dir "$ROOT_DIR/configs/claude/marketplaces"

    if [ -n "$PYTHON_BIN" ]; then
      CLAUDE_MARKETPLACES_SRC="$HOME/.claude/plugins/known_marketplaces.json"
      CLAUDE_MARKETPLACES_DST="$ROOT_DIR/configs/claude/marketplaces.json"
      CLAUDE_MARKETPLACES_DIR="$ROOT_DIR/configs/claude/marketplaces"

      local_list_tmp="$(mktemp)"
      CLAUDE_MARKETPLACES_SRC="$CLAUDE_MARKETPLACES_SRC" \
      CLAUDE_MARKETPLACES_DST="$CLAUDE_MARKETPLACES_DST" \
      CLAUDE_MARKETPLACES_DIR="$CLAUDE_MARKETPLACES_DIR" \
      "$PYTHON_BIN" - << 'PY' > "$local_list_tmp"
import json
import os
from pathlib import Path

src = Path(os.environ["CLAUDE_MARKETPLACES_SRC"])
dst = Path(os.environ["CLAUDE_MARKETPLACES_DST"])
local_root = Path(os.environ["CLAUDE_MARKETPLACES_DIR"])

raw = json.loads(src.read_text())
out = {"marketplaces": []}

for name, info in raw.items():
    source = info.get("source", {}) or {}
    source_type = source.get("source")
    entry = {"name": name, "source": source_type}

    if source_type == "github":
        entry["repo"] = source.get("repo")
        entry["source_arg"] = source.get("repo")
    elif source_type == "local":
        install_location = info.get("installLocation")
        if install_location:
            local_path = local_root / name
            entry["path"] = str(local_path)
            entry["source_arg"] = str(local_path)
            print(f"{name}\t{install_location}")
        else:
            entry["source_arg"] = None
    else:
        entry["source_arg"] = None

    out["marketplaces"].append(entry)

dst.write_text(json.dumps(out, indent=2) + "\n")
PY

      if [ -s "$local_list_tmp" ]; then
        while IFS=$'\t' read -r mp_name mp_src; do
          [ -z "$mp_name" ] && continue
          mirror_dir "$mp_src" "$ROOT_DIR/configs/claude/marketplaces/$mp_name"
        done < "$local_list_tmp"
      fi
      rm -f "$local_list_tmp"
      log "claude marketplaces: sanitized"
    else
      warn "python not found; skipped claude marketplaces"
    fi
  fi
else
  warn "~/.claude not found; skipping claude"
fi

# Codex
if [ -d "$HOME/.codex" ]; then
  copy_file "$HOME/.codex/config.toml" "$ROOT_DIR/configs/codex/config.toml"
  mirror_dir "$HOME/.codex/skills" "$ROOT_DIR/configs/codex/skills"
  copy_file "$HOME/.codex/auth.json" "$ROOT_DIR/secrets/codex/auth.json"
else
  warn "~/.codex not found; skipping codex"
fi

# Gemini
if [ -d "$HOME/.gemini" ]; then
  copy_file "$HOME/.gemini/settings.json" "$ROOT_DIR/configs/gemini/settings.json"
  copy_file "$HOME/.gemini/state.json" "$ROOT_DIR/configs/gemini/state.json"
  copy_file "$HOME/.gemini/GEMINI.md" "$ROOT_DIR/configs/gemini/GEMINI.md"
  copy_file "$HOME/.gemini/google_accounts.json" "$ROOT_DIR/secrets/gemini/google_accounts.json"
  copy_file "$HOME/.gemini/oauth_creds.json" "$ROOT_DIR/secrets/gemini/oauth_creds.json"
else
  warn "~/.gemini not found; skipping gemini"
fi

log "sync complete"
