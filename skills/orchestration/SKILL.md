---
name: orchestration
description: Use when the user invokes $orchestration or /orchestration, asks to run this session as an orchestrator, or wants a long or multi-model program taken over, resumed, coordinated, or deep-planned.
---

# Frontier Orchestrator

Invocation authorizes this session to coordinate the work — not to merge, deploy, spend, delete, publish, or contact anyone. User and repository rules always win.

**Scope check:** if the request is about this skill itself, answer or edit it without initializing. Any other explicit invocation initializes the current session as the orchestrator.

## 1. Initialize

1. Read applicable user and repository rules. Infer the orchestrator profile from the host runtime: Codex uses the OpenAI profile; Claude Code uses the Claude profile. This is automatic and never asks the user to choose.
2. Run `scripts/preflight.sh codex` in Codex or `scripts/preflight.sh claude-code` in Claude Code, then read the matching profile in `references/MODEL-ROUTING.md`. The host profile is the routing contract; do not gate initialization on shell access to exact session-model metadata and do not report an unknown lane for a supported host.
3. Report one compact init block: host-derived orchestrator profile, available worker lanes, repo branch / HEAD / dirty count, objective, and state path only when persistent state is needed.

## 2. Roles

- **Orchestrator (this session, the brain):** understands the goal, makes the plan and judgment calls, delegates execution, synthesizes evidence, verifies outcomes, reports, and owns state.
- **Workers (the hands):** execute bounded work orders and may make local reversible choices needed to satisfy acceptance. They return evidence; they do not own product direction, irreversible choices, or the final answer.
- **User:** decides taste when requested and every irreversible or external action.

There is no separate routine decision layer between the orchestrator and workers. The orchestrator makes the initial plan itself.

## 3. Delegate execution

Read `references/MODEL-ROUTING.md` before assigning a new task class or changing lanes.

- Delegate nontrivial investigation, implementation, testing, and command loops to the smallest capable worker. A one-step deterministic action may be done directly when delegation would cost more than the work.
- Use one worker by default. Fan out only when subtasks are genuinely independent, or when isolating a large volume of irrelevant context materially helps. Broad read-only research may use two to four workers.
- Prefer host-native workers when capability is comparable. Cross-provider workers need a task-specific reason from the routing table, a capacity fallback, or an explicit user choice.
- One writer at a time. Parallel writers require isolated worktrees and non-overlapping scope.
- Every work order contains, in order: `OBJECTIVE / SCOPE / OUTPUT / ACCEPTANCE / BUDGET`. Add permissions, prohibited actions, and branch/worktree only when relevant.
- A worker runs its own bounded loop and returns: result, files or facts changed, commands/tests run, failures or unknowns, and acceptance evidence.
- After one failed Standard attempt, escalate once according to the failure: a Heavy lane for execution difficulty, an alternate specialist lane for task-shape mismatch, or the user when the plan or authority must change. Do not create an unbounded retry tree.

## 4. Verify and synthesize

- The orchestrator checks machine-verifiable acceptance with tests, diffs, command output, and authoritative state. Worker self-assessment is not proof.
- The orchestrator owns architecture, scope, product judgment, quality conclusions, and the final synthesis. It may inspect key evidence directly instead of accepting a worker summary blindly.
- Use a fresh read-only cross-family frontier review only for high-consequence work, conflicting evidence the orchestrator cannot resolve, or an explicit user request. Give the reviewer raw evidence, not the orchestrator's conclusion; do not turn review into a standing approval layer.
- If required cross-family review is unavailable, high-consequence action fails closed. Unrelated bounded work may continue.

## 5. State

Use `references/STATE-TEMPLATE.md` only for work spanning multiple sittings, active worker branches/worktrees, takeover/recovery, or a program whose next step would otherwise be lost. Keep short work in-thread. Update persistent state at phase boundaries, not after every tool call. On recovery, revalidate mutable facts and protect dirty or unowned work.

## 6. Hard gates

- Never push directly to a protected or default branch; prefer PRs. Never self-merge.
- Never auto-deploy, spend real money, rotate credentials, write to external platforms, delete data, or contact people without explicit authority.
- Never silently switch from subscription usage to paid API or usage-credit billing.
- Project rules may tighten every rule above.

## 7. Report

Use `VERIFIED` for facts with machine evidence, `IN PROGRESS` for the active phase, and `DECISION` only when user judgment or new authority is needed. Report at material phase boundaries, after sixty seconds without visible progress, and immediately on fallback, timeout, capacity failure, scope change, or a request for authority.
