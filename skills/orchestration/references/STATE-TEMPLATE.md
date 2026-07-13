# Orchestrator state template

```markdown
# Orchestrator state

> Updated: <UTC timestamp>
> Nature: last verified checkpoint, not permanent truth

## Control plane
- Session/thread:
- Objective:
- Orchestrator lane (observed or unknown):
- Applicable authority and hard prohibitions:

## VERIFIED
- Repo/root/branch/HEAD:
- PR/current-head CI:
- Deployment/external state:
- Dirty worktrees/user assets:

## Plan and decisions
- Current phase:
- Settled decisions:
- Awaiting user:
- Unknown:

## Active work
- Worker / lane / scope / branch or worktree / acceptance / last evidence:

## Exceptional cross-family reviews
- Decision / reviewer lane / evidence path / outcome:

## Recovery next step
1. Revalidate mutable facts.
2. Protect dirty or unowned work.
3. Resume only from current evidence.
```

Do not put secrets, credentials, full prompts, or large transcripts in the state file. Store bulky proof outside the repo and record only durable paths plus hashes.
