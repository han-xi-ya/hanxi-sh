#!/bin/bash

# ==================================================
# Docker管理模块 v1.0.0
# ==================================================

# 模块配置
MODULE_NAME="Docker管理"
MODULE_VERSION="1.0.0"
MODULE_DESC="Docker容器和镜像管理"

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

# 主菜单
main() {
    docker_menu
}

# Docker管理菜单
docker_menu() {
    echo_color $GREEN "================================================"
    echo_color $GREEN "                    Docker管理"
    echo_color $GREEN "================================================"
    
    echo_color $BLUE "1. 列出运行中的容器"
    echo_color $BLUE "2. 列出所有容器（包括已停止）"
    echo_color $BLUE "3. 列出镜像"
    echo_color $BLUE "4. 启动容器"
    echo_color $BLUE "5. 停止容器"
    echo_color $BLUE "6. 删除容器"
    echo_color $BLUE "7. 删除镜像"
    echo_color $BLUE "8. 显示Docker信息"
    echo_color $BLUE "9. 退出"
    echo ""
    read -p "请输入选择 (1-9): " choice
    
    case "$choice" in
        1)
            echo_color $GREEN "================================================"
            echo_color $GREEN "                运行中的容器"
            echo_color $GREEN "================================================"
            docker ps
            ;;
        2)
            echo_color $GREEN "================================================"
            echo_color $GREEN "                所有容器"
            echo_color $GREEN "================================================"
            docker ps -a
            ;;
        3)
            echo_color $GREEN "================================================"
            echo_color $GREEN "                    镜像列表"
            echo_color $GREEN "================================================"
            docker images
            ;;
        4)
            read -p "请输入容器名称或ID: " container
            docker start "$container"
            ;;
        5)
            read -p "请输入容器名称或ID: " container
            docker stop "$container"
            ;;
        6)
            read -p "请输入容器名称或ID: " container
            docker rm "$container"
            ;;
        7)
            read -p "请输入镜像名称或ID: " image
            docker rmi "$image"
            ;;
        8)
            echo_color $GREEN "================================================"
            echo_color $GREEN "                    Docker信息"
            echo_color $GREEN "================================================"
            docker info
            ;;
        9)
            echo_color $GREEN "正在退出Docker管理..."
            return
            ;;
        *)
            echo_color $RED "无效选择。请重试。"
            ;;
    esac
    
    echo ""
    docker_menu
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