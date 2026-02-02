


# Yuanbo's 环境配置管理工具

YYb的 Powerlevel10k + Clash + copyzshel 的配置管理工具，让你可以轻松备份、同步和部署开发环境配置。

> 📖 **详细文档**: 更多配置管理理念和最佳实践，请参考 [pengsida 的 Notion 配置管理文档](https://pengsida.notion.site/59569d7b66954578b21bf1dc6ea35776)

## 🚀 特性

- **一键部署** - 使用 copyzshell 快速部署到新设备
- **配置备份** - 自动备份现有配置，避免丢失
- **模块化设计** - 按功能分类管理配置文件
- **跨平台支持** - 支持 macOS 和 Linux

## 📦 包含的配置

- **Shell 配置** - ZSH + Oh My Zsh + Powerlevel10k
<!-- - **ZSH 插件** - zsh-syntax-highlighting, zsh-autosuggestions, fzf, autojump -->
- **Git 配置** - 包含代理设置的 Git 配置
- **Clash 配置** - 代理工具配置
- **Tmux 配置** - 终端复用器配置（可选）
- **系统工具** - ncdu, nvtop, ctop 等监控工具
- **工具别名** - 常用命令别名

## 🛠️ 快速开始

### 1. 克隆仓库
```bash
git clone https://github.com/yourusername/ybcfg.git
cd ybcfg

# 初始化子模块
git submodule update --init --recursive
```

**注意**: 由于使用了 Git 子模块，克隆后必须初始化子模块才能正常使用 copyzshell 功能。

### 2. 一键同步本机配置到仓库
```bash
./scripts/sync.sh
```

### 3. 安装配置
```bash
chmod +x install.sh
./install.sh
```

### 4. 部署到新设备
```bash
# 使用 copyzshell 部署
copyzshell user@new-device-ip

# 或使用部署脚本
./scripts/deploy.sh user@new-device-ip
```

## 📋 使用方法

### 备份现有配置
```bash
./install.sh --backup-only
```

### 同步配置到仓库
```bash
./scripts/sync.sh
```


## 📁 目录结构

```
ybcfg/
├── README.md                 # 项目说明
├── install.sh               # 一键安装脚本
├── configs/                 # 配置文件目录
│   ├── claude/              # Claude Code 配置
│   ├── codex/               # Codex CLI 配置
│   ├── gemini/              # Gemini CLI 配置
│   ├── shell/               # Shell 配置
│   ├── git/                 # Git 配置
│   ├── clash/               # Clash 配置
│   ├── tmux/                # Tmux 配置
│   └── tools/               # 工具配置
├── scripts/                 # 管理脚本
│   ├── sync.sh              # 一键同步本机配置到仓库
│   ├── apply.sh             # 一键将仓库配置应用到本机
│   ├── deploy.sh            # 部署脚本
│   ├── manage_submodules.sh # 子模块管理脚本
│   └── clash/               # Clash 管理脚本
├── third_party/             # 第三方依赖
│   └── copyzshell/          # copyzshell 子模块
└── secrets/                 # 敏感配置模板
```

## 🔧 配置说明

### Shell 配置
- 使用 Powerlevel10k 主题
- 集成 copyzshell 插件
- 包含常用别名和函数

### Git 配置
- 用户信息配置
- 代理设置（使用 Clash）
- SSH 配置

### Clash 配置
- 基础代理配置
- 规则配置
- 支持订阅更新

## 🚀 部署到新设备

### Step1：使用 copyzshell同步zsh和插件

.third_party/copyzshell/README.md

```bash
copyzshell user@new-device-ip
```


### Step2：手动部署其他
```bash
# 在新设备上
git clone https://github.com/yourusername/ybcfg.git
cd ybcfg
./install.sh
```

## 🔄 配置更新

### 同步本地配置到仓库
```bash
./scripts/sync.sh
git add .
git commit -m "Update configs $(date)"
git push
```@    

### 迁移到新设备（从仓库恢复）
```bash
./scripts/apply.sh
```
> 注意：`secrets/` 不会进 Git，迁移时需要单独拷贝到新机器。



## 🛡️ 安全说明

- 敏感配置（如 API 密钥）存储在 `secrets/` 目录
- 使用 `.gitignore` 避免提交敏感信息
- 配置文件备份在 `backups/` 目录
- Claude/Codex/Gemini 的认证文件会被同步到 `secrets/`（不会进入 Git）


## 🙏 致谢

感谢以下开源项目和服务：

- **[Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh)** - 强大的 ZSH 框架
- **[Powerlevel10k](https://github.com/romkatv/powerlevel10k)** - 美观的 ZSH 主题
- **[copyzshell](https://github.com/rutchkiwi/copyzshell)** - ZSH 配置同步工具
- **[Clash](https://github.com/Dreamacro/clash)** - 代理工具
- **[Tmux](https://github.com/tmux/tmux)** - 终端复用器

特别感谢这些项目为开发者提供了优秀的工具和体验！

### 参考资源

- **[pengsida/configuration](https://github.com/pengsida/configuration)** - 原始配置仓库，提供了设计灵感
- **[pengsida 的 Notion 配置管理文档](https://pengsida.notion.site/59569d7b66954578b21bf1dc6ea35776)** - 详细的配置管理理念和最佳实践
- **[copyzshell](https://github.com/rutchkiwi/copyzshell)** - ZSH 配置同步工具
