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
├── claude/.claude/
│   ├── settings.json           # env、hooks、enabledPlugins（密钥字段留空）
│   ├── mcp.json                # MCP server 配置（token 留空）
│   ├── rules/                  # 11 个 md（语言、编码风格、hooks、agents…）
│   └── agents/                 # cc-advisor, fars-system-expert
├── codex/.codex/
│   ├── config.toml
│   ├── hooks.json
│   └── rules/default.rules
├── gemini/.gemini/
│   ├── settings.json
│   └── GEMINI.md
├── zsh/                        # .zshrc, .zprofile, .p10k.zsh
├── git/.gitconfig
├── tmux/.tmux.conf
├── yazi/.config/yazi/          # keymap.toml, package.toml（G 键启动 lazygit）
├── install.sh                  # stow 编排 + 自动备份
└── scripts/
    ├── bootstrap.sh            # skills 安装（personal + 第三方）
    └── third-party-skills.txt  # npx skills add 清单
```

## 同步什么 / 不同步什么

### ✅ 进 repo
- **Claude**：`settings.json`, `mcp.json`, `rules/`, `agents/`
- **Codex**：`config.toml`, `hooks.json`, `rules/`
- **Gemini**：`settings.json`, `GEMINI.md`
- **Shell / Git / Tmux**：标准 dotfiles

### ❌ 不进 repo（见 `.gitignore`）
- 任何 `settings.local.json`（machine-local 白名单）
- `auth.json` / `oauth_creds.json` / `.env` / `installation_id`（密钥 + 登录态）
- `sessions/` / `history.jsonl` / `*.sqlite` / `projects/` / `tasks/`（运行时数据）
- `skills/` 下的具体 skill（由 bootstrap.sh 装）

## Skills 管理

两类 skill 分别管：

1. **个人 skills** → [`yuanbo-skills`](https://github.com/freemty/yuanbo-skills) monorepo。`bootstrap.sh` clone 它并跑其 `install.sh --target claude`
2. **第三方 skills** → `scripts/third-party-skills.txt` 清单，`bootstrap.sh` 用 `npx skills add` 批量装

新增一个第三方 skill：
```bash
echo "new-skill-name" >> scripts/third-party-skills.txt
```

## Install.sh 行为

- 自动装 GNU Stow（macOS 用 brew，Linux 用 apt，否则报错）
- 冲突时把现有文件**备份**到 `~/.dotfiles-backup-<timestamp>/`，不覆盖
- 用 `stow --no-folding` 避免把 `~/.claude/` 这种目录整个做成 symlink（否则 Claude Code 无法写入 sessions/ 等运行时目录）
- 支持子集安装：`./install.sh claude codex` 只 stow 这两个

## 更新

```bash
cd ~/dotfiles
git pull
./install.sh                    # --restow 会自动同步变化
```

## Troubleshooting

### Stow 报 "existing target is neither a link nor a directory"
有个真实文件挡路。`install.sh` 通常会自动备份，如果手动跑 `stow` 跳过了这一步：
```bash
mv ~/.zshrc ~/.zshrc.bak
cd ~/dotfiles && stow -t "$HOME" --no-folding zsh
```

### 装完后 Claude Code 无法启动 / session 丢失
说明漏了 `--no-folding`，`~/.claude` 被整个做成了 symlink。修复：
```bash
cd ~/dotfiles && stow -t "$HOME" -D claude && stow -t "$HOME" --no-folding claude
```

### `npx skills add` 对某些 skill 报错
`third-party-skills.txt` 只应该包含**公开可装**的 skill。私有/项目 skill（fars-*、hle-solver 等）属于 yuanbo-skills monorepo，由 `bootstrap.sh` 第一步自动装。

### 密钥在哪
不在这里。[CC-Switch](https://github.com/freemty/cc-switch) 管 AWS/Notion/HF 这些 token，新机器 install 完之后跑 CC-Switch apply 把密钥填回 `settings.json` / `mcp.json` / `config.toml`。

## 设计取舍

- **为什么用 Stow 而不是脚本拷贝**：symlink 双向——你在 `~/` 改任何文件，repo 里立刻可见（`git status` 告诉你），不会忘记同步回来
- **为什么不 auto-redact 密钥**：复杂度（redact + restore 两套逻辑）换来的唯一好处是"密钥可以放在配置文件里"——而这本身就是反模式。干脆不放
- **为什么 skills 不进 repo**：个人 skill 已经有 monorepo (`yuanbo-skills`) 管理；第三方 skill 由 `npx skills` 生态管理。双重管理只会引入冲突

## License

MIT
