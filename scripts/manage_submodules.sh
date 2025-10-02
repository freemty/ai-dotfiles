#!/bin/bash
# 子模块管理脚本

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 显示帮助信息
show_help() {
    echo -e "${BLUE}子模块管理脚本${NC}"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  init          初始化所有子模块"
    echo "  update        更新所有子模块"
    echo "  status        显示子模块状态"
    echo "  help, -h      显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 init       # 初始化子模块"
    echo "  $0 update     # 更新子模块"
    echo "  $0 status     # 查看状态"
}

# 初始化子模块
init_submodules() {
    echo -e "${YELLOW}🔧 初始化子模块...${NC}"
    
    git submodule update --init --recursive
    
    echo -e "${GREEN}✅ 子模块初始化完成${NC}"
}

# 更新子模块
update_submodules() {
    echo -e "${YELLOW}🔄 更新子模块...${NC}"
    
    git submodule update --remote --recursive
    
    echo -e "${GREEN}✅ 子模块更新完成${NC}"
}

# 显示子模块状态
show_status() {
    echo -e "${YELLOW}📊 子模块状态:${NC}"
    echo ""
    git submodule status
    echo ""
    echo -e "${YELLOW}📋 子模块列表:${NC}"
    echo "  - copyzshell: ZSH 配置同步工具"
}

# 主函数
main() {
    case "${1:-}" in
        "init")
            init_submodules
            ;;
        "update")
            update_submodules
            ;;
        "status")
            show_status
            ;;
        "help"|"-h"|"")
            show_help
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
