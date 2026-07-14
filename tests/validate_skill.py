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
    "In every session, the current main model is the orchestrator.",
    "All high-level judgment belongs to the orchestrator",
    "Everything else goes to workers",
    "always choose the available worker model best suited",
    "codex:codex-rescue",
    "--model gpt-5.6-sol --effort xhigh",
    "In Codex, use the best-suited native Codex worker.",
)
for phrase in required:
    if phrase not in body:
        raise SystemExit(f"SKILL.md missing required policy: {phrase}")

if len(body.split()) > 260:
    raise SystemExit("orchestrator policy exceeds 260 words")

legacy = (
    skill / "references" / "MODEL-ROUTING.md",
    skill / "references" / "STATE-TEMPLATE.md",
    skill / "scripts" / "preflight.sh",
)
for path in legacy:
    if path.exists():
        raise SystemExit(f"legacy orchestration artifact remains: {path.relative_to(root)}")

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

updater = skill / "scripts" / "update-global.sh"
if not updater.is_file():
    raise SystemExit("automatic updater is missing")
if "AUTO_UPDATE=ready" not in readme:
    raise SystemExit("README.md must require verified automatic updates")
if "AUTO_UPDATE=ready" not in agents:
    raise SystemExit("AGENTS.md must require complete updater installation")

if (skill / "VERSION").read_text(encoding="utf-8").strip() != "4.1.0":
    raise SystemExit("VERSION must be 4.1.0")

print("SKILL_VALIDATION=pass")
