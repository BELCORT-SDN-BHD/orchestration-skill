# Orchestration Skill

A minimal, always-on orchestrator policy for Claude Code and Codex.

The current main model owns high-level judgment. Workers gather information,
execute, test, verify, and return concise evidence. Claude Code may route heavy
implementation to the official Codex plugin; Codex uses native workers.

## Install

```bash
gh repo clone BELCORT-SDN-BHD/orchestration-skill ~/.local/share/orchestration-skill
bash ~/.local/share/orchestration-skill/skills/orchestration/scripts/install-global.sh --backup-existing
```

The installer:

- links the skill into `~/.claude/skills/orchestration` and
  `${CODEX_HOME:-$HOME/.codex}/skills/orchestration`;
- adds `@~/.claude/skills/orchestration/SKILL.md` to
  `~/.claude/CLAUDE.md` exactly once;
- adds one Codex-only instruction to load `$orchestration`, because Codex does
  not expand Claude Code `@` imports;
- preserves any existing skill before replacing it when
  `--backup-existing` is supplied.

If `~/.codex/AGENTS.md` points to `~/.claude/CLAUDE.md`, Claude imports the
policy directly and Codex receives the instruction to load the same skill
through its global skill catalog. Start a fresh session after installation.

## Verify

```bash
python3 tests/validate_skill.py
bash tests/smoke.sh
```
