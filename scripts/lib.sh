#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log() {
  printf "[ai-dotfiles] %s\n" "$*"
}

warn() {
  printf "[ai-dotfiles][warn] %s\n" "$*" >&2
}

ensure_dir() {
  mkdir -p "$1"
}

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

copy_file() {
  local src="$1"
  local dest="$2"
  if [ -f "$src" ]; then
    ensure_dir "$(dirname "$dest")"
    cp "$src" "$dest"
    log "copied: $src -> $dest"
  else
    warn "missing file: $src"
  fi
}

mirror_dir() {
  local src="$1"
  local dest="$2"
  shift 2

  if [ ! -d "$src" ]; then
    warn "missing dir: $src"
    return 0
  fi

  ensure_dir "$dest"

  if has_cmd rsync; then
    local opts=("-a")
    if [ "${SYNC_PRUNE:-0}" = "1" ]; then
      opts+=("--delete")
    fi
    rsync "${opts[@]}" "$src/" "$dest/" "$@"
    log "mirrored: $src -> $dest"
  else
    warn "rsync not found; skipping dir mirror: $src"
  fi
}

backup_path() {
  local backup_root="$1"
  local target="$2"
  if [ -e "$target" ]; then
    local rel="${target#${HOME}/}"
    if [ "$rel" = "$target" ]; then
      rel="$(basename "$target")"
    fi
    local dest="$backup_root/home/$rel"
    ensure_dir "$(dirname "$dest")"
    if [ -d "$target" ]; then
      if has_cmd rsync; then
        rsync -a "$target/" "$dest/"
      else
        cp -a "$target" "$dest"
      fi
    else
      cp "$target" "$dest"
    fi
    log "backup: $target -> $dest"
  fi
}

ssh_exec() {
  local ssh_target="$1"
  shift
  local ssh_opts=("${SSH_OPTS[@]}")
  ssh "${ssh_opts[@]}" "$ssh_target" "$@"
}

ssh_test() {
  local ssh_target="$1"
  local ssh_opts=("${SSH_OPTS[@]}")
  ssh -o ConnectTimeout=5 -o BatchMode=yes "${ssh_opts[@]}" "$ssh_target" "echo ok" >/dev/null 2>&1
}

detect_remote_os() {
  local ssh_target="$1"
  local os_id
  os_id=$(ssh_exec "$ssh_target" "cat /etc/os-release 2>/dev/null | grep '^ID=' | cut -d= -f2 | tr -d '\"'" || echo "unknown")
  echo "$os_id"
}

detect_pkg_mgr() {
  local ssh_target="$1"
  local os_id="$2"

  case "$os_id" in
    ubuntu|debian)
      echo "apt"
      ;;
    centos|rhel|rocky|almalinux)
      if ssh_exec "$ssh_target" "command -v dnf >/dev/null 2>&1"; then
        echo "dnf"
      else
        echo "yum"
      fi
      ;;
    arch|manjaro)
      echo "pacman"
      ;;
    alpine)
      echo "apk"
      ;;
    *)
      echo "unknown"
      ;;
  esac
}
