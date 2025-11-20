#!/bin/bash

# ==================================================
# 更新功能库
# ==================================================

# 下载源支持: GitHub, Custom, Gitee
# 如果REPO_BASE_URL未从配置文件或命令行设置，则使用默认源
download_source="${download_source:-github}"

# 只有在REPO_BASE_URL未设置时才根据下载源设置默认值
if [ -z "$REPO_BASE_URL" ]; then
    case "$download_source" in
        github)
            REPO_BASE_URL="https://raw.githubusercontent.com/your-username/your-repo/main"
            ;;
        custom)
            REPO_BASE_URL="https://your.custom.domain/your-repo"
            ;;
        gitee)
            REPO_BASE_URL="https://gitee.com/your-username/your-repo/raw/main"
            ;;
        *)
            echo_color $RED "不支持的下载源: $download_source"
            exit 1
            ;;
    esac
fi

# 远程配置URL
REMOTE_VERSION_URL="$REPO_BASE_URL/config/version.conf"
REMOTE_MODULES_URL="$REPO_BASE_URL/config/modules.list"
REMOTE_MODULES_DIR="$REPO_BASE_URL/modules"

# 检查更新
check_updates() {
    echo_color $BLUE "正在检查更新..."
    
    # 获取远程版本信息
    local remote_version=$(curl -s "$REMOTE_VERSION_URL" | grep "TOOL_VERSION" | cut -d'=' -f2 | tr -d '"')
    local remote_config_version=$(curl -s "$REMOTE_VERSION_URL" | grep "CONFIG_VERSION" | cut -d'=' -f2 | tr -d '"')
    
    if [ -z "$remote_version" ]; then
        echo_color $RED "无法获取远程版本信息"
        return 1
    fi
    
    # 比较版本
    if [ "$TOOL_VERSION" != "$remote_version" ]; then
        echo_color $YELLOW "发现新版本: $remote_version (当前: $TOOL_VERSION)"
        read -e -p "是否更新? (y/N): " choice
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            update_tool
        fi
    else
        echo_color $GREEN "当前已是最新版本"
    fi
    
    # 检查模块更新
    check_module_updates
}

# 检查模块更新
check_module_updates() {
    echo_color $BLUE "检查模块更新..."
    
    # 获取远程模块列表
    local remote_modules_list=$(curl -s "$REMOTE_MODULES_URL")
    if [ -z "$remote_modules_list" ]; then
        echo_color $RED "无法获取远程模块列表"
        return 1
    fi
    
    # 解析远程模块列表
    declare -a remote_modules
    while IFS= read -r line; do
        [[ "$line" =~ ^# ]] || [[ -z "$line" ]] && continue
        remote_modules+=("$line")
    done <<< "$remote_modules_list"
    
    local update_available=false
    
    # 检查每个模块的更新
    for remote_module in "${remote_modules[@]}"; do
        IFS=':' read -r remote_file remote_name remote_desc remote_version <<< "$remote_module"
        
        # 查找本地对应模块
        for local_module in "${MODULES[@]}"; do
            IFS=':' read -r local_file local_name local_desc local_ver <<< "$local_module"
            
            if [ "$local_file" == "$remote_file" ]; then
                if [ "$local_ver" != "$remote_version" ]; then
                    echo_color $YELLOW "模块更新可用: $local_name ($local_ver -> $remote_version)"
                    update_available=true
                fi
                break
            fi
        done
    done
    
    if $update_available; then
        read -e -p "是否更新所有模块? (y/N): " choice
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            update_all_modules
        fi
    else
        echo_color $GREEN "所有模块都是最新版本"
    fi
}

# 更新主工具
update_tool() {
    echo_color $BLUE "开始更新主工具..."
    
    # 备份当前版本
    cp "$SCRIPT_DIR/hanxi.sh" "$SCRIPT_DIR/hanxi.sh.bak"
    
    # 下载新版本
    if curl -s "$REPO_BASE_URL/hanxi.sh" -o "$SCRIPT_DIR/hanxi.sh.new"; then
        # 验证新版本
        if head -n 10 "$SCRIPT_DIR/hanxi.sh.new" | grep -q "hanxi"; then
            mv "$SCRIPT_DIR/hanxi.sh.new" "$SCRIPT_DIR/hanxi.sh"
            chmod +x "$SCRIPT_DIR/hanxi.sh"
            
            # 更新版本配置
            curl -s "$REMOTE_VERSION_URL" -o "$CONFIG_DIR/version.conf"
            
            echo_color $GREEN "更新成功! 请重新启动脚本"
            exit 0
        else
            echo_color $RED "下载的文件无效，恢复备份"
            mv "$SCRIPT_DIR/hanxi.sh.bak" "$SCRIPT_DIR/hanxi.sh"
            rm -f "$SCRIPT_DIR/hanxi.sh.new"
        fi
    else
        echo_color $RED "下载失败"
        rm -f "$SCRIPT_DIR/hanxi.sh.bak" "$SCRIPT_DIR/hanxi.sh.new"
    fi
}

# 更新所有模块
update_all_modules() {
    echo_color $BLUE "开始更新所有模块..."
    
    # 获取远程模块列表
    local remote_modules_list=$(curl -s "$REMOTE_MODULES_URL")
    declare -a remote_modules
    while IFS= read -r line; do
        [[ "$line" =~ ^# ]] || [[ -z "$line" ]] && continue
        remote_modules+=("$line")
    done <<< "$remote_modules_list"
    
    # 更新配置文件
    echo "# 模块配置文件" > "$CONFIG_DIR/modules.list"
    echo "# 格式: 模块文件名:显示名称:描述:版本号" >> "$CONFIG_DIR/modules.list"
    echo >> "$CONFIG_DIR/modules.list"
    echo "declare -a MODULES=(" >> "$CONFIG_DIR/modules.list"
    for module in "${remote_modules[@]}"; do
        echo "    \"$module\"" >> "$CONFIG_DIR/modules.list"
    done
    echo ")" >> "$CONFIG_DIR/modules.list"
    
    # 重新加载配置
    source "$CONFIG_DIR/modules.list"
    
    # 下载所有模块
    for module in "${remote_modules[@]}"; do
        IFS=':' read -r module_file module_name module_desc module_version <<< "$module"
        download_module "$module_file"
    done
    
    echo_color $GREEN "所有模块更新完成!"
}

# 强制更新所有模块
force_update_all() {
    echo_color $YELLOW "强制更新所有模块..."
    update_all_modules
}

# 下载单个模块
download_module() {
    local module_file="$1"
    local module_url="$REMOTE_MODULES_DIR/$module_file"
    
    echo_color $BLUE "下载模块: $module_file"
    
    # 备份现有模块
    if [ -f "$MODULES_DIR/$module_file" ]; then
        cp "$MODULES_DIR/$module_file" "$MODULES_DIR/$module_file.bak"
    fi
    
    # 下载新模块
    if curl -s "$module_url" -o "$MODULES_DIR/$module_file.tmp"; then
        # 验证模块文件
        if head -n 3 "$MODULES_DIR/$module_file.tmp" | grep -q "#!/bin/bash"; then
            mv "$MODULES_DIR/$module_file.tmp" "$MODULES_DIR/$module_file"
            chmod +x "$MODULES_DIR/$module_file"
            rm -f "$MODULES_DIR/$module_file.bak"
            echo_color $GREEN "模块更新成功: $module_file"
        else
            echo_color $RED "下载的模块文件无效: $module_file"
            # 恢复备份
            if [ -f "$MODULES_DIR/$module_file.bak" ]; then
                mv "$MODULES_DIR/$module_file.bak" "$MODULES_DIR/$module_file"
            fi
            rm -f "$MODULES_DIR/$module_file.tmp"
        fi
    else
        echo_color $RED "下载失败: $module_file"
        rm -f "$MODULES_DIR/$module_file.tmp"
    fi
}

# 验证模块完整性
validate_modules() {
    echo_color $BLUE "验证模块完整性..."
    
    local valid=true
    
    for module in "${MODULES[@]}"; do
        IFS=':' read -r module_file module_name module_desc module_version <<< "$module"
        
        if [ ! -f "$MODULES_DIR/$module_file" ]; then
            echo_color $RED "模块缺失: $module_file"
            valid=false
        elif ! head -n 3 "$MODULES_DIR/$module_file" | grep -q "#!/bin/bash"; then
            echo_color $RED "模块损坏: $module_file"
            valid=false
        fi
    done
    
    if ! $valid; then
        echo_color $YELLOW "尝试修复损坏的模块..."
        for module in "${MODULES[@]}"; do
            IFS=':' read -r module_file module_name module_desc module_version <<< "$module"
            if [ ! -f "$MODULES_DIR/$module_file" ] || \
               ! head -n 3 "$MODULES_DIR/$module_file" | grep -q "#!/bin/bash"; then
                download_module "$module_file"
            fi
        done
    fi
}