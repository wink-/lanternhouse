from __future__ import annotations

import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PYTHON = sys.executable

BUILD_STEPS = [
    ["scripts/dev/build_town_modular_building_atlas.py"],
    ["scripts/dev/validate_world_art.py"],
    ["scripts/dev/validate_town_layout.py"],
    ["scripts/dev/render_town_layout_preview.py", "--all"],
]


def run_step(args: list[str]) -> None:
    command = [PYTHON, *args]
    print(">", " ".join(args))
    subprocess.run(command, cwd=ROOT, check=True)


def main() -> int:
    for step in BUILD_STEPS:
        run_step(step)
    print("WORLD_ART_BUILD_OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
