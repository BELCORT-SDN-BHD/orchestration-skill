# Orchestration skill repository rules

## Agent install contract

If a user provides this repository URL without a narrower request, follow the
README Install flow through `GLOBAL_ORCHESTRATION_POLICY=ready` and
`AUTO_UPDATE=ready`. Inspect the repository and installer first. Do not stop
after explaining, planning, or cloning. Verify both host registrations and
the background updater, asking for any required permission and continuing
afterward. Continue until verification passes or a concrete permission or
environment blocker remains. A narrower user request wins.

## Repository governance

1. All changes land through a pull request; never push directly to `main` or self-merge.
2. Keep the runtime policy in `skills/orchestration/SKILL.md` minimal. Do not add routing frameworks, state machines, or standing review layers unless the founder explicitly requests them.
3. Changes to the runtime policy, installation behavior, or this governance file are founder-only. The author or material editor may not merge them.
4. Before handoff, run `python3 tests/validate_skill.py`, `bash tests/smoke.sh`, and `bash tests/update-smoke.sh`, then review the exact diff.
5. Never add credentials, tokens, private transcripts, hidden reasoning, paid verification calls, or automatic external publication.
