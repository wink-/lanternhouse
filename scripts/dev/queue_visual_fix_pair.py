#!/usr/bin/env python3
"""Queue a standard artist -> visual-reviewer Lanternhouse visual fix pair."""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from datetime import UTC, datetime
from pathlib import Path

PROJECT = Path(__file__).resolve().parents[2]
BOARD = "2d-game"

IMPLEMENT_BODY_TEMPLATE = """Goal:
- Fix/polish the {target} visual issue: {issue}

Scope:
- Work in the Lanternhouse repo/worktree only.
- Prefer modular 16x16/retro JRPG assets and data/layout edits over monolithic scene images.
- Do not preserve or introduce credentials; redact any secrets as [REDACTED].
- Keep the change scoped to {target} and directly supporting assets/docs.

Required workflow:
1. Run `scripts/dev/lanternhouse_workflow_preflight.py` before editing.
2. Capture a before screenshot for `{target}` with `scripts/dev/capture_visual_qa.sh {target}`.
3. Make the smallest useful polish/fix pass.
4. Run relevant validators/smokes:
   - `python scripts/dev/validate_town_layout.py` if town layout/catalog changed.
   - `timeout 60 ~/.local/bin/godot4 --headless --audio-driver Dummy --path . --quit`.
5. Capture after screenshot for `{target}`.
6. Commit only intentional source/assets/import metadata.

Handoff summary must include:
- changed files
- validation commands + pass/fail
- before/after screenshot artifact dirs
- commit hash or explicit reason no commit was made
- known limitations
"""

REVIEW_BODY_TEMPLATE = """Review the parent artist/integrator handoff for `{target}`.

Required workflow:
1. Read the parent summary and changed files.
2. Run `scripts/dev/lanternhouse_workflow_preflight.py`.
3. Capture/check `{target}` with `scripts/dev/capture_visual_qa.sh {target}` unless the parent already produced a fresh after screenshot in the same worktree.
4. Visually review the screenshot. First identify the scene. If wrong, block with WRONG_SCENE.
5. PASS only if no blocking render failures, missing assets, unreadable UI, obvious atlas glitches, or style-breaking artifacts remain.

If PASS:
- Complete with exact proof paths and commands.

If FAIL:
- Block with critical fixes first, then important/nice-to-fix items.
"""


def run(cmd: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, cwd=PROJECT, text=True, capture_output=True)


def create_task(title: str, assignee: str, body: str, *, parent: str | None = None, workspace: str = "worktree", skills: list[str] | None = None, branch: str | None = None, idempotency_key: str | None = None) -> str:
    cmd = ["hermes", "kanban", "--board", BOARD, "create", title, "--assignee", assignee, "--workspace", workspace, "--body", body, "--json"]
    if parent:
        cmd += ["--parent", parent]
    if branch:
        cmd += ["--branch", branch]
    if idempotency_key:
        cmd += ["--idempotency-key", idempotency_key]
    for skill in skills or []:
        cmd += ["--skill", skill]
    proc = run(cmd)
    if proc.returncode != 0:
        print(proc.stdout, file=sys.stderr)
        print(proc.stderr, file=sys.stderr)
        raise SystemExit(proc.returncode)
    match = re.search(r"\{.*\}", proc.stdout, flags=re.S)
    if not match:
        raise SystemExit(f"Could not parse task JSON from: {proc.stdout}")
    obj = json.loads(match.group(0))
    return obj["id"]


def slugify(text: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")[:48] or "visual-fix"


def main() -> int:
    global BOARD
    parser = argparse.ArgumentParser(description="Create the standard Lanternhouse artist -> visual review task pair.")
    parser.add_argument("target", help="visual target, e.g. cave, home, forest_clearing, battle")
    parser.add_argument("issue", help="short issue statement")
    parser.add_argument("--board", default=BOARD)
    parser.add_argument("--artist", default="artist")
    parser.add_argument("--reviewer", default="visual-reviewer")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    BOARD = args.board
    preflight = run([sys.executable, "scripts/dev/lanternhouse_workflow_preflight.py", "--board", BOARD])
    if preflight.returncode != 0:
        print(preflight.stdout)
        print(preflight.stderr, file=sys.stderr)
        return preflight.returncode

    stem = slugify(f"{args.target}-{args.issue}")
    date = datetime.now(UTC).strftime("%Y%m%d")
    implement_title = f"Visual fix: {args.target} — {args.issue}"
    review_title = f"Visual review: {args.target} fix"
    implement_body = IMPLEMENT_BODY_TEMPLATE.format(target=args.target, issue=args.issue)
    review_body = REVIEW_BODY_TEMPLATE.format(target=args.target)

    if args.dry_run:
        print("DRY_RUN_OK")
        print(implement_title)
        print(review_title)
        return 0

    impl_id = create_task(
        implement_title,
        args.artist,
        implement_body,
        workspace="worktree",
        branch=f"auto/{stem}-{date}",
        skills=["lanternhouse-art-pipeline", "lanternhouse-visual-polish", "godot-headless-validation"],
        idempotency_key=f"lanternhouse:{stem}:artist",
    )
    review_id = create_task(
        review_title,
        args.reviewer,
        review_body,
        parent=impl_id,
        workspace="worktree",
        branch=f"review/{stem}-{date}",
        skills=["lanternhouse-visual-polish", "godot-headless-validation"],
        idempotency_key=f"lanternhouse:{stem}:review",
    )
    print(json.dumps({"artist_task": impl_id, "review_task": review_id, "board": BOARD}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
