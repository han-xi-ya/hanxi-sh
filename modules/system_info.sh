#!/bin/bash

# ==================================================
# 系统信息查询模块 v1.0.0
# ==================================================

# 模块配置
MODULE_NAME="系统信息查询"
MODULE_VERSION="1.0.0"
MODULE_DESC="完整的系统硬件和软件信息查询"

# 颜色定义
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
PURPLE='\033[35m'
CYAN='\033[36m'
RESET='\033[0m'

echo_color() {
    echo -e "${1}${2}${RESET}"
}

# 主函数
main() {
    echo_color $GREEN "================================================"
    echo_color $GREEN "               系统信息查询"
    echo_color $GREEN "================================================"
    
    # 获取系统信息
    echo_color $BLUE "主机名: $(hostname)"
    echo_color $BLUE "系统版本: $(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')"
    echo_color $BLUE "内核版本: $(uname -r)"
    echo_color $BLUE "CPU信息: $(lscpu | grep 'Model name' | cut -d: -f2 | sed 's/^ *//')"
    echo_color $BLUE "内存使用: $(free -h | awk '/Mem:/ {print $3 \"/\" $2}')"
    
    echo_color $GREEN "================================================"
}

# 模块信息函数
module_info() {
    echo "名称: $MODULE_NAME"
    echo "版本: $MODULE_VERSION"
    echo "描述: $MODULE_DESC"
}

# 根据参数执行不同操作
case "${1:-}" in
    "--info")
        module_info
        ;;
    "--version")
        echo "$MODULE_VERSION"
        ;;
    *)
        main
        ;;
esac