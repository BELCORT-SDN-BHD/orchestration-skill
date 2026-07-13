# Model routing — frontier orchestrators and bounded workers

Model names live only in this file. Bindings were last reviewed on 2026-07-13 against Claude Code and Codex subscription workflows. Re-run `scripts/preflight.sh` after CLI upgrades. Optimize for accepted-task quality, wall time, quota/credit use, and runtime locality — not API list price alone.

## Orchestrators — the brain in the main loop

The host runtime selects the profile automatically: Codex uses `sol-orchestrator`; Claude Code uses `fable-orchestrator`. The user never chooses a lane during initialization. The orchestrator plans, delegates, synthesizes, and decides; it should avoid long token-heavy execution loops that a worker can own.

| Lane | Model / effort | Prefer when |
|---|---|---|
| `fable-orchestrator` | Claude Fable 5, `xhigh` | repo understanding, product and design judgment, architecture, cross-file synthesis |
| `sol-orchestrator` | GPT-5.6 Sol, `max` | terminal/CLI-heavy programs, environment and build strategy, long command-oriented coordination |

These are host profiles, not a claim that a shell subprocess has independently proven server-side model identity. If the user manually overrides the host model, the runtime still keeps its host profile unless the user explicitly requests different routing.

## Workers — the hands

| Lane | Model / effort | Default tasks |
|---|---|---|
| `claude-light` | Haiku 4.5 | inventory, extraction, formatting, URL checks, short summaries |
| `claude-standard` | Sonnet 5, `high` | bounded repo implementation, tests, scoped fixes, research synthesis |
| `claude-heavy` | Opus 4.8, `high` | hard implementation, subtle debugging, cross-file refactors after a Standard failure |
| `openai-light` | GPT-5.6 Luna, `low` | terminal-shaped lookups, classification, small deterministic commands |
| `openai-standard` | GPT-5.6 Terra, `high` | terminal/build loops, bounded implementation, environment work, tests |
| `openai-heavy` | GPT-5.6 Sol, `high` | hard terminal/CLI execution, long command loops, difficult debugging after a Standard failure |

## Host profiles

### Fable orchestrator

- Default repo worker: `claude-standard`.
- Default terminal/build worker: `openai-standard` when the task is materially command-shaped; otherwise stay native.
- Light work: `claude-light`; use `openai-light` only for terminal-shaped work or Claude capacity fallback.
- Heavy escalation: `claude-heavy` for repo/coding difficulty; `openai-heavy` for terminal/environment difficulty.

### Sol orchestrator

- Default terminal/build worker: `openai-standard`.
- Default repo worker: `claude-standard` when repo-level context and cross-file coding dominate; otherwise stay native.
- Light work: `openai-light`; use `claude-light` for long-context extraction or OpenAI capacity fallback.
- Heavy escalation: `openai-heavy` for terminal/environment difficulty; `claude-heavy` for repo/coding difficulty.

## Dispatch rules

Runtime locality breaks ties: native workers avoid a cross-provider cold start and repeated context shipment. Cross-provider dispatch is justified only by a named task-shape advantage, provider capacity, a Standard failure, or explicit user direction.

Normal work gets one worker. Use two to four read-only workers only for independent research facets or codebase mapping by non-overlapping subsystem. Coding is usually sequential: keep one writer, or isolate non-overlapping writers in worktrees.

Worker effort stays at the table default. Raise effort only after a failed bounded attempt or when the work order is explicitly high-consequence. Do not use multi-agent effort modes inside a worker; fanout belongs to the orchestrator.

## Launch patterns

Inside Claude Code, use native subagents for Claude-family workers with the required model, effort, `maxTurns`, and worktree isolation. Inside Codex, use native collaboration for OpenAI-family workers when the runtime exposes a suitable lane. Shell out only for the other provider or when native lane selection is unavailable.

```bash
# OpenAI read-only worker
codex exec --ignore-user-config --skip-git-repo-check --sandbox read-only \
  -m gpt-5.6-terra -c model_reasoning_effort=high --json \
  -o worker-out.md - < work-order.md

# OpenAI implementation worker
codex exec --ignore-user-config --skip-git-repo-check --sandbox workspace-write \
  -m gpt-5.6-terra -c model_reasoning_effort=high --json \
  -o worker-out.md - < work-order.md

# Claude read-only worker
claude -p --model sonnet --effort high --permission-mode dontAsk \
  --disable-slash-commands --output-format json \
  < work-order.md > worker-out.json

# Claude implementation worker
claude -p --model sonnet --effort high --permission-mode acceptEdits \
  --disable-slash-commands --output-format json \
  < work-order.md > worker-out.json
```

Match permissions to the work order. Never silently enable API-key billing or usage-credit top-ups.

## Exceptional cross-family review

Review is not part of the normal loop. For security, credentials, migrations, production, irreversible architecture, unresolved conflicting evidence, or an explicit user request, ask the other frontier family for one fresh read-only challenge based on raw evidence. A `fable-orchestrator` uses GPT-5.6 Sol `max`; a `sol-orchestrator` uses Claude Fable 5 `xhigh`. The reviewer does not delegate, write, or replace the orchestrator. If the review disagrees materially, present the disagreement to the user.
