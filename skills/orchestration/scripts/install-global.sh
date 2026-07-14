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
backup_root="$HOME/.local/share/orchestration-skill-backups"

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
  runtime="$2"
  mkdir -p "$(dirname "$target")"

  resolved=$(resolve_target "$target")
  if [ "$resolved" = "$skill_dir" ]; then
    printf 'ALREADY_LINKED=%s\n' "$target"
    return
  fi

  if [ -e "$target" ] || [ -L "$target" ]; then
    if [ "$backup_existing" -ne 1 ]; then
      printf 'REFUSING_EXISTING=%s\n' "$target" >&2
      printf 'Re-run with --backup-existing to preserve it outside the skills directory.\n' >&2
      exit 3
    fi
    mkdir -p "$backup_root"
    backup="$backup_root/${runtime}-orchestration.${timestamp}.$$"
    mv "$target" "$backup"
    printf 'BACKUP=%s\n' "$backup"
  fi

  ln -s "$skill_dir" "$target"
  printf 'LINKED=%s -> %s\n' "$target" "$skill_dir"
}

install_target "${CODEX_HOME:-$HOME/.codex}/skills/orchestration" codex
install_target "$HOME/.claude/skills/orchestration" claude

claude_md="$HOME/.claude/CLAUDE.md"
codex_agents="${CODEX_HOME:-$HOME/.codex}/AGENTS.md"
import_line='@~/.claude/skills/orchestration/SKILL.md'
codex_line='In Codex, load and follow the `$orchestration` skill at the start of every session.'

ensure_line() {
  file="$1"
  line="$2"
  mkdir -p "$(dirname "$file")"
  touch "$file"

  if grep -Fqx "$line" "$file"; then
    printf 'ALREADY_PRESENT=%s\n' "$line"
  else
    if [ -s "$file" ]; then
      printf '\n' >> "$file"
    fi
    printf '%s\n' "$line" >> "$file"
    printf 'ADDED=%s\n' "$line"
  fi
}

ensure_line "$claude_md" "$import_line"
ensure_line "$codex_agents" "$codex_line"

test -f "${CODEX_HOME:-$HOME/.codex}/skills/orchestration/SKILL.md"
test -f "$HOME/.claude/skills/orchestration/SKILL.md"
grep -Fqx "$import_line" "$claude_md"
grep -Fqx "$codex_line" "$codex_agents"

printf 'GLOBAL_ORCHESTRATION_POLICY=ready\n'
printf 'Start a fresh host session before first use.\n'
