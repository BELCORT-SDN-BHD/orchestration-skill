#!/usr/bin/env bash
# Availability evidence for host-derived orchestrator and worker profiles.
set -u

usage() {
  echo "usage: $0 <codex|claude-code>" >&2
  exit 2
}

[ "$#" -eq 1 ] || usage

case "$1" in
  codex)
    host_runtime=codex
    orchestrator_family=openai
    ;;
  claude-code)
    host_runtime=claude-code
    orchestrator_family=claude
    ;;
  *) usage ;;
esac

printf 'PREFLIGHT_VERSION=6\n'
printf 'HOST_RUNTIME=%s\n' "$host_runtime"
printf 'ORCHESTRATOR_FAMILY=%s\n' "$orchestrator_family"

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
  for flag in --model --effort --permission-mode --disable-slash-commands --output-format \
    --strict-mcp-config --settings --disallowed-tools; do
    if ! printf '%s' "$claude_help" | grep -q -- "$flag"; then
      printf 'CLAUDE_MISSING_FLAG=%s\n' "$flag"
      claude_ok=no
    fi
  done
  for choice in dontAsk acceptEdits; do
    if ! printf '%s' "$claude_help" | grep -q -- "$choice"; then
      printf 'CLAUDE_MISSING_PERMISSION_MODE=%s\n' "$choice"
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
  for flag in --model --sandbox --json --ignore-user-config --skip-git-repo-check --output-last-message --config; do
    if ! printf '%s' "$codex_help" | grep -q -- "$flag"; then
      printf 'CODEX_MISSING_FLAG=%s\n' "$flag"
      openai_ok=no
    fi
  done
  printf 'OPENAI_LANES=%s\n' "$openai_ok"
else
  printf 'OPENAI_LANES=unavailable\n'
fi

if command -v timeout >/dev/null 2>&1; then
  printf 'TIMEOUT_AVAILABLE=yes\n'
else
  printf 'TIMEOUT_AVAILABLE=no\n'
fi

# Billing-mode evidence: a paid-API key in the environment can silently divert a
# subscription lane to metered billing, which the hard gates forbid doing silently.
if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
  printf 'CLAUDE_BILLING=api-key-env-present\n'
else
  printf 'CLAUDE_BILLING=subscription-or-oauth\n'
fi
if [ -n "${OPENAI_API_KEY:-}" ]; then
  printf 'OPENAI_BILLING=api-key-env-present\n'
else
  printf 'OPENAI_BILLING=subscription-or-oauth\n'
fi

printf 'NOTE=host_profile_and_availability_evidence\n'
