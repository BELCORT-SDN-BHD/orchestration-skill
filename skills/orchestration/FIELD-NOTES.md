# Field notes — verified mechanics

Verified 2026-07-26 against local binaries, official docs, and vendor
source. Everything here is perishable: when a note conflicts with the
live system, the live system wins. Re-verify ~2026-08-15 (gpt-5.6
lanes, Codex CLI) and 2026-09-01 (Sonnet introductory pricing ends).

## Tier map

| Tier | Claude Code | Codex |
|---|---|---|
| Orchestrator-only | Fable 5 | — (Sol orchestrates and works) |
| Strongest worker | `opus` | `gpt-5.6-sol` |
| One tier down | `sonnet` | `gpt-5.6-terra` |
| Cheapest | `haiku` (last-gen: no adaptive thinking, 200k ctx) | `gpt-5.6-luna` |
| Judge (cross-vendor) | sealed `codex exec` | hermetic `claude -p` |

Pricing snapshot ($/MTok in-out): fable 10/50, opus 5/25, sonnet 2/10
(3/15 after 2026-08-31), haiku 1/5; sol 5/30, terra 2.5/15, luna 1/6.

## Claude Code (v2.1.220)

- The Agent tool has `model` but NO effort parameter; workers inherit
  the session effort (settings `effortLevel: xhigh` means workers run
  xhigh; haiku ignores effort). Real per-worker effort control:
  Workflow `agent()` (`opts.model` + `opts.effort`) and subagent-file
  frontmatter.
- Pass `model` on every dispatch — an omitted model runs at session
  (Fable) rate. `CLAUDE_CODE_SUBAGENT_MODEL` silently overrides ALL
  subagent routing; keep it unset.
- `run_in_background: false` — background subagents lose most built-in
  tools.
- Flat topology is enforced via settings env
  `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH=1` (set 2026-07-26); the
  harness default is remote-gated (fallback 3) — never trust it.
- Forks always inherit the parent model: from a Fable session a fork
  is a Fable worker — forbidden. The built-in Explore agent inherits
  the session model.
- Limits are ceilings, not targets: 20 concurrent, 200 spawns per
  session; workflows 16 concurrent, guideline under 15 agents.
  `opusplan` is a session-model alias — the user's choice only. Agent
  teams: experimental peer sessions — watched, not adopted.
- Judge dispatch: `codex exec --ephemeral --ignore-user-config
  -s read-only -m gpt-5.6-sol -c model_reasoning_effort=xhigh`.
  Plugin lanes (`/codex:review`, `codex:codex-rescue`) are
  write-capable — rescue only, and the dispatch must still say
  read-only when reviewing.

## Codex CLI (>= 0.145.0; upgraded 2026-07-26)

- Native fleet: `spawn_agent` / `wait_agent` / `followup_task` /
  `close_agent`. Per-spawn `model` + `reasoning_effort` need >=
  0.145.0 (earlier versions: API 400).
- Leave `[agents] default_subagent_model` unset — plain spawns then
  inherit Sol; a configured default reroutes every unlabelled spawn to
  the cheap model, the dangerous direction.
- Selecting a `model` on a spawn RESETS effort to that model's default
  unless `reasoning_effort` is passed too — on terra/luna lanes pass
  both. Thinking spawns: pass effort `high` (Sol's own default is low;
  low has the silent-loss failure mode). `ultra` = auto-delegation —
  never combine with a manual fleet.
- Model overrides ride with `fork_turns: "none"` — the worker starts
  context-free, so the prompt must be self-contained.
- Results arrive as FINAL_ANSWER messages; `wait_agent` returns no
  content; native spawns have no output schema — spell the output
  shape in the prompt, write files for verification.
- Spawns inherit sandbox/cwd: give parallel editors disjoint write
  sets; research spawns need
  `sandbox_workspace_write.network_access=true`; v2 has NO depth
  config — the prompt clause is the only nesting guard. `codex exec`
  forces approval `never`.

## Hermetic `claude -p` workers (from Codex)

Explicit `--effort` is part of the seal (ambient settings otherwise
leak in); `--disallowed-tools Task` keeps topology flat. `dontAsk`
denies un-pre-approved tools but pre-allowed ones still run — only a
deny list is a hard guarantee.

```bash
# judge (read-only enforced)
claude -p --model opus --effort xhigh --permission-mode dontAsk \
  --strict-mcp-config --settings '{"disableAllHooks":true}' \
  --disallowed-tools Write Edit NotebookEdit Bash WebFetch WebSearch Task \
  --output-format json < work-order.md > worker-out.json

# coverage (one tier down)
claude -p --model sonnet --effort high --permission-mode dontAsk \
  --strict-mcp-config --settings '{"disableAllHooks":true}' \
  --disallowed-tools Task \
  --output-format json < work-order.md > worker-out.json
```

## Coverage-lane guardrails (Anthropic coordinator cookbook)

Chunk granularity has an optimum — finer splitting can raise cost.
Verify the decomposition itself with one worker (the cookbook's own
decomposition was wrong and nothing caught it). Verify results with a
stronger worker — same-tier verifiers share blind spots. Cheap readers
summarize away nuance silently; that failure never stalls.

## Config hardening applied 2026-07-26

- `~/.claude/settings.json` env:
  `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH=1`.
- `~/.codex/config.toml`: `[agents]
  max_concurrent_threads_per_session = 8`; subagent model/effort
  defaults deliberately unset.
- Codex CLI upgraded to 0.145.x via npm.
