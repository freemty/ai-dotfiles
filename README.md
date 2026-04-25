# ai-dotfiles

跨机器同步 AI CLI 和 shell 配置。用 [GNU Stow](https://www.gnu.org/software/stow/) 做 symlink 管理，一个目录 = 一个 package。

> 密钥/登录态由 [CC-Switch](https://github.com/freemty/cc-switch) 单独管理，不进此 repo。

## 快速上手

```bash
git clone git@github.com:freemty/ai-dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh                 # stow 所有 packages 到 $HOME
./scripts/bootstrap.sh       # clone yuanbo-skills + 装第三方 skills
```

## 目录结构

```
ai-dotfiles/
├── claude/        → ~/.claude/{settings.json, mcp.json, rules/, agents/}
├── codex/         → ~/.codex/{config.toml, hooks.json, rules/}
├── gemini/        → ~/.gemini/{settings.json, GEMINI.md}
├── zsh/           → ~/.zshrc, ~/.zprofile, ~/.p10k.zsh
├── git/           → ~/.gitconfig
├── tmux/          → ~/.tmux.conf
├── install.sh     # stow 编排 + 依赖安装
└── scripts/
    ├── bootstrap.sh              # skills 安装
    └── third-party-skills.txt    # 第三方 skill 清单（npx skills add）
```

## 同步什么 / 不同步什么

### ✅ 进 repo
- Claude: `settings.json`, `mcp.json`, `rules/*.md`, `agents/*.md`
- Codex: `config.toml`, `hooks.json`, `rules/`
- Gemini: `settings.json`, `GEMINI.md`
- Shell / Git / Tmux: 标准 dotfiles

### ❌ 不进 repo（由 CC-Switch 或本机管）
- 任何 `*.local.json`（machine-local 白名单）
- `auth.json` / `oauth_creds.json` / `.env`（密钥）
- `sessions/` / `history.jsonl` / `*.sqlite`（session 历史）
- `skills/` 下的具体 skill（由 bootstrap.sh 装）
- `projects/` / `tasks/` / `plans/`（运行时数据）

## Skills 管理

两类 skill 分别管：

1. **个人 skills** → [`yuanbo-skills`](https://github.com/freemty/yuanbo-skills) monorepo，`bootstrap.sh` 负责 clone 并跑它自己的 `install.sh`
2. **第三方 skills** → `scripts/third-party-skills.txt` 清单，`bootstrap.sh` 用 `npx skills add` 批量装

新加一个第三方 skill 到清单：
```bash
echo "new-skill-name" >> scripts/third-party-skills.txt
```

新机器装完后，`~/.claude/skills/` 里：
- symlink → 来自 yuanbo-skills
- 真实目录 → 来自 npx skills add

## 只装某几个 package

```bash
./install.sh claude codex       # 只 stow 这两个
```

## 更新

```bash
cd ~/dotfiles
git pull
./install.sh                    # --restow 会自动同步
```
