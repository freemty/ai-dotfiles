#!/usr/bin/env bash
# Skill bootstrap — clone personal skills monorepo + install third-party skills.
#
# Run this AFTER ./install.sh has stowed the configs.
set -euo pipefail

log() { printf "\033[1;34m==>\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[warn]\033[0m %s\n" "$*"; }

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_REPO="git@github.com:freemty/yuanbo-skills.git"
SKILLS_DIR="$HOME/code/projects/yuanbo-skills"
THIRD_PARTY_LIST="$DOTFILES_DIR/scripts/third-party-skills.txt"

# --- 1. Personal skills (yuanbo-skills) ---
if [[ ! -d "$SKILLS_DIR" ]]; then
  log "cloning yuanbo-skills -> $SKILLS_DIR"
  mkdir -p "$(dirname "$SKILLS_DIR")"
  git clone --recurse-submodules "$SKILLS_REPO" "$SKILLS_DIR"
else
  log "yuanbo-skills already present, pulling…"
  git -C "$SKILLS_DIR" pull --recurse-submodules
fi

log "running yuanbo-skills installer (symlinks skills -> ~/.claude/skills/)"
"$SKILLS_DIR/install.sh" --target claude

# --- 2. Third-party skills via npx skills ---
if [[ ! -f "$THIRD_PARTY_LIST" ]]; then
  warn "no third-party-skills.txt, skipping"
  exit 0
fi

if ! command -v npx >/dev/null 2>&1; then
  warn "npx not found — skip third-party skills. Install Node.js and rerun."
  exit 0
fi

log "installing third-party skills from $(basename "$THIRD_PARTY_LIST")"
while IFS= read -r skill; do
  [[ -z "$skill" || "$skill" =~ ^# ]] && continue
  if [[ -e "$HOME/.claude/skills/$skill" ]]; then
    echo "  [skip] $skill (already present)"
    continue
  fi
  echo "  [add]  $skill"
  npx -y skills add "$skill" </dev/null || warn "failed: $skill"
done < "$THIRD_PARTY_LIST"

log "bootstrap complete."
