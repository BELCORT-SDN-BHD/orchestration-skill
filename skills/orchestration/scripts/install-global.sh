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
# Backups must live OUTSIDE the skills directories: Claude Code and Codex
# index every directory containing a SKILL.md, so a sibling backup would be
# loaded as a second, stale orchestration skill.
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

test -f "${CODEX_HOME:-$HOME/.codex}/skills/orchestration/SKILL.md"
test -f "$HOME/.claude/skills/orchestration/SKILL.md"

# Migrate any backups a previous installer version left inside the skills
# directories, where they shadow the real skill.
migrate_stale() {
  runtime="$1"
  for stale in "$2/orchestration.backup."*; do
    [ -e "$stale" ] || continue
    mkdir -p "$backup_root"
    dest="$backup_root/${runtime}-$(basename "$stale")"
    mv "$stale" "$dest"
    printf 'MIGRATED_STALE_BACKUP=%s\n' "$dest"
  done
}
migrate_stale codex "${CODEX_HOME:-$HOME/.codex}/skills"
migrate_stale claude "$HOME/.claude/skills"

printf 'GLOBAL_ORCHESTRATION_SKILL=ready\n'
printf 'Restart the host or start a new session before first use.\n'
