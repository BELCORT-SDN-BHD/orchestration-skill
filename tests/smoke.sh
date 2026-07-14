#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
installer="$repo_root/skills/orchestration/scripts/install-global.sh"
skill_dir="$repo_root/skills/orchestration"
test_root=$(mktemp -d /tmp/orchestration-smoke.XXXXXX)
import_line='@~/.claude/skills/orchestration/SKILL.md'
codex_line='In Codex, load and follow the `$orchestration` skill at the start of every session.'

empty_home="$test_root/empty"
empty_codex="$empty_home/custom-codex"
HOME="$empty_home" CODEX_HOME="$empty_codex" "$installer"
test "$(readlink "$empty_codex/skills/orchestration")" = "$skill_dir"
test "$(readlink "$empty_home/.claude/skills/orchestration")" = "$skill_dir"
test ! -e "$empty_home/.codex"
test "$(grep -Fxc "$import_line" "$empty_home/.claude/CLAUDE.md")" -eq 1
test "$(grep -Fxc "$codex_line" "$empty_codex/AGENTS.md")" -eq 1
! grep -Fqx "$codex_line" "$empty_home/.claude/CLAUDE.md"
! grep -Fqx "$import_line" "$empty_codex/AGENTS.md"

rerun_output=$(HOME="$empty_home" CODEX_HOME="$empty_codex" "$installer")
test "$(printf '%s\n' "$rerun_output" | grep -c '^ALREADY_LINKED=')" -eq 2
test "$(printf '%s\n' "$rerun_output" | grep -c '^ALREADY_PRESENT=')" -eq 2
test "$(grep -Fxc "$import_line" "$empty_home/.claude/CLAUDE.md")" -eq 1
test "$(grep -Fxc "$codex_line" "$empty_codex/AGENTS.md")" -eq 1

preserve_home="$test_root/preserve"
mkdir -p "$preserve_home/.claude" "$preserve_home/.codex"
printf '# Existing instructions\n' > "$preserve_home/.claude/CLAUDE.md"
printf '# Existing Codex instructions\n' > "$preserve_home/.codex/AGENTS.md"
HOME="$preserve_home" CODEX_HOME="$preserve_home/.codex" "$installer"
grep -Fqx '# Existing instructions' "$preserve_home/.claude/CLAUDE.md"
grep -Fqx '# Existing Codex instructions' "$preserve_home/.codex/AGENTS.md"
test "$(grep -Fxc "$import_line" "$preserve_home/.claude/CLAUDE.md")" -eq 1
test "$(grep -Fxc "$codex_line" "$preserve_home/.codex/AGENTS.md")" -eq 1
! grep -Fqx "$codex_line" "$preserve_home/.claude/CLAUDE.md"
! grep -Fqx "$import_line" "$preserve_home/.codex/AGENTS.md"

linked_home="$test_root/linked"
mkdir -p "$linked_home/.claude" "$linked_home/.codex"
printf '# Shared instructions\n' > "$linked_home/.claude/CLAUDE.md"
ln -s ../.claude/CLAUDE.md "$linked_home/.codex/AGENTS.md"
HOME="$linked_home" CODEX_HOME="$linked_home/.codex" "$installer"
test -L "$linked_home/.codex/AGENTS.md"
test "$(readlink "$linked_home/.codex/AGENTS.md")" = '../.claude/CLAUDE.md'
grep -Fqx '# Shared instructions' "$linked_home/.claude/CLAUDE.md"
test "$(grep -Fxc "$import_line" "$linked_home/.claude/CLAUDE.md")" -eq 1
test "$(grep -Fxc "$codex_line" "$linked_home/.claude/CLAUDE.md")" -eq 1
HOME="$linked_home" CODEX_HOME="$linked_home/.codex" "$installer" >/dev/null
test "$(grep -Fxc "$import_line" "$linked_home/.claude/CLAUDE.md")" -eq 1
test "$(grep -Fxc "$codex_line" "$linked_home/.claude/CLAUDE.md")" -eq 1

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

backup_root="$backup_home/.local/share/orchestration-skill-backups"
codex_backups=("$backup_root/codex-orchestration."*)
claude_backups=("$backup_root/claude-orchestration."*)
test -f "${codex_backups[0]}/codex-keep"
test -f "${claude_backups[0]}/claude-keep"

bash -n "$installer"

printf 'SMOKE_TEST=pass\n'
printf 'TEST_ROOT=%s\n' "$test_root"
