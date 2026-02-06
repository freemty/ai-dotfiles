# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

**ai-dotfiles** 是一个轻量级的配置同步工具，专注于 **AI CLI 和 shell 配置的跨设备同步**。核心理念是将 AI 工具（Claude Code、Codex、Gemini）和开发工具的配置集中管理，实现一键同步和部署，同时自动处理敏感信息的脱敏和恢复。

### 核心特色

1. **AI CLI 优先** - 原生支持 Claude Code、Codex、Gemini 配置
2. **智能脱敏** - 自动识别并保护 API keys、tokens、passwords
3. **一键部署** - SSH 远程部署，支持交互式密钥输入
4. **安全可靠** - 双份存储（完整版 + 脱敏版），自动备份

## 前置依赖

在使用本工具前，请确保以下软件已安装：

**必需**：
- `git` - 版本控制
- `zsh` - Shell 环境
- `python3` - 用于敏感信息脱敏
- `rsync` - 文件同步（可选，但强烈推荐）

**安装示例**：
```bash
# macOS
brew install git zsh python3 rsync

# Ubuntu/Debian
sudo apt-get update && sudo apt-get install -y git zsh python3 rsync

# CentOS/RHEL
sudo yum install -y git zsh python3 rsync

# Arch Linux
sudo pacman -Sy git zsh python3 rsync
```

## 常用命令

### 配置管理
```bash
# 同步本地配置到仓库（会自动脱敏敏感信息）
./scripts/sync.sh

# 应用仓库配置到本地（会自动备份现有配置）
./scripts/apply.sh
```

### 部署到远程设备

**注意**：部署前请确保远程服务器已安装前置依赖（git、zsh、python3、rsync）。

```bash
# 一键部署到远程 Linux 服务器
./scripts/deploy.sh user@remote-host

# 交互式输入 API keys（推荐，最安全）
./scripts/deploy.sh user@remote-host --interactive-secrets

# 部署时包含敏感配置
./scripts/deploy.sh user@remote-host --with-secrets

# 增量更新
./scripts/deploy.sh user@remote-host --update

# 只部署指定模块
./scripts/deploy.sh user@remote-host --modules=shell,git,claude

# 预览部署操作
./scripts/deploy.sh user@remote-host --dry-run

# 自定义 SSH 端口和密钥
./scripts/deploy.sh user@remote-host --port=2222 --identity=~/.ssh/id_ed25519
```

### 测试脚本

```bash
# 测试脚本语法
bash -n scripts/sync.sh
bash -n scripts/apply.sh
bash -n scripts/deploy.sh
```

## 代码架构

### 双向同步架构

项目的核心是双向配置同步机制：

**sync.sh（本地 → 仓库）**
- 从 `~/.zshrc`、`~/.gitconfig`、`~/.claude/` 等位置读取配置
- 使用 Python 脚本自动识别并脱敏敏感信息（API keys、tokens、passwords）
- 生成两份文件：
  - `secrets/` - 完整配置（不进 Git，包含敏感信息）
  - `configs/` - 脱敏配置（进 Git，敏感字段替换为 `<redacted>`）

**apply.sh（仓库 → 本地）**
- 优先使用 `secrets/` 中的完整配置
- 如果不存在，使用 `configs/` 中的脱敏配置
- 自动替换 `<redacted>` 为环境变量（从 `~/.config/secret-env` 读取）或提示用户输入
- 应用前自动备份到 `backups/YYYYMMDD_HHMMSS/`

**deploy.sh（本地 → 远程服务器）**
- 通过 SSH 连接到远程服务器
- 检查远程依赖是否已安装（git、zsh、python3、rsync）
- 使用 rsync 传输配置文件到远程服务器
- 在远程服务器上执行 `apply.sh` 应用配置
- 支持选项：
  - `--with-secrets` - 包含敏感配置
  - `--interactive-secrets` - 交互式输入 API keys
  - `--update` - 增量更新
  - `--modules` - 只部署指定模块
  - `--dry-run` - 预览操作不执行

### 公共函数库（scripts/lib.sh）

所有脚本共享的核心函数：
- `log()` / `warn()` - 日志输出
- `ensure_dir()` - 确保目录存在
- `has_cmd()` - 检查命令是否存在
- `copy_file()` - 复制文件（自动创建父目录）
- `mirror_dir()` - 镜像目录（使用 rsync，支持 `--delete` 选项）
- `backup_path()` - 备份路径到指定目录
- `ssh_exec()` - 在远程主机上执行命令
- `ssh_test()` - 测试 SSH 连接
- `detect_remote_os()` - 检测远程操作系统（用于显示信息）

### 目录结构

```
ai-dotfiles/
├── configs/          # 公开配置（进 Git，已脱敏）
  ├── claude/       # Claude Code 配置（AI CLI）
  │   ├── rules/    # 行为规则
  │   ├── mcp.json  # MCP 服务器配置（已脱敏）
  │   └── settings.json  # Claude 设置（已脱敏）
  ├── codex/        # Codex CLI 配置（AI CLI）
  │   ├── config.toml    # Codex 配置（已脱敏）
  │   └── skills/        # 自定义技能
  ├── gemini/       # Gemini CLI 配置（AI CLI）
  │   ├── settings.json  # Gemini 设置
  │   └── state.json     # 状态文件
  ├── shell/        # ZSH 配置（.zshrc, .p10k.zsh 等）
  ├── git/          # Git 配置（.gitconfig）
  ├── tmux/         # Tmux 配置
  ├── ssh/          # SSH 配置
  └── tools/        # 其他工具配置

secrets/          # 敏感配置（不进 Git，包含完整信息）
  ├── claude/     # Claude 完整配置（含 API keys）
  ├── codex/      # Codex 完整配置（含认证信息）
  └── gemini/     # Gemini 完整配置（含 OAuth 凭证）

scripts/          # 管理脚本
  ├── lib.sh      # 公共函数库（126行）
  ├── sync.sh     # 同步本地配置到仓库（257行）
  ├── apply.sh    # 应用仓库配置到本地（240行）
  └── deploy.sh   # 部署配置到远程服务器（391行）

backups/          # 配置备份（不进 Git）
  └── YYYYMMDD_HHMMSS/ # 按时间戳组织
```

## 关键设计原则

### 1. 安全第一
- 所有脚本使用 `set -euo pipefail` 严格模式
- 敏感信息自动识别和隔离（通过 Python 脚本）
- `.gitignore` 排除 `secrets/`、`backups/`、`*.key`、`.env` 等
- 敏感文件使用 `chmod 600` 保护

### 2. 优雅降级
- 检查命令是否存在再执行（`has_cmd`）
- rsync 不存在时回退到 cp
- 缺少配置时警告而非失败

### 3. 模块化设计
- 每个工具独立目录
- 支持增量添加新工具配置
- 脚本自动检测配置是否存在

### 4. 跨平台支持
- 支持 macOS 和 Linux
- 自动检测操作系统并适配命令

## 修改脚本时的注意事项

1. **保持向后兼容** - 旧设备可能使用旧版本的配置
2. **测试双向同步** - 修改 sync.sh 后必须测试 apply.sh 能否正确恢复
3. **处理缺失文件** - 使用 `[ -f "$file" ]` 检查，缺失时警告而非失败
4. **保护敏感信息** - 新增配置时确保敏感字段被正确识别和脱敏
5. **备份优先** - 任何破坏性操作前先调用 `backup_path`

## AI CLI 工具配置

项目管理三个 AI CLI 工具的配置：

- **Claude Code** (`configs/claude/`)
  - `rules/` - 8个 Markdown 文件定义行为规则
  - `mcp.json` - MCP 服务器配置（已脱敏）
  - `settings.json` - Claude 设置（已脱敏）

- **Codex** (`configs/codex/`)
  - `config.toml` - 使用 rightcode 提供商和 gpt-5.2-codex 模型
  - 集成 Notion MCP 服务器

- **Gemini** (`configs/gemini/`)
  - `settings.json` / `state.json` - Gemini CLI 配置

修改这些配置时，确保敏感信息（API keys、OAuth tokens）被正确处理。
