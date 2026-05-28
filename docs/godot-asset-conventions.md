# Lanternhouse — Godot Asset Conventions

## File Organization

```
assets/
  sprites/
    characters/
      cat/
        rotations/             # PixelLab directional stills
        walk/<direction>/       # PixelLab animation frames
    overworld/
      player.png              # 64×64 sheet (4 dir × 4 frames)
      npc_<role>.png          # 64×64 sheet per NPC
      monster_<name>.png      # 64×64 sheet per encounter icon
    battle/
      enemies/
        <name>.png            # 96×48 sheet (idle + hit flash)
      party/
        <class>.png           # 64×48 sheet (2 idle frames)
    town/
      buildings/              # 3/4 town building kit
      ground/                 # 3/4 town ground/path tiles
      props/                  # transparent 3/4 town props
    tiles/
      <tile_type>.png         # 16×16 (or 16×N for animated)
    ui/
      cursor.png              # 16×16 menu cursor
      frame_border.png        # 8×8 corner/edge tiles for dialog frames
      icons/                  # item/spell icons, 16×16 each
```

## Import Settings (project.godot defaults)

All textures should use nearest-neighbor filtering. The following
`[import_defaults]` section in project.godot enforces this globally.

**Per-texture override** (if needed via `.import` file):
- Filter: Nearest
- Mipmaps: Disabled
- Repeat: Disabled
- sRGB: Enabled

## Naming Conventions

### General Rules

- Lowercase, snake_case for all file names.
- No spaces or special characters.
- Sprite names match the keys used in `SpriteCache` calls.
- Scene files: `snake_case.tscn`. Script files: `snake_case.gd`.
- PixelLab output may stay as directional frame folders when that is clearer
  than forcing it into an older sprite-sheet shape.

### Entity Naming

| Entity type | File pattern | Example |
|---|---|---|
| PixelLab character | `characters/<name>/rotations/<direction>.png` | `characters/cat/rotations/south.png` |
| PixelLab walk frames | `characters/<name>/walk/<direction>/<frame>.png` | `characters/cat/walk/east/0.png` |
| Player sprite | `overworld/player.png` | — |
| Party class | `battle/party/<class>.png` | `fighter.png`, `redmage.png` |
| Enemy | `battle/enemies/<name>.png` | `slime.png`, `drake.png` |
| NPC | `overworld/npc_<role>.png` | `npc_merchant.png` |
| Town building | `town/buildings/<name>.png` | `weapon_shop.png` |
| Town ground tile | `town/ground/<name>.png` | `cobblestone_plaza.png` |
| Town prop | `town/props/<name>.png` | `lantern_post.png` |
| Terrain tile | `tiles/<type>.png` | `water.png`, `forest.png` |
| Animated tile | `tiles/<type>.png` (vertical strip) | `water.png` (16×64) |
| UI element | `ui/<element>.png` | `cursor.png` |
| Spell icon | `ui/icons/spell_<name>.png` | `spell_fire.png` |

### Frame Naming (within sheets)

Frames are addressed by column/row index, not named regions. In code:
```
# Overworld walk: row = facing (0=down, 1=up, 2=left, 3=right), col = step frame
# Battle idle: col 0 = frame 1, col 1 = frame 2
```

If `SpriteFrames` resources are used later, name them:
```
idle_down, idle_up, idle_left, idle_right
walk_down, walk_up, walk_left, walk_right
```

## Adding New Sprites

1. Place the PNG in the correct `assets/sprites/` subdirectory.
2. Prefer `SpriteCache` lookups over direct `load()` or `Image.load()` calls.
   Use named keys such as `town.building.inn`, `town.prop.lantern_post`,
   `battle.enemy.slime`, `battle.party.fighter`, or
   `character.cat.rotation.south`.
3. For new tile types, add the color entry to `COLORS` and any block/encounter
   logic in the relevant scene script, then drop the matching PNG.

## Asset Registry

`scripts/sprite_cache.gd` is the lightweight asset registry and texture cache.
It maps logical names to files under `assets/sprites/` so scene code asks for
game concepts instead of hardcoding paths everywhere.

Common lookup patterns:

| Asset type | Registry key | File path |
|---|---|---|
| Town building | `town.building.<id>` | `town/buildings/<id>.png` |
| Town awning | `town.awning.<id>` | `town/shops/awnings/<id>.png` |
| Town sign | `town.sign.<id>` | `town/shops/signs/<id>.png` |
| Town prop | `town.prop.<id>` | `town/props/<id>.png` |
| Battle enemy | `battle.enemy.<id>` | `battle/enemies/<id>.png` |
| Battle party | `battle.party.<id>` | `battle/party/<id>.png` |
| Character rotation | `character.<id>.rotation.<direction>` | `characters/<id>/rotations/<direction>.png` |
| Character walk frame | `character.<id>.walk.<direction>.<frame>` | `characters/<id>/walk/<direction>/<frame>.png` |

For nested character folders, the `<id>` may include a subfolder, such as
`town_npcs/elder`. Add fixed one-off atlases to `ASSET_PATHS` in
`sprite_cache.gd`.

## Adding PixelLab Art

PixelLab is the preferred source for new production pixel art. Use the cat in
`assets/sprites/characters/cat/` as the current benchmark for rendering quality,
outline clarity, palette discipline, and readability. For player and town NPC
batches, default to humans unless a specific fantasy ancestry is requested.

1. Retrieve or generate the asset with the PixelLab MCP.
2. Save original PNG output under `assets/sprites/characters/<name>/`,
   `assets/sprites/battle/`, `assets/sprites/tiles/`, or another clear category.
3. Preserve useful directional folders such as `rotations/` and `walk/`.
4. Wire the art into a scene or script immediately.
5. Keep a lightweight fallback if the scene already has one.
6. Run `godot --headless --path . --quit` and, when possible, launch the specific
   scene headlessly for a short check.

When dimensions do not match the older conventions, prefer a small adapter in
code over destructive resizing. For example, the cat's source frames are 68×68,
but `town.gd` displays them at a smaller scale on the 16×16 town grid.

## Adding Town Environment Art

Town, dungeon, and interior art should use the top-down 3/4 JRPG perspective in
`docs/pixel-art-direction.md`. For Brindlewick and future towns, save coherent
environment kit output under:

- `assets/sprites/town/buildings/`
- `assets/sprites/town/ground/`
- `assets/sprites/town/props/`

Keep a lightweight manifest for generated town-kit batches with:

- asset name
- intended grid footprint in 16x16 tiles
- suggested entrance tile offset
- intended scale
- placement notes for town use

Building sprites must include visible roof/facade depth and a clear doorway at
the base/front facade. Doors should align to walkable 16x16 entrance thresholds.
Props should hug building fronts, roads, walls, or plazas rather than appearing
as scattered decoration.

### World-Building Tools

Runtime town-building tiles are assembled from a recipe instead of manually
cropping a finished atlas. The current recipe lives at:

`assets/sprites/town/buildings/modular_building_atlas.recipe.json`

Use this workflow when promoting PixelLab outputs into the playable town kit:

1. Save original PixelLab outputs under `assets/sprites/town/`.
2. Add or adjust recipe entries for the chosen source sheet, cell/crop, and tile
   id.
3. Run `python scripts/dev/build_world_art.py`.
4. Keep the generated atlas, sidecar JSON, Markdown manifest, and recipe in the
   same commit.
5. Run the relevant Godot smoke scene after wiring the art into gameplay.

Town layouts are also data-driven. Brindlewick currently lives at:

`assets/world/towns/brindlewick.layout.json`

That file defines the town map rows, building placements, door targets, shop
signs, awnings, props, and cat home/wander radius. `scripts/town.gd` loads it at
startup and falls back to the older constants if the file is missing or invalid.
Run `python scripts/dev/build_world_art.py` after edits; it validates the
runtime art atlas and every `assets/world/towns/*.layout.json`, then renders
matching `*.preview.png` files for quick placement review.

To create a new starter town layout:

```powershell
python scripts/dev/create_town_layout.py mournlight_harbor --name "Mournlight Harbor"
```

Use the generated layout as a scaffold, then add buildings, doors, props, and
art kit references as the town becomes real.

To stamp in one building and keep its door/interact data aligned:

```powershell
python scripts/dev/add_town_building.py smithy --name "Smithy" --npc weapon_merchant --x 10 --y 8 --width 6 --height 4 --plaque plaque_sword --door-width 3 --sign --awning
```

Use `--replace` when intentionally moving an existing building. The command
updates the footprint, interaction target, door tiles, and optional shop
sign/awning, then runs the world-art pipeline unless `--skip-build` is passed.

## Adding New Enemy Types

1. Add template to `scripts/data/enemies.gd` → `template()`.
2. Add color to `battle.gd` → `ENEMY_COLORS` (fallback for before art exists).
3. Add formation entries to the appropriate zone formation function.
4. Place sprite at `assets/sprites/battle/enemies/<name>.png`.

## Adding New Tile Types

1. Add tile symbol to the `MAP` array in `overworld.gd` or `town.gd`.
2. Add entry to `COLORS` dictionary.
3. Add to `BLOCKED`, `ENCOUNTER`, or other constraint dicts as needed.
4. Place sprite at `assets/sprites/tiles/<name>.png`.

## Godot Scene Structure

Current node hierarchy (for reference when adding art nodes):

```
Overworld (Node2D)         Town (Node2D)            Battle (Node2D)
  MapLayer (Node2D)          MapLayer (Node2D)        Background (ColorRect)
  PlayerSprite (Node2D)      PlayerSprite (Node2D)    EnemyArea (Node2D)
    Body (Polygon2D)           Body (Polygon2D)       PartyArea (Node2D)
    Face (ColorRect)          Dialog (RichTextLabel)   Panel (Panel)
  HUD (RichTextLabel)                                   TextDisplay (RichTextLabel)
```

When replacing colored blocks with sprites, add `Sprite2D` children under
the same parent nodes. The existing `Polygon2D` and `ColorRect` nodes can
be removed once sprite art is in place.

## Texture Import Checklist

For each PNG added to the project:

- [ ] Confirm Nearest filtering (not Linear) in the Import dock
- [ ] Confirm "Repeat" is Disabled
- [ ] Confirm Mipmaps are Off
- [ ] Transparent background (alpha channel)
- [ ] Pixel-perfect edges — no anti-aliased outlines
- [ ] Fits the grid: 16×16 for tiles/overworld, 48×48 for enemies, 32×48 for party
- [ ] Uses colors from the Lanternhouse palette (see pixel-art-direction.md)
- [ ] If generated by PixelLab, compare it against the cat benchmark in-game
