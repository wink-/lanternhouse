from __future__ import annotations

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
BUILDINGS_DIR = ROOT / "assets" / "sprites" / "town" / "buildings"
OUTPUT_DIR = BUILDINGS_DIR / "runtime"

BACKGROUND_TOLERANCE = 18
PADDING = 2

SPRITES = {
    "weapon_shop": ("runtime_shop_split_sheet.png", (26, 10, 144, 85)),
    "armor_shop": ("runtime_shop_split_sheet.png", (181, 10, 294, 85)),
    "tavern": ("runtime_shop_split_sheet.png", (27, 98, 146, 176)),
    "workshop": ("runtime_shop_split_sheet.png", (180, 96, 297, 177)),
    "small_house": ("runtime_home_split_sheet.png", (21, 17, 148, 83)),
    "large_house": ("runtime_home_split_sheet.png", (177, 15, 299, 85)),
    "house_timber": ("runtime_home_split_sheet.png", (20, 94, 148, 176)),
    "house_mossy": ("runtime_home_split_sheet.png", (180, 96, 296, 178)),
    "chapel": ("runtime_public_split_sheet.png", (14, 37, 91, 151)),
    "elder_hall": ("runtime_public_split_sheet.png", (106, 17, 216, 151)),
    "inn": ("runtime_public_split_sheet.png", (226, 23, 308, 151)),
}


def transparent_crop(sheet_path: Path, rect: tuple[int, int, int, int]) -> Image.Image:
    sheet = Image.open(sheet_path).convert("RGBA")
    bg = sheet.getpixel((0, 0))[:3]
    left, top, right, bottom = rect
    left = max(0, left - PADDING)
    top = max(0, top - PADDING)
    right = min(sheet.width, right + PADDING)
    bottom = min(sheet.height, bottom + PADDING)
    image = sheet.crop((left, top, right, bottom))
    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = pixels[x, y]
            if abs(r - bg[0]) + abs(g - bg[1]) + abs(b - bg[2]) <= BACKGROUND_TOLERANCE:
                pixels[x, y] = (r, g, b, 0)
    return image


def main() -> int:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    for building_id, (sheet_name, rect) in SPRITES.items():
        image = transparent_crop(BUILDINGS_DIR / sheet_name, rect)
        output = OUTPUT_DIR / f"{building_id}.png"
        image.save(output)
        print(f"Wrote {output.relative_to(ROOT)} ({image.width}x{image.height})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
