from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_RECIPE = ROOT / "assets" / "sprites" / "town" / "buildings" / "modular_building_atlas.recipe.json"


def source_image(path: Path) -> Image.Image:
    if not path.exists():
        raise FileNotFoundError(path)
    return Image.open(path).convert("RGBA")


def blank(tile_size: int) -> Image.Image:
    return Image.new("RGBA", (tile_size, tile_size), (0, 0, 0, 0))


def cell(src: Image.Image, tile_size: int, x: int, y: int) -> Image.Image:
    return src.crop((x * tile_size, y * tile_size, (x + 1) * tile_size, (y + 1) * tile_size))


def normalize_crop(src: Image.Image, tile_size: int, box: list[int]) -> Image.Image:
    crop = src.crop(tuple(box))
    canvas = blank(tile_size)
    crop.thumbnail((tile_size, tile_size), Image.Resampling.NEAREST)
    canvas.alpha_composite(crop, ((tile_size - crop.width) // 2, tile_size - crop.height))
    return canvas


def tint_shadow(img: Image.Image, tile_size: int, alpha: int) -> Image.Image:
    out = blank(tile_size)
    mask = img.getchannel("A")
    shadow = Image.new("RGBA", img.size, (22, 18, 20, alpha))
    out.alpha_composite(shadow)
    out.putalpha(mask)
    return out


def simple_plaque(tile_size: int, symbol: Image.Image | None = None) -> Image.Image:
    img = blank(tile_size)
    d = ImageDraw.Draw(img)
    d.rectangle((2, 4, 13, 12), fill=(47, 31, 27, 255))
    d.rectangle((3, 5, 12, 11), fill=(139, 87, 45, 255))
    d.rectangle((4, 6, 11, 10), outline=(199, 139, 72, 255))
    if symbol is not None:
        icon = symbol.copy()
        icon.thumbnail((8, 8), Image.Resampling.NEAREST)
        img.alpha_composite(icon, ((tile_size - icon.width) // 2, 5))
    return img


def simple_door(tile_size: int, opened: bool) -> Image.Image:
    img = blank(tile_size)
    d = ImageDraw.Draw(img)
    d.rectangle((3, 1, 12, 15), fill=(42, 27, 24, 255))
    if opened:
        d.rectangle((5, 3, 10, 15), fill=(24, 18, 20, 255))
        d.line((5, 3, 10, 3), fill=(238, 190, 87, 255))
    else:
        d.rectangle((5, 3, 10, 15), fill=(112, 59, 39, 255))
        d.line((7, 4, 7, 15), fill=(75, 39, 32, 255))
        d.point((9, 9), fill=(245, 194, 78, 255))
    return img


def simple_window(tile_size: int, arched: bool) -> Image.Image:
    img = blank(tile_size)
    d = ImageDraw.Draw(img)
    if arched:
        d.pieslice((3, 1, 12, 10), 180, 360, fill=(55, 37, 33, 255))
        d.rectangle((3, 6, 12, 14), fill=(55, 37, 33, 255))
        d.rectangle((5, 6, 10, 12), fill=(128, 214, 232, 255))
    else:
        d.rectangle((3, 3, 12, 13), fill=(55, 37, 33, 255))
        d.rectangle((5, 5, 10, 11), fill=(128, 214, 232, 255))
    d.line((7, 5, 7, 12), fill=(69, 87, 99, 255))
    d.line((5, 8, 10, 8), fill=(69, 87, 99, 255))
    return img


def simple_flower_box(tile_size: int) -> Image.Image:
    img = blank(tile_size)
    d = ImageDraw.Draw(img)
    d.rectangle((3, 9, 12, 12), fill=(106, 62, 38, 255))
    d.point((5, 8), fill=(219, 68, 95, 255))
    d.point((8, 8), fill=(244, 206, 77, 255))
    d.point((10, 8), fill=(92, 160, 74, 255))
    return img


def draw_lit_lantern(tile_size: int) -> Image.Image:
    img = blank(tile_size)
    d = ImageDraw.Draw(img)
    d.line((7, 1, 7, 5), fill=(42, 31, 28, 255))
    d.rectangle((5, 5, 10, 12), fill=(42, 31, 28, 255))
    d.rectangle((6, 6, 9, 10), fill=(248, 189, 72, 255))
    d.point((7, 7), fill=(255, 235, 138, 255))
    return img


def source_label(inputs: dict[str, str], spec: dict[str, Any]) -> str:
    op = spec["op"]
    if op == "blank":
        return "transparent blank"
    if op == "door":
        door_kind = "open door" if spec.get("opened", False) else "door"
        return f"{inputs.get(spec.get('palette_source', ''), 'PixelLab palette')} palette-inspired composed {door_kind}"
    if op == "window":
        window_kind = "arched window" if spec.get("arched", False) else "square window"
        return f"{inputs.get(spec.get('palette_source', ''), 'PixelLab palette')} palette-inspired composed {window_kind}"
    if op == "flower_box":
        return f"{inputs.get(spec.get('palette_source', ''), 'PixelLab palette')} palette-inspired composed flower box"
    if op == "plaque":
        if spec.get("symbol_source"):
            symbol_name = spec["id"].replace("plaque_", "").replace("_", "/")
            return f"{inputs[spec['symbol_source']]} {symbol_name} on curated plaque"
        return f"{inputs.get(spec.get('palette_source', ''), 'PixelLab palette')} palette-inspired composed blank plaque"
    if op == "lantern":
        return "hand-composed from PixelLab lantern palette"
    src = inputs[spec["source"]]
    if op in ["cell", "shadow"]:
        return f"{src} cell {spec['cell'][0]},{spec['cell'][1]}" + (" shadow mask" if op == "shadow" else "")
    if op == "crop":
        return f"{src} normalized crop {','.join(str(v) for v in spec['box'])}"
    return src


def build_tile(spec: dict[str, Any], inputs: dict[str, str], images: dict[str, Image.Image], tile_size: int) -> Image.Image:
    op = spec["op"]
    if op == "blank":
        return blank(tile_size)
    if op == "cell":
        return cell(images[spec["source"]], tile_size, spec["cell"][0], spec["cell"][1])
    if op == "crop":
        return normalize_crop(images[spec["source"]], tile_size, spec["box"])
    if op == "shadow":
        base = cell(images[spec["source"]], tile_size, spec["cell"][0], spec["cell"][1])
        return tint_shadow(base, tile_size, int(spec.get("alpha", 110)))
    if op == "door":
        return simple_door(tile_size, bool(spec.get("opened", False)))
    if op == "window":
        return simple_window(tile_size, bool(spec.get("arched", False)))
    if op == "flower_box":
        return simple_flower_box(tile_size)
    if op == "lantern":
        return draw_lit_lantern(tile_size)
    if op == "plaque":
        symbol = None
        if spec.get("symbol_source"):
            symbol = normalize_crop(images[spec["symbol_source"]], tile_size, spec["symbol_box"])
        return simple_plaque(tile_size, symbol)
    raise ValueError(f"Unsupported tile op: {op}")


def build(recipe_path: Path) -> Path:
    recipe = json.loads(recipe_path.read_text(encoding="utf-8"))
    tile_size = int(recipe.get("tile_size", 16))
    columns = int(recipe.get("columns", 8))
    inputs: dict[str, str] = recipe["inputs"]
    images = {key: source_image(ROOT / rel_path) for key, rel_path in inputs.items()}
    tiles: list[dict[str, Any]] = recipe["tiles"]

    output = ROOT / recipe["output"]
    output.parent.mkdir(parents=True, exist_ok=True)
    rows = (len(tiles) + columns - 1) // columns
    atlas = Image.new("RGBA", (columns * tile_size, rows * tile_size), (0, 0, 0, 0))
    sidecar_tiles: list[dict[str, object]] = []
    manifest = [
        "# Modular Building Atlas\n",
        "\nCurated from PixelLab town construction outputs. Tile IDs match `scripts/town.gd`.\n\n",
        "| Tile | Rect | Source |\n",
        "|---|---|---|\n",
    ]

    seen: set[str] = set()
    for index, spec in enumerate(tiles):
        tile_id = spec["id"]
        if tile_id in seen:
            raise ValueError(f"Duplicate tile id in recipe: {tile_id}")
        seen.add(tile_id)
        img = build_tile(spec, inputs, images, tile_size)
        x = index % columns
        y = index // columns
        atlas.alpha_composite(img, (x * tile_size, y * tile_size))
        rect = [x * tile_size, y * tile_size, tile_size, tile_size]
        source = source_label(inputs, spec)
        manifest.append(f"| `{tile_id}` | `{rect[0]},{rect[1]},{rect[2]},{rect[3]}` | {source} |\n")
        sidecar_tiles.append({"tile": tile_id, "rect": rect, "source": source})

    atlas.save(output)
    output.with_suffix(".md").write_text("".join(manifest), encoding="utf-8")
    output.with_suffix(".json").write_text(
        json.dumps(
            {
                "asset_name": recipe["asset_name"],
                "runtime_path": recipe["output"],
                "recipe_path": str(recipe_path.relative_to(ROOT)).replace("\\", "/"),
                "tile_size": tile_size,
                "status": "integrated",
                "notes": recipe.get("notes", ""),
                "tiles": sidecar_tiles,
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    print(f"Wrote {output.relative_to(ROOT)} ({atlas.size[0]}x{atlas.size[1]}) from {len(tiles)} curated tiles")
    return output


def main() -> None:
    parser = argparse.ArgumentParser(description="Build the Brindlewick modular building atlas from a JSON recipe.")
    parser.add_argument("--recipe", type=Path, default=DEFAULT_RECIPE, help="Path to atlas recipe JSON.")
    args = parser.parse_args()
    recipe_path = args.recipe if args.recipe.is_absolute() else ROOT / args.recipe
    build(recipe_path)


if __name__ == "__main__":
    main()
