from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
TILE_SIZE = 32
ATLAS_PATH = ROOT / "assets/sprites/tiles/lanternhouse_overworld.png"
SOURCE_DIR = ROOT / "assets/sprites/tiles/pixellab/coastline"
ARCHIVE_DIR = ROOT / "assets/sprites/tiles/source/overworld_atlas"


PALETTE = {
    "water": "#1859b7",
    "water2": "#1f6bd1",
    "water3": "#0f3f91",
    "foam": "#d6f1ff",
    "sand": "#d9ad55",
    "sand2": "#c98935",
    "sand3": "#f1d27b",
    "grass": "#34a847",
    "grass2": "#208338",
    "grass3": "#66c65d",
    "tall": "#2f9b3e",
    "tall2": "#1f7432",
    "meadow": "#46b94f",
    "meadow2": "#f4d35e",
    "marsh": "#476b48",
    "marsh2": "#75a55b",
    "forest": "#1f7a3f",
    "forest_dark": "#0b3d24",
    "hill": "#8d7240",
    "hill_hi": "#d2b75d",
    "hill_dark": "#4f3a25",
    "desert": "#d9b35c",
    "desert2": "#b98539",
    "rock": "#76706c",
    "rock_hi": "#b8ad90",
    "path": "#9b6b38",
    "path_hi": "#c08a48",
    "wood": "#b2773e",
    "wood_dark": "#7a4b25",
    "stone": "#8f8c7a",
    "stone_hi": "#d8cf8b",
    "dark": "#111827",
    "light": "#ffe36e",
    "roof": "#90422e",
    "wall": "#d8bb78",
    "ruin": "#6f6780",
}


def tile_origin(col: int, row: int) -> tuple[int, int]:
    return col * TILE_SIZE, row * TILE_SIZE


def paste_tile(atlas: Image.Image, source: Image.Image, source_col: int, source_row: int, dest_col: int, dest_row: int) -> None:
    crop = source.crop((source_col * TILE_SIZE, source_row * TILE_SIZE, source_col * TILE_SIZE + TILE_SIZE, source_row * TILE_SIZE + TILE_SIZE))
    atlas.alpha_composite(crop.convert("RGBA"), tile_origin(dest_col, dest_row))


def paste_centered(atlas: Image.Image, source: Image.Image, dest_col: int, dest_row: int, scale: float = 0.5) -> None:
    source = source.convert("RGBA")
    size = (max(1, int(source.width * scale)), max(1, int(source.height * scale)))
    source = source.resize(size, Image.Resampling.NEAREST)
    x, y = tile_origin(dest_col, dest_row)
    atlas.alpha_composite(source, (x + (TILE_SIZE - source.width) // 2, y + (TILE_SIZE - source.height) // 2))


def draw_water(draw: ImageDraw.ImageDraw, col: int, row: int) -> None:
    x, y = tile_origin(col, row)
    draw.rectangle((x, y, x + 31, y + 31), fill=PALETTE["water"])
    for yy in range(y + 3, y + 32, 7):
        draw.line((x + 2, yy, x + 9, yy), fill=PALETTE["water2"])
        draw.line((x + 15, yy + 2, x + 25, yy + 2), fill=PALETTE["foam"])
        draw.point((x + 28, yy - 1), fill=PALETTE["foam"])
    draw.line((x, y + 30, x + 31, y + 29), fill=PALETTE["water3"])


def draw_sand(draw: ImageDraw.ImageDraw, col: int, row: int) -> None:
    x, y = tile_origin(col, row)
    draw.rectangle((x, y, x + 31, y + 31), fill=PALETTE["sand"])
    draw.line((x, y + 2, x + 8, y + 5, x + 17, y + 4, x + 31, y + 7), fill=PALETTE["foam"])
    draw.line((x, y + 7, x + 31, y + 11), fill=PALETTE["sand3"])
    for px, py in [(5, 20), (13, 15), (22, 23), (27, 17), (10, 27)]:
        draw.point((x + px, y + py), fill=PALETTE["sand2"])


def draw_grass(draw: ImageDraw.ImageDraw, col: int, row: int, base: str = "grass") -> None:
    x, y = tile_origin(col, row)
    draw.rectangle((x, y, x + 31, y + 31), fill=PALETTE[base])
    for px, py in [(4, 8), (9, 20), (15, 12), (22, 24), (27, 9), (18, 28), (3, 27)]:
        draw.line((x + px, y + py, x + px + 2, y + py - 2), fill=PALETTE["grass3"])
        draw.point((x + px + 1, y + py), fill=PALETTE["grass2"])


def draw_tall_grass(draw: ImageDraw.ImageDraw, col: int, row: int) -> None:
    x, y = tile_origin(col, row)
    draw.rectangle((x, y, x + 31, y + 31), fill=PALETTE["tall"])
    for px in range(3, 32, 5):
        for py in range(8, 32, 8):
            draw.line((x + px, y + py, x + px + 1, y + py - 5), fill=PALETTE["tall2"])
            draw.line((x + px + 2, y + py, x + px + 4, y + py - 4), fill=PALETTE["grass3"])


def draw_meadow(draw: ImageDraw.ImageDraw, col: int, row: int) -> None:
    draw_grass(draw, col, row, "meadow")
    x, y = tile_origin(col, row)
    for px, py in [(6, 9), (14, 18), (24, 12), (20, 26), (9, 25)]:
        draw.rectangle((x + px, y + py, x + px + 1, y + py + 1), fill=PALETTE["meadow2"])


def draw_desert(draw: ImageDraw.ImageDraw, col: int, row: int) -> None:
    x, y = tile_origin(col, row)
    draw.rectangle((x, y, x + 31, y + 31), fill=PALETTE["desert"])
    for yy in [8, 16, 25]:
        draw.arc((x - 8, y + yy - 8, x + 24, y + yy + 6), 15, 160, fill=PALETTE["desert2"])
        draw.arc((x + 10, y + yy - 10, x + 42, y + yy + 5), 20, 165, fill=PALETTE["sand3"])


def draw_marsh(draw: ImageDraw.ImageDraw, col: int, row: int) -> None:
    x, y = tile_origin(col, row)
    draw.rectangle((x, y, x + 31, y + 31), fill=PALETTE["marsh"])
    for px, py in [(5, 9), (16, 7), (24, 15), (9, 24), (20, 25)]:
        draw.line((x + px, y + py + 6, x + px, y + py), fill=PALETTE["marsh2"])
    draw.line((x + 2, y + 20, x + 29, y + 18), fill=PALETTE["water2"])


def draw_rocky_coast(draw: ImageDraw.ImageDraw, col: int, row: int) -> None:
    x, y = tile_origin(col, row)
    draw.rectangle((x, y, x + 31, y + 31), fill=PALETTE["rock"])
    for px, py in [(4, 6), (14, 12), (24, 8), (8, 22), (21, 25)]:
        draw.polygon(
            [(x + px - 4, y + py + 4), (x + px, y + py - 4), (x + px + 5, y + py + 4)],
            fill=PALETTE["rock_hi"],
            outline=PALETTE["hill_dark"],
        )
    draw.line((x, y + 30, x + 31, y + 29), fill=PALETTE["hill_dark"])


def draw_shore_variant(draw: ImageDraw.ImageDraw, col: int, row: int, land: str, mask: int) -> None:
    x, y = tile_origin(col, row)
    land_color = PALETTE[land]
    edge_color = PALETTE["sand2"] if land == "sand" else PALETTE["hill_dark"]
    hi_color = PALETTE["sand3"] if land == "sand" else PALETTE["rock_hi"]
    draw.rectangle((x, y, x + 31, y + 31), fill=land_color)
    if land == "sand":
        for px, py in [(5, 20), (13, 15), (22, 23), (27, 17), (10, 27)]:
            draw.point((x + px, y + py), fill=PALETTE["sand2"])
    else:
        for px, py in [(5, 7), (17, 12), (25, 22), (10, 25)]:
            draw.polygon([(x + px - 3, y + py + 3), (x + px, y + py - 3), (x + px + 4, y + py + 3)], fill=hi_color, outline=PALETTE["hill_dark"])

    if mask & 1:
        draw.rectangle((x, y, x + 31, y + 8), fill=PALETTE["water"])
        draw.line((x, y + 8, x + 31, y + 7), fill=PALETTE["foam"], width=2)
        draw.line((x, y + 11, x + 31, y + 10), fill=edge_color)
    if mask & 2:
        draw.rectangle((x + 23, y, x + 31, y + 31), fill=PALETTE["water"])
        draw.line((x + 23, y, x + 22, y + 31), fill=PALETTE["foam"], width=2)
        draw.line((x + 20, y, x + 20, y + 31), fill=edge_color)
    if mask & 4:
        draw.rectangle((x, y + 23, x + 31, y + 31), fill=PALETTE["water"])
        draw.line((x, y + 23, x + 31, y + 22), fill=PALETTE["foam"], width=2)
        draw.line((x, y + 20, x + 31, y + 20), fill=edge_color)
    if mask & 8:
        draw.rectangle((x, y, x + 8, y + 31), fill=PALETTE["water"])
        draw.line((x + 8, y, x + 7, y + 31), fill=PALETTE["foam"], width=2)
        draw.line((x + 11, y, x + 11, y + 31), fill=edge_color)
    if mask:
        for yy in range(y + 4, y + 32, 8):
            draw.line((x + 2, yy, x + 8, yy), fill=PALETTE["water2"])
            draw.line((x + 16, yy + 2, x + 23, yy + 2), fill=PALETTE["foam"])
    elif land == "rock":
        draw_rocky_coast(draw, col, row)


def draw_palm(draw: ImageDraw.ImageDraw, col: int, row: int) -> None:
    draw_sand(draw, col, row)
    x, y = tile_origin(col, row)
    draw.line((x + 15, y + 27, x + 18, y + 12), fill=PALETTE["wood_dark"], width=2)
    for end in [(9, 8), (14, 5), (23, 7), (27, 12), (10, 14)]:
        draw.line((x + 18, y + 12, x + end[0], y + end[1]), fill=PALETTE["forest"], width=3)


def draw_forest(draw: ImageDraw.ImageDraw, col: int, row: int) -> None:
    x, y = tile_origin(col, row)
    draw.rectangle((x, y, x + 31, y + 31), fill=PALETTE["grass2"])
    for cy in [7, 16, 25]:
        for cx in [5, 14, 23]:
            draw.polygon([(x + cx, y + cy - 6), (x + cx - 5, y + cy + 4), (x + cx + 5, y + cy + 4)], fill=PALETTE["forest"], outline=PALETTE["forest_dark"])
            draw.line((x + cx, y + cy + 3, x + cx, y + cy + 7), fill=PALETTE["hill_dark"])


def draw_hill(draw: ImageDraw.ImageDraw, col: int, row: int, snow: bool = False) -> None:
    draw_grass(draw, col, row)
    x, y = tile_origin(col, row)
    for pts in [(7, 23, 15, 5, 25, 25), (0, 30, 8, 10, 17, 30), (17, 29, 25, 9, 33, 29)]:
        draw.polygon([(x + pts[0], y + pts[1]), (x + pts[2], y + pts[3]), (x + pts[4], y + pts[5])], fill=PALETTE["hill"], outline=PALETTE["hill_dark"])
        draw.polygon([(x + pts[2], y + pts[3]), (x + pts[2] + 4, y + 18), (x + pts[2] - 1, y + 16)], fill=PALETTE["hill_hi"])
        if snow:
            draw.polygon([(x + pts[2], y + pts[3]), (x + pts[2] - 4, y + 12), (x + pts[2] + 4, y + 12)], fill=PALETTE["foam"])


def draw_path(draw: ImageDraw.ImageDraw, col: int, row: int) -> None:
    draw_grass(draw, col, row)
    x, y = tile_origin(col, row)
    draw.polygon([(x + 10, y), (x + 23, y), (x + 20, y + 31), (x + 7, y + 31)], fill=PALETTE["path"])
    draw.line((x + 14, y, x + 11, y + 31), fill=PALETTE["path_hi"])


def draw_simple_landmark(draw: ImageDraw.ImageDraw, col: int, row: int, kind: str) -> None:
    x, y = tile_origin(col, row)
    if kind == "town":
        draw_grass(draw, col, row)
        draw.rectangle((x + 7, y + 14, x + 25, y + 27), fill=PALETTE["wall"], outline=PALETTE["dark"])
        draw.polygon([(x + 5, y + 15), (x + 16, y + 5), (x + 27, y + 15)], fill=PALETTE["roof"], outline=PALETTE["dark"])
        draw.rectangle((x + 14, y + 20, x + 18, y + 27), fill=PALETTE["dark"])
    elif kind == "lighthouse":
        draw_sand(draw, col, row)
        draw.rectangle((x + 13, y + 9, x + 20, y + 27), fill="#d7d4c6", outline=PALETTE["dark"])
        draw.rectangle((x + 11, y + 5, x + 22, y + 10), fill=PALETTE["roof"], outline=PALETTE["dark"])
        draw.polygon([(x + 16, y + 1), (x + 3, y + 8), (x + 29, y + 8)], fill=PALETTE["light"])
    elif kind == "beacon":
        draw_grass(draw, col, row)
        draw.rectangle((x + 13, y + 12, x + 20, y + 28), fill=PALETTE["stone"], outline=PALETTE["dark"])
        draw.rectangle((x + 11, y + 7, x + 22, y + 13), fill=PALETTE["stone_hi"], outline=PALETTE["dark"])
        draw.rectangle((x + 14, y + 3, x + 19, y + 8), fill=PALETTE["light"])
    elif kind == "sign":
        draw_grass(draw, col, row)
        draw.rectangle((x + 15, y + 12, x + 17, y + 27), fill=PALETTE["wood_dark"])
        draw.rectangle((x + 8, y + 9, x + 25, y + 15), fill=PALETTE["wood"], outline=PALETTE["dark"])
    elif kind == "encounter":
        draw_forest(draw, col, row)
        draw.ellipse((x + 10, y + 9, x + 22, y + 22), fill="#b72d2d", outline=PALETTE["dark"])
    elif kind == "camp":
        draw_grass(draw, col, row)
        draw.polygon([(x + 5, y + 24), (x + 13, y + 10), (x + 22, y + 24)], fill="#b0733a", outline=PALETTE["dark"])
        draw.polygon([(x + 23, y + 23), (x + 26, y + 17), (x + 29, y + 23)], fill=PALETTE["light"])
    elif kind == "clearing":
        draw_grass(draw, col, row)
        draw.ellipse((x + 6, y + 6, x + 25, y + 24), fill="#78d66d", outline=PALETTE["grass2"])
    elif kind == "ruins":
        draw_desert(draw, col, row)
        draw.rectangle((x + 6, y + 17, x + 13, y + 25), fill=PALETTE["ruin"], outline=PALETTE["dark"])
        draw.rectangle((x + 19, y + 12, x + 25, y + 25), fill=PALETTE["ruin"], outline=PALETTE["dark"])


def load_optional(path: Path) -> Image.Image | None:
    if not path.exists():
        return None
    return Image.open(path).convert("RGBA")


def main() -> None:
    ARCHIVE_DIR.mkdir(parents=True, exist_ok=True)
    if ATLAS_PATH.exists():
        before = ARCHIVE_DIR / "lanternhouse_overworld_before_expanded_biomes.png"
        if not before.exists():
            Image.open(ATLAS_PATH).save(before)

    atlas = Image.new("RGBA", (256, 224), (0, 0, 0, 0))
    draw = ImageDraw.Draw(atlas)

    ocean_beach = load_optional(SOURCE_DIR / "ocean_to_beach.png")
    beach_grass = load_optional(SOURCE_DIR / "beach_to_grass.png")
    dock = load_optional(SOURCE_DIR / "coastal_dock.png")
    cave = load_optional(SOURCE_DIR / "coastal_cave.png")

    if ocean_beach:
        paste_tile(atlas, ocean_beach, 0, 0, 0, 0)
        paste_tile(atlas, ocean_beach, 1, 1, 1, 0)
    else:
        draw_water(draw, 0, 0)
        draw_sand(draw, 1, 0)
    if beach_grass:
        paste_tile(atlas, beach_grass, 3, 3, 2, 0)
    else:
        draw_grass(draw, 2, 0)

    draw_forest(draw, 3, 0)
    draw_hill(draw, 4, 0)
    draw_hill(draw, 5, 0, snow=True)
    draw_hill(draw, 6, 0, snow=True)
    draw_path(draw, 7, 0)

    draw_simple_landmark(draw, 0, 1, "town")
    draw_simple_landmark(draw, 1, 1, "lighthouse")
    draw_simple_landmark(draw, 2, 1, "beacon")
    draw_simple_landmark(draw, 3, 1, "sign")
    draw_simple_landmark(draw, 4, 1, "encounter")
    draw_simple_landmark(draw, 5, 1, "camp")
    if cave:
        paste_centered(atlas, cave, 6, 1, 0.5)
    else:
        draw_hill(draw, 6, 1)
    if dock:
        paste_centered(atlas, dock, 7, 1, 0.5)
    else:
        draw_water(draw, 7, 1)

    draw_simple_landmark(draw, 0, 2, "clearing")
    draw_simple_landmark(draw, 1, 2, "ruins")
    draw_desert(draw, 2, 2)
    draw_tall_grass(draw, 3, 2)
    draw_meadow(draw, 4, 2)
    draw_rocky_coast(draw, 5, 2)
    draw_palm(draw, 6, 2)
    draw_marsh(draw, 7, 2)

    for mask in range(16):
        draw_shore_variant(draw, mask % 8, 3 + mask // 8, "sand", mask)
        draw_shore_variant(draw, mask % 8, 5 + mask // 8, "rock", mask)

    atlas.save(ATLAS_PATH)
    atlas.save(ARCHIVE_DIR / "lanternhouse_overworld_expanded_biomes.png")
    print(f"wrote {ATLAS_PATH}")


if __name__ == "__main__":
    main()
