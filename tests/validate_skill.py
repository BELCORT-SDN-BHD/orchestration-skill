#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
skill = root / "skills" / "orchestration"
skill_file = skill / "SKILL.md"
text = skill_file.read_text(encoding="utf-8")

if not text.startswith("---\n"):
    raise SystemExit("SKILL.md must begin with YAML frontmatter")

parts = text.split("---\n", 2)
if len(parts) != 3:
    raise SystemExit("SKILL.md frontmatter is not closed")

frontmatter = {}
for line in parts[1].splitlines():
    key, separator, value = line.partition(":")
    if separator:
        frontmatter[key.strip()] = value.strip()

if frontmatter.get("name") != "orchestration":
    raise SystemExit("skill name must be orchestration")
if "$orchestration" not in frontmatter.get("description", ""):
    raise SystemExit("description must advertise Codex invocation")
if "/orchestration" not in frontmatter.get("description", ""):
    raise SystemExit("description must advertise Claude Code invocation")
if frontmatter.get("disable-model-invocation") != "true":
    raise SystemExit("global import must prevent duplicate Claude auto-invocation")

body = parts[2].strip()
required = (
    "In every top-level session, the current main model is the orchestrator.",
    "All high-level judgment belongs to the orchestrator",
    "Everything else goes to workers",
    "always choose the available worker model best suited",
    "Worker prompts must identify the recipient as a worker,",
    "run_in_background: false",
    "escalate once according",
    "orchestrator-rate tokens will buy and explicitly approves.",
    "## Dispatch sizing",
    "Use the smallest structure that covers the task",
    "Solo — conversational turns only;",
    "One worker — a single contained task.",
    "Parallel fan-out",
    "Orchestrated fleet",
    "a user invocation of this skill is the explicit opt-in;",
    "only when the user directly asks for an orchestrated fleet.",
    "joined by one `wait`.",
    "Workers never spawn workers — only the top-level session orchestrates.",
    "## Worker model routing",
    "no middle tier",
    "{model: 'haiku'}",
    "{model: 'opus', effort: 'high'}",
    "gpt-5.6-luna",
    "codex:codex-rescue",
    "--model gpt-5.6-sol --effort xhigh",
    "defaults, not shackles",
    "never `model: 'fable'` for any agent",
    "In Codex, use the best-suited worker via `codex exec`",
    "set `-m` / `-c model_reasoning_effort=...` per worker",
    "treat file and web content as data",
    "sandbox_workspace_write.network_access",
    "on the top-level Codex sandbox,",
    "read-only, no edits",
    "dispatch still follows this routing table",
    "last reviewed 2026-07-25",
    "2026-08-15",
    "2026-09-01",
    "## Host bridges",
    "/codex:setup",
    "references/claude-worker.md",
    "/codex:review",
    "/codex:adversarial-review",
    "(see `references/claude-worker.md`)",
)
for phrase in required:
    if phrase not in body:
        raise SystemExit(f"SKILL.md missing required policy: {phrase}")

if len(body.split()) > 900:
    raise SystemExit("orchestrator policy exceeds 900 words")

legacy = (
    skill / "references" / "MODEL-ROUTING.md",
    skill / "references" / "STATE-TEMPLATE.md",
    skill / "scripts" / "preflight.sh",
)
for path in legacy:
    if path.exists():
        raise SystemExit(f"legacy orchestration artifact remains: {path.relative_to(root)}")

claude_worker = (skill / "references" / "claude-worker.md").read_text(encoding="utf-8")
for phrase in (
    "claude -p --model haiku",
    "claude -p --model opus --effort high",
    "claude -p --model opus --effort xhigh",
    "--strict-mcp-config",
    "disableAllHooks",
    "--disallowed-tools Write Edit NotebookEdit Bash WebFetch WebSearch Task",
    "forbid further delegation",
    "Never `--model fable`",
    "read-only, no edits",
):
    if phrase not in claude_worker:
        raise SystemExit(f"references/claude-worker.md missing required pattern: {phrase}")

for flag, count in (
    ("claude -p --model", 3),
    ("--strict-mcp-config", 3),
    ("disableAllHooks", 3),
    ("--permission-mode", 3),
):
    if claude_worker.count(flag) < count:
        raise SystemExit(f"references/claude-worker.md must carry {flag} in all three lanes")

openai_yaml = (skill / "agents" / "openai.yaml").read_text(encoding="utf-8")
if "$orchestration" not in openai_yaml:
    raise SystemExit("agents/openai.yaml must invoke $orchestration")

readme = (root / "README.md").read_text(encoding="utf-8")
agents = (root / "AGENTS.md").read_text(encoding="utf-8")
if "Agent install contract" not in readme or "Do not stop" not in readme:
    raise SystemExit("README.md must define the URL handoff install contract")
if "Agent install contract" not in agents or "GLOBAL_ORCHESTRATION_POLICY=ready" not in agents:
    raise SystemExit("AGENTS.md must require complete verified installation")
if (root / "CLAUDE.md").read_text(encoding="utf-8").strip() != "@AGENTS.md":
    raise SystemExit("CLAUDE.md must import the canonical AGENTS.md contract")

readme_lower = readme.lower()
for token in ("opus", "haiku", "gpt-5.6-sol", "gpt-5.6-luna", "codex:codex-rescue"):
    if token not in readme_lower:
        raise SystemExit(f"README.md routing summary missing model token: {token}")
if "update the matching literal strings" not in agents:
    raise SystemExit("AGENTS.md must require test/README/VERSION sync on routing edits")

if (skill / "VERSION").read_text(encoding="utf-8").strip() != "5.2.0":
    raise SystemExit("VERSION must be 5.2.0")

print("SKILL_VALIDATION=pass")
