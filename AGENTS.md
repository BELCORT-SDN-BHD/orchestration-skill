# Orchestration skill repository rules

1. All changes land through a pull request; never push directly to `main` or self-merge.
2. Keep the runtime policy in `skills/orchestration/SKILL.md` minimal. Do not add routing frameworks, state machines, or standing review layers unless the founder explicitly requests them.
3. Changes to the runtime policy, installation behavior, or this governance file are founder-only. The author or material editor may not merge them.
4. Before handoff, run `python3 tests/validate_skill.py` and `bash tests/smoke.sh`, then review the exact diff.
5. Never add credentials, tokens, private transcripts, hidden reasoning, paid verification calls, or automatic external publication.
