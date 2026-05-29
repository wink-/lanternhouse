from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CATALOG = ROOT / "assets" / "world" / "town_asset_catalog.json"


def load_catalog(path: Path = DEFAULT_CATALOG) -> dict[str, Any]:
    catalog_path = path if path.is_absolute() else ROOT / path
    return json.loads(catalog_path.read_text(encoding="utf-8"))


def point(value: object, fallback: list[int] | None = None) -> list[int]:
    if isinstance(value, list) and len(value) == 2:
        return [int(value[0]), int(value[1])]
    if fallback is not None:
        return fallback
    raise ValueError(f"Expected two-item point, got {value!r}")


def rect(value: object, fallback: list[int] | None = None) -> list[int]:
    if isinstance(value, list) and len(value) == 4:
        return [int(value[0]), int(value[1]), int(value[2]), int(value[3])]
    if fallback is not None:
        return fallback
    raise ValueError(f"Expected four-item rect, got {value!r}")


def building_specs(catalog: dict[str, Any]) -> dict[str, dict[str, Any]]:
    specs = catalog.get("buildings", {})
    if not isinstance(specs, dict):
        raise ValueError("town asset catalog buildings must be an object")
    return specs


def prop_specs(catalog: dict[str, Any]) -> dict[str, dict[str, Any]]:
    specs = catalog.get("props", {})
    if not isinstance(specs, dict):
        raise ValueError("town asset catalog props must be an object")
    return specs


def styles_for(spec: dict[str, Any]) -> set[str]:
    styles = spec.get("styles", [])
    if not isinstance(styles, list):
        return set()
    return {str(style) for style in styles}


def supports_style(spec: dict[str, Any], style: str) -> bool:
    styles = styles_for(spec)
    return not styles or style in styles


def prop_entry(prop_id: str, spec: dict[str, Any], grid: list[int], **overrides: Any) -> dict[str, Any]:
    entry: dict[str, Any] = {
        "id": prop_id,
        "grid": grid,
        "offset": point(spec.get("offset", [8, 8])),
        "scale": float(spec.get("scale", 0.6)),
    }
    entry.update(overrides)
    return entry


def building_entry(building_id: str, spec: dict[str, Any], grid: list[int]) -> dict[str, Any]:
    entry: dict[str, Any] = {
        "id": building_id,
        "grid": grid,
        "size": point(spec.get("size")),
        "plaque": str(spec.get("plaque", "plaque_blank")),
        "fallback_region": rect(spec.get("fallback_region", [14, 16, 118, 72])),
        "fallback_scale": float(spec.get("fallback_scale", 0.55)),
    }
    if bool(spec.get("public", False)):
        entry["public"] = True
    return entry


def building_interaction(spec: dict[str, Any]) -> dict[str, Any]:
    return {
        "npc": str(spec.get("npc", "")),
        "name": str(spec.get("display_name", spec.get("name", "Building"))),
        "door_offset": point(spec.get("door_offset", [0, 0])),
        "door_width": int(spec.get("door_width", 1)),
    }
