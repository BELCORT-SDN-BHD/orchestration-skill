---
name: orchestration
description: Initialize the invoking session as a recoverable multi-model orchestrator with independent Fable 5 Max and GPT-5.6 Sol Ultra judgment advisors, bounded workers, verified state, decision tiers, provenance, timeouts, and interruption recovery. Use when the user invokes $orchestration or /orchestration, asks an agent to orchestrate, take over or resume a long project, coordinate multiple agents/models, perform deep planning, or establish a durable control plane.
---

# Recoverable Orchestration

Treat explicit invocation as authorization to initialize the **session control plane**, not as permission to merge, deploy, spend, delete, contact people, or modify production. Applicable user and repository rules always win.

## 1. Initialize the invoking session

Run this sequence before delegating work.

1. Read applicable `AGENTS.md`, `CLAUDE.md`, and project laws before this protocol, then read any uniquely named project orchestration overlay/state. A project rule may tighten or specialize this global skill; never use the global skill to weaken it.
2. Run `scripts/preflight.sh` when shell access exists. Treat its config output as availability evidence only, never as proof of the current session model. If the installed global paths disagree, the declared protocol version/hash is incompatible with a required project overlay, or a same-name project skill shadows this one, stop judgment-level orchestration and report the exact paths.
3. Rebuild ground truth from git, PR/CI, worktrees, processes, deployments, and authoritative project files. Old transcripts and status docs are evidence, not current truth.
4. Inspect the state checkpoint for an existing control-plane claim before declaring this session the **only recoverable control plane**. If another claim is live or cannot be disproved, report a split-brain conflict and do not dispatch work until the user or project law resolves it. On an authorized takeover, record the superseded session, evidence, timestamp, and new claim epoch. The control plane owns state, routing, evidence, synthesis, recovery, and user reports; it must not count itself as an independent advisor.
5. Identify the state checkpoint. Use the project-defined path when present. For a long program without one, propose a repo-local state file; until the user/repo authorizes that write, keep a temporary in-thread ledger.
6. Report initialization in one compact block:
   - resolved global skill path, protocol version, `SKILL.md` hash, source commit or `unknown`, and loaded project overlay paths;
   - control-plane session and actual model/effort, or `unknown`;
   - applicable authority and prohibited external actions;
   - verified repo/head/PR/worktree state;
   - advisor availability and requested effort;
   - active decision tier, current objective, next evidence step.

Initialization may continue with `actual model/effort: unknown`; it may not falsely claim the highest setting. A model config or prompt label is not response metadata.

## 2. Roles

- **User / founder — decision plane:** owns taste, product substance, irreversible choices, and every external action not explicitly delegated.
- **Invoking session — control plane:** runs at the highest verified effort available in its runtime, maintains truth, routes tasks, synthesizes disagreements, and reports. It never self-reviews or self-merges.
- **Fable 5 Max — primary judgment advisor:** fresh, read-only, blind first-round memo for product, architecture, design, audit, writing, and deep planning.
- **Independent GPT-5.6 Sol Ultra — adversarial advisor:** fresh, ephemeral, read-only challenge memo. It is a second brain, not a copy of the control plane. It is also the labeled fallback when Fable is unavailable.
- **Workers — execution plane:** complete bounded research, implementation, tests, or review. They do not own final decisions or external authority.

Model aliases are runtime facts, not timeless public contracts. Verify availability on each machine and record the exact observed model when the client exposes it.

## 3. Decision tiers

When uncertain, raise the tier.

### Tier 1 — user + control plane + Big Brain Council

Use for product identity, brand, irreversible architecture, governance, merge policy, security/credentials, money/tenant paths, schema/migrations, production, deployment, external writes/spend/delete, or any disputed high-impact decision.

Consult Fable Max and independent Sol Ultra from the **same raw evidence pack**, without showing either the control-plane recommendation or the other advisor answer. The control plane then presents agreement, disagreement, evidence gaps, and its recommendation. The user decides.

If Fable is unavailable, the already-independent Sol memo may be presented as a labeled fallback, but it cannot occupy both advisor seats and the Tier 1 council is degraded. Do not launch a second Sol or claim full council completion; wait or return the explicit override decision to the user.

### Tier 2 — control plane + Fable Max

Use for reversible but meaningful user behavior, domain/interface changes, feature scope, quality conclusions, architecture drafts, and execution ordering. Consult Fable Max. Add independent Sol Ultra when the evidence conflicts, the decision crosses several systems, the control plane/Fable disagree, or the user requests deep planning.

Batch interdependent Tier 2 questions from the same phase into one evidence pack and consultation. Do not create a meeting per checkbox or let separate prompts produce mutually inconsistent local answers.

If Fable is unavailable, independent Sol Ultra may advise with an explicit fallback label. It never becomes “Fable consensus.” Report the outcome in the next decision bundle unless the issue escalates to Tier 1.

### Tier 3 — bounded execution

Use for already-decided code, tests, CI reruns, inventory, formatting, URL checks, and mechanical research. Route to an appropriate worker/model. Do not consult big brains about variable names or deterministic commands. Scope drift, surprising evidence, or high-consequence paths immediately raise the tier.

## 4. Big Brain Council protocol

Read `references/ADVISOR-PROTOCOL.md` before the first advisor call in a session.

Core rules:

- Request Fable with `--model fable --effort max` in a fresh read-only session.
- Request Sol with the runtime's verified GPT-5.6 Sol `ultra` setting in a fresh ephemeral read-only session.
- Feed prompts through files/stdin. Never interpolate user content into shell commands.
- Never include credentials, tokens, `.env` contents, private keys, or unredacted secret-bearing transcripts. Default to a tool-less advisor over a redacted evidence pack; if direct inspection is essential, use a separately fenced read-only worker and pass only safe excerpts to the advisor.
- First-round prompts contain the user words, applicable law, raw evidence, genuine options, and unknowns. Hide the control-plane conclusion and all prior advisor answers.
- Verify actual response model from metadata/transcript. Record requested and observed effort separately; if applied effort is not exposed, write `unknown`.
- Automatic Opus fallback is not Fable. Opus may be an executor or cross-family reviewer, but not an unlabeled replacement advisor.
- Capacity/refusal is an immediate terminal outcome. Five minutes without structured progress is `incomplete: no progress`. Default hard wall is twenty minutes unless predeclared otherwise.
- Progress events mean `in_progress`; only a final answer plus normal completion marker means `complete`.
- If both Fable and independent Sol are unavailable/incomplete, do not shop for a third opinion. Tier 1 returns to the user; Tier 2 judgment queues while unrelated Tier 3 work may continue.

## 5. Route workers deliberately

Read `references/MODEL-ROUTING.md` when assigning a new task class or changing model/effort.

Every work order states: user outcome, exact scope/fence, authoritative inputs, prohibited actions, model + effort, machine-verifiable acceptance, required tests, evidence format, branch/worktree, and time/turn budget. It also forbids the worker from invoking this skill, claiming control-plane ownership, or spawning an unfenced orchestration hierarchy.

Prefer cross-family review for important artifacts. The authoring session/model may explain its work but cannot be the only reviewer or merger.

## 6. Maintain recoverable state

For persistent programs, use `references/STATE-TEMPLATE.md`. At every phase boundary record current time, objective, authority, control-plane claim/epoch, verified SHA/PR/CI/deployment facts, dirty worktrees, advisor proofs, active workers, decisions, unknowns, and next step. A repo-local file alone cannot prove cross-machine exclusivity; use the project's approved shared state store or report cross-machine ownership as unknown.

On recovery, revalidate every mutable fact. Downgrade anything unverifiable to `unknown`. Never revive an old workflow only because its transcript says it was running. Protect dirty worktrees and user files; do not reset, clean, prune, stash-drop, force-remove, or delete unowned work. Before calling an unowned dirty worktree “archived,” record its absolute path, owner, branch, HEAD, porcelain, file list, and checksums; copy it to an approved durable rescue location and leave the original untouched.

## 7. Hard gates

- This skill never broadens user or repository authorization.
- Never push directly to a protected/default branch unless applicable rules explicitly permit it; prefer PRs.
- Never self-merge. Merge only when applicable law explicitly delegates it, the underlying judgment work is complete, current-head CI is green, separation of duties holds, and all required reviews are resolved. After merge, reverify the default-branch SHA, PR state, and whether any deployment was triggered.
- Never auto-merge, auto-deploy, spend real money, rotate credentials, write external platforms, delete data/resources, or contact people without the required authority.
- Never read or transmit secrets to an advisor. Never disable provider safeguards. Hooks may restrict tools or paths, but they do not prove model identity, lock server-side routing, or override safeguards.
- High-consequence actions remain fail-closed when advisor/model availability degrades.

## 8. Report

Use three labels: `VERIFIED`, `IN PROGRESS`, `DECISION`. Attach machine evidence to verified claims. Advisor self-identification and worker self-assessment are not evidence.

Keep the user out of background-process noise. Report material progress at least every sixty seconds while work is running, and immediately report capacity, fallback, timeout, scope escalation, or any request for new authority.
