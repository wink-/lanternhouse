#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import random
import sys
import subprocess
from pathlib import Path
from typing import Any

from town_catalog import (
    building_entry,
    building_interaction,
    building_specs,
    load_catalog,
    prop_entry,
    prop_specs,
    supports_style,
)

ROOT = Path(__file__).resolve().parents[2]
TOWN_DIR = ROOT / "assets" / "world" / "towns"


def find_slot(bw: int, bh: int, width: int, height: int, road_x: int, road_y: int,
              road_rects: list, building_rects: list) -> tuple[int, int] | None:
    candidates = []
    for y in range(2, height - bh - 2):
        for x in range(2, width - bw - 2):
            candidates.append((x, y))

    random.shuffle(candidates)

    for x, y in candidates:
        if x < 1 or x + bw >= width - 1 or y < 1 or y + bh >= height - 1:
            continue

        # Check overlaps with roads/plaza (0 padding)
        overlap_road = False
        for rx, ry, rw, rh in road_rects:
            if not (x + bw <= rx or x >= rx + rw or y + bh <= ry or y >= ry + rh):
                overlap_road = True
                break
        if overlap_road:
            continue

        # Check overlaps with other buildings (1 padding)
        overlap_building = False
        for bx, by, bw_val, bh_val in building_rects:
            if not (x + bw + 1 <= bx or x - 1 >= bx + bw_val or
                    y + bh + 1 <= by or y - 1 >= by + bh_val):
                overlap_building = True
                break
        if overlap_building:
            continue

        return x, y

    return None


def connect_to_road(gx: int, gy: int, road_x: int, road_y: int, grid_map: list) -> None:
    dist_to_horiz = abs(gy - road_y)
    dist_to_vert = abs(gx - road_x)

    if dist_to_horiz < dist_to_vert:
        step = 1 if road_y > gy else -1
        for y in range(gy, road_y + (1 if step > 0 else 0), step):
            grid_map[y][gx] = "="
    else:
        step = 1 if road_x > gx else -1
        for x in range(gx, road_x + (1 if step > 0 else 0), step):
            grid_map[gy][x] = "="


def apply_style_terrain(grid_map: list, style: str, width: int, height: int,
                        road_x: int, road_y: int) -> list:
    """Apply style-specific terrain modifications to the base grid."""
    if style == "coastal":
        # Bottom 3 rows become water
        water_start = height - 4
        for y in range(water_start + 1, height - 1):
            for x in range(1, width - 1):
                grid_map[y][x] = "w"
        # Sand band just above water
        for x in range(1, width - 1):
            if grid_map[water_start][x] not in ("H", "="):
                grid_map[water_start][x] = "s"
        # Dock planks extending south from horizontal road on both sides of center
        for dock_x in [road_x - 4, road_x + 6]:
            if 2 <= dock_x < width - 2:
                for y in range(road_y + 2, water_start + 1):
                    if grid_map[y][dock_x] not in ("H",):
                        grid_map[y][dock_x] = "="

    elif style == "fortress":
        # Replace border grass with stone walls on top and sides (keep bottom open)
        for x in range(width):
            grid_map[0][x] = "H"
            grid_map[1][x] = "H"
        for y in range(height):
            grid_map[y][0] = "H"
            grid_map[y][1] = "H"
            grid_map[y][width - 1] = "H"
            grid_map[y][width - 2] = "H"
        # Gate openings at road endpoints (left/right walls, horizontal road level)
        for y in [road_y, road_y + 1]:
            grid_map[y][0] = "="
            grid_map[y][1] = "="
            grid_map[y][width - 1] = "="
            grid_map[y][width - 2] = "="
        # Gate opening at top for vertical road
        for x in [road_x, road_x + 1]:
            grid_map[0][x] = "="
            grid_map[1][x] = "="
        # Corner towers: 2×2 H blocks just inside the wall corners
        for (cx, cy) in [(2, 2), (width - 4, 2), (2, height - 4), (width - 4, height - 4)]:
            for dy in range(2):
                for dx in range(2):
                    grid_map[cy + dy][cx + dx] = "H"

    return grid_map


def add_style_props(props: list, prop_defs: dict[str, dict[str, Any]], style: str, width: int, height: int,
                    road_x: int, road_y: int, occupied: set) -> None:
    """Add style-specific decorative props."""

    def try_prop(prop_id: str, grid: list[int], **overrides: Any) -> bool:
        spec = prop_defs.get(prop_id)
        if not spec or not supports_style(spec, style):
            return False
        p_data = prop_entry(prop_id, spec, grid, **overrides)
        gx, gy = p_data["grid"]
        if 0 <= gx < width and 0 <= gy < height and (gx, gy) not in occupied:
            props.append(p_data)
            occupied.add((gx, gy))
            return True
        return False

    if style == "coastal":
        water_start = height - 4
        # Fishing props near dock ends
        for dock_x in [road_x - 4, road_x + 6]:
            try_prop("barrel_pair", [dock_x - 1, water_start - 1], scale=0.58)
            try_prop("crate_stack", [dock_x + 1, water_start - 1])
        try_prop("boat_hull", [road_x + 2, water_start + 1])
        try_prop("fishing_post", [road_x - 6, water_start])
        try_prop("net_post", [road_x + 8, water_start])

    elif style == "fortress":
        # Torch brackets near gate openings (placeholder IDs)
        for gate_x in [3, width - 4]:
            try_prop("torch_bracket", [gate_x, road_y - 1])
        # Guard post at top gate
        try_prop("guard_post", [road_x - 2, 3])
        try_prop("guard_post", [road_x + 3, 3])
        # Extra lanterns at gate entrances
        try_prop("lantern_post", [3, road_y - 2])
        try_prop("lantern_post", [width - 4, road_y - 2])


def generate_layout(town_id: str, name: str, width: int, height: int,
                    seed: int, style: str = "village") -> dict[str, Any]:
    random.seed(seed)
    catalog = load_catalog()
    build_defs = building_specs(catalog)
    prop_defs = prop_specs(catalog)

    grid_map = [["." for _ in range(width)] for _ in range(height)]

    # Set grass borders and random vegetation
    for y in range(height):
        for x in range(width):
            if x == 0 or x == width - 1 or y == 0 or y == height - 1:
                grid_map[y][x] = ","
            elif random.random() < 0.15:
                grid_map[y][x] = ","

    road_y = height // 2
    road_x = width // 2

    # Main horizontal road
    for x in range(1, width - 1):
        grid_map[road_y][x] = "="
        grid_map[road_y + 1][x] = "="

    # Main vertical road
    for y in range(1, height - 1):
        grid_map[y][road_x] = "="
        grid_map[y][road_x + 1] = "="

    # Central Plaza
    plaza_w = 8
    plaza_h = 6
    px = road_x - plaza_w // 2 + 1
    py = road_y - plaza_h // 2 + 1
    for dy in range(plaza_h):
        for dx in range(plaza_w):
            grid_map[py + dy][px + dx] = "+"

    # Apply style-specific terrain before placing buildings
    grid_map = apply_style_terrain(grid_map, style, width, height, road_x, road_y)

    road_rects: list[tuple[int, int, int, int]] = []
    road_rects.append((px, py, plaza_w, plaza_h))
    road_rects.append((0, road_y, width, 2))
    road_rects.append((road_x, 0, 2, height))

    building_rects: list[tuple[int, int, int, int]] = []

    buildings = []
    building_interactions = {}
    doors = []
    shop_signs = []
    shop_awnings = []
    props = []

    # 1. Place Elder Hall at top of the vertical road
    eh_spec = build_defs["elder_hall"]
    eh_w, eh_h = eh_spec["size"]
    eh_x = road_x - eh_w // 2 + 1
    eh_y = 1 if style != "fortress" else 3  # move down in fortress to clear wall

    building_rects.append((eh_x, eh_y, eh_w, eh_h))
    buildings.append(building_entry("elder_hall", eh_spec, [eh_x, eh_y]))
    building_interactions["elder_hall"] = building_interaction(eh_spec)

    # Ensure vertical road path reaches elder hall door
    for dy in range(eh_h, eh_y + eh_h + 2):
        if dy < height:
            grid_map[dy][road_x] = "="
            grid_map[dy][road_x + 1] = "="

    # 2. Core buildings list — extended by style
    buildings_to_place = [
        "chapel", "weapon_shop", "armor_shop", "inn", "tavern", "workshop",
        "small_house", "large_house", "house_timber", "house_mossy"
    ]
    if style == "fortress":
        buildings_to_place.insert(0, "barracks")
    elif style == "coastal":
        buildings_to_place.append("dockmaster")

    for bid in buildings_to_place:
        spec = build_defs[bid]
        if not supports_style(spec, style):
            continue
        bw, bh = spec["size"]
        slot = find_slot(bw, bh, width, height, road_x, road_y, road_rects, building_rects)
        if slot:
            bx, by = slot
            building_rects.append((bx, by, bw, bh))
            buildings.append(building_entry(bid, spec, [bx, by]))
            building_interactions[bid] = building_interaction(spec)

            # Connect door threshold to road network
            if spec["door_width"] > 0:
                door_offset = spec["door_offset"]
                connect_to_road(bx + door_offset[0], by + door_offset[1] + 1,
                                road_x, road_y, grid_map)
        else:
            print(f"Warning: Could not find space to place building '{bid}'")

    # Write "H" footprints on map matrix
    for b in buildings:
        bx, by = b["grid"]
        bw, bh = b["size"]
        for dy in range(bh):
            for dx in range(bw):
                grid_map[by + dy][bx + dx] = "H"

    # Build doors, signs, awnings entries
    for b in buildings:
        bid = b["id"]
        if bid not in building_interactions:
            continue
        inter = building_interactions[bid]
        bx, by = b["grid"]
        door_offset = inter["door_offset"]
        door_width = inter["door_width"]
        npc = inter["npc"]

        # Place door tiles
        for dx in range(door_width):
            dx_pos = bx + door_offset[0] + dx
            dy_pos = by + door_offset[1]
            doors.append({
                "grid": [dx_pos, dy_pos],
                "npc": npc
            })
            # Make threshold tile directly below door walkable
            if dy_pos + 1 < height:
                grid_map[dy_pos + 1][dx_pos] = "="

        # Signs and Awnings
        spec = build_defs[bid]
        if spec.get("sign") and door_width > 0:
            shop_signs.append({
                "id": bid,
                "grid": [bx + door_offset[0], by + 1],
                "offset": [8, -5]
            })
        if spec.get("awning") and door_width > 0:
            shop_awnings.append({
                "id": bid,
                "grid": [bx + max(0, door_offset[0] - 1), by + 2],
                "offset": [0, 0]
            })

    # --- Prop placement ---
    occupied_prop_grids: set[tuple[int, int]] = set()

    # Block borders
    for x in range(width):
        occupied_prop_grids.add((x, 0))
        occupied_prop_grids.add((x, height - 1))
    for y in range(height):
        occupied_prop_grids.add((0, y))
        occupied_prop_grids.add((width - 1, y))

    # Block roads & plaza
    for rx, ry, rw, rh in road_rects:
        for y in range(ry, ry + rh):
            for x in range(rx, rx + rw):
                occupied_prop_grids.add((x, y))

    # Block building footprints
    for bx, by, bw_val, bh_val in building_rects:
        for y in range(by, by + bh_val):
            for x in range(bx, bx + bw_val):
                occupied_prop_grids.add((x, y))

    def try_add_prop(prop_id: str, grid: list[int], **overrides: Any) -> bool:
        spec = prop_defs.get(prop_id)
        if not spec or not supports_style(spec, style):
            return False
        p_data = prop_entry(prop_id, spec, grid, **overrides)
        gx, gy = p_data["grid"]
        if (gx, gy) not in occupied_prop_grids:
            props.append(p_data)
            occupied_prop_grids.add((gx, gy))
            return True
        return False

    # Well in the center of the plaza
    well_x = px + plaza_w // 2
    well_y = py + plaza_h // 2
    try_add_prop("well", [well_x, well_y])
    # Notice board near the plaza road edge
    try_add_prop("notice_board", [px - 1, py + 1])
    # Signpost at the intersection
    try_add_prop("signpost", [road_x - 1, road_y - 1])

    # Benches around the well
    try_add_prop("bench", [well_x - 2, well_y + 1])
    try_add_prop("bench", [well_x + 1, well_y + 1], scale=0.55)

    # Scatter lanterns along roads
    for x in range(4, width - 4, 8):
        if x != road_x and x != road_x + 1:
            if grid_map[road_y - 1][x] == ".":
                try_add_prop("lantern_post", [x, road_y - 1])
            elif grid_map[road_y + 2][x] == ".":
                try_add_prop("lantern_post", [x, road_y + 2])

    # Scatter crates and barrels adjacent to building facades
    for b in buildings:
        bx, by = b["grid"]
        bw, bh = b["size"]

        # Left wall cluster
        left_x = bx - 1
        left_y = by + bh - 1
        if left_x >= 0 and left_y < height and grid_map[left_y][left_x] == ".":
            try_add_prop("crate_stack", [left_x, left_y])
            if left_y + 1 < height and grid_map[left_y + 1][left_x] == ".":
                try_add_prop("barrel_pair", [left_x, left_y + 1])

        # Right wall cluster
        right_x = bx + bw
        right_y = by + bh - 1
        if right_x < width and right_y < height and grid_map[right_y][right_x] == ".":
            try_add_prop("barrel_pair", [right_x, right_y], scale=0.58)

        # Planter next to door
        if b["id"] in building_interactions:
            door_offset = building_interactions[b["id"]]["door_offset"]
            planter_x = bx + door_offset[0] - 1
            planter_y = by + door_offset[1] + 1
            if planter_x >= 0 and planter_y < height and grid_map[planter_y][planter_x] == ".":
                try_add_prop("herb_planter", [planter_x, planter_y])

    # Add style-specific props
    add_style_props(props, prop_defs, style, width, height, road_x, road_y, occupied_prop_grids)

    map_str_list = ["".join(row) for row in grid_map]

    return {
        "id": town_id,
        "name": name,
        "style": style,
        "tile_size": 16,
        "cat": {
            "home": [road_x - 2, road_y + 4],
            "wander_radius": 5
        },
        "map": map_str_list,
        "doors": doors,
        "building_interactions": building_interactions,
        "buildings": buildings,
        "shop_signs": shop_signs,
        "shop_awnings": shop_awnings,
        "props": props
    }


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Procedurally generate a complete JRPG town layout.")
    parser.add_argument("town_id", help="Layout ID of the town (e.g. brindlewick).")
    parser.add_argument("--name", help="Display name of the town. Defaults to Title Cased town_id.")
    parser.add_argument("--width", type=int, default=50, help="Grid width (min 32).")
    parser.add_argument("--height", type=int, default=42, help="Grid height (min 20).")
    parser.add_argument("--seed", type=int, default=42, help="Random seed for generation.")
    parser.add_argument("--style", choices=["village", "coastal", "fortress"],
                        default="village", help="Town layout style.")
    parser.add_argument("--force", action="store_true", help="Force overwrite existing layout.")
    parser.add_argument("--skip-build", action="store_true",
                        help="Do not run build_world_art.py after creation.")
    args = parser.parse_args()

    town_id = args.town_id.lower().replace(" ", "_")
    name = args.name or town_id.replace("_", " ").title()

    out_file = TOWN_DIR / f"{town_id}.layout.json"
    if out_file.exists() and not args.force:
        print(f"File already exists: {out_file.relative_to(ROOT)}. Use --force to overwrite.")
        return 1

    print(f"Procedurally generating town '{name}' ({args.width}x{args.height}) "
          f"style='{args.style}' seed={args.seed}...")
    layout_data = generate_layout(town_id, name, args.width, args.height, args.seed, args.style)

    TOWN_DIR.mkdir(parents=True, exist_ok=True)
    out_file.write_text(json.dumps(layout_data, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {out_file.relative_to(ROOT)}")

    if not args.skip_build:
        print("Compiling world art and rendering preview...")
        subprocess.run([sys.executable, "scripts/dev/build_world_art.py"],
                       cwd=ROOT, check=True)

    return 0


if __name__ == "__main__":
    sys.exit(main())
