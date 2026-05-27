from pathlib import Path
from random import Random

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "sprites" / "interiors" / "town" / "home_interior.png"
SOURCE_DIR = ROOT / "assets" / "sprites" / "interiors" / "town" / "source"
TILE = 16


def tile(fill: tuple[int, int, int]) -> Image.Image:
    return Image.new("RGBA", (TILE, TILE), (*fill, 255))


def wood_floor(seed: int = 1) -> Image.Image:
    img = tile((150, 102, 58))
    draw = ImageDraw.Draw(img)
    rng = Random(seed)
    for y in range(0, TILE, 4):
        draw.line((0, y, TILE - 1, y), fill=(82, 57, 41, 255))
    for _ in range(24):
        draw.point((rng.randrange(TILE), rng.randrange(TILE)), fill=(191, 130, 74, 255))
    return img


def wall(seed: int = 2) -> Image.Image:
    img = tile((92, 75, 57))
    draw = ImageDraw.Draw(img)
    for y in (3, 8, 13):
        draw.line((0, y, TILE - 1, y), fill=(56, 46, 39, 255))
    for x in range(0, TILE, 8):
        draw.line((x, 0, x, TILE - 1), fill=(70, 56, 45, 255))
    return img


def bed() -> Image.Image:
    img = tile((92, 75, 57))
    draw = ImageDraw.Draw(img)
    draw.rectangle((2, 3, 13, 14), fill=(43, 34, 31, 255))
    draw.rectangle((3, 4, 12, 13), fill=(82, 116, 72, 255))
    draw.rectangle((4, 4, 11, 7), fill=(232, 216, 178, 255))
    return img


def kitchen() -> Image.Image:
    img = wood_floor()
    draw = ImageDraw.Draw(img)
    draw.rectangle((1, 4, 14, 13), fill=(57, 42, 34, 255))
    draw.rectangle((2, 5, 13, 12), fill=(144, 98, 54, 255))
    draw.rectangle((10, 3, 14, 8), fill=(97, 101, 96, 255))
    draw.point((12, 5), fill=(234, 202, 109, 255))
    return img


def garden() -> Image.Image:
    img = tile((83, 126, 65))
    draw = ImageDraw.Draw(img)
    for y in (4, 8, 12):
        draw.line((2, y, 13, y - 1), fill=(85, 58, 39, 255))
    for x, y in [(4, 5), (9, 9), (12, 4)]:
        draw.point((x, y), fill=(137, 203, 86, 255))
        draw.point((x + 1, y), fill=(137, 203, 86, 255))
    return img


def map_table() -> Image.Image:
    img = wood_floor()
    draw = ImageDraw.Draw(img)
    draw.rectangle((2, 3, 13, 13), fill=(60, 48, 40, 255))
    draw.rectangle((3, 4, 12, 12), fill=(190, 177, 136, 255))
    draw.line((4, 8, 11, 5), fill=(76, 119, 96, 255))
    draw.point((9, 10), fill=(145, 72, 56, 255))
    return img


def workbench() -> Image.Image:
    img = wood_floor()
    draw = ImageDraw.Draw(img)
    draw.rectangle((1, 5, 14, 12), fill=(55, 38, 30, 255))
    draw.rectangle((2, 5, 13, 9), fill=(127, 82, 45, 255))
    draw.line((5, 3, 10, 8), fill=(208, 125, 58, 255))
    draw.point((12, 6), fill=(177, 186, 174, 255))
    return img


def rug() -> Image.Image:
    img = wood_floor()
    draw = ImageDraw.Draw(img)
    draw.rectangle((2, 3, 13, 13), fill=(59, 43, 66, 255))
    draw.rectangle((4, 5, 11, 11), fill=(142, 84, 158, 255))
    draw.line((4, 8, 11, 8), fill=(225, 190, 100, 255))
    return img


def trophy() -> Image.Image:
    img = wall()
    draw = ImageDraw.Draw(img)
    draw.rectangle((4, 3, 11, 12), fill=(64, 49, 38, 255))
    draw.polygon([(7, 4), (10, 6), (9, 10), (5, 10), (4, 6)], fill=(229, 191, 83, 255))
    draw.rectangle((6, 11, 9, 13), fill=(93, 60, 38, 255))
    return img


def chest() -> Image.Image:
    img = wood_floor()
    draw = ImageDraw.Draw(img)
    draw.rectangle((2, 5, 13, 13), fill=(45, 31, 25, 255))
    draw.rectangle((3, 6, 12, 12), fill=(136, 87, 43, 255))
    draw.line((3, 8, 12, 8), fill=(216, 158, 67, 255))
    draw.point((8, 10), fill=(238, 209, 92, 255))
    return img


TILES = [
    ("#", "wall", wall()),
    (".", "wood_floor", wood_floor()),
    ("B", "bed", bed()),
    ("K", "kitchen", kitchen()),
    ("G", "garden", garden()),
    ("M", "map_table", map_table()),
    ("W", "workbench", workbench()),
    ("R", "rug", rug()),
    ("T", "trophy", trophy()),
    ("C", "chest", chest()),
    ("@", "table", map_table()),
]


def main() -> None:
    OUT.parent.mkdir(parents=True, exist_ok=True)
    SOURCE_DIR.mkdir(parents=True, exist_ok=True)
    atlas = Image.new("RGBA", (8 * TILE, 2 * TILE), (0, 0, 0, 0))
    manifest = ["# Home Interior Atlas Source\n", "\n| Symbol | Tile | Atlas Coord |\n|---|---|---|\n"]
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
