#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
updater_source="$repo_root/skills/orchestration/scripts/update-global.sh"
test_root=$(mktemp -d /tmp/orchestration-update.XXXXXX)
remote="$test_root/remote.git"
source_repo="$test_root/source"
update_home="$test_root/home"
installed_repo="$update_home/.local/share/orchestration-skill"
installed_updater="$update_home/.local/libexec/orchestration-skill-update"
canonical_remote='https://github.com/BELCORT-SDN-BHD/orchestration-skill.git'
ssh_remote='git@github.com:BELCORT-SDN-BHD/orchestration-skill.git'

git init --quiet --bare --initial-branch=main "$remote"
git init --quiet --initial-branch=main "$source_repo"
git -C "$source_repo" config user.name 'Update smoke test'
git -C "$source_repo" config user.email 'update-smoke@example.invalid'
mkdir -p "$source_repo/skills/orchestration"
cp "$repo_root/skills/orchestration/SKILL.md" \
  "$source_repo/skills/orchestration/SKILL.md"
printf 'one\n' > "$source_repo/revision"
git -C "$source_repo" add .
git -C "$source_repo" commit --quiet -m 'Initial version'
git -C "$source_repo" remote add origin "$remote"
git -C "$source_repo" push --quiet -u origin main

mkdir -p "$(dirname "$installed_repo")" "$(dirname "$installed_updater")" \
  "$update_home/.config/orchestration-skill"
git clone --quiet "$remote" "$installed_repo"
git -C "$installed_repo" remote set-url origin "$canonical_remote"
cp "$updater_source" "$installed_updater"
chmod +x "$installed_updater"
printf '%s\n' "$installed_repo" \
  > "$update_home/.config/orchestration-skill/repository"

rewrite_key="url.file://$remote.insteadOf"
run_update() {
  HOME="$update_home" \
    GIT_CONFIG_COUNT=2 \
    GIT_CONFIG_KEY_0="$rewrite_key" \
    GIT_CONFIG_VALUE_0="$canonical_remote" \
    GIT_CONFIG_KEY_1='protocol.file.allow' \
    GIT_CONFIG_VALUE_1='always' \
    "$installed_updater" --force
}

run_update
grep -Fqx 'result=current' \
  "$update_home/.local/state/orchestration-skill/update-status"

git -C "$installed_repo" remote set-url origin "$ssh_remote"
run_update
grep -Fqx 'result=current' \
  "$update_home/.local/state/orchestration-skill/update-status"
git -C "$installed_repo" remote set-url origin 'https://example.invalid/wrong.git'
if run_update; then
  printf 'unexpected origin was accepted\n' >&2
  exit 1
fi
grep -Fqx 'detail=unexpected_origin' \
  "$update_home/.local/state/orchestration-skill/update-status"
git -C "$installed_repo" remote set-url origin "$canonical_remote"

printf 'two\n' > "$source_repo/revision"
git -C "$source_repo" commit --quiet -am 'Second version'
git -C "$source_repo" push --quiet
second_sha=$(git -C "$source_repo" rev-parse HEAD)
run_update
test "$(git -C "$installed_repo" rev-parse HEAD)" = "$second_sha"
grep -Fqx 'result=updated' \
  "$update_home/.local/state/orchestration-skill/update-status"

hook_sentinel="$test_root/hook-ran"
printf '#!/usr/bin/env bash\ntouch %q\n' "$hook_sentinel" \
  > "$installed_repo/.git/hooks/post-merge"
chmod +x "$installed_repo/.git/hooks/post-merge"

downloaded_sentinel="$test_root/downloaded-updater-ran"
mkdir -p "$source_repo/skills/orchestration/scripts"
printf '#!/usr/bin/env bash\ntouch %q\n' "$downloaded_sentinel" \
  > "$source_repo/skills/orchestration/scripts/update-global.sh"
chmod +x "$source_repo/skills/orchestration/scripts/update-global.sh"
printf 'three\n' > "$source_repo/revision"
git -C "$source_repo" add .
git -C "$source_repo" commit --quiet -m 'Third version'
git -C "$source_repo" push --quiet
external_hash=$(git hash-object "$installed_updater")
run_update
test ! -e "$hook_sentinel"
test ! -e "$downloaded_sentinel"
test "$(git hash-object "$installed_updater")" = "$external_hash"

printf 'four\n' > "$source_repo/revision"
git -C "$source_repo" commit --quiet -am 'Fourth version'
git -C "$source_repo" push --quiet
before_dirty=$(git -C "$installed_repo" rev-parse HEAD)
touch "$installed_repo/local-change"
if run_update; then
  printf 'dirty update unexpectedly succeeded\n' >&2
  exit 1
fi
test "$(git -C "$installed_repo" rev-parse HEAD)" = "$before_dirty"
grep -Fqx 'detail=dirty_worktree' \
  "$update_home/.local/state/orchestration-skill/update-status"
rm "$installed_repo/local-change"
run_update
test "$(git -C "$installed_repo" rev-parse HEAD)" \
  = "$(git -C "$source_repo" rev-parse HEAD)"

online_head=$(git -C "$installed_repo" rev-parse HEAD)
mv "$remote" "$remote.offline"
if run_update; then
  printf 'offline update unexpectedly succeeded\n' >&2
  exit 1
fi
test "$(git -C "$installed_repo" rev-parse HEAD)" = "$online_head"
grep -Fqx 'detail=fetch_failed' \
  "$update_home/.local/state/orchestration-skill/update-status"

bash -n "$installed_updater"
printf 'UPDATE_SMOKE_TEST=pass\n'
printf 'TEST_ROOT=%s\n' "$test_root"
