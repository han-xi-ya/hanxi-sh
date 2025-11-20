# 系统管理工具

一个功能强大的交互式系统管理工具，集成了系统信息查询、网络测试和Docker管理等多种功能，帮助用户轻松管理和维护Linux系统。

## 功能特点

- 📊 **系统信息查询** - 显示完整的系统硬件和软件信息
- 🌐 **网络测试** - 测试网络连接、DNS解析和延迟
- 🐳 **Docker管理** - 管理Docker容器和镜像
- 🔄 **自动更新** - 定期检查工具和模块更新
- 🎨 **交互式界面** - 彩色终端界面，易于使用
- ⚙️ **模块化设计** - 支持动态加载和扩展模块
- 📱 **跨平台** - 支持大多数Linux发行版

## 安装方法

### 一键安装

```bash
bash <(curl -sL https://raw.githubusercontent.com/han-xi-ya/hanxi-sh/main/install.sh)
```

### 手动安装

```bash
# 克隆项目（GitHub）
git clone https://github.com/han-xi-ya/hanxi-sh.git

# 克隆项目（Gitee）
git clone https://gitee.com/han-xi-ya/hanxi-sh.git

# 进入项目目录
cd hanxi-sh

# 赋予执行权限
chmod +x hanxi.sh modules/*.sh lib/*.sh

# 运行工具
./hanxi.sh
```

## 使用说明

### 主菜单

运行工具后，将显示主菜单界面：

```
===============================================
          系统管理工具 v1.0.0
===============================================
1. 系统信息查询
   └─ 完整的系统硬件和软件信息
2. 网络测试
   └─ 网络速度和质量测试工具
3. Docker管理
   └─ Docker容器和镜像管理
===============================================
u. 检查更新
U. 强制更新所有模块
c. 清理缓存
0. 退出
===============================================
```

### 操作说明

- 输入数字选择对应模块
- 输入 `u` 检查更新
- 输入 `U` 强制更新所有模块
- 输入 `c` 清理缓存
- 输入 `0` 退出工具

## 模块介绍

### 1. 系统信息查询

显示完整的系统硬件和软件信息，包括：
- 主机名
- 系统版本
- 内核版本
- CPU信息
- 内存使用情况

### 2. 网络测试

测试网络连接和质量，包括：
- 互联网连接测试
- DNS解析测试
- Google DNS延迟测试
- Cloudflare DNS延迟测试

### 3. Docker管理

提供Docker容器和镜像的管理功能：
- 列出运行中的容器
- 列出所有容器（包括已停止）
- 列出镜像
- 启动/停止/删除容器
- 删除镜像
- 显示Docker信息

## 命令行参数

```bash
./hanxi.sh [选项]
```

### 选项

- `--repo-url, -r <URL>` - 指定自定义仓库地址
- `--help, -h` - 显示帮助文档

## 更新机制

系统管理工具具有自动更新功能：

1. 启动时自动检查更新
2. 支持手动检查更新（主菜单 `u` 选项）
3. 支持强制更新所有模块（主菜单 `U` 选项）
4. 可以通过 `--repo-url` 参数指定自定义仓库地址

## 目录结构

```
system_manager/
├── config/          # 配置文件目录
│   ├── version.conf    # 版本配置
│   └── modules.list    # 模块配置
├── lib/             # 库文件目录
│   └── update.sh       # 更新功能实现
├── modules/         # 模块文件目录
│   ├── system_info.sh  # 系统信息模块
│   ├── network_test.sh # 网络测试模块
│   └── docker_manager.sh # Docker管理模块
├── install.sh       # 安装脚本
├── system_manager.sh # 主脚本
└── README.md        # 项目文档
```

## 开发指南

### 模块开发

系统管理工具采用模块化设计，每个模块都是一个独立的Shell脚本，存放在 `modules/` 目录下。

### 模块结构

```bash
#!/bin/bash

# ==================================================
# 模块名称 v版本号
# ==================================================

# 模块配置
MODULE_NAME="模块名称"
MODULE_VERSION="1.0.0"
MODULE_DESC="模块描述"

# 颜色定义
RED='\033[31m'
GREEN='\033[32m'
# ... 其他颜色定义

# 辅助函数
echo_color() {
    echo -e "${1}${2}${RESET}"
}

# 主函数
main() {
    # 模块核心逻辑
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
```

### 添加新模块

1. 创建新的模块脚本文件 `modules/new_module.sh`
2. 按照模块结构编写模块代码
3. 在 `config/modules.list` 中注册新模块

## 许可证

MIT License

## 贡献

欢迎提交Issue和Pull Request！

## 联系方式

- 项目主页: https://github.com/han-xi-ya/hanxi-sh
- 作者: your_username
- 邮箱: your_email@example.com