# Orchestrator state template

```markdown
# Orchestrator state

> Updated: <UTC timestamp — `date -u +%Y-%m-%dT%H:%M:%SZ`>
> Nature: last verified checkpoint, not permanent truth

## Control plane
- Session/thread:
- Objective:
- Advisor (chosen / fallback):
- Applicable authority and hard prohibitions:

## VERIFIED
- Repo/root/branch/HEAD:
- PR/current-head CI:
- Deployment/external state:
- Dirty worktrees/user assets:

## Advisor consults
- Decision → memo path, provenance.json path, status:

## IN PROGRESS
- Worker / lane / scope / branch / acceptance / last evidence:

## DECISIONS
- Settled:
- Awaiting user:
- Unknown:

## Recovery next step
1. Revalidate mutable facts.
2. Protect dirty/unowned work.
3. Resume only from current evidence.
```

Do not put secrets, raw credentials, or large transcripts in the state file. Store bulky proof outside the repo and record only durable paths plus hashes.
