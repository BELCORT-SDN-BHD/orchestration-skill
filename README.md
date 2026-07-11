# Orchestration Skill

A cross-runtime global skill that initializes the invoking Claude or Codex session as a recoverable control plane and coordinates independent Fable 5 Max and GPT-5.6 Sol Ultra judgment advisors.

The skill establishes roles, decision tiers, clean-room advisor prompts, actual-model provenance, liveness timeouts, bounded workers, state recovery, and hard permission gates. It does not grant merge, deploy, spend, credential, production, or external-write authority. Project rules always override it.

## Recommended installation: pin once, link both runtimes

```bash
gh repo clone BELCORT-SDN-BHD/orchestration-skill ~/.local/share/orchestration-skill
git -C ~/.local/share/orchestration-skill checkout --detach v1.0.0
bash ~/.local/share/orchestration-skill/skills/orchestration/scripts/install-global.sh --backup-existing
```

Start a new session after installation. Invoke it as `$orchestration` in Codex or `/orchestration` in Claude Code.

Both global skill paths point to the same Git clone:

- `~/.codex/skills/orchestration`
- `~/.claude/skills/orchestration`

The installed revision does not update itself. To upgrade both runtimes, fetch a reviewed release, run the tests, switch revisions, and start a fresh session:

```bash
git -C ~/.local/share/orchestration-skill fetch --tags
git -C ~/.local/share/orchestration-skill checkout --detach <reviewed-release-tag>
python3 ~/.local/share/orchestration-skill/tests/validate_skill.py
bash ~/.local/share/orchestration-skill/tests/smoke.sh
```

## Codex skill-installer alternative

For a private repo, use existing GitHub credentials:

```bash
python3 ~/.codex/skills/.system/skill-installer/scripts/install-skill-from-github.py \
  --repo BELCORT-SDN-BHD/orchestration-skill \
  --path skills/orchestration \
  --method git
bash ~/.codex/skills/orchestration/scripts/install-global.sh --backup-existing
```

This copies the skill into Codex and then links Claude Code to the same copy. The clone-and-link installation is preferable when you want simple updates across machines.

## Local verification

```bash
python3 tests/validate_skill.py
bash tests/smoke.sh
```

The smoke suite covers clean installation, idempotent reruns, refusal to overwrite existing skills, and backup-preserving migration.

## Project overlays

Keep project law in a uniquely named overlay, for example `project-orchestration-overlay`; never commit a second full skill named `orchestration`. The project's guaranteed bootstrap file must require the global skill, the overlay, and its durable state checkpoint. Pin the overlay's audited protocol version and `SKILL.md` SHA-256, fail closed on incompatibility, and never fetch a mutable revision during session startup.

The portability promise applies to supported, GitHub-authenticated machines after installation. The current installer and symlink tests are verified on macOS/Unix; Windows needs a separately tested adapter. Cross-machine program recovery also requires a project-approved shared state store. A local skill installation alone cannot fence two machines or transport active program state.

## What “initialize as orchestrator” means

The invoking session becomes the unique control plane and immediately resolves project law, ground truth, state, decision tier, and advisor availability. Independent advisor sessions are then launched as needed.

A skill cannot retroactively change the actual model or effort of an already-running host session, disable provider safeguards, or prove model identity from a prompt label. It records the current session model/effort as observed or unknown and verifies every external advisor from response/session metadata.
