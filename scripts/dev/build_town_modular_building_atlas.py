#!/usr/bin/env python3
from __future__ import annotations

import binascii
import json
import struct
import sys
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BUILDINGS_DIR = ROOT / "assets" / "sprites" / "town" / "buildings"
OUTPUT = BUILDINGS_DIR / "modular_building_atlas_v2.png"
SIDECAR = OUTPUT.with_suffix(".json")
TILE_SIZE = 16
ATLAS_WIDTH = 128
ATLAS_HEIGHT = 96
CANDIDATE_SHEET_WIDTH = 64
CANDIDATE_SHEET_HEIGHT = 64

PIXELLAB_SOURCES = {
    "structure": {
        "job_id": "144b6eec-4c16-41d0-b3ad-d5c8903eb34a",
        "dir": BUILDINGS_DIR / "pixellab_candidates" / "modular_tileset_144b6eec",
    },
    "details": {
        "job_id": "e0e17ab4-d78f-4234-9e5c-3fd9ef6e746d",
        "dir": BUILDINGS_DIR / "pixellab_candidates" / "modular_tileset_e0e17ab4",
    },
    "forge": {
        "job_id": "edf0c894-c136-48b9-af70-6d16b5c7f886",
        "dir": BUILDINGS_DIR / "pixellab_candidates" / "modular_tileset_edf0c894",
    },
}

CANDIDATE_SHEETS = [
    {
        "asset_name": "PixelLab Modular Roof Components",
        "job_id": "c5b96b12-d4cd-46ed-a95b-cdd8cb97e5a8",
        "seed": 6202030,
        "source_dir": BUILDINGS_DIR / "pixellab_candidates" / "modular_tileset_c5b96b12",
        "output": BUILDINGS_DIR / "modular_roof_components_c5b96b12.png",
        "status": "candidate_reviewed",
        "notes": "Useful roof textures and trim candidates, but several tiles drift into miniature facade chunks. Keep as candidate source and select manually.",
        "tile_labels": [
            "roof_center",
            "roof_left_edge",
            "roof_right_edge",
            "roof_ridge",
            "ridge_left_cap",
            "ridge_right_cap",
            "eave_underside",
            "left_eave_corner",
            "right_eave_corner",
            "gable_peak",
            "gable_timber_trim",
            "roof_dormer",
            "chimney",
            "moss_patch",
            "roof_chip_decal",
            "roof_shadow_strip",
        ],
    },
    {
        "asset_name": "PixelLab Roof Texture Swatches",
        "job_id": "3eb16325-6122-4b26-b807-d8d6ef000106",
        "seed": 6202034,
        "source_dir": BUILDINGS_DIR / "pixellab_candidates" / "modular_tileset_3eb16325",
        "output": BUILDINGS_DIR / "modular_roof_texture_swatches_3eb16325.png",
        "status": "candidate_reviewed",
        "notes": "Preferred roof material sheet from this pass. The filled-swatch prompt avoided facade drift and produced reusable red clay shingle variants.",
        "tile_labels": [
            "roof_plain",
            "roof_alternate_pattern",
            "roof_darker_rows",
            "roof_sun_worn_rows",
            "roof_tiny_chips",
            "roof_sparse_moss",
            "roof_diagonal_age",
            "roof_dense_small_tiles",
            "roof_large_tile_rows",
            "roof_old_uneven_rows",
            "roof_warm_highlights",
            "roof_cool_shadows",
            "roof_cracked_tiles",
            "roof_soot_specks",
            "roof_moss_seam",
            "roof_clean_base",
        ],
    },
    {
        "asset_name": "PixelLab Modular Wall Foundation Components",
        "job_id": "3a488c08-1b4e-4d15-8511-62ab9e80de28",
        "seed": 6202031,
        "source_dir": BUILDINGS_DIR / "pixellab_candidates" / "modular_tileset_3a488c08",
        "output": BUILDINGS_DIR / "modular_wall_foundation_components_3a488c08.png",
        "status": "candidate_reviewed",
        "notes": "Strongest sheet of this pass. Plaster, timber, braces, foundation, shadow, threshold, and stoop modules are clean enough for atlas refinement.",
        "tile_labels": [
            "plaster_plain",
            "plaster_weathered",
            "plaster_left_post",
            "plaster_right_post",
            "vertical_timber_post",
            "horizontal_timber_beam",
            "diagonal_brace_rising",
            "diagonal_brace_falling",
            "eave_shadow",
            "stone_foundation_center",
            "stone_foundation_left",
            "stone_foundation_right",
            "stone_foundation_moss",
            "contact_shadow_base",
            "stone_threshold",
            "two_step_stoop",
        ],
    },
    {
        "asset_name": "PixelLab Modular Shop Detail Components",
        "job_id": "6dba82d7-aebe-4456-9805-bfd62c6a9d9e",
        "seed": 6202032,
        "source_dir": BUILDINGS_DIR / "pixellab_candidates" / "modular_tileset_6dba82d7",
        "output": BUILDINGS_DIR / "modular_shop_detail_components_6dba82d7.png",
        "status": "candidate_reviewed",
        "notes": "Good plaque, awning, lantern, flower-box, and exterior-detail candidates. A few bottom-row outputs are larger dressing chunks and should be used selectively.",
        "tile_labels": [
            "blank_hanging_plaque",
            "crossed_swords_plaque",
            "shield_plaque",
            "forge_icon_plaque",
            "tankard_plaque",
            "bed_plaque",
            "healer_candle_plaque",
            "elder_scroll_plaque",
            "wall_lantern",
            "unlit_wall_lantern",
            "awning_left",
            "awning_middle",
            "awning_right",
            "flower_box",
            "barrel_or_crate",
            "moss_crack_soot_decal",
        ],
    },
]

TILE_MAP = {
    "roof_left": ("structure", 0, 0, 0),
    "roof_mid": ("structure", 1, 1, 0),
    "roof_right": ("structure", 2, 2, 0),
    "roof_ridge": ("structure", 3, 3, 0),
    "roof_eave": ("structure", 4, 4, 0),
    "roof_moss": ("structure", 5, 5, 0),
    "chimney": ("structure", 7, 6, 0),
    "blank": (None, -1, 7, 0),
    "wall": ("structure", 8, 0, 1),
    "wall_timber": ("structure", 9, 1, 1),
    "wall_brace": ("structure", 10, 2, 1),
    "wall_shadow": ("structure", 11, 3, 1),
    "foundation": ("structure", 12, 4, 1),
    "foundation_moss": ("structure", 13, 5, 1),
    "foundation_shadow": ("structure", 14, 6, 1),
    "threshold": ("structure", 15, 7, 1),
    "door": ("details", 0, 0, 2),
    "door_open": ("details", 1, 1, 2),
    "window": ("details", 4, 2, 2),
    "window_arch": ("details", 5, 3, 2),
    "window_flower": ("details", 6, 4, 2),
    "plaque_blank": ("details", 8, 5, 2),
    "lantern": ("details", 15, 6, 2),
    "flower_box": ("details", 7, 7, 2),
    "plaque_sword": ("details", 9, 0, 3),
    "plaque_shield": ("details", 10, 1, 3),
    "plaque_tankard": ("details", 11, 2, 3),
    "plaque_gear": ("details", 12, 3, 3),
    "plaque_bed": ("details", 13, 4, 3),
    "plaque_candle": ("details", 14, 5, 3),
    "forge_roof_left": ("forge", 0, 0, 4),
    "forge_roof_mid": ("forge", 1, 1, 4),
    "forge_roof_right": ("forge", 2, 2, 4),
    "forge_roof_eave": ("forge", 3, 3, 4),
    "forge_chimney": ("forge", 4, 4, 4),
    "forge_wall": ("forge", 5, 5, 4),
    "forge_wall_timber": ("forge", 6, 6, 4),
    "forge_foundation": ("forge", 7, 7, 4),
    "forge_door": ("forge", 8, 0, 5),
    "forge_window": ("forge", 10, 1, 5),
    "forge_weapon_rack": ("forge", 11, 2, 5),
    "forge_anvil_plaque": ("forge", 12, 3, 5),
    "forge_door_right": ("forge", 9, 4, 5),
}


def png_chunks(data: bytes):
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("not a PNG")
    pos = 8
    while pos < len(data):
        length = struct.unpack(">I", data[pos:pos + 4])[0]
        kind = data[pos + 4:pos + 8]
        payload = data[pos + 8:pos + 8 + length]
        yield kind, payload
        pos += 12 + length


def unfilter_scanline(filter_type: int, line: bytearray, prev: bytes, bpp: int) -> bytearray:
    out = bytearray(line)
    for i in range(len(out)):
        left = out[i - bpp] if i >= bpp else 0
        up = prev[i] if prev else 0
        up_left = prev[i - bpp] if prev and i >= bpp else 0
        if filter_type == 1:
            out[i] = (out[i] + left) & 0xFF
        elif filter_type == 2:
            out[i] = (out[i] + up) & 0xFF
        elif filter_type == 3:
            out[i] = (out[i] + ((left + up) // 2)) & 0xFF
        elif filter_type == 4:
            p = left + up - up_left
            pa = abs(p - left)
            pb = abs(p - up)
            pc = abs(p - up_left)
            predictor = left if pa <= pb and pa <= pc else up if pb <= pc else up_left
            out[i] = (out[i] + predictor) & 0xFF
        elif filter_type != 0:
            raise ValueError(f"unsupported PNG filter {filter_type}")
    return out


def read_png_rgba(path: Path) -> tuple[int, int, bytearray]:
    width = height = color_type = bit_depth = None
    compressed = bytearray()
    for kind, payload in png_chunks(path.read_bytes()):
        if kind == b"IHDR":
            width, height, bit_depth, color_type, _, _, interlace = struct.unpack(">IIBBBBB", payload)
            if interlace != 0:
                raise ValueError(f"{path} uses interlacing")
        elif kind == b"IDAT":
            compressed.extend(payload)
    if width is None or height is None or color_type is None or bit_depth != 8:
        raise ValueError(f"{path} is not an 8-bit PNG")
    channels = {2: 3, 6: 4}.get(color_type)
    if channels is None:
        raise ValueError(f"{path} uses unsupported PNG color type {color_type}")

    raw = zlib.decompress(bytes(compressed))
    stride = width * channels
    pixels = bytearray(width * height * 4)
    prev = bytes(stride)
    pos = 0
    out_pos = 0
    for _ in range(height):
        filter_type = raw[pos]
        pos += 1
        line = unfilter_scanline(filter_type, bytearray(raw[pos:pos + stride]), prev, channels)
        pos += stride
        prev = bytes(line)
        for x in range(width):
            src = x * channels
            pixels[out_pos:out_pos + 3] = line[src:src + 3]
            pixels[out_pos + 3] = line[src + 3] if channels == 4 else 255
            out_pos += 4
    return width, height, pixels


def write_png_rgba(path: Path, width: int, height: int, pixels: bytes) -> None:
    def chunk(kind: bytes, payload: bytes) -> bytes:
        return (
            struct.pack(">I", len(payload))
            + kind
            + payload
            + struct.pack(">I", binascii.crc32(kind + payload) & 0xFFFFFFFF)
        )

    raw = bytearray()
    stride = width * 4
    for y in range(height):
        raw.append(0)
        raw.extend(pixels[y * stride:(y + 1) * stride])
    path.write_bytes(
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(bytes(raw), 9))
        + chunk(b"IEND", b"")
    )


def blit(dst: bytearray, dst_width: int, src: bytearray, src_width: int, src_height: int, x: int, y: int) -> None:
    for row in range(src_height):
        dst_start = ((y + row) * dst_width + x) * 4
        src_start = row * src_width * 4
        dst[dst_start:dst_start + src_width * 4] = src[src_start:src_start + src_width * 4]


def build_atlas() -> bytearray:
    atlas = bytearray((0, 0, 0, 0) * ATLAS_WIDTH * ATLAS_HEIGHT)
    for tile_id, (source_key, source_tile, col, row) in TILE_MAP.items():
        if source_key is None:
            continue
        source_dir = PIXELLAB_SOURCES[source_key]["dir"]
        path = source_dir / f"tile_{source_tile}.png"
        if not path.exists():
            raise FileNotFoundError(f"Missing PixelLab source tile for {tile_id}: {path.relative_to(ROOT)}")
        width, height, pixels = read_png_rgba(path)
        if width != TILE_SIZE or height != TILE_SIZE:
            raise ValueError(f"{path.relative_to(ROOT)} is {width}x{height}, expected {TILE_SIZE}x{TILE_SIZE}")
        blit(atlas, ATLAS_WIDTH, pixels, width, height, col * TILE_SIZE, row * TILE_SIZE)
    return atlas


def build_candidate_sheet(config: dict) -> bytearray:
    sheet = bytearray((0, 0, 0, 0) * CANDIDATE_SHEET_WIDTH * CANDIDATE_SHEET_HEIGHT)
    source_dir = config["source_dir"]
    for tile_index in range(16):
        path = source_dir / f"tile_{tile_index}.png"
        if not path.exists():
            raise FileNotFoundError(f"Missing PixelLab source tile: {path.relative_to(ROOT)}")
        width, height, pixels = read_png_rgba(path)
        if width != TILE_SIZE or height != TILE_SIZE:
            raise ValueError(f"{path.relative_to(ROOT)} is {width}x{height}, expected {TILE_SIZE}x{TILE_SIZE}")
        col = tile_index % 4
        row = tile_index // 4
        blit(sheet, CANDIDATE_SHEET_WIDTH, pixels, width, height, col * TILE_SIZE, row * TILE_SIZE)
    return sheet


def write_candidate_sidecar(config: dict) -> None:
    output = config["output"]
    tiles = []
    for tile_index, tile_id in enumerate(config["tile_labels"]):
        col = tile_index % 4
        row = tile_index // 4
        tiles.append(
            {
                "tile": tile_id,
                "rect": [col * TILE_SIZE, row * TILE_SIZE, TILE_SIZE, TILE_SIZE],
                "source": f"{config['job_id']} tile_{tile_index}",
            }
        )
    payload = {
        "asset_name": config["asset_name"],
        "runtime_path": str(output.relative_to(ROOT)).replace("\\", "/"),
        "prompt_log": "assets/sprites/town/buildings/pixellab_candidates/PROMPTS.md",
        "tile_size": TILE_SIZE,
        "sheet_size": [4, 4],
        "status": config["status"],
        "notes": config["notes"],
        "pixellab_job": config["job_id"],
        "seed": config["seed"],
        "source_dir": str(config["source_dir"].relative_to(ROOT)).replace("\\", "/"),
        "tiles": tiles,
    }
    output.with_suffix(".json").write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def write_sidecar() -> None:
    tiles = []
    for tile_id, (source_key, source_tile, col, row) in TILE_MAP.items():
        source = "transparent"
        if source_key is not None:
            source = f"{PIXELLAB_SOURCES[source_key]['job_id']} tile_{source_tile}"
        tiles.append(
            {
                "tile": tile_id,
                "rect": [col * TILE_SIZE, row * TILE_SIZE, TILE_SIZE, TILE_SIZE],
                "source": source,
            }
        )
    payload = {
        "asset_name": "PixelLab Modular Building Atlas",
        "runtime_path": "assets/sprites/town/buildings/modular_building_atlas_v2.png",
        "prompt_log": "assets/sprites/town/buildings/pixellab_candidates/PROMPTS.md",
        "tile_size": TILE_SIZE,
        "status": "candidate_integrated",
        "notes": "Runtime atlas composed only from PixelLab-generated reusable 16x16 modules. No single-building sprites or assembled facade sprites.",
        "pixellab_jobs": [source["job_id"] for source in PIXELLAB_SOURCES.values()],
        "tiles": tiles,
    }
    SIDECAR.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def main() -> int:
    pixels = build_atlas()
    write_png_rgba(OUTPUT, ATLAS_WIDTH, ATLAS_HEIGHT, bytes(pixels))
    write_sidecar()
    print(f"Wrote {OUTPUT.relative_to(ROOT)} ({ATLAS_WIDTH}x{ATLAS_HEIGHT})")
    print(f"Wrote {SIDECAR.relative_to(ROOT)}")
    for config in CANDIDATE_SHEETS:
        sheet = build_candidate_sheet(config)
        output = config["output"]
        write_png_rgba(output, CANDIDATE_SHEET_WIDTH, CANDIDATE_SHEET_HEIGHT, bytes(sheet))
        write_candidate_sidecar(config)
        print(f"Wrote {output.relative_to(ROOT)} ({CANDIDATE_SHEET_WIDTH}x{CANDIDATE_SHEET_HEIGHT})")
        print(f"Wrote {output.with_suffix('.json').relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
