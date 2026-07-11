# Orchestrator state template

```markdown
# Orchestrator state

> Updated: <ISO timestamp and timezone>
> Nature: last verified checkpoint, not permanent truth

## Control plane
- Session/thread:
- Claim epoch / claimed at / last heartbeat:
- Supersedes (session + evidence), or none:
- Shared-state scope (same machine / cross-machine / unknown):
- Actual model/effort (or unknown):
- Loaded global skill path / version / SHA-256 / source commit:
- Loaded project overlay paths:
- Objective:
- Applicable authority and hard prohibitions:

## VERIFIED
- Repo/root/branch/HEAD:
- PR/current-head CI:
- Deployment/external state:
- Dirty worktrees/user assets:

## Advisor proofs
- Decision/tier:
- Requested / observed model and effort:
- Session/transcript/output/hash:
- Completion/fallback:

## IN PROGRESS
- Worker / model / scope / branch / acceptance / last evidence:

## DECISIONS
- Settled:
- Awaiting user:
- Unknown:

## Recovery next step
1. Revalidate mutable facts.
2. Protect dirty/unowned work.
3. Resume only from current evidence.
```

Do not put secrets, raw credentials, hidden reasoning, or large transcripts in the state file. Store bulky proof outside the repo or in the project's approved artifact location and record only durable paths plus hashes.
