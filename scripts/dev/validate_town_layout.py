from __future__ import annotations

import json
import argparse
import sys
from pathlib import Path

from town_catalog import building_specs, load_catalog, prop_specs


ROOT = Path(__file__).resolve().parents[2]
TOWN_DIR = ROOT / "assets" / "world" / "towns"
CATALOG_PATH = ROOT / "assets" / "world" / "town_asset_catalog.json"
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


def style_allowed(spec: dict[str, object], town_style: str) -> bool:
    styles = spec.get("styles", [])
    return not isinstance(styles, list) or not styles or town_style in styles


def repo_path(value: object) -> Path | None:
    if not isinstance(value, str) or value == "":
        return None
    return ROOT / value


def validate_catalog(catalog: dict[str, object]) -> list[str]:
    errors: list[str] = []
    if catalog.get("tile_size") != 16:
        errors.append(f"catalog tile_size must be 16, got {catalog.get('tile_size')!r}")

    buildings = catalog.get("buildings", {})
    if not isinstance(buildings, dict) or not buildings:
        errors.append("catalog buildings must be a non-empty object")
        buildings = {}
    for building_id, spec in buildings.items():
        if not isinstance(spec, dict):
            errors.append(f"catalog building {building_id!r} must be an object")
            continue
        point(spec.get("size"), f"catalog.buildings.{building_id}.size", errors)
        point(spec.get("door_offset"), f"catalog.buildings.{building_id}.door_offset", errors)
        if not isinstance(spec.get("door_width"), int):
            errors.append(f"catalog.buildings.{building_id}.door_width must be an integer")
        npc = spec.get("npc", "")
        if npc not in KNOWN_NPCS:
            errors.append(f"catalog.buildings.{building_id}.npc unknown: {npc!r}")
        if spec.get("fallback_region") is not None:
            rect(spec.get("fallback_region"), f"catalog.buildings.{building_id}.fallback_region", errors)
        if spec.get("runtime_ready", False):
            path = repo_path(spec.get("sprite_path"))
            if path is None:
                errors.append(f"catalog.buildings.{building_id}.sprite_path is required when runtime_ready")
            elif not path.exists():
                errors.append(f"catalog.buildings.{building_id}.sprite_path missing: {path.relative_to(ROOT)}")

    props = catalog.get("props", {})
    if not isinstance(props, dict) or not props:
        errors.append("catalog props must be a non-empty object")
        props = {}
    for prop_id, spec in props.items():
        if not isinstance(spec, dict):
            errors.append(f"catalog prop {prop_id!r} must be an object")
            continue
        point(spec.get("offset"), f"catalog.props.{prop_id}.offset", errors)
        if not isinstance(spec.get("scale"), (int, float)):
            errors.append(f"catalog.props.{prop_id}.scale must be numeric")
        if spec.get("runtime_ready", False):
            path = repo_path(spec.get("sprite_path"))
            if path is None:
                errors.append(f"catalog.props.{prop_id}.sprite_path is required when runtime_ready")
            elif not path.exists():
                errors.append(f"catalog.props.{prop_id}.sprite_path missing: {path.relative_to(ROOT)}")
    return errors


def footprint_tiles(grid: tuple[int, int], size: tuple[int, int]) -> set[tuple[int, int]]:
    return {
        (grid[0] + dx, grid[1] + dy)
        for dy in range(size[1])
        for dx in range(size[0])
    }


def validate(layout_path: Path, catalog: dict[str, object]) -> list[str]:
    errors: list[str] = []
    if not layout_path.exists():
        return [f"Missing town layout: {layout_path.relative_to(ROOT)}"]
    data = json.loads(layout_path.read_text(encoding="utf-8"))
    town_style = str(data.get("style", "village"))
    known_buildings = building_specs(catalog)
    known_props = prop_specs(catalog)
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
        elif building_id not in known_buildings:
            errors.append(f"buildings[{index}] unknown catalog id: {building_id!r}")
        elif not style_allowed(known_buildings[building_id], town_style):
            errors.append(f"buildings[{index}] {building_id!r} does not support town style {town_style!r}")
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
            entry_id = str(entry.get("id", ""))
            if section in ["shop_signs", "shop_awnings"]:
                if entry_id not in building_ids:
                    errors.append(f"{section}[{index}] references unknown placed building id {entry_id!r}")
            elif section == "props":
                if entry_id not in known_props:
                    errors.append(f"props[{index}] unknown catalog id: {entry_id!r}")
                elif not style_allowed(known_props[entry_id], town_style):
                    errors.append(f"props[{index}] {entry_id!r} does not support town style {town_style!r}")
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
    catalog_path = CATALOG_PATH
    if not catalog_path.exists():
        print(f"FAIL town asset catalog {catalog_path.relative_to(ROOT)}")
        print("  - Missing town asset catalog")
        return 1
    catalog = load_catalog(catalog_path)
    catalog_errors = validate_catalog(catalog)
    if catalog_errors:
        failed = True
        print(f"FAIL town asset catalog {catalog_path.relative_to(ROOT)}")
        for error in catalog_errors:
            print(f"  - {error}")
    else:
        print(f"OK town asset catalog {catalog_path.relative_to(ROOT)}")
    for layout_path in layout_paths:
        full_path = layout_path if layout_path.is_absolute() else ROOT / layout_path
        errors = validate(full_path, catalog)
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
