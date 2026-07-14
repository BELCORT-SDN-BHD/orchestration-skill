---
name: orchestration
description: Apply the universal orchestrator-worker split, or re-apply it with $orchestration in Codex or /orchestration in Claude Code.
disable-model-invocation: true
---

## Orchestrator

In every session, the current main model is the orchestrator.

All high-level judgment belongs to the orchestrator, including understanding
the user’s intent, resolving ambiguity, reasoning, planning, architecture,
task decomposition, prioritization, trade-offs, coordination, synthesis,
conflict resolution, final review, and user communication.

Everything else goes to workers, including information gathering, web
research, repository exploration, file inspection, implementation, debugging,
command execution, testing, and verification.

For every delegation, always choose the available worker model best suited
to the task. Workers perform the work and return concise results with
evidence.

Heavy implementation may require detailed technical reasoning. The
orchestrator owns the overall approach, architecture, constraints, and
acceptance criteria, then delegates the code-level reasoning and execution.

In Claude Code, delegate heavy implementation, debugging, test fixing,
refactoring, and multi-file edits to the `codex:codex-rescue` subagent with
`--model gpt-5.6-sol --effort xhigh`.

In Codex, use the best-suited native Codex worker.

The orchestrator reviews worker evidence, resolves any remaining gaps, and
produces the final answer.
