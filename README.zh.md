# ai-dotfiles

同步 AI CLI 配置（Claude Code、Codex、Gemini）到多台机器。也能处理 shell、git 等传统 dotfiles。

主要功能：提交前自动脱敏 API keys 和密钥，这样可以安全地把配置放进 Git，不用担心泄露凭证。

> 灵感来自 [transfer-cli](https://github.com/RajaRakoto/transfer-cli)

---

## 为什么做这个

我厌倦了在工作电脑、家里电脑和云服务器之间手动复制 Claude Code 的 rules 和 MCP 配置。每次调整一个设置，就得记着同步到所有地方。

大多数 dotfile 管理工具不懂 AI CLI 工具。它们把 `~/.claude/mcp.json` 当普通配置文件处理，要么把 API keys 提交到 git（危险），要么每次手动脱敏（麻烦）。

这个工具做三件事：
1. 自动同步 AI CLI 配置
2. 提交前去掉密钥
3. 在新机器上应用配置时恢复密钥

---

## 支持的配置

**AI CLI 工具：**
- Claude Code - rules、mcp.json、settings.json、marketplaces
- Codex - config.toml、skills、auth.json
- Gemini - settings.json、state.json、oauth_creds.json

**传统 dotfiles：**
- Shell - .zshrc、.p10k.zsh、.zprofile
- Git - .gitconfig
- Tmux - .tmux.conf

---

## 前置要求

本地和远程服务器都需要安装：

```bash
# macOS
brew install git zsh python3 rsync

# Ubuntu/Debian
sudo apt-get install git zsh python3 rsync

# CentOS/RHEL
sudo yum install git zsh python3 rsync
```

---

## 快速开始

### 1. 克隆并同步本地配置

```bash
git clone https://github.com/yourusername/ai-dotfiles.git
cd ai-dotfiles
./scripts/sync.sh
```

这会从 `~/.claude/`、`~/.codex/`、`~/.zshrc` 等位置读取配置，复制到仓库。Python 脚本自动找出看起来像 API key 的内容并脱敏。

生成两个版本：
- `secrets/` - 完整配置，包含真实 API keys（不提交到 git）
- `configs/` - 脱敏配置，敏感字段替换为 `<redacted>`（可以提交）

### 2. 在另一台机器上应用配置

```bash
git pull
./scripts/apply.sh
```

脚本优先查找 `secrets/`（如果你手动复制过来的话）。找不到就用 `configs/`，然后尝试填充 `<redacted>` 的值：
1. 从 `~/.config/secret-env` 读取环境变量
2. 交互式提示（让你手动输入）

应用前会自动备份现有配置到 `backups/YYYYMMDD_HHMMSS/`。

### 3. 部署到远程服务器

```bash
# 基础部署
./scripts/deploy.sh user@remote-host

# 交互模式（本地输入 API keys，通过 SSH 发送）
./scripts/deploy.sh user@remote-host --interactive-secrets

# 包含本地 secrets/ 目录的密钥
./scripts/deploy.sh user@remote-host --with-secrets

# 只部署 AI CLI 配置（默认）
./scripts/deploy.sh user@remote-host --modules=claude,codex,gemini

# 只部署 shell 配置
./scripts/deploy.sh user@remote-host --modules=shell,git

# 自定义 SSH 端口
./scripts/deploy.sh user@remote-host:2222
```

---

## 工作原理

### 目录结构

```
ai-dotfiles/
├── configs/          # 脱敏配置（提交到 git）
│   ├── claude/       # Claude Code 配置
│   ├── codex/        # Codex CLI 配置
│   ├── gemini/       # Gemini CLI 配置
│   ├── shell/        # .zshrc、.p10k.zsh 等
│   ├── git/          # .gitconfig
│   └── tmux/         # .tmux.conf
├── secrets/          # 完整配置，包含真实密钥（不在 git 里）
│   ├── claude/
│   ├── codex/
│   └── gemini/
├── scripts/
│   ├── sync.sh       # 本地 → 仓库
│   ├── apply.sh      # 仓库 → 本地
│   └── deploy.sh     # 本地 → 远程服务器
└── backups/          # 自动生成的备份（不在 git 里）
```

### 典型工作流

```bash
# 1. 本地修改配置
vim ~/.claude/rules/coding-style.md

# 2. 同步到仓库
./scripts/sync.sh

# 3. 提交
git add configs/
git commit -m "更新编码规范"
git push

# 4. 在另一台机器上
git pull
./scripts/apply.sh
```

---

## 安全性

### 密钥处理方式

`sync.sh` 里的 Python 脚本查找包含 `TOKEN`、`KEY`、`SECRET` 或 `PASSWORD` 的字段，把值替换成 `<redacted>`。

生成两个文件：
- `secrets/claude/mcp.json` - 完整文件，包含真实的 `NOTION_API_KEY=secret_xxxxx`
- `configs/claude/mcp.json` - 脱敏文件，`NOTION_API_KEY=<redacted>`

只有 `configs/` 进 git。`secrets/` 留在本地。

### 环境变量

创建 `~/.config/secret-env`：

```bash
NOTION_API_KEY=secret_xxxxx
ANTHROPIC_API_KEY=sk-ant-xxxxx
OPENAI_API_KEY=sk-xxxxx
```

运行 `apply.sh` 时，它读取这个文件，把 `<redacted>` 替换成实际值。

### 交互式密钥输入

如果不想把 `secrets/` 复制到新机器，用 `--interactive-secrets`：

```bash
./scripts/deploy.sh user@remote-host --interactive-secrets
```

会提示你在本地输入每个 API key，然后通过 SSH 发送到远程服务器的 `~/.config/secret-env`。

### 文件权限

敏感文件自动设置为 `chmod 600`（只有你能读）。

---

## 使用场景

### 多台机器

你在公司笔记本、家里台式机和云服务器上工作。想要所有地方的 Claude Code rules 保持一致。

```bash
# 公司笔记本
./scripts/sync.sh && git push

# 家里台式机
git pull && ./scripts/apply.sh

# 云服务器
./scripts/deploy.sh user@cloud-server --interactive-secrets
```

### 团队共享

和团队共享 AI CLI 配置模板（不包含个人 API keys）。

```bash
# 团队成员 A 创建模板
./scripts/sync.sh
git push

# 团队成员 B 使用模板
git clone <repo>
./scripts/apply.sh  # 会提示输入自己的 API keys
```

### 新服务器配置

刚买了新服务器，想要完整的开发环境。

```bash
./scripts/deploy.sh user@new-server --interactive-secrets
```

一条命令搞定。

---

## 高级用法

### 模块选择

默认情况下，`deploy.sh` 只同步 AI CLI 配置（claude、codex、gemini）。要包含 shell 配置：

```bash
# 在默认基础上添加 shell
./scripts/deploy.sh user@host --modules=+shell

# 或者明确指定要什么
./scripts/deploy.sh user@host --modules=shell,git,claude
```

### 预演模式

预览会发生什么，但不实际执行：

```bash
./scripts/deploy.sh user@host --dry-run
```

### 测试脚本

```bash
# 检查语法
bash -n scripts/sync.sh
bash -n scripts/apply.sh
bash -n scripts/deploy.sh
```

---

## 开发

详见 [CLAUDE.md](./CLAUDE.md)：
- 代码架构
- 双向同步机制
- 共享函数库
- 修改脚本的注意事项

---

## 致谢

- [pengsida/configuration](https://github.com/pengsida/configuration) - 设计灵感
- [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh) - ZSH 框架
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k) - ZSH 主题

---

## 许可证

MIT

---

## 贡献

欢迎提 Issue 和 PR。

如果这工具帮到你了，给个 star。
