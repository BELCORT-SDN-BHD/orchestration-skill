# Orchestration Skill

A cross-runtime global skill that initializes the invoking Claude or Codex session as a recoverable control plane and coordinates independent Fable 5 Max and GPT-5.6 Sol Ultra judgment advisors.

The skill establishes roles, decision tiers, clean-room advisor prompts, actual-model provenance, liveness timeouts, bounded workers, state recovery, and hard permission gates. It does not grant merge, deploy, spend, credential, production, or external-write authority. Project rules always override it.

## Recommended installation: clone once, link both runtimes

```bash
gh repo clone BELCORT-SDN-BHD/orchestration-skill ~/.local/share/orchestration-skill
bash ~/.local/share/orchestration-skill/skills/orchestration/scripts/install-global.sh --backup-existing
```

Start a new session after installation. Invoke it as `$orchestration` in Codex or `/orchestration` in Claude Code.

Both global skill paths point to the same Git clone:

- `~/.codex/skills/orchestration`
- `~/.claude/skills/orchestration`

Update every runtime with one command:

```bash
git -C ~/.local/share/orchestration-skill pull --ff-only
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

## What “initialize as orchestrator” means

The invoking session becomes the unique control plane and immediately resolves project law, ground truth, state, decision tier, and advisor availability. Independent advisor sessions are then launched as needed.

A skill cannot retroactively change the actual model or effort of an already-running host session, disable provider safeguards, or prove model identity from a prompt label. It records the current session model/effort as observed or unknown and verifies every external advisor from response/session metadata.
