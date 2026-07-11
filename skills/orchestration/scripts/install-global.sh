#!/usr/bin/env bash
set -euo pipefail

backup_existing=0
if [ "${1:-}" = "--backup-existing" ]; then
  backup_existing=1
elif [ "$#" -gt 0 ]; then
  echo "Usage: $0 [--backup-existing]" >&2
  exit 2
fi

skill_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
timestamp=$(date +%Y%m%d-%H%M%S)
protocol_version=$(tr -d '[:space:]' < "$skill_dir/VERSION")

resolve_target() {
  target="$1"
  if [ -L "$target" ]; then
    link=$(readlink "$target")
    case "$link" in
      /*) candidate="$link" ;;
      *) candidate="$(dirname "$target")/$link" ;;
    esac
    [ -d "$candidate" ] && (cd "$candidate" && pwd -P) || true
  elif [ -d "$target" ]; then
    (cd "$target" && pwd -P)
  fi
}

install_target() {
  target="$1"
  mkdir -p "$(dirname "$target")"

  resolved=$(resolve_target "$target")
  if [ "$resolved" = "$skill_dir" ]; then
    printf 'ALREADY_LINKED=%s\n' "$target"
    return
  fi

  if [ -e "$target" ] || [ -L "$target" ]; then
    if [ "$backup_existing" -ne 1 ]; then
      printf 'REFUSING_EXISTING=%s\n' "$target" >&2
      printf 'Re-run with --backup-existing to preserve it beside the target.\n' >&2
      exit 3
    fi
    backup="${target}.backup.${timestamp}.$$"
    mv "$target" "$backup"
    printf 'BACKUP=%s\n' "$backup"
  fi

  ln -s "$skill_dir" "$target"
  printf 'LINKED=%s -> %s\n' "$target" "$skill_dir"
}

install_target "${CODEX_HOME:-$HOME/.codex}/skills/orchestration"
install_target "$HOME/.claude/skills/orchestration"

test -f "${CODEX_HOME:-$HOME/.codex}/skills/orchestration/SKILL.md"
test -f "$HOME/.claude/skills/orchestration/SKILL.md"
printf 'GLOBAL_ORCHESTRATION_SKILL=ready\n'
printf 'ORCHESTRATION_PROTOCOL_VERSION=%s\n' "$protocol_version"
if source_root=$(git -C "$skill_dir" rev-parse --show-toplevel 2>/dev/null); then
  printf 'ORCHESTRATION_SOURCE_HEAD=%s\n' "$(git -C "$source_root" rev-parse HEAD 2>/dev/null || true)"
else
  printf 'ORCHESTRATION_SOURCE_HEAD=unknown\n'
fi
printf 'Restart the host or start a new session before first use.\n'
