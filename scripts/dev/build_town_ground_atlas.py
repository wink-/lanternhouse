from pathlib import Path
from random import Random

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "sprites" / "tiles" / "lanternhouse_town_readable.png"
SOURCE_DIR = ROOT / "assets" / "sprites" / "tiles" / "source" / "town_ground"
TILE = 16


def put_px(draw: ImageDraw.ImageDraw, x: int, y: int, color: tuple[int, int, int, int]) -> None:
    if 0 <= x < TILE and 0 <= y < TILE:
        draw.point((x, y), fill=color)


def noise_tile(base: tuple[int, int, int], flecks: list[tuple[int, int, int]], seed: int, count: int) -> Image.Image:
    rng = Random(seed)
    img = Image.new("RGBA", (TILE, TILE), (*base, 255))
    draw = ImageDraw.Draw(img)
    for _ in range(count):
        x = rng.randrange(TILE)
        y = rng.randrange(TILE)
        color = (*rng.choice(flecks), 255)
        put_px(draw, x, y, color)
    return img


def grass(seed: int = 1) -> Image.Image:
    img = noise_tile((77, 158, 67), [(63, 132, 58), (92, 181, 75), (113, 195, 84)], seed, 52)
    draw = ImageDraw.Draw(img)
    for x in range(1, TILE, 4):
        draw.line((x, 13, x + 1, 11), fill=(50, 112, 51, 255))
    return img


def packed_dirt(seed: int = 2) -> Image.Image:
    img = noise_tile((173, 126, 72), [(142, 99, 58), (198, 149, 86), (119, 84, 57)], seed, 46)
    draw = ImageDraw.Draw(img)
    for x in range(0, TILE, 5):
        draw.point((x, 4 + (x % 3)), fill=(94, 67, 48, 255))
    return img


def plaza(seed: int = 3) -> Image.Image:
    img = Image.new("RGBA", (TILE, TILE), (139, 129, 105, 255))
    draw = ImageDraw.Draw(img)
    rng = Random(seed)
    for x in range(0, TILE, 8):
        draw.line((x, 0, x, TILE - 1), fill=(84, 77, 68, 255))
    for y in range(0, TILE, 8):
        draw.line((0, y, TILE - 1, y), fill=(84, 77, 68, 255))
    for y in (0, 8):
        for x in (0, 8):
            shade = rng.choice([(156, 145, 119), (122, 113, 96), (147, 135, 111)])
            draw.rectangle((x + 1, y + 1, x + 6, y + 6), fill=(*shade, 255))
            draw.point((x + 5, y + 2), fill=(184, 172, 140, 255))
    return img


def flower_grass(seed: int = 4) -> Image.Image:
    img = grass(seed)
    draw = ImageDraw.Draw(img)
    for x, y, color in [
        (3, 5, (238, 210, 91)),
        (11, 7, (232, 119, 145)),
        (6, 12, (245, 240, 180)),
        (13, 13, (176, 142, 224)),
    ]:
        draw.point((x, y), fill=(*color, 255))
        draw.point((x + 1, y), fill=(*color, 255))
    return img


def mud(seed: int = 5) -> Image.Image:
    img = noise_tile((101, 86, 60), [(80, 68, 51), (123, 101, 67), (70, 58, 45)], seed, 54)
    draw = ImageDraw.Draw(img)
    draw.arc((2, 3, 11, 9), 190, 345, fill=(64, 52, 42, 255))
    draw.arc((7, 9, 15, 14), 190, 345, fill=(64, 52, 42, 255))
    return img


def wood_deck(seed: int = 6) -> Image.Image:
    img = Image.new("RGBA", (TILE, TILE), (143, 91, 52, 255))
    draw = ImageDraw.Draw(img)
    rng = Random(seed)
    for y in range(0, TILE, 4):
        draw.rectangle((0, y, TILE - 1, y + 2), fill=(158, 101, 59, 255))
        draw.line((0, y + 3, TILE - 1, y + 3), fill=(75, 51, 36, 255))
        for x in range(2, TILE, 7):
            draw.point((x, y + 1), fill=(83, 57, 39, 255))
    for _ in range(12):
        draw.point((rng.randrange(TILE), rng.randrange(TILE)), fill=(191, 126, 70, 255))
    return img


def stone_border(seed: int = 7) -> Image.Image:
    img = grass(seed)
    draw = ImageDraw.Draw(img)
    for x in range(TILE):
        shade = (96, 94, 83) if x % 2 else (129, 126, 110)
        draw.point((x, 7), fill=(*shade, 255))
        draw.point((x, 8), fill=(67, 65, 59, 255))
    return img


def garden_soil(seed: int = 8) -> Image.Image:
    img = noise_tile((117, 76, 49), [(91, 58, 42), (142, 89, 54), (73, 49, 37)], seed, 42)
    draw = ImageDraw.Draw(img)
    for y in (3, 7, 11):
        draw.line((1, y, 14, y - 1), fill=(73, 49, 37, 255))
        draw.line((1, y + 1, 14, y), fill=(151, 98, 60, 255))
    for x, y in [(4, 5), (10, 9), (13, 3)]:
        draw.point((x, y), fill=(88, 158, 69, 255))
        draw.point((x, y - 1), fill=(105, 189, 82, 255))
    return img


def sanded_path(seed: int = 9) -> Image.Image:
    img = noise_tile((194, 166, 101), [(167, 135, 84), (220, 188, 113), (135, 111, 74)], seed, 40)
    draw = ImageDraw.Draw(img)
    draw.point((4, 5), fill=(112, 97, 73, 255))
    draw.point((11, 10), fill=(112, 97, 73, 255))
    return img


def mossy_stone(seed: int = 10) -> Image.Image:
    img = plaza(seed)
    draw = ImageDraw.Draw(img)
    for p in [(2, 13), (3, 13), (12, 3), (13, 3), (13, 4), (6, 6)]:
        draw.point(p, fill=(62, 127, 64, 255))
    return img


def brick(seed: int = 11) -> Image.Image:
    img = Image.new("RGBA", (TILE, TILE), (128, 78, 60, 255))
    draw = ImageDraw.Draw(img)
    for y in range(0, TILE, 5):
        draw.line((0, y, TILE - 1, y), fill=(72, 49, 43, 255))
        offset = 4 if (y // 5) % 2 else 0
        for x in range(offset, TILE, 8):
            draw.line((x, y, x, min(y + 4, TILE - 1)), fill=(72, 49, 43, 255))
    rng = Random(seed)
    for _ in range(22):
        draw.point((rng.randrange(TILE), rng.randrange(TILE)), fill=(158, 96, 69, 255))
    return img


def leaf_litter(seed: int = 12) -> Image.Image:
    img = grass(seed)
    draw = ImageDraw.Draw(img)
    for x, y, color in [
        (2, 3, (166, 116, 55)),
        (8, 5, (130, 84, 42)),
        (12, 11, (190, 147, 64)),
        (5, 13, (116, 73, 36)),
    ]:
        draw.point((x, y), fill=(*color, 255))
        draw.point((x + 1, y + 1), fill=(*color, 255))
    return img


TILES = [
    (".", "short_grass", grass()),
    ("=", "packed_dirt_path", packed_dirt()),
    ("@", "town_plaza_cobble", plaza()),
    (",", "flower_grass", flower_grass()),
    (";", "muddy_track", mud()),
    ("w", "wood_decking", wood_deck()),
    ("+", "stone_path_border", stone_border()),
    ("g", "garden_soil", garden_soil()),
    ("s", "sanded_path", sanded_path()),
    ("m", "mossy_cobble", mossy_stone()),
    ("b", "warm_brick", brick()),
    ("l", "leaf_litter_grass", leaf_litter()),
]


def main() -> None:
    SOURCE_DIR.mkdir(parents=True, exist_ok=True)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    atlas = Image.new("RGBA", (8 * TILE, 2 * TILE), (0, 0, 0, 0))
    manifest = ["# Town Ground Atlas Source\n", "\n| Symbol | Tile | Atlas Coord |\n|---|---|---|\n"]
    for index, (symbol, name, img) in enumerate(TILES):
        x = index % 8
        y = index // 8
        atlas.paste(img, (x * TILE, y * TILE))
        img.save(SOURCE_DIR / f"{name}.png")
        manifest.append(f"| `{symbol}` | {name.replace('_', ' ')} | ({x}, {y}) |\n")
    atlas.save(OUT)
    (SOURCE_DIR / "README.md").write_text("".join(manifest), encoding="utf-8")
    print(f"Wrote {OUT.relative_to(ROOT)} ({atlas.size[0]}x{atlas.size[1]})")


if __name__ == "__main__":
    main()
