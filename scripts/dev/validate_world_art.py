from __future__ import annotations

import json
import re
import sys
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
TOWN_GD = ROOT / "scripts" / "town.gd"
MODULAR_ATLAS = ROOT / "assets" / "sprites" / "town" / "buildings" / "modular_building_atlas.png"
MODULAR_SIDECAR = MODULAR_ATLAS.with_suffix(".json")


def gd_modular_rects() -> dict[str, tuple[int, int, int, int]]:
    text = TOWN_GD.read_text(encoding="utf-8")
    block = text.split("const MODULAR_BUILDING_TILE_RECTS := {", 1)[1].split("\n}\n", 1)[0]
    pattern = re.compile(
        r'"([^"]+)":\s*Rect2i\(Vector2i\((\d+),\s*(\d+)\),\s*Vector2i\(TILE_SIZE,\s*TILE_SIZE\)\)'
    )
    return {m.group(1): (int(m.group(2)), int(m.group(3)), 16, 16) for m in pattern.finditer(block)}


def validate_modular_building_atlas() -> list[str]:
    errors: list[str] = []
    if not MODULAR_ATLAS.exists():
        return [f"Missing atlas: {MODULAR_ATLAS.relative_to(ROOT)}"]
    if not MODULAR_SIDECAR.exists():
        return [f"Missing atlas sidecar: {MODULAR_SIDECAR.relative_to(ROOT)}"]

    sidecar = json.loads(MODULAR_SIDECAR.read_text(encoding="utf-8"))
    tile_size = int(sidecar.get("tile_size", 16))
    tiles = sidecar.get("tiles", [])
    if tile_size != 16:
        errors.append(f"Expected modular atlas tile_size 16, got {tile_size}")

    with Image.open(MODULAR_ATLAS) as atlas:
        width, height = atlas.size
    for tile in tiles:
        tile_id = tile["tile"]
        rect = tuple(tile["rect"])
        x, y, w, h = rect
        if w != tile_size or h != tile_size:
            errors.append(f"{tile_id}: rect size {w}x{h} does not match tile_size {tile_size}")
        if x < 0 or y < 0 or x + w > width or y + h > height:
            errors.append(f"{tile_id}: rect {rect} is outside atlas {width}x{height}")

    sidecar_rects = {tile["tile"]: tuple(tile["rect"]) for tile in tiles}
    gd_rects = gd_modular_rects()
    missing_in_gd = sorted(set(sidecar_rects) - set(gd_rects))
    missing_in_sidecar = sorted(set(gd_rects) - set(sidecar_rects))
    mismatches = [
        (tile_id, sidecar_rects[tile_id], gd_rects[tile_id])
        for tile_id in sorted(set(sidecar_rects) & set(gd_rects))
        if sidecar_rects[tile_id] != gd_rects[tile_id]
    ]

    allowed_sidecar_only = {"blank"}
    unexpected_missing = [tile_id for tile_id in missing_in_gd if tile_id not in allowed_sidecar_only]
    if unexpected_missing:
        errors.append(f"Tiles in sidecar but not town.gd: {unexpected_missing}")
    if missing_in_sidecar:
        errors.append(f"Tiles in town.gd but not sidecar: {missing_in_sidecar}")
    if mismatches:
        errors.append(f"Rect mismatches: {mismatches}")
    return errors


def main() -> int:
    checks = [("modular building atlas", validate_modular_building_atlas())]
    failed = False
    for name, errors in checks:
        if errors:
            failed = True
            print(f"FAIL {name}")
            for error in errors:
                print(f"  - {error}")
        else:
            print(f"OK {name}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
