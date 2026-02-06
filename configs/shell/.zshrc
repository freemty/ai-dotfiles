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

# ============================================================================
# Homebrew Completion (cross-platform)
# ============================================================================
if command -v brew &> /dev/null; then
  # Dynamically detect Homebrew prefix
  BREW_PREFIX="$(brew --prefix)"
  if [[ -d "$BREW_PREFIX/share/zsh/site-functions" ]]; then
    FPATH="$BREW_PREFIX/share/zsh/site-functions:${FPATH}"
  fi
fi

# ============================================================================
# Oh-My-Zsh Plugins
# ============================================================================
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  fzf
  autojump
  copyzshell
)

source $ZSH/oh-my-zsh.sh

# ============================================================================
# User Configuration
# ============================================================================

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# ============================================================================
# Conda Initialization (auto-detect)
# ============================================================================
# Try multiple common Conda installation locations
for conda_base in "$HOME/miniconda3" "$HOME/anaconda3" "$HOME/miniforge3" "/opt/conda"; do
  if [ -d "$conda_base" ]; then
    __conda_setup="$('$conda_base/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
      eval "$__conda_setup"
    else
      if [ -f "$conda_base/etc/profile.d/conda.sh" ]; then
        . "$conda_base/etc/profile.d/conda.sh"
      else
        export PATH="$conda_base/bin:$PATH"
      fi
    fi
    unset __conda_setup
    break
  fi
done

# ============================================================================
# Development Tools PATH (auto-detect)
# ============================================================================

# Docker Desktop (macOS only)
if [[ "$OSTYPE" == "darwin"* ]] && [ -d "/Applications/Docker.app" ]; then
  export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"
fi

# Blender (macOS only)
if [[ "$OSTYPE" == "darwin"* ]] && [ -d "/Applications/Blender.app" ]; then
  export PATH="/Applications/Blender.app/Contents/MacOS:$PATH"
fi

# Windsurf (Codeium) - cross-platform
if [ -d "$HOME/.codeium/windsurf/bin" ]; then
  export PATH="$HOME/.codeium/windsurf/bin:$PATH"
fi

# FZF (Fuzzy Finder) - if using Homebrew
if command -v brew &> /dev/null; then
  export FZF_BASE="$(brew --prefix)/share/fzf"
fi

# Autojump - if using Homebrew
if command -v brew &> /dev/null; then
  AUTOJUMP_SCRIPT="$(brew --prefix)/etc/profile.d/autojump.sh"
  [ -f "$AUTOJUMP_SCRIPT" ] && . "$AUTOJUMP_SCRIPT"
fi

# ============================================================================
# Local Environment Variables (optional)
# ============================================================================
# Load additional local environment variables if they exist
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# ============================================================================
# Powerlevel10k Configuration
# ============================================================================
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ============================================================================
# iTerm2 Specific Functions (macOS only)
# ============================================================================
if [[ "$TERM_PROGRAM" == "iTerm.app" ]]; then
  function cycle-color() {
    local themes=(
      "Hacker"
      "Tron"
      "Matrix"
      "Cyberpunk"
      "Vaughn"
      "Solarized Dark"
      "Nord"
    )

    local index_file="$HOME/.iterm2_color_index"
    local index=-1

    if [[ -f "$index_file" ]]; then
      index=$(<"$index_file")
    fi

    index=$(( (index + 1) % ${#themes[@]} ))
    local theme_name="${themes[index + 1]}"

    printf "\033]1337;SetColors=preset=%s\a" "$theme_name"
    echo "$index" > "$index_file"
    echo "已切换到 $theme_name 主题。"
  }
fi

# ============================================================================
# Common Aliases
# ============================================================================

# AI CLI shortcuts
alias cc="claude"
alias cx="codex"
alias gm="gemini"

# Utility aliases
alias sc="source"

# Proxy aliases (auto-detect if proxy is running)
# Check if common proxy ports are open
if command -v nc &> /dev/null && nc -z 127.0.0.1 7890 2>/dev/null; then
  alias proxy="export https_proxy=http://127.0.0.1:7890 http_proxy=http://127.0.0.1:7890 all_proxy=socks5://127.0.0.1:7890"
  alias unproxy="unset https_proxy http_proxy all_proxy"
elif command -v nc &> /dev/null && nc -z 127.0.0.1 1087 2>/dev/null; then
  # Alternative proxy port (ClashX)
  alias proxy="export https_proxy=http://127.0.0.1:1087 http_proxy=http://127.0.0.1:1087 all_proxy=socks5://127.0.0.1:1087"
  alias unproxy="unset https_proxy http_proxy all_proxy"
else
  # Fallback: define aliases but they may not work
  alias proxy="export https_proxy=http://127.0.0.1:7890 http_proxy=http://127.0.0.1:7890 all_proxy=socks5://127.0.0.1:7890"
  alias unproxy="unset https_proxy http_proxy all_proxy"
fi

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
