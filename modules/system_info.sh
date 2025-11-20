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
WHITE='\033[37m'
BOLD='\033[1m'
RESET='\033[0m'

echo_color() {
    echo -e "${1}${2}${RESET}"
}

check_command() {
    command -v $1 >/dev/null 2>&1
}

# 系统信息查询功能
system_info_query() {
    # 获取公网IP和内网IP
    ip_address() {
        ipv4_address=$(curl -s4 --connect-timeout 2 ip.sb 2>/dev/null || curl -s4 --connect-timeout 2 icanhazip.com 2>/dev/null || echo "无法获取")
        ipv6_address=$(curl -s6 --connect-timeout 2 ip.sb 2>/dev/null || curl -s6 --connect-timeout 2 icanhazip.com 2>/dev/null || echo "无法获取")
        local_ipv4=$(ip addr | grep -E 'inet (192\.168|10\.|172\.)' | grep -v 127.0.0.1 | head -n1 | awk '{print $2}' | cut -d'/' -f1)
        local_ipv6=$(ip addr | grep inet6 | grep -v ::1/128 | head -n1 | awk '{print $2}' | cut -d'/' -f1)
    }

    # 获取运营商信息
    get_isp_info() {
        if [ "$ipv4_address" != "无法获取" ]; then
            isp_info=$(curl -s --connect-timeout 2 "http://ip-api.com/json/$ipv4_address?fields=isp,org" | \
                python3 -c "import json,sys; data=json.load(sys.stdin); print(data.get('isp', '未知'), data.get('org', ''))" 2>/dev/null || \
                echo "未知运营商")
        else
            isp_info="未知运营商"
        fi
    }

    # 获取地理位置
    get_geo_info() {
        if [ "$ipv4_address" != "无法获取" ]; then
            geo_info=$(curl -s --connect-timeout 2 "http://ip-api.com/json/$ipv4_address?fields=country,regionName,city" | \
                python3 -c "import json,sys; data=json.load(sys.stdin); print(f\"{data.get('country', '')} {data.get('regionName', '')} {data.get('city', '')}\")" 2>/dev/null || \
                echo "未知位置")
        else
            geo_info="未知位置"
        fi
    }

    # 获取网络算法
    get_network_algorithms() {
        congestion_algorithm=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo "未知")
        queue_algorithm=$(sysctl -n net.core.default_qdisc 2>/dev/null || echo "未知")
    }

    # 获取CPU信息
    get_cpu_info() {
        cpu_info=$(lscpu | awk -F': +' '/Model name:/ {print $2; exit}')
        cpu_cores=$(nproc)
        cpu_freq=$(cat /proc/cpuinfo | grep "MHz" | head -n1 | awk '{printf "%.2f GHz\n", $4/1000}')
        cpu_usage=$(awk '{u=$2+$4; t=$2+$4+$5; if (NR==1){u1=u; t1=t;} else printf "%.0f\n", (($2+$4-u1) * 100 / (t-t1))}' \
            <(grep 'cpu ' /proc/stat) <(sleep 0.5; grep 'cpu ' /proc/stat))
    }

    # 获取内存信息
    get_memory_info() {
        mem_total=$(free -h | awk 'NR==2{print $2}')
        mem_used=$(free -h | awk 'NR==2{print $3}')
        mem_percent=$(free | awk 'NR==2{printf "%.1f%%", $3 * 100/$2}')
        swap_total=$(free -h | awk 'NR==3{print $2}')
        swap_used=$(free -h | awk 'NR==3{print $3}')
        swap_percent=$(free | awk 'NR==3{printf "%.1f%%", $3 * 100/$2}')
    }

    # 获取磁盘信息
    get_disk_info() {
        disk_info=$(df -h | awk '$NF=="/"{printf "%s/%s (%s)", $3, $2, $5}')
    }

    # 获取系统运行时间
    get_uptime() {
        uptime_seconds=$(awk '{print int($1)}' /proc/uptime)
        days=$((uptime_seconds / 86400))
        hours=$(( (uptime_seconds % 86400) / 3600 ))
        minutes=$(( (uptime_seconds % 3600) / 60 ))
        if [ $days -gt 0 ]; then
            uptime="${days}天 ${hours}时 ${minutes}分"
        else
            uptime="${hours}时 ${minutes}分"
        fi
    }

    # 获取系统负载
    get_load_avg() {
        load=$(uptime | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//')
    }

    # 获取网络接口信息
    get_network_interfaces() {
        interfaces=$(ip link show | grep -E '^[0-9]+:' | awk -F': ' '{print $2}' | grep -v lo)
        interface_info=""
        for iface in $interfaces; do
            ipv4=$(ip addr show $iface | grep -E 'inet (192\.168|10\.|172\.)' | awk '{print $2}' | head -n1)
            ipv6=$(ip addr show $iface | grep inet6 | grep -v ::1/128 | awk '{print $2}' | head -n1)
            mac=$(ip link show $iface | grep -oE 'link/ether [0-9a-f:]+' | awk '{print $2}')
            if [ -n "$ipv4" ] || [ -n "$ipv6" ]; then
                interface_info+="\n${CYAN}$iface${RESET}"
                [ -n "$mac" ] && interface_info+=" MAC: $mac"
                [ -n "$ipv4" ] && interface_info+=" IPv4: $ipv4"
                [ -n "$ipv6" ] && interface_info+=" IPv6: $ipv6"
            fi
        done
    }

    # 获取DNS信息
    get_dns_info() {
        dns_servers=$(grep -E '^nameserver' /etc/resolv.conf 2>/dev/null | awk '{print $2}' | tr '\n' ' ' || echo "未设置")
    }

    # 获取连接统计
    get_connection_stats() {
        tcp_count=$(ss -t | wc -l)
        udp_count=$(ss -u | wc -l)
    }

    # 获取流量统计
    get_traffic_stats() {
        interface=$(ip route | grep default | awk '{print $5}' | head -n1)
        if [ -z "$interface" ]; then
            rx="N/A"
            tx="N/A"
            return
        fi
        rx_bytes=$(cat /sys/class/net/$interface/statistics/rx_bytes 2>/dev/null)
        tx_bytes=$(cat /sys/class/net/$interface/statistics/tx_bytes 2>/dev/null)
        if [ -z "$rx_bytes" ] || [ -z "$tx_bytes" ]; then
            rx="N/A"
            tx="N/A"
            return
        fi
        rx=$(awk -v bytes="$rx_bytes" 'BEGIN {
            if (bytes > 1024^3) printf "%.2fG", bytes/1024^3
            else if (bytes > 1024^2) printf "%.2fM", bytes/1024^2
            else if (bytes > 1024) printf "%.2fK", bytes/1024
            else printf "%dB", bytes
        }')
        tx=$(awk -v bytes="$tx_bytes" 'BEGIN {
            if (bytes > 1024^3) printf "%.2fG", bytes/1024^3
            else if (bytes > 1024^2) printf "%.2fM", bytes/1024^2
            else if (bytes > 1024) printf "%.2fK", bytes/1024
            else printf "%dB", bytes
        }')
    }

    # 获取进程统计信息
    get_process_stats() {
        total_processes=$(ps -e | wc -l)
        running_processes=$(ps -e -o stat | grep -c 'R')
        sleeping_processes=$(ps -e -o stat | grep -c 'S')
        stopped_processes=$(ps -e -o stat | grep -c 'T')
        zombie_processes=$(ps -e -o stat | grep -c 'Z')
        total_threads=$(ps -eL | wc -l)
        top_cpu_process=$(ps -eo pid,comm,%cpu --sort=-%cpu | head -n 2 | tail -n 1 | awk '{printf "PID:%s %s CPU:%s%%", $1, $2, $3}')
        top_mem_process=$(ps -eo pid,comm,%mem --sort=-%mem | head -n 2 | tail -n 1 | awk '{printf "PID:%s %s MEM:%s%%", $1, $2, $3}')
    }

    # 获取安全状态信息
    get_security_status() {
        logged_in_users=$(who | wc -l)
        current_user=$(whoami)
        sudo_privilege=$(sudo -n true 2>/dev/null && echo "有权限" || echo "无权限")
        root_perms=$(stat -c "%a" / 2>/dev/null || echo "N/A")
        etc_perms=$(stat -c "%a" /etc/ 2>/dev/null || echo "N/A")
        home_perms=$(stat -c "%a" /home/ 2>/dev/null || echo "N/A")
        ssh_status=$(systemctl is-active ssh 2>/dev/null || echo "未安装")
        if [ "$ssh_status" = "active" ]; then
            ssh_status="${GREEN}运行中${RESET}"
        elif [ "$ssh_status" = "inactive" ]; then
            ssh_status="${YELLOW}已停止${RESET}"
        else
            ssh_status="${RED}未安装${RESET}"
        fi
        if check_command ufw; then
            ufw_status=$(ufw status | grep Status | awk '{print $2}')
            if [ "$ufw_status" = "active" ]; then
                ufw_status="${GREEN}已启用${RESET}"
            else
                ufw_status="${YELLOW}已禁用${RESET}"
            fi
        else
            ufw_status="${RED}未安装${RESET}"
        fi
    }

    # 主信息显示函数
    display_system_info() {
        # 获取所有信息
        ip_address
        get_isp_info
        get_geo_info
        get_network_algorithms
        get_cpu_info
        get_memory_info
        get_disk_info
        get_uptime
        get_load_avg
        get_network_interfaces
        get_dns_info
        get_connection_stats
        get_traffic_stats
        get_process_stats
        get_security_status

        # 基础信息
        hostname=$(hostname)
        os_info=$(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"' 2>/dev/null || uname -s)
        kernel_version=$(uname -r)
        timezone=$(date +%Z)
        current_time=$(date '+%Y-%m-%d %H:%M:%S')

        # 清屏并显示
        clear
        
        echo_color $GREEN "================================================"
        echo_color $GREEN "               完整的系统信息查询"
        echo_color $GREEN "================================================"
        
        # 基础系统信息
        echo_color $BLUE "主机名: $hostname"
        echo_color $BLUE "系统版本: $os_info"
        echo_color $BLUE "内核版本: $kernel_version"
        echo_color $BLUE "系统时区: $timezone"
        echo_color $BLUE "当前时间: $current_time"
        echo_color $GREEN "================================================"
        
        # CPU信息
        echo_color $YELLOW "CPU型号: $cpu_info"
        echo_color $YELLOW "CPU核心: $cpu_cores 核心"
        echo_color $YELLOW "CPU频率: $cpu_freq"
        echo_color $YELLOW "CPU占用: ${cpu_usage}%"
        echo_color $YELLOW "系统负载: $load"
        echo_color $GREEN "================================================"
        
        # 内存信息
        echo_color $PURPLE "物理内存: $mem_used/$mem_total ($mem_percent)"
        echo_color $PURPLE "虚拟内存: $swap_used/$swap_total ($swap_percent)"
        echo_color $GREEN "================================================"
        
        # 磁盘信息
        echo_color $CYAN "硬盘占用: $disk_info"
        echo_color $GREEN "================================================"
        
        # 进程信息
        echo_color $WHITE "============== 进程信息 =============="
        echo_color $CYAN "总进程数: $total_processes (线程: $total_threads)"
        echo_color $CYAN "运行中: $running_processes, 睡眠中: $sleeping_processes"
        echo_color $CYAN "已停止: $stopped_processes, 僵尸进程: $zombie_processes"
        echo_color $CYAN "最高CPU进程: $top_cpu_process"
        echo_color $CYAN "最高内存进程: $top_mem_process"
        echo_color $GREEN "================================================"
        
        # 安全状态
        echo_color $WHITE "============== 安全状态 =============="
        echo_color $PURPLE "登录用户数: $logged_in_users"
        echo_color $PURPLE "当前用户: $current_user (sudo: $sudo_privilege)"
        echo_color $PURPLE "SSH服务状态: $ssh_status"
        echo_color $PURPLE "防火墙状态: $ufw_status"
        echo_color $PURPLE "关键目录权限: /($root_perms) /etc($etc_perms) /home($home_perms)"
        echo_color $GREEN "================================================"
        
        # 网络算法
        echo_color $WHITE "网络算法: $congestion_algorithm $queue_algorithm"
        echo_color $GREEN "================================================"
        
        # 连接统计
        echo_color $YELLOW "TCP/UDP连接数: $tcp_count/$udp_count"
        echo_color $GREEN "================================================"
        
        # 流量统计
        echo_color $CYAN "总接收流量: $rx"
        echo_color $CYAN "总发送流量: $tx"
        echo_color $GREEN "================================================"
        
        # IP地址信息
        if [ "$ipv4_address" != "无法获取" ]; then
            echo_color $BLUE "公网IPv4: $ipv4_address"
        fi
        
        if [ "$ipv6_address" != "无法获取" ]; then
            echo_color $BLUE "公网IPv6: $ipv6_address"
        fi
        
        if [ -n "$local_ipv4" ]; then
            echo_color $BLUE "内网IPv4: $local_ipv4"
        fi
        
        if [ -n "$local_ipv6" ]; then
            echo_color $BLUE "内网IPv6: $local_ipv6"
        fi
        
        echo_color $BLUE "DNS服务器: $dns_servers"
        echo_color $BLUE "运营商: $isp_info"
        echo_color $BLUE "地理位置: $geo_info"
        echo_color $GREEN "================================================"
        
        # 网络接口信息
        if [ -n "$interface_info" ]; then
            echo_color $CYAN "网络接口信息:"
            echo -e "$interface_info"
            echo_color $GREEN "================================================"
        fi
        
        # 运行时间
        echo_color $PURPLE "系统运行时间: $uptime"
        echo_color $GREEN "================================================"
    }

    # 执行信息查询
    display_system_info
}

# 主函数
main() {
    # 检查root权限
    if [ "$(id -u)" -ne 0 ]; then
        echo_color $YELLOW "提示: 部分功能可能需要root权限才能正常运行"
        sleep 1
    fi
    
    # 检查必要工具
    if ! check_command curl; then
        echo_color $RED "错误: 需要安装curl工具"
        echo "请运行: apt install curl 或 yum install curl"
        exit 1
    fi
    
    if ! check_command python3; then
        echo_color $YELLOW "警告: 未安装python3，部分功能可能受限"
        sleep 1
    fi
    
    # 执行系统信息查询
    system_info_query
    
    # 等待用户按键返回
    echo ""
    read -e -p "按任意键返回主菜单..." -n 1
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