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

if set(frontmatter) != {"name", "description"}:
    raise SystemExit("frontmatter must contain only name and description")
if frontmatter["name"] != "orchestration":
    raise SystemExit("skill name must be orchestration")
if "$orchestration" not in frontmatter["description"]:
    raise SystemExit("description must advertise explicit Codex invocation")
if "/orchestration" not in frontmatter["description"]:
    raise SystemExit("description must advertise explicit Claude invocation")
if "TODO" in text:
    raise SystemExit("skill contains unresolved TODO")

version = (skill / "VERSION").read_text(encoding="utf-8").strip()
if not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", version):
    raise SystemExit("VERSION must be semantic x.y.z")

for relative in sorted(set(re.findall(r"(?:references|scripts)/[A-Za-z0-9._-]+", text))):
    if not (skill / relative).is_file():
        raise SystemExit(f"missing referenced resource: {relative}")

openai_yaml = (skill / "agents" / "openai.yaml").read_text(encoding="utf-8")
if "$orchestration" not in openai_yaml:
    raise SystemExit("agents/openai.yaml default prompt must invoke $orchestration")

print("SKILL_VALIDATION=pass")
