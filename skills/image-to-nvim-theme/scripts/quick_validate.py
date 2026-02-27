#!/usr/bin/env python3
"""Dependency-free validator for Codex skills.

Validate the minimal structure and metadata required by this skill without
external Python packages (for example PyYAML).
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path


SKILL_NAME_RE = re.compile(r"^[a-z0-9-]{1,64}$")
LINK_RE = re.compile(r"\[([^\]]+)\]\(([^)]+)\)")


def read_text(path: Path) -> str:
  return path.read_text(encoding="utf-8")


def parse_frontmatter(skill_md: Path) -> tuple[str, str]:
  text = read_text(skill_md)
  lines = text.splitlines()
  if len(lines) < 4 or lines[0].strip() != "---":
    raise ValueError("SKILL.md must start with YAML frontmatter delimited by ---")

  end_idx = None
  for i in range(1, len(lines)):
    if lines[i].strip() == "---":
      end_idx = i
      break
  if end_idx is None:
    raise ValueError("SKILL.md frontmatter is not closed with ---")

  frontmatter = lines[1:end_idx]
  values: dict[str, str] = {}
  for line in frontmatter:
    if ":" not in line:
      continue
    key, value = line.split(":", 1)
    values[key.strip()] = value.strip()

  name = values.get("name", "")
  description = values.get("description", "")
  if not name:
    raise ValueError('SKILL.md frontmatter must include "name"')
  if not description:
    raise ValueError('SKILL.md frontmatter must include "description"')
  if "TODO" in description:
    raise ValueError('SKILL.md "description" must not include TODO placeholders')
  if not SKILL_NAME_RE.match(name):
    raise ValueError(
      'SKILL.md "name" must match ^[a-z0-9-]{1,64}$ (lowercase letters, digits, hyphens)'
    )
  return name, description


def validate_openai_yaml(path: Path) -> None:
  text = read_text(path)
  required_keys = [
    "interface:",
    "display_name:",
    "short_description:",
    "default_prompt:",
  ]
  for key in required_keys:
    if key not in text:
      raise ValueError(f"agents/openai.yaml missing required key: {key}")
  if "TODO" in text:
    raise ValueError("agents/openai.yaml contains TODO placeholders")


def validate_local_links(skill_md: Path) -> None:
  text = read_text(skill_md)
  for _, target in LINK_RE.findall(text):
    if target.startswith("http://") or target.startswith("https://"):
      continue
    link_path = (skill_md.parent / target).resolve()
    if not link_path.exists():
      raise ValueError(f"SKILL.md link target does not exist: {target}")


def validate(skill_dir: Path) -> list[str]:
  messages: list[str] = []

  if not skill_dir.exists():
    raise ValueError(f"Skill directory not found: {skill_dir}")
  if not skill_dir.is_dir():
    raise ValueError(f"Path is not a directory: {skill_dir}")

  skill_md = skill_dir / "SKILL.md"
  openai_yaml = skill_dir / "agents" / "openai.yaml"

  if not skill_md.exists():
    raise ValueError("Missing required file: SKILL.md")
  if not openai_yaml.exists():
    raise ValueError("Missing required file: agents/openai.yaml")

  name, _ = parse_frontmatter(skill_md)
  expected_name = skill_dir.name
  if name != expected_name:
    raise ValueError(
      f'SKILL.md name "{name}" must match directory name "{expected_name}"'
    )
  messages.append(f'[OK] SKILL.md frontmatter valid (name="{name}")')

  validate_openai_yaml(openai_yaml)
  messages.append("[OK] agents/openai.yaml interface keys present")

  validate_local_links(skill_md)
  messages.append("[OK] SKILL.md local links resolve")

  return messages


def main() -> int:
  parser = argparse.ArgumentParser(
    description="Validate a skill folder with no external dependencies."
  )
  parser.add_argument(
    "skill_path",
    nargs="?",
    default=".",
    help="Path to skill folder (default: current directory)",
  )
  args = parser.parse_args()

  skill_dir = Path(args.skill_path).resolve()
  try:
    results = validate(skill_dir)
  except ValueError as err:
    print(f"[ERROR] {err}")
    return 1

  print(f"[OK] Validation passed: {skill_dir}")
  for line in results:
    print(line)
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
