# Orchestration Skill

A cross-runtime global skill that initializes the invoking Claude Code or Codex session as an **orchestrator**: one user-chosen senior advisor model gates every judgment call, and execution routes to the cheapest capable worker lane across vendors.

The division of labor:

- **Orchestrator (the invoking session)** — decomposes work, writes work orders, routes, verifies, synthesizes, reports, owns recoverable state.
- **Advisor (the brain)** — picked by the user at init from the two advisor lanes in the routing table; the unchosen lane is the labeled fallback. All design, planning, architecture, audit, and scope decisions pass through it before execution, via fresh read-only sessions launched by `scripts/advisor.sh` (liveness timeouts and model provenance included).
- **Workers (the hands)** — bounded, already-decided execution on the cheapest lane that passes acceptance: three Claude-family tiers as native subagents, three GPT-family tiers via `codex exec`. Bindings live in one file: `skills/orchestration/references/MODEL-ROUTING.md`.

The skill grants no merge, deploy, spend, credential, production, or external-write authority. Project rules always override it.

## Recommended installation: clone once, link both runtimes

```bash
gh repo clone BELCORT-SDN-BHD/orchestration-skill ~/.local/share/orchestration-skill
bash ~/.local/share/orchestration-skill/skills/orchestration/scripts/install-global.sh --backup-existing
```

Start a new session after installation. Invoke it as `$orchestration` in Codex or `/orchestration` in Claude Code.

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

The smoke suite covers clean installation, idempotent reruns, refusal to overwrite existing skills, out-of-tree backups, migration of stale in-tree backups, and advisor.sh argument handling.

## What "initialize as orchestrator" means

The invoking session resolves project law and ground truth, asks the user which advisor to use, and reports one init block. From then on: judgment goes to the advisor, execution goes to workers, irreversible actions go to the user.

A skill cannot retroactively change the model or effort of an already-running host session, and a prompt label is not proof of model identity. Advisor provenance is verified from response metadata (claude JSON result) or session rollout files (codex), recorded by `advisor.sh` in `provenance.json`.
