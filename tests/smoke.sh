#!/usr/bin/env bash
set -euo pipefail

source_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
test_root=$(mktemp -d /tmp/orchestration-smoke.XXXXXX)
repo_root="$test_root/repository"
remote="$test_root/remote.git"
canonical_remote='https://github.com/BELCORT-SDN-BHD/orchestration-skill.git'

cp -R "$source_root" "$repo_root"
rm -rf "$repo_root/.git"
repo_root=$(cd "$repo_root" && pwd -P)
git init --quiet --initial-branch=main "$repo_root"
git -C "$repo_root" config user.name 'Installer smoke test'
git -C "$repo_root" config user.email 'installer-smoke@example.invalid'
git -C "$repo_root" add .
git -C "$repo_root" commit --quiet -m 'Installer test version'
git init --quiet --bare --initial-branch=main "$remote"
git -C "$repo_root" remote add origin "$remote"
git -C "$repo_root" push --quiet -u origin main
git -C "$repo_root" remote set-url origin "$canonical_remote"

installer="$repo_root/skills/orchestration/scripts/install-global.sh"
skill_dir="$repo_root/skills/orchestration"
import_line='@~/.claude/skills/orchestration/SKILL.md'
codex_line='In Codex, load and follow the `$orchestration` skill at the start of every session.'
real_path="$PATH"
rewrite_key="url.file://$remote.insteadOf"

export GIT_CONFIG_COUNT=2
export GIT_CONFIG_KEY_0="$rewrite_key"
export GIT_CONFIG_VALUE_0="$canonical_remote"
export GIT_CONFIG_KEY_1='protocol.file.allow'
export GIT_CONFIG_VALUE_1='always'

darwin_bin="$test_root/darwin-bin"
mkdir -p "$darwin_bin"
cat > "$darwin_bin/uname" <<'EOF'
#!/usr/bin/env bash
printf 'Darwin\n'
EOF
cat > "$darwin_bin/launchctl" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$HOME/launchctl.log"
EOF
chmod +x "$darwin_bin/uname" "$darwin_bin/launchctl"
export PATH="$darwin_bin:$real_path"

empty_home="$test_root/empty"
empty_codex="$empty_home/custom-codex"
empty_output=$(HOME="$empty_home" CODEX_HOME="$empty_codex" "$installer")
test "$(readlink "$empty_codex/skills/orchestration")" = "$skill_dir"
test "$(readlink "$empty_home/.claude/skills/orchestration")" = "$skill_dir"
test ! -e "$empty_home/.codex"
test "$(grep -Fxc "$import_line" "$empty_home/.claude/CLAUDE.md")" -eq 1
test "$(grep -Fxc "$codex_line" "$empty_codex/AGENTS.md")" -eq 1
! grep -Fqx "$codex_line" "$empty_home/.claude/CLAUDE.md"
! grep -Fqx "$import_line" "$empty_codex/AGENTS.md"
printf '%s\n' "$empty_output" | grep -Fqx 'AUTO_UPDATE_SCHEDULED=launchd-hourly'
printf '%s\n' "$empty_output" | grep -Fqx 'AUTO_UPDATE_INITIAL_CHECK=current'
printf '%s\n' "$empty_output" | grep -Fqx 'AUTO_UPDATE=ready'
test -x "$empty_home/.local/libexec/orchestration-skill-update"
test ! -L "$empty_home/.local/libexec/orchestration-skill-update"
test "$(cat "$empty_home/.config/orchestration-skill/repository")" = "$repo_root"
grep -Fq '<integer>3600</integer>' \
  "$empty_home/Library/LaunchAgents/com.belcort.orchestration-skill-update.plist"
grep -Fq 'bootstrap' "$empty_home/launchctl.log"

failed_launchd_bin="$test_root/failed-launchd-bin"
mkdir -p "$failed_launchd_bin"
cat > "$failed_launchd_bin/uname" <<'EOF'
#!/usr/bin/env bash
printf 'Darwin\n'
EOF
cat > "$failed_launchd_bin/launchctl" <<'EOF'
#!/usr/bin/env bash
if [ "${1:-}" = "enable" ]; then
  exit 1
fi
exit 0
EOF
chmod +x "$failed_launchd_bin/uname" "$failed_launchd_bin/launchctl"
failed_launchd_home="$test_root/failed-launchd"
set +e
failed_launchd_output=$(PATH="$failed_launchd_bin:$real_path" \
  HOME="$failed_launchd_home" CODEX_HOME="$failed_launchd_home/.codex" \
  "$installer" 2>&1)
failed_launchd_status=$?
set -e
test "$failed_launchd_status" -eq 4
printf '%s\n' "$failed_launchd_output" \
  | grep -Fqx 'AUTO_UPDATE_UNAVAILABLE=launchd-registration-failed'
! printf '%s\n' "$failed_launchd_output" | grep -Fqx 'AUTO_UPDATE=ready'

git -C "$repo_root" remote set-url origin 'https://example.invalid/wrong.git'
invalid_origin_home="$test_root/invalid-origin"
set +e
invalid_origin_output=$(HOME="$invalid_origin_home" \
  CODEX_HOME="$invalid_origin_home/.codex" "$installer" 2>&1)
invalid_origin_status=$?
set -e
test "$invalid_origin_status" -eq 4
printf '%s\n' "$invalid_origin_output" \
  | grep -Fqx 'AUTO_UPDATE_UNAVAILABLE=initial-check-unexpected_origin'
! printf '%s\n' "$invalid_origin_output" | grep -Fqx 'AUTO_UPDATE=ready'
git -C "$repo_root" remote set-url origin "$canonical_remote"

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

linux_bin="$test_root/linux-bin"
mkdir -p "$linux_bin"
cat > "$linux_bin/uname" <<'EOF'
#!/usr/bin/env bash
printf 'Linux\n'
EOF
cat > "$linux_bin/systemctl" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$HOME/systemctl.log"
EOF
chmod +x "$linux_bin/uname" "$linux_bin/systemctl"

linux_home="$test_root/linux home%test"
linux_output=$(PATH="$linux_bin:$real_path" HOME="$linux_home" \
  CODEX_HOME="$linux_home/.codex" "$installer")
printf '%s\n' "$linux_output" | grep -Fqx 'AUTO_UPDATE_SCHEDULED=systemd-hourly'
printf '%s\n' "$linux_output" | grep -Fqx 'AUTO_UPDATE_INITIAL_CHECK=current'
printf '%s\n' "$linux_output" | grep -Fqx 'AUTO_UPDATE=ready'
escaped_linux_home=$(printf '%s' "$linux_home" | sed 's/%/%%/g')
grep -Fq "ExecStart=\"$escaped_linux_home/.local/libexec/orchestration-skill-update\"" \
  "$linux_home/.config/systemd/user/orchestration-skill-update.service"
grep -Fq "Environment=\"HOME=$escaped_linux_home\"" \
  "$linux_home/.config/systemd/user/orchestration-skill-update.service"
grep -Fq 'OnUnitActiveSec=1h' \
  "$linux_home/.config/systemd/user/orchestration-skill-update.timer"
grep -Fq 'enable --now orchestration-skill-update.timer' "$linux_home/systemctl.log"

bash -n "$installer" "$repo_root/skills/orchestration/scripts/update-global.sh"

printf 'SMOKE_TEST=pass\n'
printf 'TEST_ROOT=%s\n' "$test_root"
