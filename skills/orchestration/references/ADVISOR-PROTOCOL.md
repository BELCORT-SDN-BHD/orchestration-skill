# Advisor protocol

`scripts/advisor.sh` owns the mechanics — launch flags, sandboxing, liveness, provenance capture. Its stall and wall thresholds are constants at the top of the script (printed by its usage text); pass wall minutes as the fourth argument to extend a consult, and predeclare that in the state ledger. This file defines what you feed it and what counts as a valid outcome.

## Evidence pack (the prompt file)

Open every pack with: "You are a read-only advisor. Answer directly in one memo; do not invoke skills, spawn agents, or delegate." (The codex lane cannot unload installed skills — this line is the guard.)

Then:

1. The user's exact words for the decision and the desired outcome.
2. Applicable user/repository law.
3. Raw evidence: paths, SHAs, test/CI facts, timestamps, unknowns.
4. Real options with consequences.
5. The ask: independent recommendation, hidden risks, missing evidence, confidence.

Round one never contains your recommendation or another advisor's answer. A second round may reveal your thesis — label it round two. Never interpolate user content into shell commands; the prompt travels as a file.

## Outcomes

`advisor.sh` classifies every run as `complete`, `unavailable` (capacity/refusal/auth — terminal, do not retry), or `incomplete: <reason>` (no progress, wall, empty output, failed run).

- `complete` → cite `memo.md`; record `provenance.json` in the state ledger.
- Anything else → run the fallback advisor once and label its memo `fallback: <model>`; report the substitution in the next user update, and never present fallback output as the primary advisor's. If the fallback also fails, the decision goes to the user. Never shop for a third opinion.

## Provenance

`provenance.json` records requested vs observed model/effort, session/thread id, prompt and output SHA-256, timestamps, and final status. The claude lane reads the observed model from the CLI's JSON result metadata; observed effort is not exposed there, so `observed_effort: unknown` is expected on that lane, not a provenance failure. The sol lane reads model and effort from the codex rollout file under the codex home — which is why `advisor.sh` never passes `--ephemeral`. A model's self-identification in its own prose is never proof. Do not make a paid advisor call without the authority the user/project requires.
