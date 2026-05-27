# PixelLab Art Inventory

This document tracks PixelLab-created art for Lanternhouse. Update it whenever a PixelLab asset is created, downloaded, integrated, replaced, or retired.

Style target: cute but grounded top-down 2D RPG pixel art, clean dark outline, readable at small size, medium detail, and basic shading. The existing PixelLab cat remains the quality/style reference.

## Status Key

| Status | Meaning |
|---|---|
| Created | PixelLab generation exists, not yet downloaded |
| Downloaded | Source output is in `assets/sprites/` |
| Integrated | Game scripts/scenes load the asset |
| Retired | No longer used, kept only for provenance |

## Characters

| Asset | PixelLab ID | Status | Source Output | Runtime Path | Size | Directions | Usage | Notes |
|---|---|---|---|---|---|---|---|---|
| Lanternhouse Player Adventurer | `77ee0770-b5a5-4eb5-a903-13fd7f0eca57` | Integrated | `assets/sprites/characters/player/pixellab_source.zip` | `assets/sprites/characters/player/rotations/*.png` | 56x56 | 8 | `scripts/overworld.gd`, `scripts/town.gd` | Shared player rotations. Overworld displays at `0.58` scale. |
| Greta Ironforge Weapon Merchant | `4b17b7f2-06b2-4f9a-bc57-af84afb9d31a` | Integrated | `assets/sprites/characters/town_npcs/weapon_merchant/pixellab_source.zip` | `assets/sprites/characters/town_npcs/weapon_merchant/rotations/*.png` | 52x52 | 8 | `scripts/town.gd` | Replaces the weapon merchant atlas marker when present. |
| Old Thatch Elder | `ce3344ff-ab05-421e-8700-a1d7bde0f55c` | Integrated | `assets/sprites/characters/town_npcs/elder/pixellab_source.zip` | `assets/sprites/characters/town_npcs/elder/rotations/*.png` | 48x48 | 8 | `scripts/town.gd` | Replaces the elder atlas marker when present. |

## Style References

| Asset | PixelLab ID | Status | Runtime Path | Size | Directions/Animations | Usage | Notes |
|---|---|---|---|---|---|---|---|
| Orange tabby cat | `192115aa-b638-4770-8103-aace28f448df` | Integrated | `assets/sprites/characters/cat/` | 68x68 | 8 directions, walk frames | `scripts/town.gd` | Current quality/style target for new PixelLab work. |

## Overworld Coastline

| Asset | PixelLab ID | Status | Source Output | Runtime Path | Size | Usage | Notes |
|---|---|---|---|---|---|---|---|
| Ocean to beach Wang tileset | `e8857225-3de3-4a6c-94c7-15d26b65290f` | Integrated | `assets/sprites/tiles/pixellab/coastline/ocean_to_beach.png` | `assets/sprites/tiles/lanternhouse_overworld.png` | 32x32 tiles, 16 tiles | Overworld water and beach atlas slots | Source metadata: `assets/sprites/tiles/pixellab/coastline/ocean_to_beach.json`. |
| Beach to grass Wang tileset | `179c6f90-fb40-4ca2-b0e0-607ffd6521ef` | Integrated | `assets/sprites/tiles/pixellab/coastline/beach_to_grass.png` | `assets/sprites/tiles/lanternhouse_overworld.png` | 32x32 tiles, 16 tiles | Overworld grass atlas slot | Source metadata: `assets/sprites/tiles/pixellab/coastline/beach_to_grass.json`. |
| Coastal dock | `04140612-af3a-4a76-be65-c7d8d4f57c64` | Integrated | `assets/sprites/tiles/pixellab/coastline/coastal_dock.png` | `assets/sprites/tiles/lanternhouse_overworld.png` | 64x64 source | Overworld dock atlas slot | Downscaled into the 32x32 dock tile by `scripts/dev/build_coastline_atlas.gd`. |
| Coastal cave | `78502baa-e6bf-4522-8a5e-0ec0e72e8c0f` | Integrated | `assets/sprites/tiles/pixellab/coastline/coastal_cave.png` | `assets/sprites/tiles/lanternhouse_overworld.png` | 64x64 source | Overworld cave atlas slot | Downscaled into the 32x32 cave tile by `scripts/dev/build_coastline_atlas.gd`. |

## Creation Prompts

### Lanternhouse Player Adventurer

Lanternhouse player adventurer for a top-down 2D pixel RPG, cute but grounded, clean dark outline, readable at small size, medium detail, basic shading, warm brown travel cloak, small brass lantern at belt, leather boots, friendly determined silhouette, style consistent with a small orange tabby cat pixel art asset.

### Greta Ironforge Weapon Merchant

Lanternhouse town weapon merchant NPC, stout friendly blacksmith woman, red-brown apron, rolled sleeves, tiny hammer at belt, top-down 2D pixel RPG sprite, cute but grounded, clean dark outline, readable at 16 to 32 pixels, medium detail, basic shading, style consistent with a small orange tabby cat pixel art asset.

### Old Thatch Elder

Lanternhouse town elder NPC, small old villager with purple shawl and long grey eyebrows, carrying a candle or walking stick, top-down 2D pixel RPG sprite, cute but grounded, clean dark outline, readable at 16 to 32 pixels, medium detail, basic shading, style consistent with a small orange tabby cat pixel art asset.

### Ocean To Beach Wang Tileset

Deep blue ocean water with small white wave flecks to warm sandy coastline beach edge. Transition: white sea foam and wet golden sand shoreline.

### Beach To Grass Wang Tileset

Warm sandy beach to bright green island grass. Transition: uneven natural grass edge over sand with tiny stones.

### Coastal Dock

Top-down pixel art coastal dock, short wooden pier over blue water, clean dark outline, medium detail, basic shading, transparent background.

### Coastal Cave

Top-down pixel art rocky coastal cave entrance in tan cliff, dark opening with small white surf foam at base, clean dark outline, medium detail, transparent background.

## Integration Notes

- Keep downloaded PixelLab zips and `metadata.json` files next to the normalized runtime files.
- Normalize runtime rotations to `rotations/<direction>.png` under each asset folder.
- Prefer script fallbacks so missing art does not block gameplay.
- Run Godot headless checks after each integration.
- Rebuild the overworld coastline atlas with `godot_console.exe --headless --path . --script res://scripts/dev/build_coastline_atlas.gd`.
