from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
BUILDINGS = ROOT / "assets" / "sprites" / "town" / "buildings"
OUT = BUILDINGS / "modular_building_atlas.png"
MANIFEST = OUT.with_suffix(".md")
SIDECAR = BUILDINGS / "modular_building_atlas.json"
TILE = 16


def load_rgba(relative_path: str) -> Image.Image:
    return (ROOT / relative_path).open("rb")


def source_image(relative_path: str) -> Image.Image:
    return Image.open(ROOT / relative_path).convert("RGBA")


def blank() -> Image.Image:
    return Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))


def normalize_crop(relative_path: str, box: tuple[int, int, int, int]) -> Image.Image:
    src = source_image(relative_path)
    crop = src.crop(box)
    canvas = blank()
    crop.thumbnail((TILE, TILE), Image.Resampling.NEAREST)
    canvas.alpha_composite(crop, ((TILE - crop.width) // 2, TILE - crop.height))
    return canvas


def cell(relative_path: str, x: int, y: int) -> Image.Image:
    return source_image(relative_path).crop((x * TILE, y * TILE, (x + 1) * TILE, (y + 1) * TILE))


def tint_shadow(img: Image.Image, alpha: int = 110) -> Image.Image:
    out = blank()
    mask = img.getchannel("A")
    shadow = Image.new("RGBA", img.size, (22, 18, 20, alpha))
    out.alpha_composite(shadow)
    out.putalpha(mask)
    return out


def simple_plaque(symbol: Image.Image | None = None) -> Image.Image:
    img = blank()
    d = ImageDraw.Draw(img)
    d.rectangle((2, 4, 13, 12), fill=(47, 31, 27, 255))
    d.rectangle((3, 5, 12, 11), fill=(139, 87, 45, 255))
    d.rectangle((4, 6, 11, 10), outline=(199, 139, 72, 255))
    if symbol is not None:
        icon = symbol.copy()
        icon.thumbnail((8, 8), Image.Resampling.NEAREST)
        img.alpha_composite(icon, ((TILE - icon.width) // 2, 5))
    return img


def simple_door(opened: bool = False) -> Image.Image:
    img = blank()
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


def simple_window(arched: bool = False) -> Image.Image:
    img = blank()
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


def simple_flower_box() -> Image.Image:
    img = blank()
    d = ImageDraw.Draw(img)
    d.rectangle((3, 9, 12, 12), fill=(106, 62, 38, 255))
    d.point((5, 8), fill=(219, 68, 95, 255))
    d.point((8, 8), fill=(244, 206, 77, 255))
    d.point((10, 8), fill=(92, 160, 74, 255))
    return img


def draw_lit_lantern() -> Image.Image:
    img = blank()
    d = ImageDraw.Draw(img)
    d.line((7, 1, 7, 5), fill=(42, 31, 28, 255))
    d.rectangle((5, 5, 10, 12), fill=(42, 31, 28, 255))
    d.rectangle((6, 6, 9, 10), fill=(248, 189, 72, 255))
    d.point((7, 7), fill=(255, 235, 138, 255))
    return img


def build_tiles() -> list[tuple[str, Image.Image, str]]:
    roof = "assets/sprites/town/buildings/pure_roof_swatches_retry.png"
    roof_edges = "assets/sprites/town/buildings/roof_corner_edge_variants.png"
    cohesion = "assets/sprites/town/buildings/final_building_tile_cohesion.png"
    windows = "assets/sprites/town/buildings/window_door_tiles_expanded.png"
    accessories = "assets/sprites/town/buildings/roof_accessories.png"
    symbols = "assets/sprites/town/buildings/isolated_shop_symbols_retry.png"
    signs = "assets/sprites/town/buildings/blank_sign_boards.png"

    sword = normalize_crop(symbols, (0, 0, 32, 32))
    shield = normalize_crop(symbols, (64, 0, 96, 32))
    tankard = normalize_crop(symbols, (32, 0, 64, 32))
    candle = normalize_crop(symbols, (64, 32, 96, 64))
    gear = normalize_crop(symbols, (32, 32, 64, 64))
    bed = normalize_crop(symbols, (0, 32, 32, 64))

    wall = cell(cohesion, 4, 3)
    wall_timber = cell(cohesion, 5, 3)
    wall_brace = cell(cohesion, 3, 3)
    foundation = cell(cohesion, 3, 5)
    foundation_moss = cell(cohesion, 4, 5)
    door = simple_door(False)
    open_door = simple_door(True)
    window = simple_window(False)
    window_arch = simple_window(True)
    window_flower = simple_window(True)
    flower_box = simple_flower_box()
    chimney = normalize_crop(accessories, (0, 64, 32, 112))

    return [
        ("roof_left", cell(roof, 1, 2), f"{roof} cell 1,2"),
        ("roof_mid", cell(roof, 2, 2), f"{roof} cell 2,2"),
        ("roof_right", cell(roof, 4, 2), f"{roof} cell 4,2"),
        ("roof_ridge", cell(roof, 3, 2), f"{roof} cell 3,2"),
        ("roof_eave", cell(roof_edges, 2, 3), f"{roof_edges} cell 2,3"),
        ("roof_moss", cell(roof, 2, 4), f"{roof} cell 2,4"),
        ("chimney", chimney, f"{accessories} normalized crop 0,64,32,112"),
        ("blank", blank(), "transparent blank"),
        ("wall", wall, f"{cohesion} cell 4,3"),
        ("wall_timber", wall_timber, f"{cohesion} cell 5,3"),
        ("wall_brace", wall_brace, f"{cohesion} cell 3,3"),
        ("wall_shadow", tint_shadow(wall), f"{cohesion} cell 4,3 shadow mask"),
        ("foundation", foundation, f"{cohesion} cell 3,5"),
        ("foundation_moss", foundation_moss, f"{cohesion} cell 4,5"),
        ("foundation_shadow", tint_shadow(foundation, 150), f"{cohesion} cell 3,5 shadow mask"),
        ("threshold", cell(cohesion, 5, 5), f"{cohesion} cell 5,5"),
        ("door", door, f"{windows} palette-inspired composed door"),
        ("door_open", open_door, f"{windows} palette-inspired composed open door"),
        ("window", window, f"{windows} palette-inspired composed square window"),
        ("window_arch", window_arch, f"{windows} palette-inspired composed arched window"),
        ("window_flower", window_flower, f"{windows} palette-inspired composed arched window"),
        ("plaque_blank", simple_plaque(), f"{signs} palette-inspired composed blank plaque"),
        ("lantern", draw_lit_lantern(), "hand-composed from PixelLab lantern palette"),
        ("flower_box", flower_box, f"{windows} palette-inspired composed flower box"),
        ("plaque_sword", simple_plaque(sword), f"{symbols} sword on curated plaque"),
        ("plaque_shield", simple_plaque(shield), f"{symbols} shield on curated plaque"),
        ("plaque_tankard", simple_plaque(tankard), f"{symbols} tankard on curated plaque"),
        ("plaque_gear", simple_plaque(gear), f"{symbols} gear on curated plaque"),
        ("plaque_bed", simple_plaque(bed), f"{symbols} bed/leaf on curated plaque"),
        ("plaque_candle", simple_plaque(candle), f"{symbols} candle/boot on curated plaque"),
    ]


def main() -> None:
    OUT.parent.mkdir(parents=True, exist_ok=True)
    cols = 8
    tiles = build_tiles()
    rows = (len(tiles) + cols - 1) // cols
    atlas = Image.new("RGBA", (cols * TILE, rows * TILE), (0, 0, 0, 0))
    manifest = ["# Modular Building Atlas\n", "\nCurated from PixelLab town construction outputs. Tile IDs match `scripts/town.gd`.\n\n", "| Tile | Rect | Source |\n", "|---|---|---|\n"]
    sidecar_tiles: list[dict[str, object]] = []
    for index, (name, img, source) in enumerate(tiles):
        x = index % cols
        y = index // cols
        atlas.alpha_composite(img, (x * TILE, y * TILE))
        rect = [x * TILE, y * TILE, TILE, TILE]
        manifest.append(f"| `{name}` | `{rect[0]},{rect[1]},{rect[2]},{rect[3]}` | {source} |\n")
        sidecar_tiles.append({"tile": name, "rect": rect, "source": source})
    atlas.save(OUT)
    MANIFEST.write_text("".join(manifest), encoding="utf-8")
    SIDECAR.write_text(
        json.dumps(
            {
                "asset_name": "Curated Modular Building Atlas",
                "runtime_path": "assets/sprites/town/buildings/modular_building_atlas.png",
                "tile_size": TILE,
                "status": "integrated",
                "notes": "Runtime atlas used by scripts/town.gd. Curated from PixelLab sheets and references while preserving existing tile IDs.",
                "tiles": sidecar_tiles,
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    print(f"Wrote {OUT.relative_to(ROOT)} ({atlas.size[0]}x{atlas.size[1]}) from {len(tiles)} curated tiles")


if __name__ == "__main__":
    main()
