# Hooks System

## Hook Types

- **PreToolUse**: Before tool execution (validation, parameter modification)
- **PostToolUse**: After tool execution (auto-format, checks)
- **Stop**: When session ends (final verification)
- **Notification**: Desktop notifications for idle/permission prompts

## Current Hooks (in ~/.claude/settings.json)

### PreToolUse
- **webfetch-block** (matcher: `WebFetch`): Blocks URLs with dedicated tools, redirects to web-fetcher skill
- **secrets-guard** (matcher: `Bash|Write|Edit`): Detects API key patterns (AWS/OpenAI/GitHub/HF/Slack), blocks writes containing secrets
- **destructive-git** (matcher: `Bash`): Blocks force-push, reset --hard, clean -f, checkout ., restore ., branch -D
- **codeisland** (matcher: `""`): IDE integration bridge, forwards tool events to local socket

### Stop
- **wiki-auto-ingest**: Pipes session transcript to wiki auto-ingest script (async, background)

### Notification
- **notify**: macOS desktop notification (Glass/Purr/Submarine sounds by type)

## Project-Level Hooks (fars-autotrain/.claude/settings.json)

### PreToolUse
- **exp-launch-guard** (matcher: `Bash`): Enforces op rules #1 (dry-run within 1h) and #4 (--per-rank required) for launch_pai.py

## Auto-Accept Permissions

Use with caution:
- Enable for trusted, well-defined plans
- Disable for exploratory work
- Never use dangerously-skip-permissions flag
- Configure `allowedTools` in `~/.claude.json` instead

## TodoWrite Best Practices

Use TodoWrite tool to:
- Track progress on multi-step tasks
- Verify understanding of instructions
- Enable real-time steering
- Show granular implementation steps

Todo list reveals:
- Out of order steps
- Missing items
- Extra unnecessary items
- Wrong granularity
- Misinterpreted requirements
