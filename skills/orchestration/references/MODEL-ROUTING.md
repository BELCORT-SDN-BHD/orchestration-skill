# Model routing — the single binding table

Model names live only in this file and in `scripts/advisor.sh` (`tests/` may use stub fixtures). Bindings verified on 2026-07-11 against claude CLI 2.1.206 and codex CLI 0.144.0; rerun `scripts/preflight.sh` when in doubt. Prices are $/MTok input/output, standard tier, July 2026.

## Advisors (the brain — user picks one at init, the other is fallback)

| Lane key | Model | Effort | Price | Launch |
|---|---|---|---|---|
| `fable` | Claude Fable 5 | `max` | $10 / $50 | `scripts/advisor.sh fable <prompt> <out-dir>` |
| `sol` | GPT-5.6 Sol | `ultra` | $5 / $30 | `scripts/advisor.sh sol <prompt> <out-dir>` |

## Workers (the hands)

Defaults are Claude-native; the GPT lane is a deliberate alternate with a stated trigger, not an equal column. Decided 2026-07-11 (GPT-5.6 was 2 days post-GA) — **re-evaluate ~2026-08-15**, and re-run the Standard-lane math on 2026-09-01 when Sonnet 5 intro pricing ends.

| Lane | Task classes | Default | Alternate — use when |
|---|---|---|---|
| Heavy | hard implementation, cross-file refactors, subtle debugging | Opus 4.8, effort `high` (`xhigh` when high-consequence) — $5/$25 | `gpt-5.6-sol` `high` ($5/$30) — the task is terminal/CLI-shaped (builds, env wrangling, long command loops), or a long run's token bill matters |
| Standard | bounded implementation, tests, scoped fixes, research synthesis | Sonnet 5, `high` — intro $2/$10 through 2026-08-31, then $3/$15 | `gpt-5.6-terra` `high` ($2.50/$15) — named challenger; promote if independent repo-level data confirms parity after intro pricing ends |
| Light | formatting, inventory, extraction, URL checks, short summaries, classification | Haiku 4.5 — $1/$5 | `gpt-5.6-luna` `low` ($1/$6) — terminal-shaped light tasks only; never long-context extraction (Luna MRCR recall 41.3% vs Terra 89.6%) |
| Search | read-only repo/web sweeps | Explore subagent (pin `model: haiku` for simple lookups) | — |

Why these defaults (evidence as of 2026-07-11):

- **Repo-level coding still favors Claude** — on SWE-bench Pro, OpenAI's own launch table has Sol 64.6% vs Opus 4.8 69.2% (Sonnet 5 63.2 ≈ Terra 63.4). Prior generation showed the same split (Opus 4.7 64.3 vs GPT-5.5 58.6).
- **Terminal-style execution favors GPT-5.6 at every tier** (Terminal-Bench 2.1: 88.8/87.4/84.7 vs Opus ~74-79) — hence the terminal-shaped trigger, discounted ~5 points for harness effects.
- **GPT-5.6's real edge is efficiency**: independent AA data shows ~54% fewer output tokens and ~57% less wall-clock per task (Sol ≈ $1.04/task vs Opus ≈ $1.99) — why Sol is the cost escape valve on long Heavy runs.
- **Integration tax breaks ties**: native subagents keep the repo-context cache warm across calls; every `codex exec` shell-out re-ships context at full input price. Ties go Claude-native; only Heavy-lane runs amortize the shell-out.
- Independent post-GA evidence is 2 days old (one AA index, no practitioner track record) — challenger slots, not default flips.

**Codebase mapping** (understand-the-repo): the one shape that fans out wide — split by subsystem, one read-only worker each (inventory sweeps on the Search lane, judgment-adjacent module reads on the Standard lane), every work order demanding the same structured map (entry points, data flow, dependencies, conventions, risks). The orchestrator synthesizes the full picture into the state file. A cheap reader can summarize away exactly what matters: any conclusion the map will drive — refactor direction, architecture verdict, audit finding — still goes through the advisor, which spot-checks the key files itself.

Mapping quality escalates by layer, not by defaulting to a flagship reader: core or subtle modules (concurrency, security-critical, dense abstractions) read on the Heavy lane; the user saying "audit-grade" raises all module reads to Heavy; a user-named reader always wins. Reader effort caps at `high` — deeper reasoning buys nothing on coverage reads, and `ultra` on the GPT lane is a multi-agent mode, wrong for a bounded reader.

**Inside Claude Code**, run Claude-family workers as native subagents — the Agent/Task tool takes `model:` (`sonnet`/`haiku`/`opus`), `effort:`, `maxTurns`, and `isolation: worktree`, and provenance comes with the transcript. Shell out only for GPT-family workers or deliberate cross-family review.

**Permissions must match the work order.** Read-only lanes get read-only sessions; implementation lanes need write access, or the worker silently produces prose instead of edits:

```bash
# GPT research worker: fresh, read-only
codex exec --ignore-user-config --skip-git-repo-check --sandbox read-only \
  -m gpt-5.6-luna -c model_reasoning_effort=low --json \
  -o worker-out.md - < work-order.md

# GPT implementation worker: may write inside the workspace
codex exec --ignore-user-config --skip-git-repo-check --sandbox workspace-write \
  -m gpt-5.6-terra --json -o worker-out.md - < work-order.md

# Claude worker from a non-Claude-Code control plane:
#   read-only research  -> --permission-mode dontAsk
#   implementation      -> --permission-mode acceptEdits
#                          (+ scoped --allowedTools "Bash(npm test:*)" as needed)
claude -p --model sonnet --effort high --permission-mode acceptEdits \
  --disable-slash-commands --max-budget-usd 2 --output-format json \
  < work-order.md > worker-out.json
```

## Evidence behind the SKILL.md §4 non-negotiables

Citations only — the operative rules live in SKILL.md §4.

- Planning/judgment never routes down: PEAR, arXiv 2510.07505; AgentCARD, arXiv 2606.20629.
- The advisor gate pays for itself: claude.com/blog/the-advisor-strategy.
- Verifier ≥ author tier: arXiv 2606.28050.
- Work-order discipline beats bigger workers: MAST, arXiv 2503.13657 (~79% of multi-agent failures are specification/coordination, not model capability).
- Coding parallelizes poorly; research fans out safely: anthropic.com/engineering/multi-agent-research-system.
