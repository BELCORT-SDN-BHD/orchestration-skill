#!/usr/bin/env bash
# advisor.sh <fable|sol> <prompt-file> <out-dir> [wall-minutes] [effort]
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

STALL_FABLE=300   # claude stream-json emits thinking_tokens heartbeats every 1-2s; 5 min is safe
STALL_SOL=900     # codex --json is silent until the first item; deep memos show 6+ min TTFT
DEFAULT_WALL_MIN=20
POLL_SECONDS=10

usage() {
  echo "usage: $0 <fable|sol> <prompt-file> <out-dir> [wall-minutes] [effort]" >&2
  echo "stall: ${STALL_FABLE}s (fable) / ${STALL_SOL}s (sol) without output; wall default: ${DEFAULT_WALL_MIN} min" >&2
  echo "effort: fable xhigh (default) or max — max is the predeclared high-consequence escalation and requires wall-minutes >= 40; sol is fixed at max" >&2
  exit 2
}
[ $# -ge 3 ] || usage
role="$1"; prompt="$2"; out="$3"; wall_min="${4:-$DEFAULT_WALL_MIN}"; effort_arg="${5:-}"
[ -f "$prompt" ] || { echo "prompt file not found: $prompt" >&2; exit 2; }
mkdir -p "$out"
events="$out/events.jsonl"; errlog="$out/stderr.log"; memo="$out/memo.md"; prov="$out/provenance.json"
: > "$events"; : > "$errlog"

sha256() { shasum -a 256 "$1" 2>/dev/null | awk '{print $1}'; }
utcnow() { date -u +%Y-%m-%dT%H:%M:%SZ; }
start_iso=$(utcnow)

case "$role" in
  fable)
    requested_model="fable"; requested_effort="${effort_arg:-xhigh}"; stall_limit=$STALL_FABLE
    # xhigh is the capability-sensitive agentic setting (Claude Code's own
    # default); max is documented for frontier, latency-insensitive work and
    # routinely outruns the wall — allow it only as a predeclared escalation
    # paired with an extended wall.
    case "$requested_effort" in
      xhigh) ;;
      max)
        [ "$wall_min" -ge 40 ] || { echo "effort max requires wall-minutes >= 40 (predeclare the extended wall)" >&2; exit 2; }
        ;;
      *) echo "fable effort must be xhigh or max" >&2; exit 2 ;;
    esac
    command -v claude >/dev/null 2>&1 || { echo "claude CLI not installed" >&2; exit 3; }
    # --tools restricts only the BUILT-IN set; --strict-mcp-config drops user
    # MCP servers and disableAllHooks stops user hooks (without them the
    # session loads write-capable MCP tools and runs SessionStart hooks).
    # Not --bare: it would bypass keychain/OAuth auth.
    cmd=(claude -p --model fable --effort "$requested_effort"
      --permission-mode dontAsk --tools "Read,Grep,Glob"
      --strict-mcp-config --settings '{"disableAllHooks":true}'
      --disable-slash-commands
      --output-format stream-json --verbose)
    ;;
  sol)
    requested_model="gpt-5.6-sol"; requested_effort="max"; stall_limit=$STALL_SOL
    # max is the deepest SINGLE-AGENT setting. ultra layers multi-agent
    # fanout (spawn_agent) on top of max — the one thing the advisor
    # protocol forbids — so it is banned here, and features.multi_agent is
    # disabled mechanically (the evidence-pack preamble stays as the prose
    # guard). Any spawn_agent call found in the rollout is flagged.
    [ -z "$effort_arg" ] || [ "$effort_arg" = "max" ] || {
      echo "sol effort is fixed at max (ultra is a multi-agent mode the advisor protocol forbids)" >&2; exit 2; }
    command -v codex >/dev/null 2>&1 || { echo "codex CLI not installed" >&2; exit 3; }
    # No --ephemeral: the rollout file under the codex home is the only
    # record of which model actually answered. --ignore-user-config does NOT
    # unload installed skills; the evidence-pack preamble is the guard.
    cmd=(codex exec --ignore-user-config --skip-git-repo-check
      --sandbox read-only --json
      -m gpt-5.6-sol -c model_reasoning_effort=max
      -c features.multi_agent=false
      -o "$memo" -)
    ;;
  *) usage ;;
esac

"${cmd[@]}" < "$prompt" > "$events" 2> "$errlog" &
pid=$!

# Collect the full descendant tree (deepest first) so codex/claude helper
# grandchildren cannot survive as token-burning orphans.
descendants() {
  level="$1"; all=""
  while [ -n "$level" ]; do
    all="$level $all"
    next=""
    for p in $level; do
      next="$next $(pgrep -P "$p" 2>/dev/null | tr '\n' ' ')"
    done
    level=$(printf '%s' "$next" | tr -s ' ' | sed 's/^ //; s/ $//')
  done
  printf '%s' "$all"
}

terminate() {
  victims=$(descendants "$pid")
  kill $victims 2>/dev/null
  for _ in 1 2 3 4 5; do
    kill -0 "$pid" 2>/dev/null || return 0
    sleep 2
  done
  victims=$(descendants "$pid")
  kill -9 $victims 2>/dev/null
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
memo_partial = False
spawn_agent_calls = 0
assistant_texts = []

def read_jsonl(path):
    try:
        with open(path, errors="replace") as f:
            for line in f:
                line = line.strip()
                if line.startswith("{"):
                    try: yield json.loads(line)
                    except json.JSONDecodeError: pass
    except OSError: pass

# Extraction must never abort provenance: on any parse surprise, keep the
# defaults ("unknown") and still write provenance.json + the ADVISOR_* lines.
try:
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
            elif ev.get("type") == "assistant":
                for blk in (ev.get("message") or {}).get("content") or []:
                    if isinstance(blk, dict) and blk.get("type") == "text" and blk.get("text"):
                        assistant_texts.append(blk["text"])
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
                    if not isinstance(payload, dict):
                        continue
                    if payload.get("model"):
                        observed_model = payload["model"]
                        settings = (payload.get("collaboration_mode") or {}).get("settings") or {}
                        observed_effort = (settings.get("reasoning_effort")
                                           or payload.get("effort") or observed_effort)
                    # Delegation is forbidden by the advisor protocol; count
                    # violations so the orchestrator can report them.
                    if payload.get("type") == "function_call" and payload.get("name") == "spawn_agent":
                        spawn_agent_calls += 1
except Exception as exc:
    print(f"ADVISOR_PARSE_WARNING={exc}", file=sys.stderr)

# A killed or truncated fable run has no "result" event, but the stream may
# hold completed assistant text — recover it rather than discard the spend.
memo_exists = os.path.isfile(memo_path) and os.path.getsize(memo_path) > 0
if role == "fable" and not memo_exists and assistant_texts:
    with open(memo_path, "w") as f:
        f.write("> PARTIAL MEMO — run terminated before a final result; "
                "text recovered from the event stream. Treat as incomplete evidence.\n\n")
        f.write("\n\n".join(assistant_texts))
    memo_exists = True
    memo_partial = True

if status == "complete":
    try:
        err = open(os.environ["ERRLOG"], errors="replace").read()
    except OSError:
        err = ""
    # "connection refused" is a transient transport error, not a terminal
    # advisor condition — strip it before matching "refus".
    err = re.sub(r"(?i)connection\s+refused", "", err)
    terminal = re.search(
        r"(?i)(rate.?limit|too many requests|\b429\b|quota|capacity|overloaded|refus|"
        r"unauthorized|forbidden|authentication|not logged in|billing|"
        r"credit balance|insufficient credit)", err)
    if rc == 0 and memo_exists and not memo_partial and not result_error:
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
    "memo_partial": memo_partial, "spawn_agent_calls": spawn_agent_calls,
}, open(os.environ["PROV"], "w"), indent=2)
print(f"ADVISOR_STATUS={status}")
print(f"ADVISOR_OBSERVED_MODEL={observed_model}")
print(f"ADVISOR_MEMO={memo_path if memo_exists else 'none'}")
print(f"ADVISOR_PROVENANCE={os.environ['PROV']}")
if memo_partial:
    print("ADVISOR_MEMO_PARTIAL=true")
if spawn_agent_calls:
    print(f"ADVISOR_PROTOCOL_VIOLATION=spawn_agent_calls:{spawn_agent_calls}")
sys.exit(0 if status == "complete" else 3 if status == "unavailable" else 4)
PY
