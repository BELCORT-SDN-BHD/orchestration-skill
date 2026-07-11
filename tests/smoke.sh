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

# Backups land OUTSIDE the skills directories so runtimes never index them
# as a second stale skill.
backup_root="$backup_home/.local/share/orchestration-skill-backups"
codex_backups=("$backup_root/codex-orchestration."*)
claude_backups=("$backup_root/claude-orchestration."*)
test -f "${codex_backups[0]}/codex-keep"
test -f "${claude_backups[0]}/claude-keep"
test -z "$(find "$backup_home/.codex/skills" "$backup_home/.claude/skills" -maxdepth 1 -name 'orchestration.backup.*' -print)"

# A stale in-skills backup from an older installer version gets migrated out.
migrate_home="$test_root/migrate"
mkdir -p "$migrate_home/.codex/skills/orchestration.backup.20260101-000000.1" \
         "$migrate_home/.claude/skills/orchestration.backup.20260101-000000.1"
touch "$migrate_home/.claude/skills/orchestration.backup.20260101-000000.1/old-keep"
HOME="$migrate_home" CODEX_HOME="$migrate_home/.codex" "$installer"
test -z "$(find "$migrate_home/.codex/skills" "$migrate_home/.claude/skills" -maxdepth 1 -name 'orchestration.backup.*' -print)"
test -d "$migrate_home/.local/share/orchestration-skill-backups/codex-orchestration.backup.20260101-000000.1"
test -f "$migrate_home/.local/share/orchestration-skill-backups/claude-orchestration.backup.20260101-000000.1/old-keep"

# advisor.sh and preflight.sh parse cleanly and reject bad usage.
bash -n "$repo_root/skills/orchestration/scripts/advisor.sh"
bash -n "$repo_root/skills/orchestration/scripts/preflight.sh"
advisor="$repo_root/skills/orchestration/scripts/advisor.sh"
set +e
"$advisor" >/dev/null 2>&1
usage_status=$?
"$advisor" fable /nonexistent-prompt "$test_root/adv" >/dev/null 2>&1
prompt_status=$?
set -e
test "$usage_status" -eq 2
test "$prompt_status" -eq 2

# advisor.sh classification against stub CLIs — no real model calls.
shims="$test_root/shims"
mkdir -p "$shims"
cat > "$shims/claude" <<'SHIM'
#!/usr/bin/env bash
cat > /dev/null
case "${CLAUDE_STUB_MODE:-ok}" in
  ok)
    printf '%s\n' '{"type":"system","subtype":"init","model":"stub-model-1"}'
    printf '%s\n' '{"type":"result","result":"stub memo","session_id":"sess-stub","modelUsage":{"stub-model-1":{}}}'
    ;;
  ratelimit) echo "rate limit exceeded" >&2; exit 1 ;;
  empty) printf '%s\n' '{"type":"system","subtype":"init"}' ;;
esac
SHIM
cat > "$shims/codex" <<'SHIM'
#!/usr/bin/env bash
out=""; prev=""
for a in "$@"; do [ "$prev" = "-o" ] && out="$a"; prev="$a"; done
cat > /dev/null
printf '%s\n' '{"type":"thread.started","thread_id":"stub-thread"}'
[ -n "$out" ] && printf 'sol stub memo\n' > "$out"
printf '%s\n' '{"type":"turn.completed","usage":{}}'
SHIM
chmod +x "$shims/claude" "$shims/codex"
stub_prompt="$test_root/prompt.md"
echo "stub question" > "$stub_prompt"

PATH="$shims:$PATH" "$advisor" fable "$stub_prompt" "$test_root/adv-ok" >/dev/null
test "$(cat "$test_root/adv-ok/memo.md")" = "stub memo"
grep -q '"status": "complete"' "$test_root/adv-ok/provenance.json"
grep -q 'stub-model-1' "$test_root/adv-ok/provenance.json"

set +e
CLAUDE_STUB_MODE=ratelimit PATH="$shims:$PATH" "$advisor" fable "$stub_prompt" "$test_root/adv-rl" >/dev/null
rl_status=$?
CLAUDE_STUB_MODE=empty PATH="$shims:$PATH" "$advisor" fable "$stub_prompt" "$test_root/adv-empty" >/dev/null
empty_status=$?
set -e
test "$rl_status" -eq 3
test "$empty_status" -eq 4
grep -q '"status": "unavailable"' "$test_root/adv-rl/provenance.json"
grep -q '"status": "incomplete: empty output"' "$test_root/adv-empty/provenance.json"

CODEX_HOME="$test_root/nocodex" PATH="$shims:$PATH" "$advisor" sol "$stub_prompt" "$test_root/adv-sol" >/dev/null
test "$(cat "$test_root/adv-sol/memo.md")" = "sol stub memo"
grep -q '"status": "complete"' "$test_root/adv-sol/provenance.json"

printf 'SMOKE_TEST=pass\n'
printf 'TEST_ROOT=%s\n' "$test_root"
