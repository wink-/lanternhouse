from pathlib import Path
from random import Random

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = ROOT / "assets" / "sprites" / "town" / "shops" / "buildings"
SIZE = (96, 64)


BUILDINGS = {
    "elder_hall": {
        "wall": (128, 103, 82),
        "roof": (88, 72, 105),
        "trim": (218, 185, 102),
        "icon": "lantern",
    },
    "weapon_shop": {
        "wall": (132, 92, 68),
        "roof": (120, 50, 42),
        "trim": (216, 142, 78),
        "icon": "sword",
    },
    "armor_shop": {
        "wall": (102, 111, 126),
        "roof": (52, 78, 122),
        "trim": (169, 184, 205),
        "icon": "shield",
    },
    "inn": {
        "wall": (126, 101, 72),
        "roof": (61, 124, 68),
        "trim": (197, 178, 112),
        "icon": "bed",
    },
    "tavern": {
        "wall": (124, 86, 58),
        "roof": (142, 83, 40),
        "trim": (224, 166, 80),
        "icon": "mug",
    },
    "workshop": {
        "wall": (107, 91, 76),
        "roof": (134, 82, 45),
        "trim": (220, 122, 58),
        "icon": "gear",
    },
    "chapel": {
        "wall": (124, 129, 126),
        "roof": (76, 84, 112),
        "trim": (147, 198, 166),
        "icon": "star",
    },
}


OUTLINE = (36, 30, 28, 255)
SHADOW = (23, 21, 20, 92)


def draw_roof(draw: ImageDraw.ImageDraw, roof: tuple[int, int, int], trim: tuple[int, int, int]) -> None:
    draw.polygon([(5, 24), (48, 4), (91, 24)], fill=OUTLINE)
    draw.polygon([(10, 23), (48, 7), (86, 23)], fill=(*roof, 255))
    for y in range(13, 24, 4):
        draw.line((14, y, 82, y), fill=(max(roof[0] - 30, 0), max(roof[1] - 30, 0), max(roof[2] - 30, 0), 255))
    draw.line((15, 24, 81, 24), fill=(*trim, 255))


def draw_icon(draw: ImageDraw.ImageDraw, icon: str, cx: int, cy: int, trim: tuple[int, int, int]) -> None:
    color = (*trim, 255)
    dark = OUTLINE
    if icon == "sword":
        draw.line((cx - 4, cy + 5, cx + 5, cy - 4), fill=color, width=2)
        draw.line((cx - 5, cy - 1, cx + 1, cy + 5), fill=dark)
    elif icon == "shield":
        draw.polygon([(cx, cy - 6), (cx + 6, cy - 3), (cx + 4, cy + 5), (cx, cy + 8), (cx - 4, cy + 5), (cx - 6, cy - 3)], fill=color)
        draw.line((cx, cy - 4, cx, cy + 5), fill=dark)
    elif icon == "bed":
        draw.rectangle((cx - 7, cy - 2, cx + 7, cy + 5), fill=color)
        draw.rectangle((cx - 7, cy - 5, cx - 1, cy - 1), fill=(238, 221, 165, 255))
    elif icon == "mug":
        draw.rectangle((cx - 5, cy - 5, cx + 3, cy + 6), fill=color)
        draw.arc((cx + 1, cy - 3, cx + 9, cy + 5), -85, 90, fill=color, width=2)
    elif icon == "gear":
        draw.ellipse((cx - 6, cy - 6, cx + 6, cy + 6), fill=color)
        draw.ellipse((cx - 2, cy - 2, cx + 2, cy + 2), fill=dark)
        for dx, dy in [(-8, 0), (8, 0), (0, -8), (0, 8)]:
            draw.rectangle((cx + dx - 1, cy + dy - 1, cx + dx + 1, cy + dy + 1), fill=color)
    elif icon == "star":
        draw.line((cx, cy - 7, cx, cy + 7), fill=color, width=2)
        draw.line((cx - 7, cy, cx + 7, cy), fill=color, width=2)
        draw.point((cx - 4, cy - 4), fill=color)
        draw.point((cx + 4, cy - 4), fill=color)
    else:
        draw.ellipse((cx - 4, cy - 6, cx + 4, cy + 5), fill=color)
        draw.rectangle((cx - 1, cy + 5, cx + 1, cy + 9), fill=dark)


def make_building(name: str, cfg: dict) -> Image.Image:
    rng = Random(name)
    wall = cfg["wall"]
    roof = cfg["roof"]
    trim = cfg["trim"]
    img = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.ellipse((13, 53, 83, 63), fill=SHADOW)
    draw.rectangle((13, 22, 83, 58), fill=OUTLINE)
    draw.rectangle((17, 25, 79, 56), fill=(*wall, 255))
    for _ in range(40):
        x = rng.randrange(19, 78)
        y = rng.randrange(27, 55)
        shade = rng.choice([-18, 16])
        draw.point((x, y), fill=(max(min(wall[0] + shade, 255), 0), max(min(wall[1] + shade, 255), 0), max(min(wall[2] + shade, 255), 0), 255))
    draw_roof(draw, roof, trim)
    draw.rectangle((41, 39, 55, 58), fill=OUTLINE)
    draw.rectangle((44, 42, 52, 58), fill=(82, 54, 38, 255))
    draw.point((51, 50), fill=(*trim, 255))
    for x in (25, 64):
        draw.rectangle((x, 34, x + 10, 44), fill=OUTLINE)
        draw.rectangle((x + 2, 36, x + 8, 42), fill=(222, 190, 105, 255))
    draw.rectangle((34, 27, 62, 37), fill=OUTLINE)
    draw.rectangle((36, 28, 60, 35), fill=(86, 58, 42, 255))
    draw_icon(draw, cfg["icon"], 48, 32, trim)
    return img


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for name, cfg in BUILDINGS.items():
        path = OUT_DIR / f"{name}.png"
        make_building(name, cfg).save(path)
        print(f"Wrote {path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
