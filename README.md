# Orchestration

One prompt that makes the current main model the orchestrator in every
installed Claude Code and Codex session.

- The orchestrator reasons, plans, decides, synthesizes, and communicates.
- Workers gather information, implement, debug, test, and verify.
- Claude Code sends heavy code work to `codex:codex-rescue` using
  `gpt-5.6-sol` with `xhigh` effort.
- Codex uses the best-suited native Codex worker.

## Install

```bash
gh repo clone BELCORT-SDN-BHD/orchestration-skill ~/.local/share/orchestration-skill
bash ~/.local/share/orchestration-skill/skills/orchestration/scripts/install-global.sh --backup-existing
```

Cloning only downloads the repository. The installer makes the policy
always-on by:

- linking the same skill into `~/.claude/skills/orchestration` and
  `${CODEX_HOME:-$HOME/.codex}/skills/orchestration`;
- adding `@~/.claude/skills/orchestration/SKILL.md` to
  `~/.claude/CLAUDE.md` exactly once;
- adding a Codex instruction to load `$orchestration` to
  `${CODEX_HOME:-$HOME/.codex}/AGENTS.md` exactly once;
- preserving an existing `AGENTS.md` symlink and all existing instructions;
- preserving any existing skill before replacing it when
  `--backup-existing` is supplied.

Run the installer again safely at any time. Start a fresh session after
installation.

## Update

```bash
git -C ~/.local/share/orchestration-skill pull --ff-only
```

No reinstall is needed after pulling; new sessions use the updated local
clone. GitHub changes are not downloaded automatically.

## Verify

```bash
python3 tests/validate_skill.py
bash tests/smoke.sh
```
