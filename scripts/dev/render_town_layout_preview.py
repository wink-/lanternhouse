from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_LAYOUT = ROOT / "assets" / "world" / "towns" / "brindlewick.layout.json"
DEFAULT_OUTPUT = ROOT / "assets" / "world" / "towns" / "brindlewick.preview.png"

TILE_COLORS = {
    ",": (79, 158, 67),
    "=": (173, 126, 72),
    "H": (77, 158, 67),
    ";": (101, 86, 60),
    "w": (143, 91, 52),
    "+": (128, 126, 110),
    "g": (117, 76, 49),
    "s": (194, 166, 101),
    "m": (139, 129, 105),
    "b": (128, 78, 60),
    "l": (74, 143, 62),
    ".": (196, 155, 86),
}

BUILDING_COLORS = {
    "elder_hall": (140, 93, 59, 205),
    "weapon_shop": (150, 70, 54, 205),
    "armor_shop": (70, 92, 148, 205),
    "inn": (136, 158, 76, 205),
    "tavern": (143, 126, 104, 205),
    "workshop": (188, 109, 52, 205),
    "chapel": (220, 214, 181, 205),
}


def load_font(size: int = 10) -> ImageFont.ImageFont:
    try:
        return ImageFont.truetype("arial.ttf", size)
    except OSError:
        return ImageFont.load_default()


def point(value: list[int]) -> tuple[int, int]:
    return int(value[0]), int(value[1])


def rect_from_grid(grid: tuple[int, int], size: tuple[int, int], scale: int) -> tuple[int, int, int, int]:
    x, y = grid
    w, h = size
    return x * scale, y * scale, (x + w) * scale - 1, (y + h) * scale - 1


def draw_grid(draw: ImageDraw.ImageDraw, width: int, height: int, scale: int) -> None:
    for x in range(width + 1):
        color = (20, 24, 20, 80) if x % 5 else (20, 24, 20, 145)
        draw.line((x * scale, 0, x * scale, height * scale), fill=color)
    for y in range(height + 1):
        color = (20, 24, 20, 80) if y % 5 else (20, 24, 20, 145)
        draw.line((0, y * scale, width * scale, y * scale), fill=color)


def display_path(path: Path) -> str:
    try:
        return str(path.relative_to(ROOT))
    except ValueError:
        return str(path)


def render(layout: dict[str, Any], output: Path, scale: int) -> None:
    town_map: list[str] = layout["map"]
    width = len(town_map[0])
    height = len(town_map)
    legend_width = 300
    canvas = Image.new("RGBA", (width * scale + legend_width, height * scale), (28, 30, 28, 255))
    draw = ImageDraw.Draw(canvas)
    font = load_font(10)
    title_font = load_font(14)

    for y, row in enumerate(town_map):
        for x, tile in enumerate(row):
            color = TILE_COLORS.get(tile, (230, 80, 230))
            draw.rectangle((x * scale, y * scale, (x + 1) * scale - 1, (y + 1) * scale - 1), fill=color)
    draw_grid(draw, width, height, scale)

    for building in layout.get("buildings", []):
        grid = point(building["grid"])
        size = point(building["size"])
        building_id = building["id"]
        color = BUILDING_COLORS.get(building_id, (210, 180, 100, 205))
        box = rect_from_grid(grid, size, scale)
        draw.rectangle(box, fill=color, outline=(28, 18, 14, 255), width=2)
        label = building_id.replace("_", " ")
        draw.text((box[0] + 3, box[1] + 3), label, fill=(20, 16, 12, 255), font=font)

    for door in layout.get("doors", []):
        x, y = point(door["grid"])
        cx = x * scale + scale // 2
        cy = y * scale + scale // 2
        draw.ellipse((cx - 4, cy - 4, cx + 4, cy + 4), fill=(255, 230, 88, 255), outline=(40, 30, 10, 255))

    for prop in layout.get("props", []):
        x, y = point(prop["grid"])
        cx = x * scale + scale // 2
        cy = y * scale + scale // 2
        draw.rectangle((cx - 3, cy - 3, cx + 3, cy + 3), fill=(50, 42, 190, 255), outline=(240, 240, 255, 255))

    cat = layout.get("cat", {})
    if isinstance(cat, dict) and isinstance(cat.get("home"), list):
        x, y = point(cat["home"])
        cx = x * scale + scale // 2
        cy = y * scale + scale // 2
        radius = int(cat.get("wander_radius", 0)) * scale
        draw.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), outline=(255, 170, 70, 190), width=2)
        draw.polygon([(cx, cy - 7), (cx - 7, cy + 6), (cx + 7, cy + 6)], fill=(255, 170, 70, 255), outline=(60, 35, 20, 255))

    legend_x = width * scale + 18
    draw.text((legend_x, 16), layout.get("name", "Town Layout"), fill=(245, 230, 170), font=title_font)
    draw.text((legend_x, 42), f"{width}x{height} tiles  scale {scale}px", fill=(220, 220, 210), font=font)
    legend_items = [
        ("building footprint", (180, 120, 80, 255)),
        ("door target", (255, 230, 88, 255)),
        ("prop", (50, 42, 190, 255)),
        ("cat home/radius", (255, 170, 70, 255)),
    ]
    y = 76
    for label, color in legend_items:
        draw.rectangle((legend_x, y, legend_x + 14, y + 14), fill=color)
        draw.text((legend_x + 22, y), label, fill=(230, 230, 220), font=font)
        y += 24
    y += 8
    draw.text((legend_x, y), "Buildings", fill=(245, 230, 170), font=font)
    y += 18
    for building in layout.get("buildings", []):
        label = f"- {building['id']} @ {building['grid']}"
        draw.text((legend_x, y), label, fill=(220, 220, 210), font=font)
        y += 14

    output.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(output)
    print(f"Wrote {display_path(output)} ({canvas.size[0]}x{canvas.size[1]})")


def main() -> None:
    parser = argparse.ArgumentParser(description="Render a quick PNG preview from a town layout JSON file.")
    parser.add_argument("--layout", type=Path, default=DEFAULT_LAYOUT)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--scale", type=int, default=24)
    parser.add_argument("--all", action="store_true", help="Render every assets/world/towns/*.layout.json file.")
    args = parser.parse_args()
    if args.all:
        for layout_path in sorted((ROOT / "assets" / "world" / "towns").glob("*.layout.json")):
            output_path = layout_path.with_name(layout_path.name.replace(".layout.json", ".preview.png"))
            layout = json.loads(layout_path.read_text(encoding="utf-8"))
            render(layout, output_path, args.scale)
        return
    layout_path = args.layout if args.layout.is_absolute() else ROOT / args.layout
    output_path = args.output if args.output.is_absolute() else ROOT / args.output
    layout = json.loads(layout_path.read_text(encoding="utf-8"))
    render(layout, output_path, args.scale)


if __name__ == "__main__":
    main()
