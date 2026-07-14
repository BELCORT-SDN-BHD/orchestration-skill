# Orchestration skill repository rules

This repository is the canonical source for a high-privilege global orchestration protocol.

1. After the initial repository bootstrap, all changes land through a pull request; never push directly to `main`.
2. Changes to roles, decision tiers, cross-family review independence, provenance, permission gates, installation/update behavior, or this governance file are founder-only. The author or material editor may not merge them.
3. Never auto-merge or auto-update installed machines. Review the exact revision, run `python3 tests/validate_skill.py` and `bash tests/smoke.sh`, then start a fresh host/session.
4. Never add credentials, tokens, private transcripts, hidden reasoning, or paid verification calls. Ask the user before any real incremental spend or external publication.
5. Project rules always override this global protocol. A project overlay may tighten behavior but must not copy the complete global skill under the same name.
