# Orchestration Skill

A cross-runtime global skill that initializes the invoking Claude Code or Codex frontier session as the **orchestrator**. The orchestrator stays in the main loop to plan, judge, delegate, synthesize, and verify; token-heavy execution routes to bounded workers across the two supported model families.

The division of labor:

- **Orchestrator (the brain)** — the invoking frontier session. It owns planning, architecture, scope, routing, synthesis, verification, final judgment, reports, and recoverable state.
- **Workers (the hands)** — bounded execution sessions chosen by task shape and runtime locality. They investigate, implement, test, and return machine evidence.
- **User** — owns irreversible and external actions.

There is no routine approval layer between the orchestrator and workers. A fresh cross-family frontier review is exceptional: high-consequence work, unresolved conflicting evidence, or an explicit user request.

The skill grants no merge, deploy, spend, credential, production, or external-write authority. Project rules always override it.

## Recommended installation: clone once, link both runtimes

```bash
gh repo clone BELCORT-SDN-BHD/orchestration-skill ~/.local/share/orchestration-skill
bash ~/.local/share/orchestration-skill/skills/orchestration/scripts/install-global.sh --backup-existing
```

Start a new frontier-model session after installation, then invoke `$orchestration` in Codex or `/orchestration` in Claude Code. A skill cannot change the model or effort of an already-running host session.

Both global skill paths point to the same Git clone:

- `~/.codex/skills/orchestration`
- `~/.claude/skills/orchestration`

Backups of any pre-existing skill go to `~/.local/share/orchestration-skill-backups/` — never inside the skills directories, where runtimes would index them as a second stale skill.

Update every runtime with one command:

```bash
git -C ~/.local/share/orchestration-skill pull --ff-only
```

## Local verification

```bash
python3 tests/validate_skill.py
bash tests/smoke.sh
```

The smoke suite covers clean installation, idempotent reruns, refusal to overwrite existing skills, out-of-tree backups, migration of stale in-tree backups, and script syntax.

## What initialization means

The invoking session resolves project law and ground truth, reports its observed orchestrator lane when trustworthy runtime metadata is available, and selects the smallest capable workers for execution. Normal work uses one worker; parallel fanout is reserved for independent subtasks or context isolation. High-consequence external actions still return to the user.
