# Town Generation Workflow

Lanternhouse towns are moving toward reusable data-driven kits: PixelLab makes
building and prop pieces, `assets/world/town_asset_catalog.json` describes how
those pieces can be used, and layout JSON files place them on tile maps.

## Files

| File | Purpose |
|---|---|
| `assets/world/town_asset_catalog.json` | Reusable building and prop metadata. |
| `assets/world/towns/*.layout.json` | Concrete town layouts generated or hand-edited from the catalog. |
| `scripts/dev/generate_town.py` | Deterministic procedural layout generator. |
| `scripts/dev/validate_town_layout.py` | Catalog and layout validator. |
| `scripts/dev/render_town_layout_preview.py` | Quick PNG layout preview renderer. |
| `scripts/dev/build_world_art.py` | Runs atlas build, validation, and town previews. |

## Ground And Path Terrain

Brindlewick currently uses a PixelLab Wang/autotile sheet for visible dirt paths
and grass-to-dirt transitions:

| File | Purpose |
|---|---|
| `assets/sprites/tiles/pixellab/brindlewick_grass_dirt_wang_tileset.png` | 64x64 source sheet containing 16 16x16 Wang tiles. |
| `assets/sprites/tiles/pixellab/brindlewick_grass_dirt_wang_tileset.metadata.json` | PixelLab corner metadata and source prompt. |
| `scripts/town.gd` | Computes the Wang mask from neighboring `=` and `+` path/plaza cells. |
| `scripts/sprite_cache.gd` | Registers the sheet as `town.grass_dirt_wang`. |

The runtime intentionally keeps the older textured grass for plain grass cells and
uses the PixelLab sheet only where a path or transition is needed. This avoids
turning the whole town into a flat fill while still exercising the autotile edge
workflow.

Current layout symbols relevant to this terrain pass:

| Symbol | Runtime role |
|---|---|
| `=` | Dirt path terrain. |
| `+` | Dirt/plaza terrain. |
| `.`, `,`, `H` | Grass/building-footprint cells that can receive grass-to-dirt transition edges. |

The first integrated sheet is functional but not final art polish. In screenshots,
the path is darker/purpler than ideal and some transition edges read like a stone
curb. Prefer a future retry with warmer brown dirt, muted olive grass, and a soft
muddy transition with no stone border.

## Adding A Building Asset

1. Generate or curate the PixelLab output under `assets/sprites/town/buildings/`.
2. Add an entry to `assets/world/town_asset_catalog.json` under `buildings`.
3. Set `runtime_ready` to `true` only when `sprite_path` points to a PNG that
   `scripts/town.gd` can load directly by building id.
4. Define the building footprint and doorway in 16x16 tiles:
   `size`, `door_offset`, and `door_width`.
5. Add allowed `styles`, such as `village`, `coastal`, or `fortress`.
6. Run `python scripts/dev/build_world_art.py`.

Catalog building entries should keep the runtime simple. If a PixelLab sheet is
only a reference or source sheet, keep `runtime_ready` false until it is split or
assembled into a directly loadable asset.

## Adding A Prop Asset

1. Generate or curate the PixelLab output under `assets/sprites/town/props/`.
2. Add an entry to `assets/world/town_asset_catalog.json` under `props`.
3. Set `offset` and `scale` defaults that look correct on a 16x16 grid.
4. Add `styles` and `placement_tags` so generators know where the prop belongs.
5. Set `runtime_ready` to `true` only for direct PNGs loadable by prop id.
6. Run `python scripts/dev/build_world_art.py`.

## Generating Towns

```bash
python scripts/dev/generate_town.py mournlight_harbor --name "Mournlight Harbor" --style coastal --seed 101 --skip-build
python scripts/dev/generate_town.py greywatch_keep --name "Greywatch Keep" --style fortress --seed 202 --skip-build
python scripts/dev/build_world_art.py
```

Use `--force` only when intentionally replacing an existing generated layout.
The generator is deterministic for a given style, size, and seed.

## Validation Rules

`validate_town_layout.py` checks both the asset catalog and every town layout:

- Catalog tile size is 16.
- Runtime-ready catalog sprite paths exist.
- Building sizes, door offsets, fallback regions, and NPC ids are valid.
- Layout buildings and props reference known catalog ids.
- Building and prop ids are allowed for the town's `style`.
- Doors are in bounds and have walkable approach tiles.
- Props do not sit on blocked tiles or inside building footprints.

## Current Generated Towns

| Layout | Style | Seed | Notes |
|---|---|---|---|
| `assets/world/towns/brindlewick.layout.json` | village | hand-curated | Main playable town. |
| `assets/world/towns/mournlight_harbor.layout.json` | coastal | 101 | Generated harbor proof-of-concept. |
| `assets/world/towns/greywatch_keep.layout.json` | fortress | 202 | Generated fortified-town proof-of-concept. |

These generated towns are validated content assets. They are not yet wired into
overworld scene transitions.
