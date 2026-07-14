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

backup_root="$backup_home/.local/share/orchestration-skill-backups"
codex_backups=("$backup_root/codex-orchestration."*)
claude_backups=("$backup_root/claude-orchestration."*)
test -f "${codex_backups[0]}/codex-keep"
test -f "${claude_backups[0]}/claude-keep"
test -z "$(find "$backup_home/.codex/skills" "$backup_home/.claude/skills" -maxdepth 1 -name 'orchestration.backup.*' -print)"

migrate_home="$test_root/migrate"
mkdir -p "$migrate_home/.codex/skills/orchestration.backup.20260101-000000.1" \
         "$migrate_home/.claude/skills/orchestration.backup.20260101-000000.1"
touch "$migrate_home/.claude/skills/orchestration.backup.20260101-000000.1/old-keep"
HOME="$migrate_home" CODEX_HOME="$migrate_home/.codex" "$installer"
test -z "$(find "$migrate_home/.codex/skills" "$migrate_home/.claude/skills" -maxdepth 1 -name 'orchestration.backup.*' -print)"
test -d "$migrate_home/.local/share/orchestration-skill-backups/codex-orchestration.backup.20260101-000000.1"
test -f "$migrate_home/.local/share/orchestration-skill-backups/claude-orchestration.backup.20260101-000000.1/old-keep"

bash -n "$repo_root/skills/orchestration/scripts/install-global.sh"
bash -n "$repo_root/skills/orchestration/scripts/preflight.sh"

preflight="$repo_root/skills/orchestration/scripts/preflight.sh"
set +e
"$preflight" >/dev/null 2>&1
missing_runtime_status=$?
"$preflight" unsupported >/dev/null 2>&1
unsupported_runtime_status=$?
set -e
test "$missing_runtime_status" -eq 2
test "$unsupported_runtime_status" -eq 2

codex_preflight=$(PATH="/usr/bin:/bin" "$preflight" codex)
grep -q '^PREFLIGHT_VERSION=5$' <<<"$codex_preflight"
grep -q '^HOST_RUNTIME=codex$' <<<"$codex_preflight"
grep -q '^ORCHESTRATOR_FAMILY=openai$' <<<"$codex_preflight"
grep -q '^NOTE=host_profile_and_availability_evidence$' <<<"$codex_preflight"

claude_preflight=$(PATH="/usr/bin:/bin" "$preflight" claude-code)
grep -q '^PREFLIGHT_VERSION=5$' <<<"$claude_preflight"
grep -q '^HOST_RUNTIME=claude-code$' <<<"$claude_preflight"
grep -q '^ORCHESTRATOR_FAMILY=claude$' <<<"$claude_preflight"

printf 'SMOKE_TEST=pass\n'
printf 'TEST_ROOT=%s\n' "$test_root"
