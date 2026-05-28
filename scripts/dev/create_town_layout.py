from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
TOWN_DIR = ROOT / "assets" / "world" / "towns"


def slugify(value: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "_", value.lower()).strip("_")
    if not slug:
        raise ValueError("Town id cannot be empty")
    return slug


def build_map(width: int, height: int) -> list[str]:
    if width < 16 or height < 12:
        raise ValueError("Town layouts should be at least 16x12 tiles")
    center_x = width // 2
    center_y = height // 2
    rows: list[str] = []
    for y in range(height):
        chars = ["," for _ in range(width)]
        for dx in [-1, 0]:
            x = center_x + dx
            if 0 <= x < width:
                chars[x] = "="
        if center_y - 1 <= y <= center_y:
            for x in range(2, width - 2):
                chars[x] = "="
        rows.append("".join(chars))
    return rows


def create_layout(town_id: str, name: str, width: int, height: int) -> dict[str, object]:
    return {
        "id": town_id,
        "name": name,
        "tile_size": 16,
        "cat": {
            "home": [width // 2, min(height - 3, height // 2 + 4)],
            "wander_radius": 4,
        },
        "map": build_map(width, height),
        "doors": [],
        "building_interactions": {},
        "buildings": [],
        "shop_signs": [],
        "shop_awnings": [],
        "props": [],
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Create a starter town layout JSON file.")
    parser.add_argument("town_id", help="Town id or name, e.g. mournlight_harbor.")
    parser.add_argument("--name", help="Display name. Defaults to title-cased town id.")
    parser.add_argument("--width", type=int, default=40)
    parser.add_argument("--height", type=int, default=24)
    parser.add_argument("--force", action="store_true", help="Overwrite an existing layout file.")
    parser.add_argument("--skip-build", action="store_true", help="Do not run build_world_art.py after creating the file.")
    args = parser.parse_args()

    town_id = slugify(args.town_id)
    name = args.name or town_id.replace("_", " ").title()
    out_path = TOWN_DIR / f"{town_id}.layout.json"
    if out_path.exists() and not args.force:
        print(f"Refusing to overwrite existing layout: {out_path.relative_to(ROOT)}")
        return 1

    layout = create_layout(town_id, name, args.width, args.height)
    TOWN_DIR.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(layout, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {out_path.relative_to(ROOT)}")

    if not args.skip_build:
        subprocess.run([sys.executable, "scripts/dev/build_world_art.py"], cwd=ROOT, check=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
