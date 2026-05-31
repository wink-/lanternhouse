from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "assets" / "sprites" / "town" / "buildings" / "modular_building_atlas.png"
SIDECAR = OUTPUT.with_suffix(".json")
TILE_SIZE = 16
COLUMNS = 8
ROWS = 4

TILE_ORDER = [
    "roof_left",
    "roof_mid",
    "roof_right",
    "roof_ridge",
    "roof_eave",
    "roof_moss",
    "chimney",
    "blank",
    "wall",
    "wall_timber",
    "wall_brace",
    "wall_shadow",
    "foundation",
    "foundation_moss",
    "foundation_shadow",
    "threshold",
    "door",
    "door_open",
    "window",
    "window_arch",
    "window_flower",
    "plaque_blank",
    "lantern",
    "flower_box",
    "plaque_sword",
    "plaque_shield",
    "plaque_tankard",
    "plaque_gear",
    "plaque_bed",
    "plaque_candle",
]

ROOF_DARK = (112, 45, 34, 255)
ROOF_MID = (184, 78, 49, 255)
ROOF_LIGHT = (222, 118, 67, 255)
ROOF_SHADOW = (95, 38, 31, 255)
CREAM = (224, 196, 139, 255)
CREAM_SHADOW = (181, 144, 94, 255)
TIMBER = (78, 54, 42, 255)
TIMBER_HI = (125, 84, 53, 255)
STONE = (102, 105, 101, 255)
STONE_HI = (152, 148, 135, 255)
STONE_DARK = (63, 67, 68, 255)
BLUE = (77, 130, 151, 255)
BLUE_HI = (151, 200, 198, 255)
DOOR = (102, 57, 36, 255)
DOOR_HI = (158, 93, 51, 255)


def tile_draw(img: Image.Image, col: int, row: int, bg: tuple[int, int, int, int] | None = None) -> tuple[ImageDraw.ImageDraw, int, int]:
    draw = ImageDraw.Draw(img)
    x = col * TILE_SIZE
    y = row * TILE_SIZE
    if bg is not None:
        draw.rectangle([x, y, x + 15, y + 15], fill=bg)
    return draw, x, y


def build_atlas() -> Image.Image:
    img = Image.new("RGBA", (COLUMNS * TILE_SIZE, ROWS * TILE_SIZE), (0, 0, 0, 0))

    for c in range(3):
        draw, x, y = tile_draw(img, c, 0, ROOF_MID)
        draw.rectangle([x, y, x + 15, y + 2], fill=ROOF_LIGHT)
        draw.rectangle([x, y + 13, x + 15, y + 15], fill=ROOF_SHADOW)
        for yy in (5, 9, 13):
            draw.line([x + 1, y + yy, x + 14, y + yy], fill=ROOF_DARK)
        for xx in (4, 9, 14):
            draw.line([x + xx, y + 3, x + xx, y + 13], fill=ROOF_DARK)
        if c == 0:
            draw.line([x, y, x, y + 15], fill=ROOF_DARK)
            draw.line([x + 1, y + 1, x + 5, y + 15], fill=ROOF_LIGHT)
        elif c == 2:
            draw.line([x + 15, y, x + 15, y + 15], fill=ROOF_DARK)
            draw.line([x + 14, y + 1, x + 10, y + 15], fill=ROOF_SHADOW)

    draw, x, y = tile_draw(img, 3, 0)
    draw.polygon([(x + 1, y + 13), (x + 8, y + 1), (x + 14, y + 13)], fill=ROOF_MID, outline=ROOF_DARK)
    draw.line([x + 8, y + 1, x + 8, y + 13], fill=ROOF_LIGHT)
    draw.rectangle([x + 4, y + 10, x + 12, y + 15], fill=CREAM)
    draw.rectangle([x + 7, y + 11, x + 9, y + 13], fill=BLUE)
    draw.rectangle([x + 3, y + 14, x + 13, y + 15], fill=ROOF_SHADOW)

    draw, x, y = tile_draw(img, 4, 0)
    draw.rectangle([x, y, x + 15, y + 6], fill=ROOF_MID)
    draw.rectangle([x, y + 7, x + 15, y + 10], fill=ROOF_SHADOW)
    draw.rectangle([x, y + 11, x + 15, y + 15], fill=(70, 51, 43, 255))
    for xx in (2, 7, 12):
        draw.line([x + xx, y + 1, x + xx + 2, y + 6], fill=ROOF_LIGHT)

    draw, x, y = tile_draw(img, 5, 0, ROOF_MID)
    draw.rectangle([x, y + 11, x + 15, y + 15], fill=ROOF_SHADOW)
    draw.point([(x + 3, y + 3), (x + 7, y + 6), (x + 12, y + 4)], fill=(178, 132, 75, 255))

    draw, x, y = tile_draw(img, 6, 0)
    draw.rectangle([x + 5, y + 1, x + 10, y + 13], fill=(112, 69, 52, 255), outline=(60, 38, 35, 255))
    draw.rectangle([x + 4, y, x + 11, y + 2], fill=(78, 48, 43, 255))
    draw.rectangle([x + 6, y + 4, x + 9, y + 6], fill=(166, 101, 68, 255))

    draw, x, y = tile_draw(img, 0, 1, CREAM)
    draw.rectangle([x, y + 12, x + 15, y + 15], fill=CREAM_SHADOW)
    draw.point([(x + 4, y + 5), (x + 11, y + 8)], fill=(196, 162, 105, 255))

    draw, x, y = tile_draw(img, 1, 1, CREAM)
    draw.rectangle([x, y, x + 3, y + 15], fill=TIMBER)
    draw.rectangle([x + 12, y, x + 15, y + 15], fill=TIMBER)
    draw.rectangle([x, y + 12, x + 15, y + 15], fill=CREAM_SHADOW)
    draw.line([x + 3, y + 2, x + 12, y + 11], fill=TIMBER_HI)

    draw, x, y = tile_draw(img, 2, 1, CREAM)
    draw.rectangle([x, y + 12, x + 15, y + 15], fill=CREAM_SHADOW)
    draw.line([x + 1, y + 13, x + 14, y + 1], fill=TIMBER)
    draw.line([x + 1, y + 1, x + 14, y + 13], fill=TIMBER_HI)

    draw, x, y = tile_draw(img, 3, 1, CREAM_SHADOW)
    draw.rectangle([x, y, x + 15, y + 3], fill=(104, 65, 47, 255))
    draw.rectangle([x, y + 12, x + 15, y + 15], fill=(151, 111, 76, 255))

    draw, x, y = tile_draw(img, 4, 1, STONE)
    for yy in (4, 9, 14):
        draw.line([x, y + yy, x + 15, y + yy], fill=STONE_DARK)
    for xx in (5, 10):
        draw.line([x + xx, y, x + xx, y + 15], fill=STONE_DARK)
    draw.line([x + 1, y + 1, x + 13, y + 1], fill=STONE_HI)

    draw, x, y = tile_draw(img, 5, 1, STONE)
    for yy in (4, 9, 14):
        draw.line([x, y + yy, x + 15, y + yy], fill=STONE_DARK)
    draw.rectangle([x, y, x + 4, y + 3], fill=(83, 123, 65, 255))
    draw.point([(x + 7, y + 2), (x + 13, y + 5)], fill=(104, 147, 77, 255))

    draw, x, y = tile_draw(img, 6, 1, STONE_DARK)
    draw.rectangle([x, y, x + 15, y + 6], fill=STONE)
    draw.rectangle([x, y + 12, x + 15, y + 15], fill=(42, 44, 45, 255))

    draw, x, y = tile_draw(img, 7, 1)
    draw.rectangle([x + 1, y + 6, x + 14, y + 13], fill=STONE_HI, outline=STONE_DARK)
    draw.rectangle([x + 3, y + 2, x + 12, y + 7], fill=(128, 103, 74, 255), outline=(66, 54, 42, 255))

    draw, x, y = tile_draw(img, 0, 2, CREAM)
    draw.rectangle([x + 3, y + 2, x + 12, y + 15], fill=DOOR, outline=(50, 33, 29, 255))
    draw.rectangle([x + 5, y + 4, x + 10, y + 7], fill=DOOR_HI)
    draw.point((x + 10, y + 10), fill=(231, 181, 83, 255))
    draw.rectangle([x, y + 14, x + 15, y + 15], fill=STONE_DARK)

    draw, x, y = tile_draw(img, 1, 2, CREAM)
    draw.rectangle([x + 3, y + 2, x + 12, y + 15], fill=(38, 28, 25, 255), outline=(50, 33, 29, 255))
    draw.rectangle([x + 3, y + 2, x + 5, y + 15], fill=DOOR_HI)

    draw, x, y = tile_draw(img, 2, 2, CREAM)
    draw.rectangle([x + 4, y + 4, x + 12, y + 11], fill=BLUE, outline=TIMBER)
    draw.line([x + 8, y + 4, x + 8, y + 11], fill=BLUE_HI)
    draw.line([x + 4, y + 7, x + 12, y + 7], fill=BLUE_HI)
    draw.rectangle([x + 3, y + 12, x + 13, y + 14], fill=TIMBER_HI)

    draw, x, y = tile_draw(img, 3, 2, CREAM)
    draw.pieslice([x + 3, y + 2, x + 13, y + 12], 180, 360, fill=BLUE, outline=TIMBER)
    draw.rectangle([x + 3, y + 7, x + 13, y + 13], fill=BLUE, outline=TIMBER)
    draw.line([x + 8, y + 4, x + 8, y + 13], fill=BLUE_HI)

    draw, x, y = tile_draw(img, 4, 2, CREAM)
    draw.rectangle([x + 4, y + 3, x + 12, y + 10], fill=BLUE, outline=TIMBER)
    draw.rectangle([x + 3, y + 11, x + 13, y + 14], fill=TIMBER_HI)
    draw.point([(x + 5, y + 12), (x + 8, y + 13), (x + 11, y + 12)], fill=(221, 104, 90, 255))

    draw, x, y = tile_draw(img, 5, 2)
    draw.rectangle([x + 3, y + 5, x + 12, y + 10], fill=(130, 87, 52, 255), outline=(63, 44, 36, 255))

    draw, x, y = tile_draw(img, 6, 2)
    draw.line([x + 8, y, x + 8, y + 4], fill=TIMBER)
    draw.rectangle([x + 5, y + 4, x + 11, y + 12], fill=(235, 167, 77, 255), outline=(75, 45, 32, 255))
    draw.point((x + 8, y + 8), fill=(255, 231, 129, 255))
    draw.rectangle([x + 6, y + 12, x + 10, y + 14], fill=TIMBER)

    draw, x, y = tile_draw(img, 7, 2)
    draw.rectangle([x + 2, y + 7, x + 14, y + 12], fill=TIMBER_HI, outline=TIMBER)
    draw.point([(x + 4, y + 6), (x + 7, y + 5), (x + 10, y + 6), (x + 12, y + 5)], fill=(214, 88, 82, 255))
    draw.point([(x + 5, y + 7), (x + 9, y + 7)], fill=(83, 131, 70, 255))

    icon_colors = [
        (199, 202, 190, 255),
        (127, 157, 186, 255),
        (219, 147, 72, 255),
        (157, 157, 133, 255),
        (185, 142, 90, 255),
        (238, 198, 83, 255),
    ]
    for c, color in enumerate(icon_colors):
        draw, x, y = tile_draw(img, c, 3)
        draw.rectangle([x + 2, y + 4, x + 13, y + 11], fill=(117, 76, 45, 255), outline=(51, 35, 30, 255))
        draw.rectangle([x + 6, y + 5, x + 9, y + 10], fill=color)

    return img


def write_sidecar() -> None:
    tiles = []
    for idx, tile_id in enumerate(TILE_ORDER):
        col = idx % COLUMNS
        row = idx // COLUMNS
        tiles.append(
            {
                "tile": tile_id,
                "rect": [col * TILE_SIZE, row * TILE_SIZE, TILE_SIZE, TILE_SIZE],
                "source": "red-clay coherent residential reset palette from small_house_direction_preview and roof_tileset",
            }
        )
    payload = {
        "asset_name": "Curated Modular Building Atlas",
        "runtime_path": "assets/sprites/town/buildings/modular_building_atlas.png",
        "recipe_path": "assets/sprites/town/buildings/modular_building_atlas.recipe.json",
        "tile_size": TILE_SIZE,
        "status": "integrated",
        "notes": "Runtime atlas for 3/4 Brindlewick buildings. Red-clay roof, cream plaster walls, timber trim, gray foundation; tile ids are consumed by scripts/town.gd.",
        "tiles": tiles,
    }
    SIDECAR.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def main() -> int:
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    atlas = build_atlas()
    atlas.save(OUTPUT)
    write_sidecar()
    print(f"Wrote {OUTPUT.relative_to(ROOT)} ({atlas.width}x{atlas.height})")
    print(f"Wrote {SIDECAR.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
