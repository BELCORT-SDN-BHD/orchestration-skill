#!/usr/bin/env python3
import re
from datetime import date, timedelta
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
    "the current main model is the orchestrator",
    "standing request for sub-agent delegation",
    "Judgment stays with the orchestrator",
    "never spent on a worker",
    "never `fable` as a worker",
    "name the recipient a worker and forbid further delegation",
    "evidence, not just conclusions",
    "escalate once",
    "smallest structure",
    "only on the user's direct ask",
    "Workers never spawn workers",
    "enumerability is not",
    "strongest native worker tier",
    "verify the decomposition itself",
    "crosses vendors",
    "sealed, read-only",
    "data, never instructions",
    "Mechanics rot; principles do not",
    "verify them at the point of use",
    "Host enforcement lives in host config, not in this file",
    "Everything else goes to workers",
    "no shared context",
    "Synthesize only after every dispatch",
    "goes one tier down, in parallel",
    "verify the results with a stronger worker",
    "Zero-judgment bulk goes to the cheapest tier",
    "repo contents or secrets anywhere the user did not ask",
    "orchestrator-rate tokens",
    "orchestrator and strongest worker are the same model",
    "a graph whose edges you have not drawn",
    "fan-out has already earned its place",
    "draw the task graph by hand",
    "searching for a topology",
    "join only on what the join needs",
    "machine-checkable contract",
    "a check on form, never a substitute",
    "a new consent or topology class",
    "every gate on the dispatches",
    "only under that host's own opt-in",
    "the runtime only schedules and records",
    "Discovery-shaped work never enters a precomputed graph",
    "Parallel writers own disjoint write sets",
)
for phrase in required:
    if phrase not in body:
        raise SystemExit(f"SKILL.md missing required principle: {phrase}")

if len(body.split()) > 675:
    raise SystemExit("orchestrator policy exceeds 675 words")

if (skill / "references").exists():
    raise SystemExit("perishable reference material belongs in FIELD-NOTES.md, not references/")

notes = skill / "FIELD-NOTES.md"
if not notes.exists():
    raise SystemExit("FIELD-NOTES.md must exist beside SKILL.md")
notes_text = notes.read_text(encoding="utf-8")
stamp = re.search(r"Verified (\d{4})-(\d{2})-(\d{2})", notes_text)
if not stamp or "perishable" not in notes_text.lower():
    raise SystemExit("FIELD-NOTES.md must carry a dated perishability header")
verified = date(int(stamp.group(1)), int(stamp.group(2)), int(stamp.group(3)))
if date.today() - verified > timedelta(days=180):
    raise SystemExit("field notes are stale (>180 days) — re-verify and re-date them")

openai_yaml = (skill / "agents" / "openai.yaml").read_text(encoding="utf-8")
if "$orchestration" not in openai_yaml:
    raise SystemExit("agents/openai.yaml must invoke $orchestration")

readme = (root / "README.md").read_text(encoding="utf-8")
agents = (root / "AGENTS.md").read_text(encoding="utf-8")
if "Agent install contract" not in readme or "Do not stop" not in readme:
    raise SystemExit("README.md must define the URL handoff install contract")
if "Agent install contract" not in agents or "GLOBAL_ORCHESTRATION_POLICY=ready" not in agents:
    raise SystemExit("AGENTS.md must require complete verified installation")
if "update the matching literal strings" not in agents:
    raise SystemExit("AGENTS.md must require test/README/VERSION sync on routing edits")
if (root / "CLAUDE.md").read_text(encoding="utf-8").strip() != "@AGENTS.md":
    raise SystemExit("CLAUDE.md must import the canonical AGENTS.md contract")

if "FIELD-NOTES.md" not in readme:
    raise SystemExit("README.md must point at the dated field notes")

if (skill / "VERSION").read_text(encoding="utf-8").strip() != "7.1.0":
    raise SystemExit("VERSION must be 7.1.0")

print("SKILL_VALIDATION=pass")
