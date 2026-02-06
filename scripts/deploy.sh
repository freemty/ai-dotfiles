#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

REMOTE_DEPLOY_DIR="ai-dotfiles"
DEFAULT_SSH_PORT=22
DEFAULT_MODULES="claude,codex,gemini"
WITH_SECRETS=0
INTERACTIVE_SECRETS=0
UPDATE_MODE=0
DRY_RUN=0
MODULES=""
MODULES_RAW=""
MODULES_APPEND=0
SSH_PORT="$DEFAULT_SSH_PORT"
SSH_IDENTITY=""
SSH_TARGET=""

declare -a SSH_OPTS=()

usage() {
  cat <<EOF
Usage: $0 <user@host> [OPTIONS]

Deploy ai-dotfiles configurations to a remote Linux server.

Arguments:
  user@host           SSH target (required)

Options:
  --with-secrets      Include secrets/ directory (sensitive data)
  --interactive-secrets  Prompt for API keys locally and transfer securely
  --update            Incremental update (skip dependency installation)
  --modules=<list>    Deploy specific modules. Default: claude,codex,gemini
                      Prefix with + to append to defaults (e.g., +shell,git)
                      Available: shell,git,tmux,ssh,tools,claude,codex,gemini
  --dry-run           Preview actions without executing
  --port=<port>       SSH port (default: 22)
  --identity=<file>   SSH identity file
  --help              Show this help message

Examples:
  # Basic deployment (AI CLI only)
  $0 user@192.168.1.100

  # Deploy AI CLI + shell configs
  $0 user@server1 --modules=+shell,git

  # Deploy only shell configs (override default)
  $0 user@server1 --modules=shell,git

  # Interactive secrets input (recommended)
  $0 user@server1 --interactive-secrets

  # Incremental update
  $0 user@server1 --update

  # Preview without executing
  $0 user@server1 --dry-run
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --with-secrets)
        WITH_SECRETS=1
        shift
        ;;
      --interactive-secrets)
        INTERACTIVE_SECRETS=1
        shift
        ;;
      --update)
        UPDATE_MODE=1
        shift
        ;;
      --dry-run)
        DRY_RUN=1
        shift
        ;;
      --modules=*)
        MODULES_RAW="${1#*=}"
        # Check if starts with +
        if [[ "$MODULES_RAW" == +* ]]; then
          MODULES_APPEND=1
          MODULES_RAW="${MODULES_RAW#+}"  # Strip leading +
        fi
        shift
        ;;
      --port=*)
        SSH_PORT="${1#*=}"
        shift
        ;;
      --identity=*)
        SSH_IDENTITY="${1#*=}"
        shift
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      -*)
        warn "Unknown option: $1"
        usage
        exit 1
        ;;
      *)
        if [ -z "$SSH_TARGET" ]; then
          SSH_TARGET="$1"
        else
          warn "Unexpected argument: $1"
          usage
          exit 1
        fi
        shift
        ;;
    esac
  done

  if [ -z "$SSH_TARGET" ]; then
    warn "SSH target is required"
    usage
    exit 1
  fi

  SSH_OPTS=(-p "$SSH_PORT")
  if [ -n "$SSH_IDENTITY" ]; then
    SSH_OPTS+=(-i "$SSH_IDENTITY")
  fi

  # Resolve final module list
  if [ -z "$MODULES_RAW" ]; then
    # No --modules specified: use defaults (AI CLI only)
    MODULES="$DEFAULT_MODULES"
  elif [ "$MODULES_APPEND" = "1" ]; then
    # + prefix: append to defaults
    MODULES="$DEFAULT_MODULES,$MODULES_RAW"
  else
    # No + prefix: override defaults
    MODULES="$MODULES_RAW"
  fi
}

check_ssh_connection() {
  log "checking SSH connection to $SSH_TARGET..."
  if ! ssh_test "$SSH_TARGET"; then
    warn "failed to connect to $SSH_TARGET"
    warn "please ensure:"
    warn "  1. SSH server is running on remote host"
    warn "  2. SSH key is configured (ssh-copy-id $SSH_TARGET)"
    warn "  3. Firewall allows SSH connections"
    exit 1
  fi
  log "SSH connection OK"
}

check_remote_deps() {
  log "checking remote dependencies..."

  local missing_deps=()

  for cmd in git zsh python3 rsync; do
    if ! ssh_exec "$SSH_TARGET" "command -v $cmd >/dev/null 2>&1"; then
      missing_deps+=("$cmd")
    fi
  done

  if [ ${#missing_deps[@]} -gt 0 ]; then
    warn "missing dependencies on remote host: ${missing_deps[*]}"
    warn ""
    warn "please install them manually before deployment:"
    warn ""
    warn "  # Ubuntu/Debian:"
    warn "  sudo apt-get update && sudo apt-get install -y ${missing_deps[*]}"
    warn ""
    warn "  # CentOS/RHEL:"
    warn "  sudo yum install -y ${missing_deps[*]}"
    warn ""
    warn "  # Arch Linux:"
    warn "  sudo pacman -Sy ${missing_deps[*]}"
    warn ""
    exit 1
  fi

  log "all dependencies are installed"
}

build_rsync_excludes() {
  local -a excludes=(
    --exclude='.git'
    --exclude='backups/'
    --exclude='*.log'
    --exclude='.DS_Store'
  )

  if [ "$WITH_SECRETS" != "1" ]; then
    excludes+=(--exclude='secrets/')
  fi

  # Module filtering (always applied since MODULES is always set)
  IFS=',' read -ra module_list <<< "$MODULES"

  # Include parent directory first
  excludes+=(--include='configs/')

  # Include specific modules (must come before exclude)
  for module in "${module_list[@]}"; do
    excludes+=(--include="configs/$module/")
    excludes+=(--include="configs/$module/**")
  done

  # Exclude everything else in configs/
  excludes+=(--exclude='configs/*')

  echo "${excludes[@]}"
}

transfer_repo() {
  log "transferring repository to $SSH_TARGET:~/$REMOTE_DEPLOY_DIR..."

  if [ "$DRY_RUN" = "1" ]; then
    log "[dry-run] would transfer: $ROOT_DIR -> $SSH_TARGET:~/$REMOTE_DEPLOY_DIR"
    return 0
  fi

  if ! has_cmd rsync; then
    warn "rsync not found locally"
    exit 1
  fi

  # Build SSH command for rsync
  local ssh_cmd="ssh -p $SSH_PORT"
  if [ -n "$SSH_IDENTITY" ]; then
    ssh_cmd="$ssh_cmd -i $SSH_IDENTITY"
  fi

  local -a rsync_opts=(
    -avz
    --delete
    -e "$ssh_cmd"
  )

  local excludes
  excludes=$(build_rsync_excludes)
  rsync_opts+=($excludes)

  rsync "${rsync_opts[@]}" "$ROOT_DIR/" "$SSH_TARGET:$REMOTE_DEPLOY_DIR/"

  log "transfer complete"
}

transfer_secrets() {
  if [ "$WITH_SECRETS" != "1" ]; then
    return 0
  fi

  if [ ! -d "$ROOT_DIR/secrets" ]; then
    warn "secrets/ directory not found, skipping"
    return 0
  fi

  log "transferring secrets..."
  warn "⚠️  transferring sensitive data to remote server"

  if [ "$DRY_RUN" = "1" ]; then
    log "[dry-run] would transfer secrets/"
    return 0
  fi

  ssh_exec "$SSH_TARGET" "chmod 700 ~/$REMOTE_DEPLOY_DIR/secrets 2>/dev/null || true"
  ssh_exec "$SSH_TARGET" "find ~/$REMOTE_DEPLOY_DIR/secrets -type f -exec chmod 600 {} \\; 2>/dev/null || true"

  log "secrets transferred with restrictive permissions"
}

detect_required_keys() {
  local -a required_keys=()

  if [ -f "$ROOT_DIR/configs/claude/mcp.json" ] && grep -q "NOTION_API_KEY" "$ROOT_DIR/configs/claude/mcp.json" 2>/dev/null; then
    required_keys+=("NOTION_API_KEY")
  fi

  if [ -f "$ROOT_DIR/configs/codex/config.toml" ] && grep -q "NOTION_API_KEY" "$ROOT_DIR/configs/codex/config.toml" 2>/dev/null; then
    if [[ ! " ${required_keys[@]+"${required_keys[@]}"} " =~ " NOTION_API_KEY " ]]; then
      required_keys+=("NOTION_API_KEY")
    fi
  fi

  if [ -f "$ROOT_DIR/configs/claude/mcp.json" ] && grep -q "ANTHROPIC_API_KEY" "$ROOT_DIR/configs/claude/mcp.json" 2>/dev/null; then
    required_keys+=("ANTHROPIC_API_KEY")
  fi

  if [ -f "$ROOT_DIR/configs/codex/config.toml" ] && grep -q "OPENAI_API_KEY" "$ROOT_DIR/configs/codex/config.toml" 2>/dev/null; then
    required_keys+=("OPENAI_API_KEY")
  fi

  echo "${required_keys[@]+"${required_keys[@]}"}"
}

collect_and_transfer_interactive_secrets() {
  if [ "$INTERACTIVE_SECRETS" != "1" ]; then
    return 0
  fi

  log "collecting API keys interactively..."

  local required_keys
  required_keys=$(detect_required_keys)

  if [ -z "$required_keys" ]; then
    log "no API keys required in configuration"
    return 0
  fi

  if [ "$DRY_RUN" = "1" ]; then
    log "[dry-run] would collect keys: $required_keys"
    return 0
  fi

  # Prepare remote secret-env file
  ssh_exec "$SSH_TARGET" "mkdir -p ~/.config && touch ~/.config/secret-env && chmod 600 ~/.config/secret-env"

  log "transferring secrets to remote server..."
  local collected_count=0

  for key in $required_keys; do
    read -r -s -p "Enter $key: " value
    printf "\n"
    if [ -n "$value" ]; then
      # Directly transfer to remote server
      ssh_exec "$SSH_TARGET" "grep -q '^${key}=' ~/.config/secret-env 2>/dev/null && sed -i.bak 's|^${key}=.*|${key}=${value}|' ~/.config/secret-env || echo '${key}=${value}' >> ~/.config/secret-env"
      log "✓ collected and transferred $key"
      collected_count=$((collected_count + 1))
    else
      warn "⚠️  skipped $key (empty value)"
    fi
  done

  if [ "$collected_count" -eq 0 ]; then
    warn "no secrets collected"
    return 0
  fi

  log "secrets transferred securely"
}

run_remote_apply() {
  log "executing apply.sh on remote server..."

  if [ "$DRY_RUN" = "1" ]; then
    log "[dry-run] would execute: cd ~/$REMOTE_DEPLOY_DIR && ./scripts/apply.sh"
    return 0
  fi

  ssh_exec "$SSH_TARGET" "cd ~/$REMOTE_DEPLOY_DIR && chmod +x scripts/apply.sh && ./scripts/apply.sh" || {
    warn "apply.sh failed on remote server"
    warn "you may need to manually run: ssh $SSH_TARGET 'cd ~/$REMOTE_DEPLOY_DIR && ./scripts/apply.sh'"
    exit 1
  }

  log "apply.sh completed successfully"
}

verify_deployment() {
  log "verifying deployment..."

  if [ "$DRY_RUN" = "1" ]; then
    log "[dry-run] would verify deployment"
    return 0
  fi

  local -a check_files=()

  # Use comma-wrapping to avoid partial matches
  if [[ ",$MODULES," == *",shell,"* ]]; then
    check_files+=("~/.zshrc")
  fi

  if [[ ",$MODULES," == *",git,"* ]]; then
    check_files+=("~/.gitconfig")
  fi

  if [[ ",$MODULES," == *",claude,"* ]]; then
    check_files+=("~/.claude/settings.json")
  fi

  if [[ ",$MODULES," == *",codex,"* ]]; then
    check_files+=("~/.codex/config.toml")
  fi

  if [[ ",$MODULES," == *",gemini,"* ]]; then
    check_files+=("~/.gemini/settings.json")
  fi

  for file in "${check_files[@]}"; do
    if ssh_exec "$SSH_TARGET" "[ -f $file ]"; then
      log "✓ $file exists"
    else
      warn "✗ $file not found"
    fi
  done

  log "deployment verification complete"
}

main() {
  parse_args "$@"

  log "=== ai-dotfiles deployment to $SSH_TARGET ==="
  log "modules to deploy: $MODULES"

  check_ssh_connection

  check_remote_deps

  transfer_repo

  transfer_secrets

  collect_and_transfer_interactive_secrets

  run_remote_apply

  verify_deployment

  log "=== deployment complete ==="
  log "you can now SSH to $SSH_TARGET and use the configured environment"
}

main "$@"

