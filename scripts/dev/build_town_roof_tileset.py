from __future__ import annotations

import argparse
import json
import tempfile
import urllib.request
import zipfile
from pathlib import Path
from typing import Any

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_RECIPE = ROOT / "assets" / "sprites" / "town" / "buildings" / "roof_tileset.recipe.json"


def fetch_zip(tileset_id: str, dest: Path) -> None:
    url = f"https://api.pixellab.ai/mcp/tiles-pro/{tileset_id}/download"
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req) as response:
        dest.write_bytes(response.read())


def load_tile_folder(zip_path: Path, extract_dir: Path) -> list[Path]:
    with zipfile.ZipFile(zip_path) as zf:
        zf.extractall(extract_dir)

    def tile_index(path: Path) -> int:
        stem = path.stem.rsplit("_", 1)[-1]
        return int(stem)

    return sorted(extract_dir.glob("*.png"), key=tile_index)


def load_image(path: Path) -> Image.Image:
    return Image.open(path).convert("RGBA")


def build(recipe_path: Path) -> Path:
    recipe = json.loads(recipe_path.read_text(encoding="utf-8"))
    output = ROOT / recipe["output"]
    output.parent.mkdir(parents=True, exist_ok=True)

    tile_size = int(recipe.get("tile_size", 16))
    family_columns = int(recipe.get("family_columns", 4))
    family_rows = int(recipe.get("family_rows", 4))
    atlas_columns = family_columns * 2
    atlas_rows = family_rows

    green_id = recipe["sources"]["green"]
    red_id = recipe["sources"]["red"]

    with tempfile.TemporaryDirectory(prefix="roof_tileset_build_") as tmp:
        tmpdir = Path(tmp)
        green_zip = tmpdir / f"{green_id}.zip"
        red_zip = tmpdir / f"{red_id}.zip"
        fetch_zip(green_id, green_zip)
        fetch_zip(red_id, red_zip)

        green_dir = tmpdir / "green"
        red_dir = tmpdir / "red"
        green_dir.mkdir()
        red_dir.mkdir()
        green_files = load_tile_folder(green_zip, green_dir)
        red_files = load_tile_folder(red_zip, red_dir)

        expected = family_columns * family_rows
        if len(green_files) != expected:
            raise RuntimeError(f"Expected {expected} green tiles, found {len(green_files)}")
        if len(red_files) != expected:
            raise RuntimeError(f"Expected {expected} red tiles, found {len(red_files)}")

        atlas = Image.new("RGBA", (atlas_columns * tile_size, atlas_rows * tile_size), (0, 0, 0, 0))
        tiles: list[dict[str, Any]] = []

        family_specs = [
            ("green", recipe["green_roles"], green_files, 0),
            ("red", recipe["red_roles"], red_files, family_columns),
        ]

        for family_name, roles, files, x_offset in family_specs:
            if len(roles) != expected:
                raise RuntimeError(f"{family_name} role list should have {expected} entries")
            for idx, role in enumerate(roles):
                src = load_image(files[idx])
                if src.size != (tile_size, tile_size):
                    raise RuntimeError(f"{files[idx].name} is {src.size}, expected {(tile_size, tile_size)}")
                x = x_offset + (idx % family_columns)
                y = idx // family_columns
                atlas.alpha_composite(src, (x * tile_size, y * tile_size))
                tiles.append(
                    {
                        "id": f"{family_name}_{role}",
                        "family": family_name,
                        "role": role,
                        "source_index": idx,
                        "rect": [x * tile_size, y * tile_size, tile_size, tile_size],
                    }
                )

        atlas.save(output)
        manifest_path = output.with_suffix(".json")
        manifest = {
            "asset_name": recipe["asset_name"],
            "runtime_path": recipe["output"],
            "recipe_path": str(recipe_path.relative_to(ROOT)).replace("\\", "/"),
            "tile_size": tile_size,
            "atlas_size": [atlas.width, atlas.height],
            "status": "integrated",
            "notes": recipe.get("notes", ""),
            "tiles": tiles,
        }
        manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")

        md_path = output.with_suffix(".md")
        md_lines = [
            f"# {recipe['asset_name']}\n",
            "\n",
            f"Tile size: {tile_size}x{tile_size}\n",
            f"Atlas size: {atlas.width}x{atlas.height}\n",
            "\n",
            "| Tile ID | Rect | Family | Role | Source Index |\n",
            "|---|---:|---|---|---:|\n",
        ]
        for tile in tiles:
            rect = tile["rect"]
            md_lines.append(
                f"| `{tile['id']}` | `{rect[0]},{rect[1]},{rect[2]},{rect[3]}` | {tile['family']} | {tile['role']} | {tile['source_index']} |\n"
            )
        md_lines.append("\nAssembly note: green roof family occupies the left 4 columns; red-brown roof family occupies the right 4 columns.\n")
        md_path.write_text("".join(md_lines), encoding="utf-8")

    print(f"Wrote {output.relative_to(ROOT)} ({atlas.width}x{atlas.height}) from {len(tiles)} tiles")
    return output


def main() -> None:
    parser = argparse.ArgumentParser(description="Build the Lanternhouse roof atlas from two PixelLab roof tile sheets.")
    parser.add_argument("--recipe", type=Path, default=DEFAULT_RECIPE, help="Path to roof atlas recipe JSON.")
    args = parser.parse_args()
    recipe_path = args.recipe if args.recipe.is_absolute() else ROOT / args.recipe
    build(recipe_path)


if __name__ == "__main__":
    main()
