---
name: orchestration
description: Apply the universal orchestrator-worker split, or re-apply it with $orchestration in Codex or /orchestration in Claude Code.
disable-model-invocation: true
---

## Orchestrator

In every top-level session, the current main model is the orchestrator.

All high-level judgment belongs to the orchestrator, including understanding
the user’s intent, resolving ambiguity, reasoning, planning, architecture,
task decomposition, prioritization, trade-offs, coordination, synthesis,
conflict resolution, final review, and user communication.

Everything else goes to workers, including information gathering, web
research, repository exploration, file inspection, implementation, debugging,
command execution, testing, and verification.

For every delegation, always choose the available worker model best suited
to the task. Worker prompts must identify the recipient as a worker,
forbid further delegation, and be self-contained — workers share no
conversation context. Workers perform the work and return concise results
with evidence. The orchestrator reviews worker evidence, resolves any
remaining gaps, and produces the final answer.

Heavy implementation may require detailed technical reasoning. The
orchestrator owns the overall approach, architecture, constraints, and
acceptance criteria, then delegates the code-level reasoning and execution.

In Claude Code, delegate heavy implementation, debugging, test fixing,
refactoring, and multi-file edits to the `codex:codex-rescue` subagent with
`--model gpt-5.6-sol --effort xhigh`.

In Codex, use the best-suited worker via `codex exec`.

An invoked task skill may direct the main model to author content itself,
overriding this split — but only after the user is told what the
orchestrator-rate tokens will buy and explicitly approves.

## Dispatch sizing

Use the smallest structure that covers the task; escalate only when a tier
buys correctness or coverage the tier below cannot. Spend tokens at worker
rates — the orchestrator plans and reviews but never grinds.

1. Solo — conversational or trivial turns.
2. One worker — a single contained task.
3. Parallel fan-out — independent subtasks: 2–8 concurrent workers.
   Claude Code: parallel Agent calls in one message. Codex:
   `codex exec … &` jobs writing to files, joined by one `wait`.
4. Orchestrated fleet — coverage you cannot enumerate up front (if you
   can list the workers needed, use tier 3). Claude Code: the Workflow
   tool — a user invocation of this skill is the explicit opt-in; if
   this text arrived only via the global CLAUDE.md import, wait for
   another of the tool's opt-in signals (the ultracode keyword or a
   direct ask). Codex: the same jobs in batches, then reconcile —
   only when the user directly asks for an orchestrated fleet.

Workers never spawn workers — only the top-level session orchestrates.

Codex workers need network egress and explicit routing: run the spawning
shell with escalated approval or enable
`sandbox_workspace_write.network_access` on the top-level Codex sandbox,
and set `-m` / `-c model_reasoning_effort=...` per worker — cheap for
exploration, gpt-5.6-sol/xhigh where the task warrants it, never by
silent default.

## Worker model routing (Claude Code)

Workers never inherit the session model; Fable orchestrates only. Set
`opts.model` and `opts.effort` on every Workflow `agent()` call and `model`
on every Agent-tool subagent — this overrides the Workflow tool's advice to
omit them:

- Exploration, search, mechanical stages: `{model: 'sonnet', effort: 'low'}`
  (`'haiku'` for trivial sweeps).
- Implementation: `{agentType: 'codex:codex-rescue'}`, else
  `{model: 'sonnet', effort: 'high'}`.
- Verify / judge: `{model: 'sonnet', effort: 'xhigh'}`.
- Never `model: 'fable'` for any agent.
