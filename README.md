# ai-dotfiles

Sync your AI CLI configs (Claude Code, Codex, Gemini) across machines. Also handles shell, git, and other dotfiles.

The main thing: it automatically redacts API keys and secrets before committing, so you can safely version control your configs without leaking credentials.

> Inspired by [transfer-cli](hhttps://github.com/RajaRakoto/transfer-cli)

---

## Why this exists

I got tired of manually copying Claude Code rules and MCP configs between my work laptop, home desktop, and cloud servers. Every time I tweaked a setting, I had to remember to sync it everywhere.

Most dotfile managers don't understand AI CLI tools. They treat `~/.claude/mcp.json` like any other config file, which means you either commit your API keys to git (bad) or manually redact them every time (annoying).

This tool does three things:
1. Syncs AI CLI configs automatically
2. Strips out secrets before committing
3. Restores secrets when applying configs on new machines

---

## What it syncs

**AI CLI tools:**
- Claude Code - rules, mcp.json, settings.json, marketplaces
- Codex - config.toml, skills, auth.json
- Gemini - settings.json, state.json, oauth_creds.json

**Traditional dotfiles:**
- Shell - .zshrc, .p10k.zsh, .zprofile
- Git - .gitconfig
- Tmux - .tmux.conf

---

## Prerequisites

You need these installed locally and on any remote servers:

```bash
# macOS
brew install git zsh python3 rsync

# Ubuntu/Debian
sudo apt-get install git zsh python3 rsync

# CentOS/RHEL
sudo yum install git zsh python3 rsync
```

---

## Quick start

### 1. Clone and sync your local configs

```bash
git clone https://github.com/yourusername/ai-dotfiles.git
cd ai-dotfiles
./scripts/sync.sh
```

This reads your configs from `~/.claude/`, `~/.codex/`, `~/.zshrc`, etc. and copies them into the repo. A Python script automatically finds and redacts anything that looks like an API key.

You get two versions:
- `secrets/` - full configs with real API keys (not committed to git)
- `configs/` - redacted configs with `<redacted>` placeholders (safe to commit)

### 2. Apply configs on another machine

```bash
git pull
./scripts/apply.sh
```

The script looks for `secrets/` first (if you copied them manually). If not found, it uses `configs/` and tries to fill in the `<redacted>` values from:
1. Environment variables in `~/.config/secret-env`
2. Interactive prompts (it'll ask you to type them in)

Before applying anything, it backs up your existing configs to `backups/YYYYMMDD_HHMMSS/`.

### 3. Deploy to remote servers

```bash
# Basic deployment
./scripts/deploy.sh user@remote-host

# Interactive mode (type API keys locally, they're sent over SSH)
./scripts/deploy.sh user@remote-host --interactive-secrets

# Include secrets from local secrets/ directory
./scripts/deploy.sh user@remote-host --with-secrets

# Deploy only AI CLI configs (default)
./scripts/deploy.sh user@remote-host --modules=claude,codex,gemini

# Deploy only shell configs
./scripts/deploy.sh user@remote-host --modules=shell,git

# Custom SSH port
./scripts/deploy.sh user@remote-host:2222
```

---

## How it works

### Directory structure

```
ai-dotfiles/
├── configs/          # Redacted configs (committed to git)
│   ├── claude/       # Claude Code configs
│   ├── codex/        # Codex CLI configs
│   ├── gemini/       # Gemini CLI configs
│   ├── shell/        # .zshrc, .p10k.zsh, etc.
│   ├── git/          # .gitconfig
│   └── tmux/         # .tmux.conf
├── secrets/          # Full configs with real keys (NOT in git)
│   ├── claude/
│   ├── codex/
│   └── gemini/
├── scripts/
│   ├── sync.sh       # Local → repo
│   ├── apply.sh      # Repo → local
│   └── deploy.sh     # Local → remote server
└── backups/          # Auto-generated backups (NOT in git)
```

### Typical workflow

```bash
# 1. Change configs locally
vim ~/.claude/rules/coding-style.md

# 2. Sync to repo
./scripts/sync.sh

# 3. Commit
git add configs/
git commit -m "Update coding style rules"
git push

# 4. On another machine
git pull
./scripts/apply.sh
```

---

## Security

### How secrets are handled

The Python script in `sync.sh` looks for fields containing `TOKEN`, `KEY`, `SECRET`, or `PASSWORD` and replaces their values with `<redacted>`.

Two files are created:
- `secrets/claude/mcp.json` - full file with real `NOTION_API_KEY=secret_xxxxx`
- `configs/claude/mcp.json` - redacted file with `NOTION_API_KEY=<redacted>`

Only `configs/` goes into git. `secrets/` stays local.

### Environment variables

Create `~/.config/secret-env`:

```bash
NOTION_API_KEY=secret_xxxxx
ANTHROPIC_API_KEY=sk-ant-xxxxx
OPENAI_API_KEY=sk-xxxxx
```

When you run `apply.sh`, it reads this file and replaces `<redacted>` with the actual values.

### Interactive secrets

If you don't want to copy `secrets/` to a new machine, use `--interactive-secrets`:

```bash
./scripts/deploy.sh user@remote-host --interactive-secrets
```

It'll prompt you to type each API key locally, then send them over SSH to the remote server's `~/.config/secret-env`.

### File permissions

Sensitive files are automatically set to `chmod 600` (readable only by you).

---

## Use cases

### Multiple machines

You work on a company laptop, home desktop, and cloud server. You want the same Claude Code rules everywhere.

```bash
# Company laptop
./scripts/sync.sh && git push

# Home desktop
git pull && ./scripts/apply.sh

# Cloud server
./scripts/deploy.sh user@cloud-server --interactive-secrets
```

### Team sharing

Share AI CLI config templates with your team (without sharing personal API keys).

```bash
# Team member A creates template
./scripts/sync.sh
git push

# Team member B uses template
git clone <repo>
./scripts/apply.sh  # Prompts for their own API keys
```

### New server setup

You just spun up a new server and want your full dev environment.

```bash
./scripts/deploy.sh user@new-server --interactive-secrets
```

One command. Done.

---

## Advanced usage

### Module selection

By default, `deploy.sh` only syncs AI CLI configs (claude, codex, gemini). To include shell configs:

```bash
# Add shell to defaults
./scripts/deploy.sh user@host --modules=+shell

# Or specify exactly what you want
./scripts/deploy.sh user@host --modules=shell,git,claude
```

### Dry run

Preview what would happen without actually doing it:

```bash
./scripts/deploy.sh user@host --dry-run
```

### Testing scripts

```bash
# Check syntax
bash -n scripts/sync.sh
bash -n scripts/apply.sh
bash -n scripts/deploy.sh
```

---

## Development

See [CLAUDE.md](./CLAUDE.md) for:
- Code architecture
- How the bidirectional sync works
- Shared function library
- Notes for modifying scripts

---

## Credits

- [pengsida/configuration](https://github.com/pengsida/configuration) - design inspiration
- [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh) - ZSH framework
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k) - ZSH theme

---

## License

MIT

---

## Contributing

Issues and PRs welcome.

If this saved you time, give it a star.
