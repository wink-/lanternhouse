#!/usr/bin/env python3
"""Preflight checks for Lanternhouse autonomous Kanban/Godot workflows.

This is intentionally lightweight and local-first: it verifies the repo, Godot,
visual QA wrapper, and worker-profile skill availability before dispatching
artist/reviewer tasks.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Iterable

PROJECT = Path(__file__).resolve().parents[2]
HERMES_HOME = Path(os.environ.get("HERMES_HOME", Path.home() / ".hermes")).expanduser()
DEFAULT_BOARD = "2d-game"
DEFAULT_REQUIREMENTS = {
    "artist": [
        "lanternhouse-art-pipeline",
        "lanternhouse-visual-polish",
        "godot-headless-validation",
    ],
    "visual-reviewer": [
        "lanternhouse-visual-polish",
        "godot-headless-validation",
    ],
}


@dataclass
class Check:
    name: str
    ok: bool
    detail: str


def run(cmd: list[str], timeout: int = 20, cwd: Path = PROJECT) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, cwd=cwd, text=True, capture_output=True, timeout=timeout)


def resolve_godot(explicit: str | None = None) -> str | None:
    candidates: list[str] = []
    if explicit:
        candidates.append(explicit)
    if os.environ.get("GODOT_BIN"):
        candidates.append(os.environ["GODOT_BIN"])
    candidates += [
        str(Path.home() / ".local/bin/godot4"),
        str(Path.home() / ".local/bin/godot"),
        shutil.which("godot4") or "",
        shutil.which("godot") or "",
    ]
    for candidate in candidates:
        if candidate and Path(candidate).exists() and os.access(candidate, os.X_OK):
            return candidate
    return None


def skill_names_under(skill_root: Path) -> dict[str, list[Path]]:
    found: dict[str, list[Path]] = {}
    if not skill_root.exists():
        return found
    for skill_file in skill_root.rglob("SKILL.md"):
        text = skill_file.read_text(errors="replace")[:4000]
        match = re.search(r"^name:\s*['\"]?([^'\"\n]+)", text, flags=re.MULTILINE)
        name = match.group(1).strip() if match else skill_file.parent.name
        found.setdefault(name, []).append(skill_file.parent)
        # Also accept directory basename as a pragmatic fallback.
        found.setdefault(skill_file.parent.name, []).append(skill_file.parent)
    return found


def profile_skill_root(profile: str) -> Path:
    if profile in {"default", "main"}:
        return HERMES_HOME / "skills"
    return HERMES_HOME / "profiles" / profile / "skills"


def check_profile_skills(profile: str, skills: Iterable[str]) -> list[Check]:
    root = profile_skill_root(profile)
    names = skill_names_under(root)
    checks = [Check(f"profile:{profile}:skills_dir", root.exists(), str(root))]
    for skill in skills:
        matches = names.get(skill, [])
        if matches:
            checks.append(Check(f"profile:{profile}:skill:{skill}", True, ", ".join(str(p) for p in sorted(set(matches)))))
        else:
            checks.append(Check(f"profile:{profile}:skill:{skill}", False, f"missing under {root}"))
    return checks


def git_dirty_summary() -> str:
    proc = run(["git", "status", "--short"], timeout=10)
    if proc.returncode != 0:
        return f"git status failed: {proc.stderr.strip()}"
    lines = proc.stdout.splitlines()
    if not lines:
        return "clean"
    return f"{len(lines)} changed/untracked files"


def main() -> int:
    parser = argparse.ArgumentParser(description="Preflight Lanternhouse autonomous workflow prerequisites.")
    parser.add_argument("--board", default=DEFAULT_BOARD)
    parser.add_argument("--godot")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--profile-skill", action="append", default=[], metavar="PROFILE:SKILL", help="Extra profile skill requirement; repeatable.")
    args = parser.parse_args()

    requirements = {k: list(v) for k, v in DEFAULT_REQUIREMENTS.items()}
    for item in args.profile_skill:
        if ":" not in item:
            print(f"ERROR: --profile-skill must be PROFILE:SKILL, got {item!r}", file=sys.stderr)
            return 2
        profile, skill = item.split(":", 1)
        requirements.setdefault(profile, []).append(skill)

    checks: list[Check] = []
    checks.append(Check("project:root", (PROJECT / "project.godot").exists(), str(PROJECT)))
    checks.append(Check("project:visual_wrapper", os.access(PROJECT / "scripts/dev/capture_visual_qa.sh", os.X_OK), "scripts/dev/capture_visual_qa.sh"))
    checks.append(Check("project:layout_validator", (PROJECT / "scripts/dev/validate_town_layout.py").exists(), "scripts/dev/validate_town_layout.py"))
    checks.append(Check("project:git_status", True, git_dirty_summary()))

    godot = resolve_godot(args.godot)
    if godot:
        proc = run([godot, "--version"], timeout=20)
        detail = proc.stdout.strip().splitlines()[0] if proc.stdout.strip() else godot
        checks.append(Check("godot:binary", proc.returncode == 0, detail))
    else:
        checks.append(Check("godot:binary", False, "not found/executable; set GODOT_BIN"))

    if shutil.which("xvfb-run"):
        checks.append(Check("capture:xvfb-run", True, shutil.which("xvfb-run") or "xvfb-run"))
    else:
        checks.append(Check("capture:xvfb-run", False, "missing xvfb-run"))

    if shutil.which("hermes"):
        proc = run(["hermes", "kanban", "--board", args.board, "assignees"], timeout=30)
        checks.append(Check("kanban:board", proc.returncode == 0, args.board if proc.returncode == 0 else proc.stderr.strip()[:300]))
    else:
        checks.append(Check("kanban:cli", False, "hermes command not found"))

    for profile, skills in sorted(requirements.items()):
        checks.extend(check_profile_skills(profile, skills))

    ok = all(c.ok for c in checks)
    if args.json:
        print(json.dumps({"ok": ok, "project": str(PROJECT), "checks": [asdict(c) for c in checks]}, indent=2))
    else:
        print("=== Lanternhouse workflow preflight ===")
        print(f"Project: {PROJECT}")
        print(f"Board:   {args.board}")
        for c in checks:
            mark = "PASS" if c.ok else "FAIL"
            print(f"[{mark}] {c.name}: {c.detail}")
        print("PREFLIGHT_OK" if ok else "PREFLIGHT_FAILED")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
