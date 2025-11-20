#!/bin/bash

# 系统管理工具安装脚本

# 提示用户选择下载源
echo "选择下载源:"
echo "1) 自定义域名"
echo "2) GitHub"
echo "3) Gitee"
read -p "输入选项 (1-3): " source_choice

# 设置基础URL
case $source_choice in
    1)
        read -p "请输入自定义域名 (例如: https://your-domain.com/hanxi-sh): " BASE_URL
        ;;
    2)
        BASE_URL="https://raw.githubusercontent.com/han-xi-ya/hanxi-sh/main"
        ;;
    3)
        BASE_URL="https://gitee.com/han-xi-ya/hanxi-sh/raw/main"
        ;;
    *)
        echo "无效选项，默认使用Gitee"
        BASE_URL="https://gitee.com/han-xi-ya/hanxi-sh/raw/main"
        ;;
esac

echo "正在安装系统管理工具... (源: $BASE_URL)"
mkdir -p hanxi-sh
cd hanxi-sh

# 创建目录结构
mkdir -p config modules lib

# 下载主脚本
echo "下载主脚本..."
curl -sL "$BASE_URL/hanxi.sh" -o hanxi.sh
chmod +x hanxi.sh

# 下载配置文件
echo "下载配置文件..."
curl -sL "$BASE_URL/config/version.conf" -o config/version.conf
curl -sL "$BASE_URL/config/modules.list" -o config/modules.list

# 下载库文件
echo "下载库文件..."
curl -sL "$BASE_URL/lib/update.sh" -o lib/update.sh

# 下载模块文件
echo "下载模块文件..."
curl -sL "$BASE_URL/modules/system_info.sh" -o modules/system_info.sh
curl -sL "$BASE_URL/modules/network_test.sh" -o modules/network_test.sh
curl -sL "$BASE_URL/modules/docker_manager.sh" -o modules/docker_manager.sh

# 设置执行权限
chmod +x modules/*.sh
chmod +x lib/*.sh

# 修改配置文件中的远程仓库URL
sed -i "s|REPO_BASE_URL=\"https://raw.githubusercontent.com/han-xi-ya/hanxi-sh/main\"|REPO_BASE_URL=\"$BASE_URL\"|" config/version.conf

echo "安装完成!"
echo "运行方式: ./hanxi-sh/hanxi.sh"