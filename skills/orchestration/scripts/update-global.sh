#!/usr/bin/env bash

# This file is copied outside the repository during installation. The scheduler
# runs that fixed copy so an update cannot replace and immediately execute it.

set -u
umask 077

interval_seconds=3600
force=0

if [ "${1:-}" = "--force" ] && [ "$#" -eq 1 ]; then
  force=1
elif [ "$#" -gt 0 ]; then
  printf 'Usage: %s [--force]\n' "$0" >&2
  exit 2
fi

config_dir="$HOME/.config/orchestration-skill"
repo_file="$config_dir/repository"
state_dir="$HOME/.local/state/orchestration-skill"
status_file="$state_dir/update-status"
lock_dir="$state_dir/update-lock"
expected_remote='https://github.com/BELCORT-SDN-BHD/orchestration-skill.git'

mkdir -p "$state_dir" 2>/dev/null || exit 0

lock_held=0
cleanup() {
  if [ "$lock_held" -eq 1 ]; then
    rm -f "$lock_dir/pid"
    rmdir "$lock_dir" 2>/dev/null || true
  fi
}
trap cleanup EXIT
trap 'exit 0' HUP INT TERM

if ! mkdir "$lock_dir" 2>/dev/null; then
  lock_pid=$(sed -n '1p' "$lock_dir/pid" 2>/dev/null || true)
  case "$lock_pid" in
    ''|*[!0-9]*) lock_pid=0 ;;
  esac
  if [ "$lock_pid" -gt 0 ] && kill -0 "$lock_pid" 2>/dev/null; then
    if [ "$force" -eq 1 ]; then
      exit 1
    fi
    exit 0
  fi
  rm -f "$lock_dir/pid"
  rmdir "$lock_dir" 2>/dev/null || exit 0
  mkdir "$lock_dir" 2>/dev/null || exit 0
fi
lock_held=1
printf '%s\n' "$$" > "$lock_dir/pid"

now_epoch=$(date +%s 2>/dev/null || printf '0')
now_iso=$(date -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || printf 'unknown')

if [ "$force" -ne 1 ] && [ -f "$status_file" ]; then
  last_attempt=$(sed -n 's/^attempt_epoch=//p' "$status_file" | head -n 1)
  case "$last_attempt" in
    ''|*[!0-9]*) last_attempt=0 ;;
  esac
  if [ "$now_epoch" -gt 0 ] && [ $((now_epoch - last_attempt)) -lt "$interval_seconds" ]; then
    exit 0
  fi
fi

old_sha=''
new_sha=''
finish() {
  result="$1"
  detail="$2"
  tmp_status="$status_file.tmp.$$"
  {
    printf 'attempt_epoch=%s\n' "$now_epoch"
    printf 'attempted_at=%s\n' "$now_iso"
    printf 'result=%s\n' "$result"
    printf 'detail=%s\n' "$detail"
    printf 'from=%s\n' "$old_sha"
    printf 'to=%s\n' "$new_sha"
  } > "$tmp_status" 2>/dev/null && mv "$tmp_status" "$status_file"
  if [ "$force" -eq 1 ] && [ "$result" = "skipped" ]; then
    exit 1
  fi
  exit 0
}

if [ ! -r "$repo_file" ]; then
  finish skipped missing_repository_config
fi

repo=$(sed -n '1p' "$repo_file")
line_count=$(wc -l < "$repo_file" 2>/dev/null | tr -d ' ')
case "$repo" in
  /*) ;;
  *) finish skipped invalid_repository_config ;;
esac
if [ "$line_count" != "1" ] || [ ! -d "$repo" ]; then
  finish skipped invalid_repository_config
fi

repo=$(cd "$repo" 2>/dev/null && pwd -P) || finish skipped missing_repository

git_repo() {
  command git \
    -c core.hooksPath=/dev/null \
    -c core.fsmonitor=false \
    -C "$repo" "$@"
}

top=$(git_repo rev-parse --show-toplevel 2>/dev/null) || finish skipped invalid_repository
top=$(cd "$top" 2>/dev/null && pwd -P) || finish skipped invalid_repository
if [ "$top" != "$repo" ]; then
  finish skipped invalid_repository
fi

origin=$(git_repo config --get remote.origin.url 2>/dev/null) || finish skipped missing_origin
case "$origin" in
  "$expected_remote"|"${expected_remote%.git}" \
    |git@github.com:BELCORT-SDN-BHD/orchestration-skill.git \
    |ssh://git@github.com/BELCORT-SDN-BHD/orchestration-skill.git) ;;
  *) finish skipped unexpected_origin ;;
esac

branch=$(git_repo symbolic-ref --quiet --short HEAD 2>/dev/null) || finish skipped detached_head
if [ "$branch" != "main" ]; then
  finish skipped non_main_branch
fi

worktree=$(git_repo status --porcelain=v1 --untracked-files=normal 2>/dev/null) \
  || finish skipped unreadable_worktree
if [ -n "$worktree" ]; then
  finish skipped dirty_worktree
fi

old_sha=$(git_repo rev-parse HEAD 2>/dev/null) || finish skipped invalid_head

if ! GIT_TERMINAL_PROMPT=0 git_repo \
  -c credential.interactive=never \
  -c http.lowSpeedLimit=1 \
  -c http.lowSpeedTime=30 \
  fetch --quiet --no-tags "$expected_remote" \
  refs/heads/main:refs/remotes/origin/main 2>/dev/null; then
  finish skipped fetch_failed
fi

new_sha=$(git_repo rev-parse 'refs/remotes/origin/main^{commit}' 2>/dev/null) \
  || finish skipped invalid_remote_head

if [ "$old_sha" = "$new_sha" ]; then
  finish current already_current
fi

if ! git_repo merge-base --is-ancestor "$old_sha" "$new_sha" 2>/dev/null; then
  finish skipped remote_not_fast_forward
fi

entry=$(git_repo ls-tree "$new_sha" -- skills/orchestration/SKILL.md 2>/dev/null) \
  || finish skipped invalid_skill_tree
set -- $entry
if [ "${1:-}" != "100644" ] || [ "${2:-}" != "blob" ]; then
  finish skipped invalid_skill_tree
fi

skill_size=$(git_repo cat-file -s "$new_sha:skills/orchestration/SKILL.md" 2>/dev/null) \
  || finish skipped invalid_skill_blob
case "$skill_size" in
  ''|*[!0-9]*) finish skipped invalid_skill_blob ;;
esac
if [ "$skill_size" -lt 80 ] || [ "$skill_size" -gt 32768 ]; then
  finish skipped invalid_skill_size
fi

skill_tmp=$(mktemp "$state_dir/skill.XXXXXX" 2>/dev/null) \
  || finish skipped temporary_file_failed
if ! git_repo show "$new_sha:skills/orchestration/SKILL.md" > "$skill_tmp" 2>/dev/null; then
  rm -f "$skill_tmp"
  finish skipped invalid_skill_blob
fi

first_line=$(sed -n '1p' "$skill_tmp")
delimiter_count=$(grep -c '^---$' "$skill_tmp" 2>/dev/null || true)
if [ "$first_line" != "---" ] \
  || [ "$delimiter_count" -lt 2 ] \
  || ! sed -n '1,20p' "$skill_tmp" | grep -Fqx 'name: orchestration' \
  || ! sed -n '1,20p' "$skill_tmp" | grep -Fqx 'disable-model-invocation: true'; then
  rm -f "$skill_tmp"
  finish skipped invalid_skill_structure
fi
rm -f "$skill_tmp"

# Re-check after the network operation in case the user changed the checkout.
if [ "$(git_repo symbolic-ref --quiet --short HEAD 2>/dev/null || true)" != "main" ] \
  || [ "$(git_repo rev-parse HEAD 2>/dev/null || true)" != "$old_sha" ] \
  || [ -n "$(git_repo status --porcelain=v1 --untracked-files=normal 2>/dev/null || printf 'unreadable')" ]; then
  finish skipped worktree_changed_during_update
fi

if ! git_repo merge --quiet --ff-only "$new_sha" >/dev/null 2>&1; then
  finish skipped fast_forward_failed
fi

if [ "$(git_repo rev-parse HEAD 2>/dev/null || true)" != "$new_sha" ]; then
  finish skipped fast_forward_failed
fi

finish updated fast_forwarded
