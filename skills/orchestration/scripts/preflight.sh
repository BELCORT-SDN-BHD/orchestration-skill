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

skill_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
protocol_version=$(tr -d '[:space:]' < "$skill_dir/VERSION")
if command -v shasum >/dev/null 2>&1; then
  skill_sha=$(shasum -a 256 "$skill_dir/SKILL.md" | awk '{print $1}')
else
  skill_sha=$(sha256sum "$skill_dir/SKILL.md" | awk '{print $1}')
fi
printf 'ORCHESTRATION_SKILL_PATH=%s\n' "$skill_dir"
printf 'ORCHESTRATION_PROTOCOL_VERSION=%s\n' "$protocol_version"
printf 'ORCHESTRATION_SKILL_SHA256=%s\n' "$skill_sha"

if source_root=$(git -C "$skill_dir" rev-parse --show-toplevel 2>/dev/null); then
  printf 'ORCHESTRATION_SOURCE_ROOT=%s\n' "$source_root"
  printf 'ORCHESTRATION_SOURCE_HEAD=%s\n' "$(git -C "$source_root" rev-parse HEAD 2>/dev/null || true)"
else
  printf 'ORCHESTRATION_SOURCE_ROOT=unknown\n'
  printf 'ORCHESTRATION_SOURCE_HEAD=unknown\n'
fi

resolve_skill() {
  target="$1"
  [ -d "$target" ] && (cd "$target" && pwd -P) || true
}

codex_skill=$(resolve_skill "${CODEX_HOME:-$HOME/.codex}/skills/orchestration")
claude_skill=$(resolve_skill "$HOME/.claude/skills/orchestration")
printf 'CODEX_ORCHESTRATION_PATH=%s\n' "${codex_skill:-missing}"
printf 'CLAUDE_ORCHESTRATION_PATH=%s\n' "${claude_skill:-missing}"
if [ -n "$codex_skill" ] && [ "$codex_skill" = "$claude_skill" ] && [ "$codex_skill" = "$skill_dir" ]; then
  printf 'GLOBAL_INSTALL_COHERENT=yes\n'
else
  printf 'GLOBAL_INSTALL_COHERENT=no\n'
fi

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
