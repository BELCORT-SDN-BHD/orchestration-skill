# Advisor protocol

Read this before the first advisor call in each orchestration session.

## Evidence pack

First-round advisor input contains only:

1. the user's exact decision and desired outcome;
2. applicable user/repository law;
3. raw current evidence with paths, SHA/PR/test facts, timestamps, and unknowns;
4. real options and consequences;
5. the requested output: independent answer, adversarial attack, hidden risks, confidence, and missing evidence.

Do not include the control-plane recommendation, another advisor answer, or a desired verdict. A second round may reveal the control-plane thesis only after the independent memo is complete. Put the decision and real options before implementation status, say explicitly that reversal is acceptable, and remove credentials, tokens, `.env` contents, private keys, secret-bearing logs, and hidden reasoning.

## Fable 5 Max

Use a new session. Default to a tool-less memo over the complete redacted evidence pack. A representative Claude Code launch is:

```bash
claude -p --model fable --effort max \
  --output-format stream-json --verbose --disable-slash-commands \
  --tools "" \
  < "$PROMPT_FILE" > "$EVENTS_FILE" 2> "$ERR_FILE"
```

If the installed client cannot stream, use its structured JSON mode and monitor the durable transcript without reading hidden reasoning. If the advisor needs repository facts not safe to embed, use a separately fenced read-only evidence worker and add only redacted excerpts to a new evidence pack; do not grant the advisor repo-wide access. An automatic safety fallback to Opus ends Fable provenance for that answer.

## Independent Sol Ultra

Use a new ephemeral session, ignore personal model defaults when supported, and enforce a read-only sandbox. Verify the exact local model slug before invocation. Run from an evidence-only directory, not an unredacted repository or home directory. A representative Codex launch is:

```bash
codex exec --ignore-user-config --ephemeral --sandbox read-only \
  --model gpt-5.6-sol --config 'model_reasoning_effort="ultra"' \
  --json --cd "$EVIDENCE_DIR" - \
  < "$PROMPT_FILE" > "$EVENTS_FILE" 2> "$ERR_FILE"
```

The invoking control-plane session is never reused or resumed as this advisor. The evidence directory contains only the redacted packet and explicitly safe attachments. If the runtime does not expose that model/effort, record observed model/effort as `unknown`; do not silently substitute a smaller model for Tier 1.

## Liveness

- Capacity/refusal/auth error: terminal immediately.
- No new structured event or transcript record for five continuous minutes: terminate gracefully and mark `incomplete: no progress`.
- Default total wall: twenty minutes. Predeclare a longer budget in the state ledger before launch.
- UI spinner, process existence, and CPU alone are not completion evidence.
- Stop only the exact process/session created by this work; never kill unrelated user tasks.

## Provenance record

Record for every attempt:

- advisor role and decision tier;
- prompt/evidence SHA-256;
- requested model and effort;
- observed response model and applied effort, or `unknown`;
- session/thread ID and durable response/transcript path;
- start, last-progress, end timestamps;
- fallback/refusal/capacity events;
- final completion state and output SHA-256.

Allowed labels:

- `Fable 5 verified, complete`
- `independent Sol Ultra verified, complete`
- `fallback: <actual model>`
- `advisor unavailable: <reason>`
- `advisor incomplete: <reason>`
- `advisor provenance unknown`

Never let a model self-report its identity as proof. Do not make a paid/usage-metered advisor call without the authority required by the user/project.
