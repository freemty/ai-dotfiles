# --- Oh My Zsh ---
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""  # 使用 starship，禁用 omz 主题

# Homebrew 补全
if [[ -d "/opt/homebrew/share/zsh/site-functions" ]]; then
  FPATH="/opt/homebrew/share/zsh/site-functions:${FPATH}"
fi

plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  fzf
  copyzshell
)

source $ZSH/oh-my-zsh.sh

# --- 环境变量 ---
export EDITOR='vim'
export LANG=en_US.UTF-8

# --- 历史记录 ---
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_ALL_DUPS  # 去重
setopt HIST_FIND_NO_DUPS     # 搜索时不显示重复
setopt HIST_SAVE_NO_DUPS     # 保存时去重
setopt SHARE_HISTORY         # 多终端共享历史
setopt INC_APPEND_HISTORY    # 即时追加而非退出时写入

# --- 目录导航 ---
setopt AUTO_CD               # 输入目录名直接 cd
setopt AUTO_PUSHD            # cd 自动压栈
setopt PUSHD_IGNORE_DUPS     # 栈中不重复
DIRSTACKSIZE=20

# --- 补全增强 ---
setopt COMPLETE_ALIASES
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'  # 忽略大小写

# --- 别名 ---
# 工具
alias cc="claude"
alias cldd="claude --dangerously-skip-permissions"
alias hldd="happy --dangerously-skip-permissions"
alias claudepeers="claude --dangerously-load-development-channels server:claude-peers"
alias cx="codex"
alias cxd="codex --dangerously-bypass-approvals-and-sandbox"
alias gm="gemini"
alias sc="source"
alias v="vim"
alias lg="lazygit"

# 文件操作
alias ll="eza -lAh --icons --git"
alias la="eza -A --icons"
alias ls="eza --icons"
alias cat="bat --paging=never"
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

# Git 快捷
alias gs="git status"
alias gd="git diff"
alias gl="git log --oneline -20"
alias gp="git push"
alias gpull="git pull"

# 网络
alias proxy="export https_proxy=http://127.0.0.1:7890 http_proxy=http://127.0.0.1:7890 all_proxy=socks5://127.0.0.1:7890"
alias unproxy="unset https_proxy http_proxy all_proxy ALL_PROXY"
alias myip="curl -s ifconfig.me"

# tmux
alias ta="tmux attach -t"
alias tl="tmux ls"
alias tn="tmux new -s"

# --- 实用函数 ---
# 创建目录并进入
mkcd() { mkdir -p "$1" && cd "$1" }

# 快速查找文件
ff() { find . -name "*$1*" 2>/dev/null }

# 快速查找内容
fg() { grep -rn "$1" . --include="$2" 2>/dev/null }

# 解压万能命令
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

# iTerm2 配色切换
cycle-color() {
  local themes=(
    "Hacker" "Tron" "Matrix" "Cyberpunk"
    "Vaughn" "Solarized Dark" "Nord"
  )
  local index_file="$HOME/.iterm2_color_index"
  local index=-1
  [[ -f "$index_file" ]] && index=$(<"$index_file")
  index=$(( (index + 1) % ${#themes[@]} ))
  local theme_name="${themes[index + 1]}"
  printf "]1337;SetColors=preset=%s\a" "$theme_name"
  echo "$index" > "$index_file"
  echo "已切换到 $theme_name 主题。"
}

# --- PATH ---
export FZF_BASE="/opt/homebrew/opt/fzf"
export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"
export PATH="/Applications/Blender.app/Contents/MacOS:$PATH"
export PATH="/Users/sum_young/.codeium/windsurf/bin:$PATH"

# --- Conda (懒加载) ---
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

. "$HOME/.local/bin/env"

# --- Secret Env ---
if [ -f "$HOME/.config/secret-env" ]; then
  set -a
  source "$HOME/.config/secret-env"
  set +a
fi

# --- 代理（默认开启） ---
export https_proxy=http://127.0.0.1:7890
export http_proxy=http://127.0.0.1:7890
export all_proxy=socks5://127.0.0.1:7890
export ALL_PROXY=socks5://127.0.0.1:7890

# bun completions
[ -s "/Users/sum_young/.bun/_bun" ] && source "/Users/sum_young/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# --- zoxide (smart cd) ---
eval "$(zoxide init zsh)"

# --- Starship prompt ---
eval "$(starship init zsh)"
