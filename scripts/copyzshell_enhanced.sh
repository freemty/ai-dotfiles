#!/bin/bash
# 增强版 copyzshell 脚本，支持端口号参数

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 显示帮助信息
show_help() {
    echo -e "${GREEN}增强版 copyzshell${NC}"
    echo ""
    echo "用法: $0 [选项] <远程主机>"
    echo ""
    echo "选项:"
    echo "  -p, --port PORT     指定 SSH 端口号"
    echo "  -u, --user USER     指定用户名"
    echo "  -h, --help          显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 user@host"
    echo "  $0 -p 66 user@host"
    echo "  $0 -u ybyang -p 66 10.13.74.23"
    echo "  $0 ybyang@10.13.74.23 -p 66"
}

# 解析命令行参数
parse_arguments() {
    REMOTE_HOST=""
    SSH_PORT=""
    SSH_USER=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--port)
                SSH_PORT="$2"
                shift 2
                ;;
            -u|--user)
                SSH_USER="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -*)
                echo -e "${RED}未知选项: $1${NC}"
                show_help
                exit 1
                ;;
            *)
                if [[ -z "$REMOTE_HOST" ]]; then
                    REMOTE_HOST="$1"
                else
                    echo -e "${RED}错误: 只能指定一个远程主机${NC}"
                    show_help
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    if [[ -z "$REMOTE_HOST" ]]; then
        echo -e "${RED}错误: 必须指定远程主机${NC}"
        show_help
        exit 1
    fi
}

# 构建 SSH 命令
build_ssh_command() {
    local ssh_cmd="ssh"
    
    if [[ -n "$SSH_PORT" ]]; then
        ssh_cmd="$ssh_cmd -p $SSH_PORT"
    fi
    
    if [[ -n "$SSH_USER" ]]; then
        ssh_cmd="$ssh_cmd $SSH_USER@$REMOTE_HOST"
    else
        ssh_cmd="$ssh_cmd $REMOTE_HOST"
    fi
    
    echo "$ssh_cmd"
}

# 构建 SCP 命令
build_scp_command() {
    local scp_cmd="scp"
    
    if [[ -n "$SSH_PORT" ]]; then
        scp_cmd="$scp_cmd -P $SSH_PORT"
    fi
    
    echo "$scp_cmd"
}

# 主函数
main() {
    echo -e "${GREEN}🚀 增强版 copyzshell 开始部署...${NC}"
    
    # 解析参数
    parse_arguments "$@"
    
    # 检查 ZSH 路径
    if [[ -z "$ZSH" ]]; then
        ZSH="$HOME/.oh-my-zsh"
    fi
    
    if [[ ! -d "$ZSH" ]]; then
        echo -e "${RED}错误: Oh My Zsh 未安装，请先运行 ./install.sh${NC}"
        exit 1
    fi
    
    if [[ ! $ZSH =~ ^$HOME/ ]]; then
        echo -e "${RED}错误: ZSH 文件夹 $ZSH 不在用户主目录中${NC}"
        exit 1
    fi
    
    # 构建命令
    local ssh_cmd=$(build_ssh_command)
    local scp_cmd=$(build_scp_command)
    
    echo -e "${YELLOW}使用 SSH 命令: $ssh_cmd${NC}"
    echo -e "${YELLOW}使用 SCP 命令: $scp_cmd${NC}"
    
    # 创建临时目录
    local datestr=$(date "+%Y-%m-%d-%H:%M:%S")
    local zsh_folder=${ZSH#$HOME/}
    local zsh_base=${ZSH##*/}
    local zsh_folder_without_base=./${zsh_folder%$zsh_base}
    local tmp_dir="/tmp/copyshell_$datestr"
    
    echo -e "${YELLOW}准备传输文件...${NC}"
    mkdir "$tmp_dir"
    
    # 复制文件到临时目录
    cp -r "$ZSH" "$tmp_dir/oh-my-zsh"
    cp ~/.zshrc "$tmp_dir/"
    cp ~/.gitconfig "$tmp_dir/"
    
    # 传输文件
    echo -e "${YELLOW}传输文件到远程主机...${NC}"
    if [[ -n "$SSH_USER" ]]; then
        $scp_cmd -r "$tmp_dir" "$SSH_USER@$REMOTE_HOST:$tmp_dir"
    else
        $scp_cmd -r "$tmp_dir" "$REMOTE_HOST:$tmp_dir"
    fi
    
    echo -e "${YELLOW}在远程主机上设置配置...${NC}"
    
    # 远程命令
    local remote_commands="
    cd ~
    
    # 检查现有 zsh 文件夹
    if [ -d $zsh_folder ]; then
        echo '备份现有 zsh 配置...'
        mv $zsh_folder ${zsh_folder}_${datestr}
    fi
    
    # 移动新的 zsh 文件夹
    mkdir -p $zsh_folder_without_base
    mv ${tmp_dir}/oh-my-zsh $zsh_folder
    
    # 备份现有配置文件
    if [ -f .zshrc ]; then 
        mv .zshrc .zshrc_${datestr}
        echo '已备份现有 .zshrc'
    fi
    if [ -f .gitconfig ]; then 
        mv .gitconfig .gitconfig_${datestr}
        echo '已备份现有 .gitconfig'
    fi
    
    # 移动新配置文件
    mv ${tmp_dir}/.zshrc .zshrc
    mv ${tmp_dir}/.gitconfig .gitconfig
    
    # 清理临时文件
    rm -rf $tmp_dir
    
    # 检查 zsh 是否安装
    if command -v zsh >/dev/null 2>&1; then
        echo '设置 zsh 为默认 shell...'
        chsh -s \$(which zsh)
        echo '配置部署完成！请重新登录以激活配置。'
    else
        echo '警告: zsh 未安装，请先安装 zsh'
    fi
    "
    
    # 执行远程命令
    $ssh_cmd "echo '$remote_commands' | sh"
    
    # 清理本地临时文件
    rm -rf "$tmp_dir"
    
    echo -e "${GREEN}✅ 配置部署完成！${NC}"
    echo -e "${YELLOW}💡 请在新设备上重新登录以激活配置${NC}"
}

# 运行主函数
main "$@"
