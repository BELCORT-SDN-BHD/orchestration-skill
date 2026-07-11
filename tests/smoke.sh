#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
installer="$repo_root/skills/orchestration/scripts/install-global.sh"
skill_dir="$repo_root/skills/orchestration"
test_root=$(mktemp -d /tmp/orchestration-smoke.XXXXXX)

empty_home="$test_root/empty"
HOME="$empty_home" CODEX_HOME="$empty_home/.codex" "$installer"
test "$(readlink "$empty_home/.codex/skills/orchestration")" = "$skill_dir"
test "$(readlink "$empty_home/.claude/skills/orchestration")" = "$skill_dir"

rerun_output=$(HOME="$empty_home" CODEX_HOME="$empty_home/.codex" "$installer")
test "$(printf '%s\n' "$rerun_output" | grep -c '^ALREADY_LINKED=')" -eq 2

refuse_home="$test_root/refuse"
mkdir -p "$refuse_home/.codex/skills/orchestration" "$refuse_home/.claude/skills/orchestration"
touch "$refuse_home/.codex/skills/orchestration/keep" "$refuse_home/.claude/skills/orchestration/keep"
set +e
HOME="$refuse_home" CODEX_HOME="$refuse_home/.codex" "$installer" >/dev/null 2>&1
refuse_status=$?
set -e
test "$refuse_status" -eq 3
test -f "$refuse_home/.codex/skills/orchestration/keep"
test -f "$refuse_home/.claude/skills/orchestration/keep"

backup_home="$test_root/backup"
mkdir -p "$backup_home/.codex/skills/orchestration" "$backup_home/.claude/skills/orchestration"
touch "$backup_home/.codex/skills/orchestration/codex-keep"
touch "$backup_home/.claude/skills/orchestration/claude-keep"
HOME="$backup_home" CODEX_HOME="$backup_home/.codex" "$installer" --backup-existing
test -L "$backup_home/.codex/skills/orchestration"
test -L "$backup_home/.claude/skills/orchestration"

codex_backups=("$backup_home/.codex/skills/orchestration.backup."*)
claude_backups=("$backup_home/.claude/skills/orchestration.backup."*)
test -f "${codex_backups[0]}/codex-keep"
test -f "${claude_backups[0]}/claude-keep"

printf 'SMOKE_TEST=pass\n'
printf 'TEST_ROOT=%s\n' "$test_root"
