#!/bin/bash
# ybcfg - 环境配置管理工具
# 基于你的实际环境：Powerlevel10k + Clash + copyzshell

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 显示帮助信息
show_help() {
    echo -e "${BLUE}ybcfg - 环境配置管理工具${NC}"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --backup-only     仅备份现有配置"
    echo "  --sync-only  --sync-only       仅同步配置到仓库"
    echo "  --install         完整安装（默认）"
    echo "  --help, -h        显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0                # 完整安装"
    echo "  $0 --backup-only  # 仅备份配置"
    echo "  $0 --sync-only   # 仅同步配置"
}

# 检测操作系统
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        if command -v apt-get &> /dev/null; then
            PACKAGE_MANAGER="apt"
        elif command -v yum &> /dev/null; then
            PACKAGE_MANAGER="yum"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        PACKAGE_MANAGER="brew"
    else
        echo -e "${RED}不支持的操作系统: $OSTYPE${NC}"
        exit 1
    fi
    echo -e "${GREEN}检测到操作系统: $OS${NC}"
}

# 备份现有配置
backup_existing_configs() {
    echo -e "${YELLOW}📦 备份现有配置...${NC}"
    
    local backup_dir="backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # 备份现有配置文件
    if [ -f "$HOME/.zshrc" ]; then
        cp "$HOME/.zshrc" "$backup_dir/.zshrc.backup"
        echo "✅ 已备份 .zshrc"
    fi
    
    if [ -f "$HOME/.gitconfig" ]; then
        cp "$HOME/.gitconfig" "$backup_dir/.gitconfig.backup"
        echo "✅ 已备份 .gitconfig"
    fi
    
    if [ -d "$HOME/.config/clash" ]; then
        cp -r "$HOME/.config/clash" "$backup_dir/clash.backup"
        echo "✅ 已备份 Clash 配置"
    fi
    
    if [ -f "$HOME/.tmux.conf" ]; then
        cp "$HOME/.tmux.conf" "$backup_dir/.tmux.conf.backup"
        echo "✅ 已备份 .tmux.conf"
    fi
    
    echo -e "${GREEN}配置备份完成: $backup_dir${NC}"
}

# 安装系统依赖
install_dependencies() {
    echo -e "${YELLOW}📦 安装系统依赖...${NC}"
    
    case $PACKAGE_MANAGER in
        "apt")
            sudo apt update
            sudo apt install -y git curl wget zsh tmux vim python3 python3-pip ncdu
            ;;
        "brew")
            brew install git curl wget zsh tmux vim python3 ncdu
            ;;
        "yum")
            sudo yum install -y git curl wget zsh tmux vim python3 python3-pip ncdu
            ;;
    esac
    
    # 安装系统工具
    install_system_tools
    
    echo -e "${GREEN}✅ 系统依赖安装完成${NC}"
}

# 安装系统工具
install_system_tools() {
    echo -e "${YELLOW}🛠️ 安装系统工具...${NC}"
    
    # 安装 nvtop (GPU 监控)
    install_nvtop
    
    # 安装 ctop (Docker 监控)
    install_ctop
    
    echo -e "${GREEN}✅ 系统工具安装完成${NC}"
}

# 安装 nvtop
install_nvtop() {
    echo -e "${YELLOW}🎮 安装 GPU 监控工具...${NC}"
    
    if command -v nvtop &> /dev/null; then
        echo "nvtop 已安装"
        return
    fi
    
    case $PACKAGE_MANAGER in
        "apt")
            sudo apt install -y nvtop
            ;;
        "brew")
            brew install nvtop
            ;;
        "yum")
            # 尝试安装 nvtop，如果失败则安装 nvitop
            if ! sudo yum install -y nvtop; then
                echo "安装 nvitop 作为替代..."
                pip3 install nvitop
            fi
            ;;
    esac
    
    echo -e "${GREEN}✅ GPU 监控工具安装完成${NC}"
}

# 安装 ctop
install_ctop() {
    echo -e "${YELLOW}🐳 安装 Docker 监控工具...${NC}"
    
    if command -v ctop &> /dev/null; then
        echo "ctop 已安装"
        return
    fi
    
    # 下载并安装 ctop
    local ctop_version="0.7.7"
    local download_url=""
    
    case $OS in
        "linux")
            case $(uname -m) in
                "x86_64")
                    download_url="https://github.com/bcicen/ctop/releases/download/v${ctop_version}/ctop-${ctop_version}-linux-amd64"
                    ;;
                "aarch64")
                    download_url="https://github.com/bcicen/ctop/releases/download/v${ctop_version}/ctop-${ctop_version}-linux-arm64"
                    ;;
            esac
            ;;
        "macos")
            case $(uname -m) in
                "x86_64")
                    download_url="https://github.com/bcicen/ctop/releases/download/v${ctop_version}/ctop-${ctop_version}-darwin-amd64"
                    ;;
                "arm64")
                    download_url="https://github.com/bcicen/ctop/releases/download/v${ctop_version}/ctop-${ctop_version}-darwin-arm64"
                    ;;
            esac
            ;;
    esac
    
    if [ -n "$download_url" ]; then
        echo "下载 ctop..."
        wget -O ctop "$download_url"
        chmod +x ctop
        sudo mv ctop /usr/local/bin/
        echo -e "${GREEN}✅ ctop 安装完成${NC}"
    else
        echo -e "${YELLOW}⚠️ 跳过 ctop 安装（不支持的架构）${NC}"
    fi
}

# 安装 Oh My Zsh 和 Powerlevel10k
install_zsh_and_themes() {
    echo -e "${YELLOW}🐚 安装 ZSH 和主题...${NC}"
    
    # 确保 oh-my-zsh 已安装
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        echo "安装 Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        echo "Oh My Zsh 已安装"
    fi
    
    # 安装 Powerlevel10k
    if [ ! -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
        echo "安装 Powerlevel10k 主题..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
            "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
    else
        echo "Powerlevel10k 已安装"
    fi
    
    # 安装必装插件
    install_zsh_plugins
    
    # 安装 copyzshell
    install_copyzshell
    
    # 修复 Homebrew 补全问题
    fix_homebrew_completion
    
    # 检查并修复 zsh 配置问题
    fix_zsh_config_issues
    
    echo -e "${GREEN}✅ ZSH 和主题安装完成${NC}"
}

# 安装 ZSH 必装插件
install_zsh_plugins() {
    echo -e "${YELLOW}🔌 安装 ZSH 必装插件...${NC}"
    
    # 安装 zsh-syntax-highlighting
    if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
        echo "安装 zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
            ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    else
        echo "zsh-syntax-highlighting 已安装"
    fi
    
    # 安装 zsh-autosuggestions
    if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
        echo "安装 zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions \
            ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    else
        echo "zsh-autosuggestions 已安装"
    fi
    
    # 安装 fzf
    install_fzf
    
    # 安装 autojump
    install_autojump
    
    echo -e "${GREEN}✅ ZSH 插件安装完成${NC}"
}

# 安装 fzf
install_fzf() {
    echo -e "${YELLOW}🔍 安装 fzf...${NC}"
    
    if command -v fzf &> /dev/null; then
        echo "fzf 已安装"
        return
    fi
    
    case $PACKAGE_MANAGER in
        "apt")
            sudo apt install -y fzf
            ;;
        "brew")
            brew install fzf
            ;;
        "yum")
            sudo yum install -y fzf
            ;;
    esac
    
    echo -e "${GREEN}✅ fzf 安装完成${NC}"
}

# 安装 autojump
install_autojump() {
    echo -e "${YELLOW}🚀 安装 autojump...${NC}"
    
    if command -v autojump &> /dev/null; then
        echo "autojump 已安装"
        return
    fi
    
    case $PACKAGE_MANAGER in
        "apt")
            sudo apt install -y autojump
            ;;
        "brew")
            brew install autojump
            ;;
        "yum")
            sudo yum install -y autojump
            ;;
    esac
    
    echo -e "${GREEN}✅ autojump 安装完成${NC}"
}

# 检查并修复 zsh 配置问题
fix_zsh_config_issues() {
    echo -e "${YELLOW}🔧 检查并修复 zsh 配置问题...${NC}"
    
    # 检查 fzf 安装
    if ! command -v fzf &> /dev/null; then
        echo -e "${YELLOW}⚠️ fzf 未安装，跳过 fzf 插件${NC}"
    else
        echo -e "${GREEN}✅ fzf 已安装${NC}"
    fi
    
    # 检查 autojump 安装
    if ! command -v autojump &> /dev/null; then
        echo -e "${YELLOW}⚠️ autojump 未安装，跳过 autojump 插件${NC}"
    else
        echo -e "${GREEN}✅ autojump 已安装${NC}"
    fi
    
    # 检查 zsh-syntax-highlighting 插件
    if [[ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]]; then
        echo -e "${YELLOW}⚠️ zsh-syntax-highlighting 插件未安装${NC}"
    else
        echo -e "${GREEN}✅ zsh-syntax-highlighting 插件已安装${NC}"
    fi
    
    # 检查 zsh-autosuggestions 插件
    if [[ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]]; then
        echo -e "${YELLOW}⚠️ zsh-autosuggestions 插件未安装${NC}"
    else
        echo -e "${GREEN}✅ zsh-autosuggestions 插件已安装${NC}"
    fi
    
    echo -e "${GREEN}✅ zsh 配置检查完成${NC}"
}

# 安装 copyzshell
install_copyzshell() {
    echo -e "${YELLOW}📋 安装 copyzshell 插件...${NC}"
    
    local copyzshell_dir="$HOME/.oh-my-zsh/custom/plugins/copyzshell"
    
    # 确保子模块已初始化
    if [ -d "third_party/copyzshell" ]; then
        echo "使用项目中的 copyzshell 子模块..."
        git submodule update --init --recursive third_party/copyzshell
        
        # 复制到 oh-my-zsh 插件目录
        if [ ! -d "$copyzshell_dir" ]; then
            mkdir -p "$copyzshell_dir"
        fi
        cp -r third_party/copyzshell/* "$copyzshell_dir/"
        echo "✅ copyzshell 插件已从子模块安装"
    else
        # 回退到直接克隆
        if [ ! -d "$copyzshell_dir" ]; then
            echo "克隆 copyzshell 插件..."
            git clone https://github.com/rutchkiwi/copyzshell.git "$copyzshell_dir"
        else
            echo "copyzshell 插件已存在，更新中..."
            cd "$copyzshell_dir"
            git pull
        fi
    fi
}

# 安装 Clash
install_clash() {
    echo -e "${YELLOW}🌐 安装 Clash...${NC}"
    
    if command -v clash &> /dev/null; then
        echo "Clash 已安装"
        return
    fi
    
    local clash_version="v1.18.0"
    local download_url=""
    
    case $OS in
        "linux")
            case $(uname -m) in
                "x86_64")
                    download_url="https://github.com/Dreamacro/clash/releases/download/${clash_version}/clash-linux-amd64-${clash_version}.gz"
                    ;;
                "aarch64")
                    download_url="https://github.com/Dreamacro/clash/releases/download/${clash_version}/clash-linux-arm64-${clash_version}.gz"
                    ;;
                *)
                    echo -e "${RED}不支持的架构: $(uname -m)${NC}"
                    return 1
                    ;;
            esac
            ;;
        "macos")
            case $(uname -m) in
                "x86_64")
                    download_url="https://github.com/Dreamacro/clash/releases/download/${clash_version}/clash-darwin-amd64-${clash_version}.gz"
                    ;;
                "arm64")
                    download_url="https://github.com/Dreamacro/clash/releases/download/${clash_version}/clash-darwin-arm64-${clash_version}.gz"
                    ;;
                *)
                    echo -e "${RED}不支持的架构: $(uname -m)${NC}"
                    return 1
                    ;;
            esac
            ;;
    esac
    
    # 下载并安装
    echo "下载 Clash..."
    wget -O clash.gz "$download_url"
    gunzip clash.gz
    chmod +x clash
    sudo mv clash /usr/local/bin/
    
    echo -e "${GREEN}✅ Clash 安装完成${NC}"
}

# 同步配置到仓库
sync_configs_to_repo() {
    echo -e "${YELLOW}🔄 同步配置到仓库...${NC}"
    
    # 复制当前配置到仓库
    if [ -f "$HOME/.zshrc" ]; then
        cp "$HOME/.zshrc" "configs/shell/.zshrc"
        echo "✅ 已同步 .zshrc"
    fi
    
    if [ -f "$HOME/.gitconfig" ]; then
        cp "$HOME/.gitconfig" "configs/git/.gitconfig"
        echo "✅ 已同步 .gitconfig"
    fi
    
    if [ -d "$HOME/.config/clash" ]; then
        cp -r "$HOME/.config/clash" "configs/"
        echo "✅ 已同步 Clash 配置"
    fi
    
    if [ -f "$HOME/.tmux.conf" ]; then
        cp "$HOME/.tmux.conf" "configs/tmux/.tmux.conf"
        echo "✅ 已同步 .tmux.conf"
    fi
    
    echo -e "${GREEN}✅ 配置同步完成${NC}"
}

# 创建管理脚本
create_management_scripts() {
    echo -e "${YELLOW}📝 创建管理脚本...${NC}"
    
    # 创建部署脚本
    cat > "scripts/deploy.sh" << 'EOF'
#!/bin/bash
# 使用 copyzshell 部署配置到远程机器

if [ $# -eq 0 ]; then
    echo "用法: $0 <remote-host> [user@host]"
    echo "示例: $0 192.168.1.100"
    echo "示例: $0 user@192.168.1.100"
    exit 1
fi

REMOTE_HOST="$1"

echo "🚀 开始部署配置到 $REMOTE_HOST..."

# 确保 copyzshell 可用
if ! command -v copyzshell &> /dev/null; then
    echo "❌ copyzshell 命令不可用，请先运行 ./install.sh"
    exit 1
fi

# 使用 copyzshell 部署
echo "📦 使用 copyzshell 部署配置..."
copyzshell "$REMOTE_HOST"

echo "✅ 配置部署完成！"
echo "💡 提示：请在新设备上重新登录以激活配置"
EOF
    
    chmod +x "scripts/deploy.sh"
    
    # 创建 Clash 管理脚本
    mkdir -p "scripts/clash"
    
    cat > "scripts/clash/start_clash.sh" << 'EOF'
#!/bin/bash
# 启动 Clash

CLASH_CONFIG_DIR="$HOME/.config/clash"
CLASH_LOG_FILE="$HOME/.config/clash/clash.log"

echo "🚀 启动 Clash..."

# 检查配置文件
if [ ! -f "$CLASH_CONFIG_DIR/config.yaml" ]; then
    echo "❌ Clash 配置文件不存在: $CLASH_CONFIG_DIR/config.yaml"
    exit 1
fi

# 启动 Clash
if command -v systemctl &> /dev/null && systemctl is-active --quiet clash; then
    echo "📡 使用 systemd 启动 Clash..."
    sudo systemctl start clash
    sudo systemctl status clash
else
    echo "📡 直接启动 Clash..."
    nohup clash -d "$CLASH_CONFIG_DIR" > "$CLASH_LOG_FILE" 2>&1 &
    echo "✅ Clash 已启动，PID: $!"
    echo "📋 日志文件: $CLASH_LOG_FILE"
fi

echo "🌐 Clash Web UI: http://clash.razord.top"
echo "🔧 Clash API: http://127.0.0.1:9090"
EOF
    
    chmod +x "scripts/clash/start_clash.sh"
    
    cat > "scripts/clash/stop_clash.sh" << 'EOF'
#!/bin/bash
# 停止 Clash

echo "🛑 停止 Clash..."

# 尝试停止 systemd 服务
if command -v systemctl &> /dev/null && systemctl is-active --quiet clash; then
    echo "📡 停止 systemd 服务..."
    sudo systemctl stop clash
else
    echo "📡 停止 Clash 进程..."
    pkill -f "clash -d" || true
fi

echo "✅ Clash 已停止"
EOF
    
    chmod +x "scripts/clash/stop_clash.sh"
    
    echo -e "${GREEN}✅ 管理脚本创建完成${NC}"
}

# 主函数
main() {
    echo -e "${GREEN}🚀 ybcfg - 环境配置管理工具${NC}"
    echo -e "${BLUE}基于你的实际环境：Powerlevel10k + Clash + copyzshell${NC}"
    echo ""
    
    # 处理命令行参数
    case "${1:-}" in
        "--help"|"-h")
            show_help
            exit 0
            ;;
        "--backup-only")
            detect_os
            backup_existing_configs
            exit 0
            ;;
        "--sync-only")
            sync_configs_to_repo
            exit 0
            ;;
        "--install"|"")
            # 完整安装流程
            detect_os
            backup_existing_configs
            install_dependencies
            install_zsh_and_themes
            install_clash
            sync_configs_to_repo
            create_management_scripts
            
            echo ""
            echo -e "${GREEN}✅ 安装完成！${NC}"
            echo -e "${YELLOW}💡 使用 'copyzshell <remote-host>' 部署配置到其他设备${NC}"
            echo -e "${YELLOW}💡 使用 './scripts/deploy.sh <remote-host>' 进行部署${NC}"
            echo -e "${YELLOW}💡 使用 './scripts/clash/start_clash.sh' 启动 Clash${NC}"
            echo -e "${YELLOW}💡 使用 './install.sh --sync-only' 同步最新配置到仓库${NC}"
            ;;
        *)
            echo -e "${RED}未知选项: $1${NC}"
            show_help
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"
