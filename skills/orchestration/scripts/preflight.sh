#!/usr/bin/env bash
set -u

value_from_toml() {
  key="$1"
  file="$2"
  [ -f "$file" ] || return 0
  awk -F= -v key="$key" '
    $1 ~ "^[[:space:]]*" key "[[:space:]]*$" {
      value=$2
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      gsub(/^"|"$/, "", value)
      print value
      exit
    }
  ' "$file"
}

printf 'PREFLIGHT_VERSION=1\n'
printf 'CURRENT_SESSION_MODEL=unverifiable_from_shell\n'
printf 'CURRENT_SESSION_EFFORT=unverifiable_from_shell\n'

if root=$(git rev-parse --show-toplevel 2>/dev/null); then
  printf 'GIT_ROOT=%s\n' "$root"
  printf 'GIT_BRANCH=%s\n' "$(git branch --show-current 2>/dev/null || true)"
  printf 'GIT_HEAD=%s\n' "$(git rev-parse --short=12 HEAD 2>/dev/null || true)"
  dirty=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  printf 'GIT_DIRTY_COUNT=%s\n' "$dirty"
else
  printf 'GIT_ROOT=none\n'
fi

if command -v claude >/dev/null 2>&1; then
  printf 'CLAUDE_BIN=available\n'
  printf 'CLAUDE_VERSION=%s\n' "$(claude --version 2>/dev/null | head -1)"
  if claude --help 2>/dev/null | grep -q -- '--effort'; then
    printf 'CLAUDE_EFFORT_FLAG=yes\n'
  else
    printf 'CLAUDE_EFFORT_FLAG=no\n'
  fi
else
  printf 'CLAUDE_BIN=unavailable\n'
fi

if command -v codex >/dev/null 2>&1; then
  printf 'CODEX_BIN=available\n'
  printf 'CODEX_VERSION=%s\n' "$(codex --version 2>/dev/null | head -1)"
else
  printf 'CODEX_BIN=unavailable\n'
fi

codex_config="${CODEX_HOME:-$HOME/.codex}/config.toml"
printf 'LOCAL_CODEX_CONFIG_MODEL=%s\n' "$(value_from_toml model "$codex_config")"
printf 'LOCAL_CODEX_CONFIG_EFFORT=%s\n' "$(value_from_toml model_reasoning_effort "$codex_config")"

printf 'NOTE=config_is_not_current_session_proof\n'
