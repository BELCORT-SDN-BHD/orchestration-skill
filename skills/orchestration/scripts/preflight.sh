#!/usr/bin/env bash
# Availability evidence for the orchestrator init block. Config output is
# never proof of the current session's model.
set -u

printf 'PREFLIGHT_VERSION=2\n'
printf 'CURRENT_SESSION_MODEL=unverifiable_from_shell\n'

if root=$(git rev-parse --show-toplevel 2>/dev/null); then
  printf 'GIT_ROOT=%s\n' "$root"
  printf 'GIT_BRANCH=%s\n' "$(git branch --show-current 2>/dev/null || true)"
  printf 'GIT_HEAD=%s\n' "$(git rev-parse --short=12 HEAD 2>/dev/null || true)"
  printf 'GIT_DIRTY_COUNT=%s\n' "$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
else
  printf 'GIT_ROOT=none\n'
fi

# Advisor lane: fable (claude CLI)
if command -v claude >/dev/null 2>&1; then
  claude_help=$(claude --help 2>/dev/null)
  printf 'CLAUDE_VERSION=%s\n' "$(claude --version 2>/dev/null | head -1)"
  fable_ok=yes
  for flag in --effort --permission-mode --disable-slash-commands --output-format --tools; do
    if ! printf '%s' "$claude_help" | grep -q -- "$flag"; then
      printf 'CLAUDE_MISSING_FLAG=%s\n' "$flag"
      fable_ok=no
    fi
  done
  printf 'ADVISOR_FABLE=%s\n' "$fable_ok"
  printf 'WORKER_CLAUDE_LANES=native_subagents_or_cli\n'
else
  printf 'ADVISOR_FABLE=unavailable\n'
fi

# Advisor lane: sol (codex CLI)
if command -v codex >/dev/null 2>&1; then
  codex_help=$(codex exec --help 2>/dev/null)
  printf 'CODEX_VERSION=%s\n' "$(codex --version 2>/dev/null | head -1)"
  sol_ok=yes
  for flag in --sandbox --json --ignore-user-config --skip-git-repo-check --output-last-message; do
    if ! printf '%s' "$codex_help" | grep -q -- "$flag"; then
      printf 'CODEX_MISSING_FLAG=%s\n' "$flag"
      sol_ok=no
    fi
  done
  printf 'ADVISOR_SOL=%s\n' "$sol_ok"
  printf 'WORKER_GPT_LANES=codex_exec\n'
else
  printf 'ADVISOR_SOL=unavailable\n'
fi

printf 'NOTE=availability_evidence_only\n'
