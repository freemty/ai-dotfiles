# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load
ZSH_THEME="powerlevel10k/powerlevel10k"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Homebrew completion paths (cross-platform)
if command -v brew &> /dev/null; then
  # Dynamically detect Homebrew prefix
  BREW_PREFIX="$(brew --prefix)"
  if [[ -d "$BREW_PREFIX/share/zsh/site-functions" ]]; then
    FPATH="$BREW_PREFIX/share/zsh/site-functions:${FPATH}"
  fi
fi

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  fzf
  autojump
  copyzshell
)

source $ZSH/oh-my-zsh.sh

# User configuration

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ============================================================================
# Common Aliases
# ============================================================================

# AI CLI shortcuts
alias cc="claude"
alias cx="codex"
alias gm="gemini"

# Utility aliases
alias sc="source"

# ============================================================================
# Load Secret Environment Variables
# ============================================================================
# This file should contain sensitive data like API keys
# Format: KEY=value (one per line)
if [ -f "$HOME/.config/secret-env" ]; then
  set -a
  source "$HOME/.config/secret-env"
  set +a
fi

# ============================================================================
# Load Local Configuration
# ============================================================================
# Put device-specific configurations in ~/.zshrc.local
# This file is not tracked by ai-dotfiles and should contain:
#   - Local paths (Conda, Docker, etc.)
#   - Device-specific aliases
#   - Proxy settings
#   - Any other machine-specific settings
#
# Example ~/.zshrc.local:
#   # Conda
#   [ -d "$HOME/miniconda3" ] && export PATH="$HOME/miniconda3/bin:$PATH"
#
#   # Docker (macOS)
#   [ -d "/Applications/Docker.app" ] && \
#     export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"
#
#   # Proxy
#   alias proxy="export https_proxy=http://127.0.0.1:7890 ..."
#
#   # FZF (if using Homebrew)
#   command -v brew >/dev/null && export FZF_BASE=$(brew --prefix fzf)
#
#   # Autojump (if using Homebrew)
#   command -v brew >/dev/null && \
#     [ -f "$(brew --prefix)/etc/profile.d/autojump.sh" ] && \
#     . "$(brew --prefix)/etc/profile.d/autojump.sh"

[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
