# Lanternhouse Pixel-Art Direction

## Overview

Lanternhouse is a retro JRPG with a warm, candlelit aesthetic. The art direction
channels the spirit of 8-bit console RPGs — small sprites, limited palettes,
cardinal-direction movement — while establishing its own identity through a
lantern/firelight motif and slightly warmer tones than the cold NES palette.

Everything is designed to slot directly into the existing Godot 4 codebase
which renders at **960×640** with **16×16** tiles.

## Current Art Pipeline

Lanternhouse now uses **PixelLab-generated pixel art as the primary production
art source**. The first successful benchmark is the town cat:

`res://assets/sprites/characters/cat/`

The cat sets the current quality target:

- Top-down 2D RPG readability
- Clean single-color dark outline
- Medium detail with basic shading
- Cute but grounded character design
- Transparent PNG output
- Strong silhouette at the game's zoom level

When generating new art, treat the cat as the style anchor. New player, NPC,
enemy, prop, and object sprites should feel like they belong in the same world,
even if their source dimensions differ from the older handmade placeholder
assets.

### Generation Workflow

1. Use the PixelLab MCP to create or retrieve an asset.
2. Download the source output into `assets/sprites/` under a clear category.
3. Keep original PixelLab frames when useful instead of immediately flattening
   everything into legacy sheets.
4. Integrate the asset into the actual scene or script.
5. Keep the old polygon/color fallback when it is cheap and helps the game boot
   if an asset is missing.
6. Run a Godot headless check after integration.

This project is intentionally moving from playable placeholders toward final art
incrementally. A sprite is not considered "in the game" just because it exists on
disk; it should be wired into the relevant scene, visible at runtime, and covered
by at least a basic launch check.

---

## Core Constants

| Property | Value | Notes |
|---|---|---|
| Tile size | 16 × 16 px | matches `TILE_SIZE` constant in code |
| Overworld sprite | 16 × 16 px | player, NPCs, and map icons |
| Battle sprite (enemy) | 48 × 48 px | drawn at scale in battle scene |
| Battle sprite (party) | 32 × 48 px | side-view front-facing |
| UI element size | multiples of 8 | buttons, icons, cursors |
| Canvas resolution | 960 × 640 | set in project.godot |
| Stretch mode | canvas_items / keep | integer scaling at 2×/3×/4× |

All sprite sheets should use **1:1 pixel ratio** (no sub-pixel rendering).
Set `texture_filter = Nearest` on all imported textures.

---

## Palette Philosophy

Work from a fixed 32-color master palette to maintain cohesion. The palette is
organized into five groups:

| Group | Colors | Usage |
|---|---|---|
| Lanternfire | 4 warm yellows/oranges | UI highlights, light effects, lantern glow |
| Stone & Earth | 6 browns / grays | buildings, paths, cave walls, dungeon floors |
| Nature | 8 greens / blues | grass, trees, water, mountains |
| Character | 6 skin / hair tones | party, NPCs, portraits |
| Shadow & Night | 8 dark purples / blues | outlines, deep water, night overlays, caves |

**Style rules:**
- Maximum 4 unique colors per 16×16 tile (excluding alpha).
- Outlines are 1px, darkest color in the relevant group.
- Dithering: use 50% checkerboard pattern only for gradients (sky, water).
- Avoid pure black (#000000) for fills; use the darkest shadow color instead.
- Warm light bounce: edge pixels facing a lantern get a single-pixel highlight
  from the Lanternfire group.

### Reference Palette (hex)

```
Lanternfire:  #FFF4B8  #FFD54F  #FF9800  #E65100
Stone/Earth:  #D7CCC8  #A1887F  #795548  #5D4037  #4E342E  #3E2723
Nature:       #C8E6C9  #81C784  #4CAF50  #2E7D32  #1B5E20  #64B5F6  #1976D2  #0D47A1
Character:    #FFCCBC  #FFAB91  #8D6E63  #5D4037  #3E2723  #FDD835
Shadow/Night: #263238  #1A237E  #311B92  #4A148C  #1B1B2F  #2C2C54  #3D3D5C  #0A0A14
```

---

## Sprite Sheet Layout

### Overworld Characters (16×16 per frame)

Layout: **4 columns × 4 rows** — one row per cardinal direction.

```
Frame grid (each cell = 16×16):
     col0   col1   col2   col3
row0  ↓S1    ↓S2    ↓S3    ↓S4     ← facing DOWN
row1  ↑S1    ↑S2    ↑S3    ↑S4     ← facing UP
row2  ←S1   ←S2   ←S3   ←S4    ← facing LEFT
row3  →S1   →S2   →S3   →S4    ← facing RIGHT
```

- S1–S2 = walk cycle (alternating legs)
- S3 = idle / standing
- S4 = interact / action pose (optional, can duplicate S3)

**File format:** PNG with transparency. Sheet size: 64×64 px.

**Naming convention:**
```
assets/sprites/overworld/player.png
assets/sprites/overworld/npc_<role>.png        # npc_merchant.png, npc_elder.png
assets/sprites/overworld/monster_<name>.png     # overworld encounter icon
```

### Battle Sprites

**Enemies — 48×48 per frame, single idle frame + optional hit flash row:**

```
col0    col1
idle    hit-flash   (each 48×48)
```

**File:** `assets/sprites/battle/enemies/<name>.png`
Examples: `slime.png`, `imp.png`, `wolf.png`, `ghoul.png`,
`skeleton.png`, `ogre.png`, `wraith.png`, `drake.png`, `golem.png`

**Party — 32×48 per frame, 2-frame idle:**

```
col0    col1
idle1   idle2
```

**File:** `assets/sprites/battle/party/<class_lowercase>.png`
Examples: `fighter.png`, `thief.png`, `blackbelt.png`, `redmage.png`

### Tile Sheets

Each tile is a standalone 16×16 PNG (matching current `SpriteCache` paths):

```
assets/sprites/tiles/water.png
assets/sprites/tiles/grass.png
assets/sprites/tiles/forest.png
assets/sprites/tiles/mountain.png
assets/sprites/tiles/town.png
assets/sprites/tiles/path.png
assets/sprites/tiles/cave.png
assets/sprites/tiles/bridge.png
```

For animated tiles (water shimmer, torch flicker), use vertical strips:
`water.png` → 4 frames stacked vertically (16×64 sheet).

---

## Scene-Specific Art Direction

### Overworld

The overworld map is 32×24 tiles. Current terrain types:

| Symbol | Tile | Art Direction |
|---|---|---|
| `~` | Ocean | Deep blue with subtle wave pattern; 4-frame animation strip |
| `.` | Grassland | Warm green, small tuft detail at corners |
| `T` | Forest | Dense canopy tree top, dark trunk edges; blocked tile |
| `^` | Mountain | Rocky gray-brown peaks with snow cap highlight; blocked |
| `=` | Path | Packed dirt, slightly lighter than forest floor |
| `@` | Town | Small peaked-roof building icon, warm-lit windows |
| `C` | Cave | Dark maw in cliff face, torch glow at entrance |
| `B` | Bridge | Wooden planks over water, rope rail accent |
| `!` | Encounter | Pulsing red marker or small monster icon |

**Player overworld sprite:** lantern-carrying adventurer, visible lantern glow
in facing direction (1px warm highlight on tile ahead).

### Town

24×14 tile interior. Buildings, NPCs, and props use the same 16×16 grid.

| Current marker | Replacement concept |
|---|---|
| `#` walls | Stone interior walls with torch sconces |
| `.` floor | Wooden plank flooring |
| `W` weapon shop | Anvil + weapon rack backdrop |
| `A` armor shop | Shield + armor stand backdrop |
| `I` inn | Bed with quilt, window |
| `S` storage | Crate and barrel cluster |
| `E` elder | Bookshelf, desk, candle |
| `@` path/counter | Counter with items displayed |

**NPC sprites:** 16×16, facing down by default, warm-tinted robes/clothes.
Each NPC gets a distinct silhouette color from the Stone/Earth or Character palette.

### Battle

Dark background (#14141F to #0A0A14 gradient). Enemies left, party right.

- Enemies rendered at 3× scale (48px source → ~144px display).
- Party rendered at 2× scale (32px source → ~64px display).
- HP bars use Lanternfire colors (full = gold, low = orange, critical = deep red).
- Magic effects: simple 4-frame flash overlays in spell color
  (fire = orange, heal = green, lightning = white-blue).

### Lighthouse (Future Content)

The namesake Lanternhouse — a lighthouse dungeon with ascending floors.

- Interior tiles: spiral staircase, brass lantern fixtures, fogged glass.
- Exterior: beacon beam (animated 4-frame rotation), crashing waves at base.
- Color shift: cooler palette (Shadow/Night group) with Lanternfire accents.

---

## Animation Guidelines

| Animation | Frames | FPS | Notes |
|---|---|---|---|
| Walk cycle | 2 | 4 | Left-right leg alternation |
| Idle | 2 | 2 | Subtle breathing bounce (1px) |
| Attack slash | 3 | 8 | Weapon arc flash |
| Spell cast | 4 | 6 | Glow → release → fade |
| Water tile | 4 | 2 | Wave shimmer |
| Torch/fire | 4 | 4 | Randomized flicker |

All animation is handled via `AnimatedSprite2D` or code-driven frame cycling,
not sprite sheet rows in a TileMap (current code draws tiles procedurally).

---

## Replacement Mapping (Color Blocks → Pixel Art)

Every colored rectangle in the current codebase has a corresponding pixel-art
target. The `SpriteCache` autoload already checks for PNG files and falls back
to colored blocks, so art can be dropped in incrementally without code changes.

| Code location | Current | Art target |
|---|---|---|
| `overworld.gd:_draw_map` | `ColorRect` per tile | `SpriteCache.tile_sprite()` |
| `overworld.gd:_update_player_visual` | `Polygon2D` shape | `SpriteCache.player_sprite()` |
| `town.gd:_draw_map` | `ColorRect` per tile | Tile sprites + furniture layers |
| `town.gd` NPC markers | White `ColorRect` | NPC overworld sprites |
| `battle.gd:_draw_block` (enemy) | Colored `Polygon2D` | `SpriteCache.enemy_sprite()` |
| `battle.gd:_draw_block` (party) | Colored `Polygon2D` | `SpriteCache.party_sprite()` |
