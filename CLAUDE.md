# CLAUDE.md

给未来在此 repo 工作的 Claude Code 的上下文说明。

## 这是什么

`ai-dotfiles`——用 GNU Stow 管理的跨机器配置同步 repo。作用是在新机器上一条命令恢复 AI CLI（Claude / Codex / Gemini）+ shell（zsh / git / tmux）的完整配置。

## 核心设计

- **Stow-based**：每个顶层目录（`claude/`, `codex/`, ...）是一个 Stow package，里面镜像 `$HOME` 下的目标路径。例如 `claude/.claude/settings.json` → `~/.claude/settings.json`
- **密钥不管**：所有 token/key 字段在 repo 里留空（`""`），由 [CC-Switch](https://github.com/freemty/cc-switch) 在 apply 时填回
- **skills 不进 repo**：个人 skill 走 [yuanbo-skills](https://github.com/freemty/yuanbo-skills) monorepo，第三方 skill 走 `scripts/third-party-skills.txt` + `npx skills add`

## 关键文件

- `install.sh` — Stow 编排。核心是 `stow -t "$HOME" --no-folding --restow <pkg>`
- `scripts/bootstrap.sh` — clone yuanbo-skills + 批量装第三方 skills
- `scripts/third-party-skills.txt` — 每行一个 skill 名，注释用 `#` 开头
- `.gitignore` — 白名单式排除：`*.local.json`, `auth.json`, `oauth_creds.json`, `*.sqlite`, `sessions/` 等

## 操作注意事项

### 改配置的正确流程

用户在 `~/` 下改了 `~/.claude/settings.json`。由于 stow 是 symlink，repo 里 `claude/.claude/settings.json` 会**自动**看到变化——`cd ~/dotfiles && git status` 应能看到 diff。commit push 就完成同步。

**不要**在 repo 里改文件然后手动 `cp` 到 `~/`。symlink 是双向的，直接改哪边都行。

### 绝不要做的事

- **不要 commit 真实密钥**。GitHub push protection 会拦，而且会污染 git 历史。任何新字段加进 `settings.json` / `mcp.json` / `config.toml` 前，先确认是 config 还是 secret
- **不要去掉 `stow --no-folding`**。没有它，`~/.claude/` 会被做成单个 symlink 指向 `repo/claude/.claude/`——Claude Code 写入 `sessions/` `history.jsonl` 等运行时文件时会直接污染 repo
- **不要把 fars-*/hle-solver 等私有 skill 加进 `third-party-skills.txt`**。这些是 yuanbo-skills 里的项目 skill，不是 npx 能装的

### 新增一个 AI CLI 工具（例如 `aider`）

1. `mkdir -p aider/.config/aider`
2. 把 `~/.config/aider/*.conf` 拷进去（确认没密钥）
3. 改 `install.sh` 的 `PACKAGES_ALL` 加 `aider`
4. 改 `install.sh` 的 `backup_if_exists` 分支加对应路径
5. 更新 `README.md` 的目录结构部分

## Repo 风格

- Commit message 用中英混写都行，但保持技术性，不用 emoji
- PR/commit 不写 `Co-Authored-By: Claude` 之类的标签（用户全局禁了）
- 所有脚本都要 `set -euo pipefail`
- 支持 macOS + Linux；macOS 是 bash 3.2，注意别用 bash 4+ 语法（associative arrays、`${var,,}` 等）

## 关联 repos

- [freemty/yuanbo-skills](https://github.com/freemty/yuanbo-skills) — 个人 skills monorepo
- [freemty/cc-switch](https://github.com/freemty/cc-switch) — 密钥管理
- [jiahao-shao1/dotfiles](https://github.com/jiahao-shao1/dotfiles) — 本 repo 的结构参考样板
