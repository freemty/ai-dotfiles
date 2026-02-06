# ai-dotfiles

🤖 **专为 AI CLI 工具设计的配置同步工具**

自动同步 **Claude Code**、**Codex**、**Gemini** 等 AI CLI 配置，同时支持 shell、git 等传统 dotfiles。内置敏感信息自动脱敏功能，让你安全地管理和分享配置。

> 📖 **设计理念**: 参考 [pengsida 的 Notion 配置管理文档](https://pengsida.notion.site/59569d7b66954578b21bf1dc6ea35776)

---

## ✨ 为什么选择 ai-dotfiles？

### 🤖 AI CLI 优先设计
- **原生支持** Claude Code、Codex、Gemini 配置
- 自动处理 `rules/`、`mcp.json`、`settings.json`、`config.toml` 等
- 智能识别 AI 工具的配置结构

### 🔒 智能敏感信息处理
- **自动脱敏** - API keys、tokens、passwords 自动识别
- **双份存储** - 完整版本（本地）+ 脱敏版本（Git）
- **环境变量支持** - 从 `~/.config/secret-env` 读取密钥
- **交互式输入** - 部署时可选择交互式输入 API keys

### 🚀 一键部署
- **SSH 远程部署** - 一条命令部署到多台服务器
- **模块化同步** - 选择性同步指定配置
- **自动备份** - 应用前自动备份，永不丢失配置

### 🌐 跨平台支持
- macOS 和 Linux 全支持
- 自动检测操作系统并适配

---

## 📦 支持的配置

### AI CLI 工具 🤖
- **Claude Code** - rules/, mcp.json, settings.json, marketplaces/
- **Codex** - config.toml, skills/, auth.json
- **Gemini** - settings.json, state.json, oauth_creds.json

### 传统 Dotfiles 💻
- **Shell** - .zshrc, .p10k.zsh, .zprofile
- **Git** - .gitconfig
- **Tmux** - .tmux.conf
- **SSH** - SSH 配置

---

## 🛠️ 前置依赖

在使用前，请确保以下软件已安装：

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

---

## 🚀 快速开始

### 1. 克隆仓库

```bash
git clone https://github.com/yourusername/ai-dotfiles.git
cd ai-dotfiles
```

### 2. 同步本地配置到仓库

```bash
./scripts/sync.sh
```

**这会做什么？**
- 从 `~/.claude/`、`~/.codex/`、`~/.gemini/` 读取 AI CLI 配置
- 从 `~/.zshrc`、`~/.gitconfig` 读取 shell 配置
- 自动识别并脱敏敏感信息（API keys、tokens）
- 生成两份文件：
  - `secrets/` - 完整配置（不进 Git，包含敏感信息）
  - `configs/` - 脱敏配置（进 Git，敏感字段替换为 `<redacted>`）

### 3. 应用配置到本地

```bash
./scripts/apply.sh
```

**这会做什么？**
- 优先使用 `secrets/` 中的完整配置
- 如果不存在，使用 `configs/` 中的脱敏配置
- 自动替换 `<redacted>` 为环境变量（从 `~/.config/secret-env` 读取）
- 如果环境变量不存在，提示用户输入
- 应用前自动备份到 `backups/YYYYMMDD_HHMMSS/`

### 4. 部署到远程服务器

**注意**：部署前请确保远程服务器已安装前置依赖。

```bash
# 基础部署
./scripts/deploy.sh user@remote-host

# 交互式输入 API keys（推荐，最安全）
./scripts/deploy.sh user@remote-host --interactive-secrets

# 部署时包含敏感配置
./scripts/deploy.sh user@remote-host --with-secrets

# 只部署 AI CLI 配置
./scripts/deploy.sh user@remote-host --modules=claude,codex,gemini

# 只部署 shell 配置
./scripts/deploy.sh user@remote-host --modules=shell,git

# 预览部署操作（不实际执行）
./scripts/deploy.sh user@remote-host --dry-run

# 自定义 SSH 端口和密钥
./scripts/deploy.sh user@remote-host --port=2222 --identity=~/.ssh/id_ed25519
```

---

## 📁 目录结构

```
ai-dotfiles/
├── configs/          # 公开配置（进 Git，已脱敏）
│   ├── claude/       # Claude Code 配置
│   │   ├── rules/    # 行为规则
│   │   ├── mcp.json  # MCP 服务器配置（已脱敏）
│   │   └── settings.json  # Claude 设置（已脱敏）
│   ├── codex/        # Codex CLI 配置
│   │   ├── config.toml    # Codex 配置（已脱敏）
│   │   └── skills/        # 自定义技能
│   ├── gemini/       # Gemini CLI 配置
│   │   ├── settings.json  # Gemini 设置
│   │   └── state.json     # 状态文件
│   ├── shell/        # Shell 配置
│   │   ├── .zshrc
│   │   └── .p10k.zsh
│   ├── git/          # Git 配置
│   │   └── .gitconfig
│   ├── tmux/         # Tmux 配置
│   └── ssh/          # SSH 配置
├── secrets/          # 敏感配置（不进 Git）
│   ├── claude/       # Claude 完整配置（含 API keys）
│   ├── codex/        # Codex 完整配置（含认证信息）
│   └── gemini/       # Gemini 完整配置（含 OAuth 凭证）
├── scripts/          # 管理脚本
│   ├── lib.sh        # 公共函数库
│   ├── sync.sh       # 同步本地配置到仓库
│   ├── apply.sh      # 应用仓库配置到本地
│   └── deploy.sh     # 部署配置到远程服务器
└── backups/          # 配置备份（不进 Git）
```

---

## 🔄 工作流程

### 日常使用

```bash
# 1. 修改本地配置后，同步到仓库
./scripts/sync.sh

# 2. 提交到 Git
git add configs/
git commit -m "Update AI CLI configs"
git push

# 3. 在其他设备上拉取并应用
git pull
./scripts/apply.sh
```

### 新设备部署

```bash
# 方式 1：直接部署（推荐）
./scripts/deploy.sh user@new-device --interactive-secrets

# 方式 2：手动部署
ssh user@new-device
git clone https://github.com/yourusername/ai-dotfiles.git
cd ai-dotfiles
./scripts/apply.sh
```

---

## 🛡️ 安全说明

### 敏感信息处理

**自动脱敏机制**：
- Python 脚本自动识别包含 `TOKEN`、`KEY`、`SECRET`、`PASSWORD` 的字段
- 生成两份文件：
  - `secrets/` - 完整配置（不进 Git）
  - `configs/` - 脱敏配置（进 Git，敏感字段替换为 `<redacted>`）

**环境变量支持**：
编辑 `~/.config/secret-env` 文件：

```bash
# AI CLI API Keys
NOTION_API_KEY=secret_xxxxx
ANTHROPIC_API_KEY=sk-ant-xxxxx
OPENAI_API_KEY=sk-xxxxx
```

**交互式输入**：
部署时使用 `--interactive-secrets` 选项，在本地输入 API keys，通过 SSH 安全传输到远程服务器。

### 文件权限

- 敏感文件自动设置为 `chmod 600`
- 敏感目录自动设置为 `chmod 700`
- `~/.config/secret-env` 自动设置为 `chmod 600`

### .gitignore

确保以下内容不会进入 Git：
```
secrets/          # 敏感配置
backups/          # 配置备份
*.key             # 密钥文件
.env              # 环境变量文件
```

---

## 🔧 高级用法

### 只同步 AI CLI 配置

```bash
# 只部署 Claude Code 配置
./scripts/deploy.sh user@host --modules=claude

# 只部署所有 AI CLI 配置
./scripts/deploy.sh user@host --modules=claude,codex,gemini
```

### 只同步 Shell 配置

```bash
./scripts/deploy.sh user@host --modules=shell,git
```

### 增量更新

```bash
# 跳过依赖检查，直接更新配置
./scripts/deploy.sh user@host --update
```

### 测试脚本

```bash
# 测试脚本语法
bash -n scripts/sync.sh
bash -n scripts/apply.sh
bash -n scripts/deploy.sh

# 预览部署操作
./scripts/deploy.sh user@host --dry-run
```

---

## 📝 开发指南

详细的开发指南请参考 [CLAUDE.md](./CLAUDE.md)，包括：
- 代码架构说明
- 双向同步机制
- 公共函数库
- 修改脚本的注意事项

---

## 🎯 使用场景

### 场景 1：多设备开发者
你在公司电脑、家里电脑、云服务器上都使用 Claude Code 和 Codex，需要保持配置一致。

```bash
# 在公司电脑上
./scripts/sync.sh && git push

# 在家里电脑上
git pull && ./scripts/apply.sh

# 在云服务器上
./scripts/deploy.sh user@cloud-server --interactive-secrets
```

### 场景 2：团队协作
团队成员共享 AI CLI 配置模板（不包含个人 API keys）。

```bash
# 团队成员 A 创建配置模板
./scripts/sync.sh
git push

# 团队成员 B 使用配置模板
git clone <repo>
./scripts/apply.sh  # 会提示输入个人 API keys
```

### 场景 3：新机器快速配置
购买新服务器或重装系统后，快速恢复开发环境。

```bash
# 一条命令完成所有配置
./scripts/deploy.sh user@new-server --interactive-secrets
```

---

## 🙏 致谢

- **[pengsida/configuration](https://github.com/pengsida/configuration)** - 设计灵感来源
- **[Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh)** - 强大的 ZSH 框架
- **[Powerlevel10k](https://github.com/romkatv/powerlevel10k)** - 美观的 ZSH 主题
- **[Claude Code](https://claude.ai/code)** - 强大的 AI 编程助手
- **[Codex](https://github.com/anthropics/codex)** - AI CLI 工具
- **[Gemini](https://ai.google.dev/)** - Google AI 助手

---

## 📄 许可证

MIT License

---

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

如果你觉得这个项目有用，请给个 ⭐️ Star 支持一下！
