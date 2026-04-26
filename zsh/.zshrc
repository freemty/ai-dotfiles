# ============================================================================
# Oh My Zsh
# ============================================================================
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""  # starship 接管 prompt

if [[ -d "/opt/homebrew/share/zsh/site-functions" ]]; then
  FPATH="/opt/homebrew/share/zsh/site-functions:${FPATH}"
fi

plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  you-should-use
  fzf
  copyzshell
)

source $ZSH/oh-my-zsh.sh

# ============================================================================
# Environment
# ============================================================================
export EDITOR='vim'
export LANG=en_US.UTF-8
export TERM=xterm-256color

# PATH
export PATH="$HOME/.local/bin:$PATH"
export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"
export PATH="/Applications/Blender.app/Contents/MacOS:$PATH"
export FZF_BASE="/opt/homebrew/opt/fzf"

# ============================================================================
# History
# ============================================================================
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY

# ============================================================================
# Shell Options
# ============================================================================
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt COMPLETE_ALIASES
setopt NO_NOMATCH
DIRSTACKSIZE=20

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# ============================================================================
# Aliases
# ============================================================================

# --- AI tools ---
alias cc="claude"
alias cldd="claude --dangerously-skip-permissions"
alias hldd="happy --dangerously-skip-permissions"
alias claudepeers="claude --dangerously-load-development-channels server:claude-peers"
alias cx="codex"
alias cxd="codex --dangerously-bypass-approvals-and-sandbox"
alias gm="gemini"

# --- Files & navigation ---
alias ls="eza --icons"
alias la="eza -A --icons"
alias ll="eza -lAh --icons --git"
alias cat="bat --paging=never"
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

# --- Git ---
alias gs="git status"
alias gd="git diff"
alias gl="git log --oneline -20"
alias gp="git push"
alias gpull="git pull"

# --- Tools ---
alias lg="lazygit"
alias v="vim"
alias sc="source"
alias sz="source ~/.zshrc"

# --- tmux ---
alias ta="tmux attach -t"
alias tl="tmux ls"
alias tn="tmux new -s"

# --- Proxy toggle ---
alias proxy="export http_proxy=http://127.0.0.1:7890 https_proxy=http://127.0.0.1:7890 all_proxy=socks5://127.0.0.1:7890 ALL_PROXY=socks5://127.0.0.1:7890"
alias unproxy="unset http_proxy https_proxy all_proxy ALL_PROXY"
alias myip="curl -s ifconfig.me"

# --- Dotfiles ---
alias dot-sync="cd ~/dotfiles && git pull --ff-only && ./install.sh && cd -"

# ============================================================================
# Functions
# ============================================================================

# yazi wrapper: cd to last browsed directory on exit
y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  command yazi "$@" --cwd-file="$tmp"
  IFS= read -r -d '' cwd < "$tmp"
  [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
  rm -f -- "$tmp"
}

mkcd() { mkdir -p "$1" && cd "$1" }

ff() { find . -name "*$1*" 2>/dev/null }

extract() {
  if [[ -f "$1" ]]; then
    case "$1" in
      *.tar.bz2) tar xjf "$1" ;;
      *.tar.gz)  tar xzf "$1" ;;
      *.tar.xz)  tar xJf "$1" ;;
      *.bz2)     bunzip2 "$1" ;;
      *.gz)      gunzip "$1" ;;
      *.tar)     tar xf "$1" ;;
      *.zip)     unzip "$1" ;;
      *.7z)      7z x "$1" ;;
      *)         echo "无法解压: $1" ;;
    esac
  else
    echo "文件不存在: $1"
  fi
}

# ============================================================================
# Lazy-loaded Tools
# ============================================================================

# Conda
conda() {
  unfunction conda
  __conda_setup="$('/Users/sum_young/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
  if [ $? -eq 0 ]; then
    eval "$__conda_setup"
  else
    if [ -f "/Users/sum_young/miniconda3/etc/profile.d/conda.sh" ]; then
      . "/Users/sum_young/miniconda3/etc/profile.d/conda.sh"
    else
      export PATH="/Users/sum_young/miniconda3/bin:$PATH"
    fi
  fi
  unset __conda_setup
  conda "$@"
}

# ============================================================================
# Runtime Init
# ============================================================================

. "$HOME/.local/bin/env"

# bun
[ -s "/Users/sum_young/.bun/_bun" ] && source "/Users/sum_young/.bun/_bun"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Secret env (API keys, managed by CC-Switch)
if [ -f "$HOME/.config/secret-env" ]; then
  set -a
  source "$HOME/.config/secret-env"
  set +a
fi

# Proxy (default on)
export http_proxy=http://127.0.0.1:7890
export https_proxy=http://127.0.0.1:7890
export all_proxy=socks5://127.0.0.1:7890
export ALL_PROXY=socks5://127.0.0.1:7890

# zoxide (smart cd)
eval "$(zoxide init zsh)"

# Starship prompt (must be last)
eval "$(starship init zsh)"
