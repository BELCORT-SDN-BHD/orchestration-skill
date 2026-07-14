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
repo_root=$(cd "$skill_dir/../.." && pwd -P)
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

updater_source="$skill_dir/scripts/update-global.sh"
updater_target="$HOME/.local/libexec/orchestration-skill-update"
updater_config="$HOME/.config/orchestration-skill/repository"

install_updater() {
  mkdir -p "$(dirname "$updater_target")" "$(dirname "$updater_config")"

  updater_tmp="$updater_target.tmp.$$"
  cp "$updater_source" "$updater_tmp"
  chmod 755 "$updater_tmp"
  mv "$updater_tmp" "$updater_target"

  config_tmp="$updater_config.tmp.$$"
  printf '%s\n' "$repo_root" > "$config_tmp"
  mv "$config_tmp" "$updater_config"
}

xml_escape() {
  printf '%s' "$1" | sed \
    -e 's/&/\&amp;/g' \
    -e 's/</\&lt;/g' \
    -e 's/>/\&gt;/g' \
    -e 's/"/\&quot;/g' \
    -e "s/'/\\\&apos;/g"
}

schedule_macos() {
  label='com.belcort.orchestration-skill-update'
  plist="$HOME/Library/LaunchAgents/$label.plist"
  mkdir -p "$(dirname "$plist")"
  escaped_updater=$(xml_escape "$updater_target")
  escaped_home=$(xml_escape "$HOME")
  plist_tmp="$plist.tmp.$$"
  cat > "$plist_tmp" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$label</string>
  <key>ProgramArguments</key>
  <array>
    <string>$escaped_updater</string>
  </array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>HOME</key>
    <string>$escaped_home</string>
  </dict>
  <key>RunAtLoad</key>
  <true/>
  <key>StartInterval</key>
  <integer>3600</integer>
  <key>ProcessType</key>
  <string>Background</string>
</dict>
</plist>
EOF
  mv "$plist_tmp" "$plist"

  domain="gui/$(id -u)"
  launchctl bootout "$domain/$label" >/dev/null 2>&1 || true
  if launchctl bootstrap "$domain" "$plist" >/dev/null 2>&1 \
    || launchctl print "$domain/$label" >/dev/null 2>&1 \
    || launchctl load -w "$plist" >/dev/null 2>&1; then
    :
  else
    return 1
  fi
  launchctl enable "$domain/$label" >/dev/null 2>&1 || return 1
  launchctl print "$domain/$label" >/dev/null 2>&1 || return 1
  printf 'AUTO_UPDATE_SCHEDULED=launchd-hourly\n'
}

systemd_escape() {
  printf '%s' "$1" | sed \
    -e 's/\\/\\\\/g' \
    -e 's/"/\\"/g' \
    -e 's/%/%%/g'
}

schedule_systemd() {
  unit_dir="$HOME/.config/systemd/user"
  service="$unit_dir/orchestration-skill-update.service"
  timer="$unit_dir/orchestration-skill-update.timer"
  mkdir -p "$unit_dir"
  escaped_updater=$(systemd_escape "$updater_target")
  escaped_home=$(systemd_escape "$HOME")

  cat > "$service" <<EOF
[Unit]
Description=Update the shared orchestration skill

[Service]
Type=oneshot
Environment="HOME=$escaped_home"
ExecStart="$escaped_updater"
EOF

  cat > "$timer" <<'EOF'
[Unit]
Description=Update the shared orchestration skill hourly

[Timer]
OnBootSec=2m
OnUnitActiveSec=1h
Persistent=true
RandomizedDelaySec=5m

[Install]
WantedBy=timers.target
EOF

  if systemctl --user daemon-reload >/dev/null 2>&1 \
    && systemctl --user enable --now orchestration-skill-update.timer >/dev/null 2>&1 \
    && systemctl --user is-enabled --quiet orchestration-skill-update.timer >/dev/null 2>&1 \
    && systemctl --user is-active --quiet orchestration-skill-update.timer >/dev/null 2>&1; then
    printf 'AUTO_UPDATE_SCHEDULED=systemd-hourly\n'
    return 0
  fi
  return 1
}

install_updater
if ! "$updater_target" --force >/dev/null 2>&1; then
  update_detail=$(sed -n 's/^detail=//p' \
    "$HOME/.local/state/orchestration-skill/update-status" 2>/dev/null | head -n 1)
  printf 'AUTO_UPDATE_UNAVAILABLE=initial-check-%s\n' "${update_detail:-failed}" >&2
  exit 4
fi

update_result=$(sed -n 's/^result=//p' \
  "$HOME/.local/state/orchestration-skill/update-status" 2>/dev/null | head -n 1)
case "$update_result" in
  current|updated) ;;
  *)
    printf 'AUTO_UPDATE_UNAVAILABLE=unverified-initial-check\n' >&2
    exit 4
    ;;
esac

case "$(uname -s)" in
  Darwin)
    command -v launchctl >/dev/null 2>&1 || {
      printf 'AUTO_UPDATE_UNAVAILABLE=launchctl-not-found\n' >&2
      exit 4
    }
    if ! schedule_macos; then
      printf 'AUTO_UPDATE_UNAVAILABLE=launchd-registration-failed\n' >&2
      exit 4
    fi
    ;;
  Linux)
    if ! schedule_systemd; then
      printf 'AUTO_UPDATE_UNAVAILABLE=systemd-user-timer-failed\n' >&2
      exit 4
    fi
    ;;
  *)
    printf 'AUTO_UPDATE_UNAVAILABLE=unsupported-platform\n' >&2
    exit 4
    ;;
esac

test -f "${CODEX_HOME:-$HOME/.codex}/skills/orchestration/SKILL.md"
test -f "$HOME/.claude/skills/orchestration/SKILL.md"
grep -Fqx "$import_line" "$claude_md"
grep -Fqx "$codex_line" "$codex_agents"
test -x "$updater_target"
test ! -L "$updater_target"
test "$(sed -n '1p' "$updater_config")" = "$repo_root"

printf 'GLOBAL_ORCHESTRATION_POLICY=ready\n'
printf 'AUTO_UPDATE_INITIAL_CHECK=%s\n' "$update_result"
printf 'AUTO_UPDATE=ready\n'
printf 'Start a fresh host session before first use.\n'
