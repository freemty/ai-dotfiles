# Workflow Rules

## Documentation Indexing

All documentation (specs, guides, notes) MUST be indexed in CLAUDE.md with path + one-line description.
A document not in the CLAUDE.md index is effectively dead — it will never be read in future sessions.

When creating any new document, always add the corresponding entry to CLAUDE.md in the same operation.

## Directory Renaming Breaks Symlinks

After renaming or moving a directory, always check for symlinks that pointed to the old path.
Key locations with symlinks: `~/.claude/skills/`, `~/.claude/agents/`, project `skills/` directories.
Quick check: `find ~/.claude/skills -maxdepth 1 -type l ! -exec test -e {} \; -print`

## Periodic Code Review

Proactively initiate code review + codebase cleanup + brainstorming on a regular cadence:
1. Code review — check recent changes for quality and consistency
2. Codebase cleanup — remove dead code, stale docs, inconsistent naming
3. Brainstorming — review current architecture, discuss improvements

Trigger: every Friday, or after completing a major feature.
