from pathlib import Path
from random import Random

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = ROOT / "assets" / "sprites" / "town" / "shops" / "awnings"
SIZE = (48, 24)


SHOP_COLORS = {
    "weapon_shop": ((130, 57, 43), (219, 150, 91), (72, 38, 35)),
    "armor_shop": ((58, 88, 132), (144, 174, 213), (36, 49, 76)),
    "inn": ((70, 126, 73), (166, 206, 120), (40, 76, 48)),
    "tavern": ((127, 78, 43), (220, 168, 77), (75, 46, 34)),
    "workshop": ((119, 79, 49), (216, 127, 59), (66, 48, 39)),
    "chapel": ((78, 91, 116), (159, 196, 166), (46, 54, 72)),
}


def make_awning(shop_id: str, colors: tuple[tuple[int, int, int], tuple[int, int, int], tuple[int, int, int]]) -> Image.Image:
    dark, light, outline = colors
    rng = Random(shop_id)
    img = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.rectangle((2, 4, 45, 16), fill=(*outline, 255))
    for x in range(4, 44, 8):
        color = light if (x // 8) % 2 else dark
        draw.rectangle((x, 5, x + 7, 14), fill=(*color, 255))
        draw.polygon([(x, 14), (x + 7, 14), (x + 5, 18), (x + 2, 18)], fill=(*color, 255))
    draw.line((4, 5, 43, 5), fill=(244, 219, 154, 255))
    draw.line((4, 15, 43, 15), fill=(*outline, 255))
    draw.rectangle((5, 19, 42, 21), fill=(33, 27, 24, 92))
    for _ in range(10):
        x = rng.randrange(6, 42)
        y = rng.randrange(7, 14)
        draw.point((x, y), fill=(255, 238, 181, 120))
    return img


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for shop_id, colors in SHOP_COLORS.items():
        path = OUT_DIR / f"{shop_id}.png"
        make_awning(shop_id, colors).save(path)
        print(f"Wrote {path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
