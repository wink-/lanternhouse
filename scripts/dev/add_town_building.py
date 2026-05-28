from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_LAYOUT = ROOT / "assets" / "world" / "towns" / "brindlewick.layout.json"


def display_path(path: Path) -> str:
    resolved = path.resolve()
    try:
        return str(resolved.relative_to(ROOT))
    except ValueError:
        return str(resolved)


def load_layout(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def save_layout(path: Path, layout: dict[str, Any]) -> None:
    path.write_text(json.dumps(layout, indent=2) + "\n", encoding="utf-8")


def remove_building(layout: dict[str, Any], building_id: str) -> None:
    remove_doors_for_building(layout, building_id)
    layout["buildings"] = [b for b in layout.get("buildings", []) if b.get("id") != building_id]
    layout["shop_signs"] = [s for s in layout.get("shop_signs", []) if s.get("id") != building_id]
    layout["shop_awnings"] = [a for a in layout.get("shop_awnings", []) if a.get("id") != building_id]
    interactions = layout.get("building_interactions", {})
    if isinstance(interactions, dict):
        interactions.pop(building_id, None)


def remove_doors_for_building(layout: dict[str, Any], building_id: str) -> None:
    door_grids = derived_door_grids(layout, building_id)
    if not door_grids:
        return
    layout["doors"] = [
        d
        for d in layout.get("doors", [])
        if tuple(d.get("grid", [])) not in door_grids
    ]


def derived_door_grids(layout: dict[str, Any], building_id: str) -> set[tuple[int, int]]:
    building = next((b for b in layout.get("buildings", []) if b.get("id") == building_id), None)
    interactions = layout.get("building_interactions", {})
    interaction = interactions.get(building_id, {}) if isinstance(interactions, dict) else {}
    if not isinstance(building, dict) or not isinstance(interaction, dict):
        return set()

    grid = building.get("grid", [])
    door_offset = interaction.get("door_offset", [])
    door_width = interaction.get("door_width", 1)
    if not valid_point(grid) or not valid_point(door_offset) or not isinstance(door_width, int):
        return set()

    return {
        (grid[0] + door_offset[0] + dx, grid[1] + door_offset[1])
        for dx in range(door_width)
    }


def valid_point(value: object) -> bool:
    return (
        isinstance(value, list)
        and len(value) == 2
        and all(isinstance(coord, int) for coord in value)
    )


def add_building(layout: dict[str, Any], args: argparse.Namespace) -> None:
    if args.replace:
        remove_building(layout, args.building_id)

    if any(b.get("id") == args.building_id for b in layout.get("buildings", [])):
        raise ValueError(f"Building id already exists: {args.building_id}. Use --replace to overwrite.")

    door_width = args.door_width
    door_x = args.door_offset_x if args.door_offset_x is not None else max(0, (args.width - door_width) // 2)
    door_y = args.door_offset_y if args.door_offset_y is not None else args.height - 1

    building: dict[str, Any] = {
        "id": args.building_id,
        "grid": [args.x, args.y],
        "size": [args.width, args.height],
        "plaque": args.plaque,
    }
    if args.public:
        building["public"] = True
    layout.setdefault("buildings", []).append(building)

    layout.setdefault("building_interactions", {})[args.building_id] = {
        "npc": args.npc,
        "name": args.name,
        "door_offset": [door_x, door_y],
        "door_width": door_width,
    }

    for dx in range(door_width):
        layout.setdefault("doors", []).append({
            "grid": [args.x + door_x + dx, args.y + door_y],
            "npc": args.npc,
        })

    if args.sign:
        layout.setdefault("shop_signs", []).append({
            "id": args.building_id,
            "grid": [args.x + door_x, args.y],
            "offset": [8, -5],
        })
    if args.awning:
        layout.setdefault("shop_awnings", []).append({
            "id": args.building_id,
            "grid": [args.x + max(0, door_x - 1), args.y + 1],
            "offset": [0, 0],
        })


def main() -> int:
    parser = argparse.ArgumentParser(description="Add or replace one building in a town layout JSON file.")
    parser.add_argument("building_id")
    parser.add_argument("--layout", type=Path, default=DEFAULT_LAYOUT)
    parser.add_argument("--name", required=True)
    parser.add_argument("--npc", required=True)
    parser.add_argument("--x", type=int, required=True)
    parser.add_argument("--y", type=int, required=True)
    parser.add_argument("--width", type=int, required=True)
    parser.add_argument("--height", type=int, required=True)
    parser.add_argument("--plaque", default="plaque_blank")
    parser.add_argument("--door-width", type=int, default=1)
    parser.add_argument("--door-offset-x", type=int)
    parser.add_argument("--door-offset-y", type=int)
    parser.add_argument("--public", action="store_true")
    parser.add_argument("--sign", action="store_true")
    parser.add_argument("--awning", action="store_true")
    parser.add_argument("--replace", action="store_true")
    parser.add_argument("--skip-build", action="store_true")
    args = parser.parse_args()

    layout_path = args.layout if args.layout.is_absolute() else ROOT / args.layout
    layout = load_layout(layout_path)
    add_building(layout, args)
    save_layout(layout_path, layout)
    print(f"Updated {display_path(layout_path)} with building {args.building_id}")

    if not args.skip_build:
        subprocess.run([sys.executable, "scripts/dev/build_world_art.py"], cwd=ROOT, check=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
