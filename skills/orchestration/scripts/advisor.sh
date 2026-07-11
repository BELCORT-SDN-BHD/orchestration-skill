#!/usr/bin/env bash
# advisor.sh <fable|sol> <prompt-file> <out-dir> [wall-minutes]
#
# Launches a fresh, read-only advisor session and enforces the protocol
# mechanically: liveness (stall without new output), a hard wall, and
# provenance capture.
#
# Writes into <out-dir>:
#   events.jsonl      raw event stream from the CLI
#   memo.md           the advisor's final answer
#   provenance.json   requested vs observed model/effort, ids, hashes, status
#
# Exit codes: 0 complete | 2 usage error | 3 unavailable | 4 incomplete
set -u

STALL_FABLE=300   # claude stream-json emits token heartbeats; 5 min is safe
STALL_SOL=600     # codex --json has no heartbeats between items; allow deep thought
DEFAULT_WALL_MIN=20
POLL_SECONDS=10

usage() {
  echo "usage: $0 <fable|sol> <prompt-file> <out-dir> [wall-minutes]" >&2
  echo "stall: ${STALL_FABLE}s (fable) / ${STALL_SOL}s (sol) without output; wall default: ${DEFAULT_WALL_MIN} min" >&2
  exit 2
}
[ $# -ge 3 ] || usage
role="$1"; prompt="$2"; out="$3"; wall_min="${4:-$DEFAULT_WALL_MIN}"
[ -f "$prompt" ] || { echo "prompt file not found: $prompt" >&2; exit 2; }
mkdir -p "$out"
events="$out/events.jsonl"; errlog="$out/stderr.log"; memo="$out/memo.md"; prov="$out/provenance.json"
: > "$events"; : > "$errlog"

sha256() { shasum -a 256 "$1" 2>/dev/null | awk '{print $1}'; }
utcnow() { date -u +%Y-%m-%dT%H:%M:%SZ; }
start_iso=$(utcnow)

case "$role" in
  fable)
    requested_model="fable"; requested_effort="max"; stall_limit=$STALL_FABLE
    command -v claude >/dev/null 2>&1 || { echo "claude CLI not installed" >&2; exit 3; }
    # --tools restricts only the BUILT-IN set; --strict-mcp-config drops user
    # MCP servers and disableAllHooks stops user hooks (without them the
    # session loads write-capable MCP tools and runs SessionStart hooks).
    # Not --bare: it would bypass keychain/OAuth auth.
    cmd=(claude -p --model fable --effort max
      --permission-mode dontAsk --tools "Read,Grep,Glob"
      --strict-mcp-config --settings '{"disableAllHooks":true}'
      --disable-slash-commands
      --output-format stream-json --verbose)
    ;;
  sol)
    requested_model="gpt-5.6-sol"; requested_effort="ultra"; stall_limit=$STALL_SOL
    command -v codex >/dev/null 2>&1 || { echo "codex CLI not installed" >&2; exit 3; }
    # No --ephemeral: the rollout file under the codex home is the only
    # record of which model actually answered. --ignore-user-config does NOT
    # unload installed skills; the evidence-pack preamble is the guard.
    cmd=(codex exec --ignore-user-config --skip-git-repo-check
      --sandbox read-only --json
      -m gpt-5.6-sol -c model_reasoning_effort=ultra
      -o "$memo" -)
    ;;
  *) usage ;;
esac

"${cmd[@]}" < "$prompt" > "$events" 2> "$errlog" &
pid=$!

terminate() {
  pkill -P "$pid" 2>/dev/null
  kill "$pid" 2>/dev/null
  for _ in 1 2 3 4 5; do
    kill -0 "$pid" 2>/dev/null || return 0
    sleep 2
  done
  pkill -9 -P "$pid" 2>/dev/null
  kill -9 "$pid" 2>/dev/null
}

status="complete"
wall_limit=$((wall_min * 60)); start_s=$(date +%s); last_size=0; last_change=$start_s
while kill -0 "$pid" 2>/dev/null; do
  sleep "$POLL_SECONDS"
  now_s=$(date +%s)
  size=$(wc -c < "$events" 2>/dev/null | tr -d ' ')
  if [ "${size:-0}" -gt "$last_size" ]; then last_size=$size; last_change=$now_s; fi
  if [ $((now_s - last_change)) -ge "$stall_limit" ]; then
    terminate; status="incomplete: no progress"; break
  fi
  if [ $((now_s - start_s)) -ge "$wall_limit" ]; then
    terminate; status="incomplete: wall"; break
  fi
done
wait "$pid" 2>/dev/null; rc=$?
end_iso=$(utcnow)

# Classify, extract the memo and the observed model, write provenance.
ROLE="$role" EVENTS="$events" ERRLOG="$errlog" MEMO="$memo" PROV="$prov" \
STATUS="$status" RC="$rc" REQ_MODEL="$requested_model" REQ_EFFORT="$requested_effort" \
START="$start_iso" END="$end_iso" PROMPT_SHA="$(sha256 "$prompt")" \
python3 <<'PY'
import glob, hashlib, json, os, re, sys

role, events_path, memo_path = os.environ["ROLE"], os.environ["EVENTS"], os.environ["MEMO"]
status, rc = os.environ["STATUS"], int(os.environ["RC"])
observed_model = observed_effort = "unknown"
session_id = "unknown"
result_error = False

def read_jsonl(path):
    try:
        with open(path, errors="replace") as f:
            for line in f:
                line = line.strip()
                if line.startswith("{"):
                    try: yield json.loads(line)
                    except json.JSONDecodeError: pass
    except OSError: pass

if role == "fable":
    for ev in read_jsonl(events_path):
        if ev.get("type") == "result":
            session_id = ev.get("session_id", session_id)
            result_error = bool(ev.get("is_error"))
            mu = ev.get("modelUsage") or {}
            if mu: observed_model = ",".join(sorted(mu))
            text = ev.get("result")
            if text:
                with open(memo_path, "w") as f: f.write(text)
        elif ev.get("type") == "system" and ev.get("model"):
            observed_model = ev["model"]
else:  # sol
    for ev in read_jsonl(events_path):
        if ev.get("type") == "thread.started":
            session_id = ev.get("thread_id", session_id)
    if session_id != "unknown":
        codex_home = os.environ.get("CODEX_HOME") or os.path.expanduser("~/.codex")
        pattern = f"{codex_home}/sessions/*/*/*/rollout-*{session_id}.jsonl"
        for rollout in glob.glob(pattern):
            for ev in read_jsonl(rollout):
                payload = ev.get("payload") or {}
                if payload.get("model"):
                    observed_model = payload["model"]
                    observed_effort = (payload.get("collaboration_mode", {}).get("settings", {})
                                       .get("reasoning_effort") or payload.get("effort")
                                       or observed_effort)

memo_exists = os.path.isfile(memo_path) and os.path.getsize(memo_path) > 0
if status == "complete":
    try:
        err = open(os.environ["ERRLOG"], errors="replace").read()
    except OSError:
        err = ""
    terminal = re.search(
        r"(?i)(rate.?limit|capacity|overloaded|refus|unauthorized|forbidden|"
        r"authentication|not logged in|billing|credit)", err)
    if rc == 0 and memo_exists and not result_error:
        pass  # complete
    elif terminal:
        status = "unavailable"
    elif memo_exists:
        status = "incomplete: failed run"
    else:
        status = "incomplete: empty output"

memo_sha = hashlib.sha256(open(memo_path, "rb").read()).hexdigest() if memo_exists else None
json.dump({
    "role": role, "status": status, "exit_code": rc,
    "requested_model": os.environ["REQ_MODEL"], "requested_effort": os.environ["REQ_EFFORT"],
    "observed_model": observed_model, "observed_effort": observed_effort,
    "session_id": session_id,
    "started": os.environ["START"], "ended": os.environ["END"],
    "prompt_sha256": os.environ["PROMPT_SHA"], "memo_sha256": memo_sha,
}, open(os.environ["PROV"], "w"), indent=2)
print(f"ADVISOR_STATUS={status}")
print(f"ADVISOR_OBSERVED_MODEL={observed_model}")
print(f"ADVISOR_MEMO={memo_path if memo_exists else 'none'}")
print(f"ADVISOR_PROVENANCE={os.environ['PROV']}")
sys.exit(0 if status == "complete" else 3 if status == "unavailable" else 4)
PY
