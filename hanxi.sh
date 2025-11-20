#!/bin/bash

# ==================================================
# 系统管理工具 - 主入口脚本
# ==================================================

# 颜色定义
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
PURPLE='\033[35m'
CYAN='\033[36m'
WHITE='\033[37m'
BOLD='\033[1m'
RESET='\033[0m'

# 路径配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/config"
MODULES_DIR="$SCRIPT_DIR/modules"
LIB_DIR="$SCRIPT_DIR/lib"

# 加载配置文件
source "$CONFIG_DIR/version.conf"
source "$CONFIG_DIR/modules.list"

# 处理命令行参数函数
process_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --repo-url|-r)
                REPO_BASE_URL="$2"
                shift 2
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                echo_color $RED "未知参数: $1"
                echo_color $YELLOW "使用 --help 获取帮助"
                exit 1
                ;;
        esac
    done
}

# 处理命令行参数
process_args "$@"

# 加载库函数
source "$LIB_DIR/update.sh"

# 辅助函数
echo_color() {
    echo -e "${1}${2}${RESET}"
}

check_command() {
    command -v "$1" >/dev/null 2>&1
}

ensure_directories() {
    mkdir -p "$CONFIG_DIR" "$MODULES_DIR" "$LIB_DIR"
}

# 模块加载系统
load_module() {
    local module_name="$1"
    local module_path="$MODULES_DIR/$module_name"
    
    if [ ! -f "$module_path" ]; then
        echo_color $RED "错误: 模块 $module_name 不存在"
        return 1
    fi
    
    if ! source "$module_path"; then
        echo_color $RED "错误: 模块 $module_name 加载失败"
        return 1
    fi
    
    return 0
}

# 显示主菜单
show_main_menu() {
    clear
    echo_color $GREEN "================================================"
    echo_color $GREEN "          系统管理工具 v$TOOL_VERSION"
    echo_color $GREEN "================================================"
    
    local i=1
    for module in "${MODULES[@]}"; do
        # 跳过配置行和空行
        if [[ "$module" =~ ^MODULES=\($ ]] || [[ "$module" =~ ^\)$ ]] || [[ -z "$module" ]]; then
            continue
        fi
        
        # 正确解析模块配置：模块文件名:显示名称:描述:版本号
        IFS=':' read -r module_file module_name module_desc module_version <<< "$module"
        echo_color $BLUE "$i. $module_name"
        echo_color $CYAN "   └─ $module_desc"
        ((i++))
    done
    
    # 添加系统功能选项
    echo_color $BLUE "$i. 显示帮助文档"
    echo_color $CYAN "   └─ 查看工具的帮助信息"
    ((i++))
    
    echo_color $BLUE "$i. 检查更新"
    echo_color $CYAN "   └─ 检查工具和模块的更新"
    ((i++))
    
    echo_color $BLUE "$i. 强制更新所有模块"
    echo_color $CYAN "   └─ 强制更新所有模块"
    ((i++))
    
    echo_color $BLUE "$i. 清理缓存"
    echo_color $CYAN "   └─ 清理工具缓存"
    
    echo_color $GREEN "================================================"
    echo_color $YELLOW "0. 退出"
    echo_color $GREEN "================================================"
}

# 执行模块
execute_module() {
    local index="$1"
    local module="${MODULES[$index]}"
    IFS=':' read -r module_file module_name module_desc <<< "$module"
    
    if load_module "$module_file"; then
        # 调用模块的主函数（约定每个模块都有 main 函数）
        if declare -f main > /dev/null; then
            main
        else
            echo_color $RED "错误: 模块 $module_name 没有 main 函数"
        fi
    fi
}

# 清理函数
cleanup() {
    echo_color $GREEN "清理完成"
    # 重新加载模块配置
    source "$CONFIG_DIR/modules.list"
}

# 显示帮助文档
show_help() {
    clear
    echo_color $BLUE "=== 系统管理工具帮助文档 ==="
    echo_color $WHITE "版本: $TOOL_VERSION"
    echo_color $WHITE "更新: $(date -d @$LAST_UPDATE_CHECK)"
    echo ""
    echo_color $CYAN "【功能介绍】"
    echo "系统管理工具是一个集系统监控、网络测试、服务管理于一体的综合管理工具。"
    echo "支持命令行参数快速执行功能，也可通过菜单交互模式使用。"
    echo ""
    echo_color $CYAN "【使用方法】"
    echo "1. 菜单模式: ./hanxi.sh"
    echo "2. 命令模式: ./hanxi.sh [参数]"
    echo ""
    echo_color $CYAN "【命令行选项】"
    echo "-h, --help        显示帮助文档"
    echo "--info            显示模块信息"
    echo "--version         显示工具版本"
    echo "--repo-url|-r     指定远程仓库URL（用于安装和更新）"
    echo ""
    echo_color $CYAN "【主菜单操作】"
    echo "1. 系统信息查询"
    echo "2. 网络测试"
    echo "3. Docker管理"
    echo "4. 工具更新"
    echo "5. 退出"
    echo ""
    echo_color $CYAN "【模块说明】"
    local idx=1
    for module in "${MODULES[@]}"; do
        IFS=':' read -r module_file module_name module_desc module_version <<< "$module"
        echo "$idx. $module_name ($module_version) - $module_desc"
        ((idx++))
    done
    echo ""
    echo_color $CYAN "【更新机制】"
    echo "工具支持自动检查更新功能，默认每周一00:00执行。"
    echo "您也可以通过菜单选项或直接运行 './hanxi.sh --update' 手动检查更新。"
    echo "支持的下载源: GitHub、自定义域名、Gitee"
    echo ""
}

# 主循环
main() {
    ensure_directories
    
    while true; do
        show_main_menu
        
        read -e -p "请输入选择: " choice
        
        case "$choice" in
            [1-9]*)
                local module_count=${#MODULES[@]}
                local total_options=$((module_count + 4))  # 模块数 + 4个系统选项
                
                if [ "$choice" -ge 1 ] && [ "$choice" -le "$module_count" ]; then
                    execute_module $((choice-1))
                elif [ "$choice" -eq $((module_count + 1)) ]; then
                    show_help
                elif [ "$choice" -eq $((module_count + 2)) ]; then
                    check_updates
                elif [ "$choice" -eq $((module_count + 3)) ]; then
                    force_update_all
                elif [ "$choice" -eq $((module_count + 4)) ]; then
                    cleanup
                else
                    echo_color $RED "无效的选择! 请输入 0-$total_options 之间的数字"
                    sleep 1
                    continue
                fi
                echo -n "按任意键返回主菜单..."
                read -n 1 -s -r
                echo
                ;;
            0)
                echo_color $GREEN "感谢使用，再见！"
                exit 0
                ;;
            *)
                echo_color $RED "无效的选择! 请输入数字"
                sleep 1
                ;;
        esac
    done
}

# 启动脚本
trap cleanup EXIT
main