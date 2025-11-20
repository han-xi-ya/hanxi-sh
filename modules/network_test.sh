#!/bin/bash

# ==================================================
# 网络测试模块 v1.0.0
# ==================================================

# 模块配置
MODULE_NAME="网络测试"
MODULE_VERSION="1.0.0"
MODULE_DESC="网络速度和质量测试工具"

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

run_network_test() {
    echo_color $GREEN "================================================"
    echo_color $GREEN "                    网络测试"
    echo_color $GREEN "================================================"
    
    echo_color $BLUE "Testing Internet Connectivity..."
    if ping -c 1 8.8.8.8 > /dev/null 2>&1; then
        echo_color $GREEN "✓ Internet is connected"
    else
        echo_color $RED "✗ Internet is NOT connected"
        return 1
    fi
    echo ""
    
    echo_color $BLUE "Testing DNS Resolution..."
    if nslookup google.com > /dev/null 2>&1; then
        echo_color $GREEN "✓ DNS resolution is working"
    else
        echo_color $RED "✗ DNS resolution is NOT working"
        return 1
    fi
    echo ""
    
    echo_color $BLUE "Testing Latency to Google DNS..."
    ping -c 3 8.8.8.8
    echo ""
    
    echo_color $BLUE "Testing Latency to Cloudflare DNS..."
    ping -c 3 1.1.1.1
    echo ""
    
    echo_color $GREEN "================================================"
    echo_color $GREEN "              网络测试完成"
    echo_color $GREEN "================================================"
}

# 主函数
main() {
    run_network_test
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