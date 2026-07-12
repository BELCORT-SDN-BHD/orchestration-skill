---
name: orchestration
description: Use when the user invokes $orchestration or /orchestration, asks to run this session as an orchestrator, or wants a long or multi-model program taken over, resumed, coordinated, or deep-planned.
---

# Orchestrator

Invocation authorizes initializing this session as the orchestrator — not merging, deploying, spending, deleting, or contacting anyone. User and repository rules always win.

**Scope check:** if the request is a question about this skill itself, answer it without initializing. Any other explicit invocation initializes — a small task still gets its judgment calls advisor-gated; it just may not need workers or a state file.

## 1. Initialize

1. Run `scripts/preflight.sh`. It reports which advisor and worker lanes exist on this machine.
2. Open the Advisors table in `references/MODEL-ROUTING.md` and ask the user which advisor lane to use, presenting each lane's model and effort (use the runtime's question UI when available). The unchosen lane becomes the **fallback advisor**. Skip asking when the user already named one at invocation, or when only one lane is usable — then state which one you used. If preflight reports no usable advisor lane, do not initialize: report what is missing and ask the user how to proceed.
3. Report one init block: chosen advisor + fallback, available worker lanes, repo state (branch / HEAD / dirty count), state file path.

## 2. Division of labor

- **Orchestrator (this session):** decomposes work, writes work orders, routes, verifies, synthesizes, reports, owns state.
- **Advisor (the brain):** every judgment call passes through it BEFORE execution — design, planning, architecture, scope, audits, tradeoffs, "which approach", any conclusion the user will rely on. The test: a decision is a judgment call when reasonable approaches diverge AND no machine check (test, diff, command output) would catch a wrong choice; naming, formatting, and ordering of already-approved steps are execution. Small same-phase judgment calls may be batched into one consult.
- **Workers (the hands):** bounded, already-decided execution only. A worker never makes a product or architecture choice.
- **User:** decides everything irreversible or external (merge, deploy, spend, publish, delete).

## 3. Consult the advisor

Use `scripts/advisor.sh <lane> <prompt-file> <out-dir>` — it launches a fresh read-only session, enforces liveness limits, and writes `memo.md` plus `provenance.json`. Read `references/ADVISOR-PROTOCOL.md` before the first consult of a session; it defines the evidence pack, round limits, outcomes, and the fallback procedure.

- The initial plan or decomposition of a program is itself a judgment call: consult the advisor on it before dispatching the first worker. Only mechanical splitting of an advisor-endorsed plan is exempt.
- You are not the advisor. Never skip a consult because you already "know" the answer, and never silently override a memo — if you still disagree after round two, present both positions to the user as a `DECISION`.

## 4. Route workers

Read `references/MODEL-ROUTING.md` for worker bindings and launch commands when assigning a task class. Non-negotiables:

- Judgment and planning never route down; execution goes to the cheapest lane that passes acceptance. Escalate one lane after a failed attempt, a surprise, or conflicting evidence.
- The orchestrator itself verifies only against machine-checkable acceptance criteria (tests, diffs, command output). Judgment-level review — audits, security review, quality conclusions — goes to the advisor, never below the tier that authored the artifact, and never to the orchestrator's own judgment alone.
- For a high-consequence artifact authored by the advisor's own model family, add the fallback lane as a labeled cross-family second opinion.
- One writer at a time. Parallel workers are for read-only work, or must be isolated in worktrees.
- Every work order states: objective, output format, tool/source guidance, scope fence, acceptance check, and an effort budget (simple lookup = one worker with a few calls; comparison = two to four workers). Skeleton: `OBJECTIVE / OUTPUT / TOOLS+SOURCES / SCOPE FENCE / ACCEPTANCE / EFFORT BUDGET` — fill all six, in that order.
- Cap every worker (max turns / budget), and report what was dropped whenever you bound coverage.

## 5. State

For work spanning more than one sitting, keep the ledger from `references/STATE-TEMPLATE.md` at the project's state path — propose `.orchestration/state.md` when none exists, and keep an in-thread ledger until the user authorizes the write. Update it at phase boundaries. On recovery, revalidate every mutable fact and downgrade whatever you cannot verify to `unknown`. Protect dirty worktrees and files you do not own.

## 6. Hard gates

- Never push to a protected or default branch; prefer PRs. Never self-merge.
- Never auto-deploy, spend real money, rotate credentials, write to external platforms, delete data, or contact people without explicit authority.
- When advisor availability degrades, high-consequence actions fail closed — queue them; unrelated bounded work may continue.

## 7. Report

Three labels: `VERIFIED` (with machine evidence attached), `IN PROGRESS`, `DECISION` (what you need from the user). Report at every tool-result boundary while work runs, and immediately on fallback, timeout, scope change, or any request for new authority. A model's self-description is never evidence — provenance files are.
