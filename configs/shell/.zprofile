# ============================================================================
# .zprofile - Shell login configuration
# ============================================================================
# This file is sourced by zsh for login shells
# Put device-specific PATH initialization in ~/.zprofile.local

# ----------------------------------------------------------------------------
# Homebrew Initialization (cross-platform)
# ----------------------------------------------------------------------------
# Detect Homebrew installation and initialize shell environment
# Supports both Apple Silicon (/opt/homebrew) and Intel (/usr/local) Macs

if [ -x "/opt/homebrew/bin/brew" ]; then
  # Apple Silicon Mac
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x "/usr/local/bin/brew" ]; then
  # Intel Mac
  eval "$(/usr/local/bin/brew shellenv)"
elif [ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
  # Linux (Linuxbrew)
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# ----------------------------------------------------------------------------
# Load Local Profile Configuration
# ----------------------------------------------------------------------------
# Put device-specific configurations in ~/.zprofile.local
# This file is not tracked by ai-dotfiles

[ -f "$HOME/.zprofile.local" ] && source "$HOME/.zprofile.local"
