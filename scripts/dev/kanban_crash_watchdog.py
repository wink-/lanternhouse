#!/usr/bin/env python3
"""Watch a Hermes Kanban board for repeated worker crashes.

Designed for cron/no-agent use: by default it prints only newly observed alerts.
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
from pathlib import Path

DEFAULT_BOARD = "2d-game"
STATE_PATH = Path.home() / ".cache/lanternhouse-kanban-crash-watchdog.json"
TERMINAL_STATUSES = {"done", "archived", "cancelled"}


def run(cmd: list[str], cwd: Path | None = None) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, cwd=cwd, text=True, capture_output=True, timeout=45)


def load_state(path: Path) -> dict:
    if path.exists():
        try:
            return json.loads(path.read_text())
        except Exception:
            return {}
    return {}


def save_state(path: Path, state: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(state, indent=2, sort_keys=True))


def list_tasks(board: str) -> list[tuple[str, str, str]]:
    proc = run(["hermes", "kanban", "--board", board, "list"])
    if proc.returncode != 0:
        raise RuntimeError(proc.stderr.strip() or proc.stdout.strip())
    tasks = []
    for line in proc.stdout.splitlines():
        match = re.match(r"^[^\w]*(t_[0-9a-f]+)\s+(\w+)\s+(\S+)\s+(.*)$", line)
        if match:
            tasks.append((match.group(1), match.group(2), match.group(4).strip()))
    return tasks


def count_crashes(board: str, task_id: str) -> tuple[int, str]:
    proc = run(["hermes", "kanban", "--board", board, "runs", task_id])
    if proc.returncode != 0:
        return 0, proc.stderr.strip()[:300]
    crashes = len(re.findall(r"\bcrashed\b", proc.stdout))
    reason_match = re.search(r"✖\s+(.+)", proc.stdout)
    reason = reason_match.group(1).strip() if reason_match else "worker crashed"
    return crashes, reason


def main() -> int:
    parser = argparse.ArgumentParser(description="Alert when kanban tasks show repeated crashed runs.")
    parser.add_argument("--board", default=DEFAULT_BOARD)
    parser.add_argument("--threshold", type=int, default=3)
    parser.add_argument("--state", type=Path, default=STATE_PATH)
    parser.add_argument("--include-terminal", action="store_true")
    parser.add_argument("--all", action="store_true", help="Print current alerts even if already reported.")
    args = parser.parse_args()

    state = load_state(args.state)
    reported = state.setdefault("reported", {})
    messages = []

    for task_id, status, title in list_tasks(args.board):
        if status in TERMINAL_STATUSES and not args.include_terminal:
            continue
        crashes, reason = count_crashes(args.board, task_id)
        if crashes < args.threshold:
            continue
        key = f"{args.board}:{task_id}:{crashes}"
        if not args.all and reported.get(task_id, 0) >= crashes:
            continue
        reported[task_id] = crashes
        messages.append(
            f"⚠ Lanternhouse kanban crash-loop: {task_id} ({status})\n"
            f"Title: {title}\n"
            f"Crashed runs: {crashes}\n"
            f"Latest reason: {reason}\n"
            f"Inspect: hermes kanban --board {args.board} log {task_id}\n"
            f"Recover: hermes kanban --board {args.board} reclaim {task_id} or reassign after fixing profile/tools"
        )

    save_state(args.state, state)
    if messages:
        print("\n\n".join(messages))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
