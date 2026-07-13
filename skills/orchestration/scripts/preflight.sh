#!/usr/bin/env bash
# Availability evidence for orchestrator and worker lanes. This script never
# proves the model of the already-running host session.
set -u

printf 'PREFLIGHT_VERSION=3\n'
printf 'CURRENT_SESSION_MODEL=unverifiable_from_shell\n'

if root=$(git rev-parse --show-toplevel 2>/dev/null); then
  printf 'GIT_ROOT=%s\n' "$root"
  printf 'GIT_BRANCH=%s\n' "$(git branch --show-current 2>/dev/null || true)"
  printf 'GIT_HEAD=%s\n' "$(git rev-parse --short=12 HEAD 2>/dev/null || true)"
  printf 'GIT_DIRTY_COUNT=%s\n' "$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
else
  printf 'GIT_ROOT=none\n'
fi

if command -v claude >/dev/null 2>&1; then
  claude_help=$(claude --help 2>/dev/null)
  printf 'CLAUDE_VERSION=%s\n' "$(claude --version 2>/dev/null | head -1)"
  claude_ok=yes
  for flag in --model --effort --permission-mode --disable-slash-commands --output-format; do
    if ! printf '%s' "$claude_help" | grep -q -- "$flag"; then
      printf 'CLAUDE_MISSING_FLAG=%s\n' "$flag"
      claude_ok=no
    fi
  done
  printf 'CLAUDE_LANES=%s\n' "$claude_ok"
else
  printf 'CLAUDE_LANES=unavailable\n'
fi

if command -v codex >/dev/null 2>&1; then
  codex_help=$(codex exec --help 2>/dev/null)
  printf 'CODEX_VERSION=%s\n' "$(codex --version 2>/dev/null | head -1)"
  openai_ok=yes
  for flag in --model --sandbox --json --ignore-user-config --skip-git-repo-check --output-last-message; do
    if ! printf '%s' "$codex_help" | grep -q -- "$flag"; then
      printf 'CODEX_MISSING_FLAG=%s\n' "$flag"
      openai_ok=no
    fi
  done
  printf 'OPENAI_LANES=%s\n' "$openai_ok"
else
  printf 'OPENAI_LANES=unavailable\n'
fi

printf 'NOTE=availability_evidence_only\n'
