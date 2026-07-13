#!/usr/bin/env python3
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
skill = root / "skills" / "orchestration"
text = (skill / "SKILL.md").read_text(encoding="utf-8")

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

if not {"name", "description"} <= set(frontmatter):
    raise SystemExit("frontmatter must contain name and description")
if frontmatter["name"] != "orchestration":
    raise SystemExit("skill name must be orchestration")
if "$orchestration" not in frontmatter["description"]:
    raise SystemExit("description must advertise explicit Codex invocation")
if "/orchestration" not in frontmatter["description"]:
    raise SystemExit("description must advertise explicit Claude invocation")
if len(frontmatter["description"]) > 500:
    raise SystemExit("description over 500 chars — keep it to triggering conditions")
for banned in ("Fable", "Sol", "GPT"):
    if banned in frontmatter["description"]:
        raise SystemExit(f"description must not hardcode model names ({banned}); bindings live in MODEL-ROUTING.md")
if "TODO" in text:
    raise SystemExit("skill contains unresolved TODO")

for relative in sorted(set(re.findall(r"(?:references|scripts)/[A-Za-z0-9._-]+", text))):
    if not (skill / relative).is_file():
        raise SystemExit(f"missing referenced resource: {relative}")

openai_yaml = (skill / "agents" / "openai.yaml").read_text(encoding="utf-8")
if "$orchestration" not in openai_yaml:
    raise SystemExit("agents/openai.yaml default prompt must invoke $orchestration")

required_phrases = (
    "Orchestrator (this session, the brain)",
    "There is no separate routine decision layer",
    "Delegate nontrivial investigation",
    "references/MODEL-ROUTING.md",
)
for phrase in required_phrases:
    if phrase not in text:
        raise SystemExit(f"SKILL.md missing v3 invariant: {phrase}")

for banned in (
    "every judgment call",
    "advisor-gated",
    "consult the advisor",
    "initial plan or decomposition of a program is itself a judgment call",
):
    if banned.lower() in text.lower():
        raise SystemExit(f"SKILL.md retains removed approval layer: {banned}")

for legacy in (
    skill / "references" / "ADVISOR-PROTOCOL.md",
    skill / "scripts" / "advisor.sh",
):
    if legacy.exists():
        raise SystemExit(f"legacy advisor artifact must be removed: {legacy.relative_to(root)}")

# Core invariant: model names live only in the binding files (tests may use
# stub fixtures). Everything else must speak in lanes and roles.
binding_files = {
    skill / "references" / "MODEL-ROUTING.md",
}
model_name = re.compile(
    r"\b(Fable|Opus|Sonnet|Haiku|Terra|Luna|Sol|GPT-5[.\d]*|gpt-5[.\w-]*"
    r"|claude-(?:fable|opus|sonnet|haiku)[\w.-]*)\b"
)
for path in sorted(root.rglob("*")):
    if not path.is_file() or ".git" in path.parts or "tests" in path.parts:
        continue
    if path in binding_files:
        continue
    try:
        content = path.read_text(encoding="utf-8")
    except (UnicodeDecodeError, OSError):
        continue
    match = model_name.search(content)
    if match:
        raise SystemExit(
            f"model name '{match.group(0)}' outside binding files: {path.relative_to(root)}"
        )

print("SKILL_VALIDATION=pass")
