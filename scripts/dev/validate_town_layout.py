from __future__ import annotations

import json
import argparse
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
TOWN_DIR = ROOT / "assets" / "world" / "towns"
KNOWN_NPCS = {
    "weapon_merchant",
    "armor_merchant",
    "innkeeper",
    "elder",
    "tavern_keeper",
    "healer",
    "tinkerer",
    "realtor",
}
BLOCKED_TILES = {"#", "H"}


def point(value: object, label: str, errors: list[str]) -> tuple[int, int] | None:
    if not isinstance(value, list) or len(value) != 2:
        errors.append(f"{label} must be a two-item [x, y] array")
        return None
    if not all(isinstance(v, int) for v in value):
        errors.append(f"{label} must contain integers")
        return None
    return int(value[0]), int(value[1])


def rect(value: object, label: str, errors: list[str]) -> None:
    if not isinstance(value, list) or len(value) != 4:
        errors.append(f"{label} must be a four-item [x, y, w, h] array")
        return
    if not all(isinstance(v, int) for v in value):
        errors.append(f"{label} must contain integers")


def in_bounds(pos: tuple[int, int], width: int, height: int) -> bool:
    return 0 <= pos[0] < width and 0 <= pos[1] < height


def tile_at(town_map: list[str], pos: tuple[int, int]) -> str:
    return town_map[pos[1]][pos[0]]


def walkable(town_map: list[str], pos: tuple[int, int]) -> bool:
    return tile_at(town_map, pos) not in BLOCKED_TILES


def footprint_tiles(grid: tuple[int, int], size: tuple[int, int]) -> set[tuple[int, int]]:
    return {
        (grid[0] + dx, grid[1] + dy)
        for dy in range(size[1])
        for dx in range(size[0])
    }


def validate(layout_path: Path) -> list[str]:
    errors: list[str] = []
    if not layout_path.exists():
        return [f"Missing town layout: {layout_path.relative_to(ROOT)}"]
    data = json.loads(layout_path.read_text(encoding="utf-8"))
    town_map = data.get("map", [])
    if not isinstance(town_map, list) or not town_map:
        return ["layout.map must be a non-empty array of strings"]
    if not all(isinstance(row, str) for row in town_map):
        errors.append("layout.map must contain only strings")
        return errors
    width = len(town_map[0])
    height = len(town_map)
    for index, row in enumerate(town_map):
        if len(row) != width:
            errors.append(f"map row {index} has width {len(row)}; expected {width}")

    tile_size = data.get("tile_size")
    if tile_size != 16:
        errors.append(f"tile_size must be 16, got {tile_size!r}")

    cat = data.get("cat", {})
    if isinstance(cat, dict):
        cat_home = point(cat.get("home"), "cat.home", errors)
        if cat_home and not in_bounds(cat_home, width, height):
            errors.append(f"cat.home {cat_home} is outside map bounds")
        if not isinstance(cat.get("wander_radius", 0), int):
            errors.append("cat.wander_radius must be an integer")
    else:
        errors.append("cat must be an object")

    interactions = data.get("building_interactions", {})
    if not isinstance(interactions, dict):
        errors.append("building_interactions must be an object")
        interactions = {}
    for building_id, interaction in interactions.items():
        if not isinstance(interaction, dict):
            errors.append(f"building_interactions.{building_id} must be an object")
            continue
        npc = interaction.get("npc", "")
        if npc not in KNOWN_NPCS:
            errors.append(f"building_interactions.{building_id}.npc unknown: {npc!r}")
        point(interaction.get("door_offset"), f"building_interactions.{building_id}.door_offset", errors)
        if not isinstance(interaction.get("door_width", 0), int):
            errors.append(f"building_interactions.{building_id}.door_width must be an integer")

    building_ids: set[str] = set()
    building_footprints: dict[str, set[tuple[int, int]]] = {}
    for index, building in enumerate(data.get("buildings", [])):
        if not isinstance(building, dict):
            errors.append(f"buildings[{index}] must be an object")
            continue
        building_id = str(building.get("id", ""))
        if not building_id:
            errors.append(f"buildings[{index}] is missing id")
        building_ids.add(building_id)
        grid = point(building.get("grid"), f"buildings[{index}].grid", errors)
        size = point(building.get("size"), f"buildings[{index}].size", errors)
        if grid and size:
            far_corner = (grid[0] + size[0] - 1, grid[1] + size[1] - 1)
            if not in_bounds(grid, width, height) or not in_bounds(far_corner, width, height):
                errors.append(f"buildings[{index}] {building_id} footprint is outside map bounds")
            else:
                building_footprints[building_id] = footprint_tiles(grid, size)
        if building.get("fallback_region") is not None:
            rect(building.get("fallback_region"), f"buildings[{index}].fallback_region", errors)
        if building_id and building_id not in interactions:
            errors.append(f"building {building_id!r} has no building_interactions entry")

    for index, door in enumerate(data.get("doors", [])):
        if not isinstance(door, dict):
            errors.append(f"doors[{index}] must be an object")
            continue
        grid = point(door.get("grid"), f"doors[{index}].grid", errors)
        if grid and not in_bounds(grid, width, height):
            errors.append(f"doors[{index}] is outside map bounds")
        elif grid:
            approach = (grid[0], grid[1] + 1)
            if not in_bounds(approach, width, height):
                errors.append(f"doors[{index}] has no in-bounds approach tile below it")
            elif not walkable(town_map, approach):
                errors.append(f"doors[{index}] approach tile {approach} is blocked by {tile_at(town_map, approach)!r}")
        npc = door.get("npc", "")
        if npc not in KNOWN_NPCS:
            errors.append(f"doors[{index}].npc unknown: {npc!r}")

    for building_id, interaction in interactions.items():
        footprint = building_footprints.get(building_id)
        if not footprint:
            continue
        building = next((b for b in data.get("buildings", []) if isinstance(b, dict) and b.get("id") == building_id), None)
        if not isinstance(building, dict):
            continue
        grid = point(building.get("grid"), f"buildings.{building_id}.grid", errors)
        door_offset = point(interaction.get("door_offset"), f"building_interactions.{building_id}.door_offset", errors)
        door_width = interaction.get("door_width", 1)
        if grid and door_offset and isinstance(door_width, int):
            for dx in range(door_width):
                door_pos = (grid[0] + door_offset[0] + dx, grid[1] + door_offset[1])
                if door_pos not in footprint:
                    errors.append(f"building_interactions.{building_id} derived door {door_pos} is outside its footprint")
                approach = (door_pos[0], door_pos[1] + 1)
                if in_bounds(approach, width, height) and not walkable(town_map, approach):
                    errors.append(f"building_interactions.{building_id} approach tile {approach} is blocked")

    for section in ["shop_signs", "shop_awnings", "props"]:
        occupied: set[tuple[int, int]] = set()
        for index, entry in enumerate(data.get(section, [])):
            if not isinstance(entry, dict):
                errors.append(f"{section}[{index}] must be an object")
                continue
            grid = point(entry.get("grid"), f"{section}[{index}].grid", errors)
            if grid and not in_bounds(grid, width, height):
                errors.append(f"{section}[{index}] is outside map bounds")
            elif grid:
                if grid in occupied:
                    errors.append(f"{section}[{index}] duplicates grid {grid}")
                occupied.add(grid)
                if section == "props":
                    if not walkable(town_map, grid):
                        errors.append(f"props[{index}] sits on blocked tile {grid} ({tile_at(town_map, grid)!r})")
                    for building_id, footprint in building_footprints.items():
                        if grid in footprint:
                            errors.append(f"props[{index}] overlaps building {building_id} at {grid}")
            point(entry.get("offset"), f"{section}[{index}].offset", errors)

    return errors


def discover_layouts() -> list[Path]:
    return sorted(TOWN_DIR.glob("*.layout.json"))


def display_path(path: Path) -> str:
    try:
        return str(path.relative_to(ROOT))
    except ValueError:
        return str(path)


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate Lanternhouse town layout JSON files.")
    parser.add_argument("layouts", nargs="*", type=Path, help="Specific layout JSON files. Defaults to all assets/world/towns/*.layout.json.")
    args = parser.parse_args()

    layout_paths = args.layouts if args.layouts else discover_layouts()
    if not layout_paths:
        print("FAIL town layout")
        print("  - No town layout files found")
        return 1

    failed = False
    for layout_path in layout_paths:
        full_path = layout_path if layout_path.is_absolute() else ROOT / layout_path
        errors = validate(full_path)
        label = display_path(full_path)
        if errors:
            failed = True
            print(f"FAIL town layout {label}")
            for error in errors:
                print(f"  - {error}")
        else:
            print(f"OK town layout {label}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
