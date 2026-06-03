from __future__ import annotations

from pathlib import Path
from random import Random

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "sprites" / "tiles" / "pixellab" / "brindlewick_grass_dirt_wang_tileset.png"
TILE = 16

WANG_RECTS = {
    0: (32, 16),
    1: (16, 16),
    2: (32, 0),
    3: (48, 0),
    4: (32, 32),
    5: (16, 0),
    6: (0, 16),
    7: (16, 48),
    8: (48, 16),
    9: (32, 48),
    10: (48, 32),
    11: (0, 0),
    12: (16, 32),
    13: (0, 32),
    14: (48, 48),
    15: (0, 48),
}

GRASS = [(58, 126, 54), (67, 142, 59), (76, 153, 64), (49, 104, 48)]
DIRT = [(132, 90, 55), (151, 105, 62), (111, 76, 51), (174, 123, 73)]
EDGE = [(88, 104, 53), (103, 91, 49), (66, 111, 51)]
FLOWERS = [(216, 176, 80), (191, 108, 125), (160, 126, 202)]


def _corner(mask: int, bit: int) -> int:
    return 1 if mask & bit else 0


def _is_dirt(mask: int, x: int, y: int, rng: Random) -> bool:
    if mask == 0:
        return False
    if mask == 15:
        return True

    nx = x / (TILE - 1)
    ny = y / (TILE - 1)
    nw = _corner(mask, 1)
    ne = _corner(mask, 2)
    sw = _corner(mask, 4)
    se = _corner(mask, 8)
    influence = (
        nw * (1.0 - nx) * (1.0 - ny)
        + ne * nx * (1.0 - ny)
        + sw * (1.0 - nx) * ny
        + se * nx * ny
    )
    wobble = (rng.randrange(-18, 19) / 100.0)
    return influence + wobble > 0.38


def _tile(mask: int) -> Image.Image:
    rng = Random(5200 + mask * 97)
    img = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    dirt_pixels: set[tuple[int, int]] = set()

    for y in range(TILE):
        for x in range(TILE):
            if _is_dirt(mask, x, y, rng):
                dirt_pixels.add((x, y))
                color = rng.choice(DIRT)
            else:
                color = rng.choice(GRASS)
            draw.point((x, y), fill=(*color, 255))

    for x, y in list(dirt_pixels):
        neighbors_grass = any(
            (x + dx, y + dy) not in dirt_pixels
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))
            if 0 <= x + dx < TILE and 0 <= y + dy < TILE
        )
        if neighbors_grass and rng.randrange(100) < 62:
            draw.point((x, y), fill=(*rng.choice(EDGE), 255))

    fleck_count = 18 if mask in (0, 15) else 13
    for _ in range(fleck_count):
        x = rng.randrange(TILE)
        y = rng.randrange(TILE)
        if (x, y) in dirt_pixels:
            draw.point((x, y), fill=(*rng.choice([(91, 65, 48), (190, 142, 84), (104, 88, 67)]), 255))
        else:
            draw.point((x, y), fill=(*rng.choice([(42, 94, 43), (96, 171, 74), (82, 136, 57)]), 255))

    if mask == 0:
        for _ in range(3):
            x = rng.randrange(2, TILE - 2)
            y = rng.randrange(2, TILE - 2)
            color = rng.choice(FLOWERS)
            draw.point((x, y), fill=(*color, 255))
            draw.point((x + 1, y), fill=(*color, 255))

    return img


def main() -> None:
    OUT.parent.mkdir(parents=True, exist_ok=True)
    atlas = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    for mask, pos in WANG_RECTS.items():
        atlas.paste(_tile(mask), pos)
    atlas.save(OUT)
    print(f"Wrote {OUT.relative_to(ROOT)} ({atlas.width}x{atlas.height})")


if __name__ == "__main__":
    main()
