# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Running the project

This is a **Godot 4.6** project. Open `project.godot` in the Godot editor to run. There is no CLI build step — Godot handles compilation of `.gd` scripts on launch. The HTML5 export is at `index.html` (for GitHub Pages).

There are no tests or linting configured. Validate changes by running in the editor.

## Architecture

**Main scene:** `scenes/overworld/overworld.tscn` (set in `project.godot`)

### Autoload singletons (persist across scene changes)

- **`GameData`** (`scripts/game_data.gd`) — All mutable state: party (4-character array of dictionaries), gold, tonics, equipment bags, equipped indices, overworld position/facing, world flags (beacon_lit, visited_town, boss_defeated). Has helpers for effective STR/DEF (base + weapon/armor bonuses), full heal, and alive checks.
- **`SpriteCache`** (`scripts/sprite_cache.gd`) — Loads PNG sprites from `assets/sprites/` on demand, cached in memory. Returns `null` for missing sprites, which triggers colored-block fallback rendering. Adding a PNG to the right path is all that's needed — no code change required.

### Scene flow

```
Overworld (overworld.tscn) ──random encounter──→ Battle (battle.tscn)
       │                                          │
       └──walk to town edge──→ Town (town.tscn)   │
                                  │               │
                                  └──interact merchant──→ Shop (shop.tscn)
                                                         │
                                                         └──Esc──→ Town
```

Scene transitions use `get_tree().change_scene_to_file()`. Data passes between scenes via `GameData.set_meta()` / `GameData.get_meta()` (e.g., `battle_zone`, `battle_surprise`, `shop_type`).

### Scene scripts

| Script | Scene | Role |
|--------|-------|------|
| `overworld.gd` | Overworld | 40×40 tile map built from ASCII `MAP` array, 4-dir grid movement (32px tiles), Pipoya terrain atlas via TileMapLayer, random encounters in forest tiles, lighthouse interaction, F3 debug overlay |
| `town.gd` | Town | 14×24 interior map (16px ColorRect tiles), NPC interaction (weapon/armor merchant → shop, innkeeper → full heal, elder → dialogue), exit to overworld at bottom edge |
| `battle.gd` | Battle | FF1-style turn-based combat: command phase → resolution by AGI-sorted turn order. Fight/Magic/Item/Run per character. Enemy AI picks random targets. Surprise/ambush mechanic. XP/gold rewards + level-up with randomized stat gains |
| `shop.gd` | Shop | Up/down browse, buy weapons/armor (then pick character to equip) or items (tonic/ether). Gold check. Esc returns to town |

### Data scripts (static classes, no instances)

| Script | Purpose |
|--------|---------|
| `data/classes.gd` | `CharDB` — class templates (Fighter/Thief/BlackBelt/RedMage/WhiteMage/BlackMage), spell definitions by level (Cure/Fire/Fira/etc.), level-up stat gain ranges |
| `data/enemies.gd` | `EnemyDB` — enemy stat templates (Slime through Golem), zone-based formations (grassland/forest/mountain/cave) |
| `data/items.gd` | `ItemDB` — weapon and armor tier lists with ATK/DEF/price, consumable shop items |

### Key patterns

- **Maps are ASCII arrays** — tile characters map to colors (fallback) or atlas coordinates (Pipoya). Blocked tiles, encounter zones, and interactable tiles are defined in const dictionaries.
- **Party members are plain dictionaries** — keys: `name`, `class`, `hp`, `max_hp`, `str`, `def`, `agi`, `level`, `xp`, `next_xp`, `magic_levels`, `alive`, `command`, `command_label`. Equipment is tracked separately via index arrays on `GameData`.
- **Commands are strings** — `"fight:<target_idx>"`, `"magic:<lvl>:<spell_idx>:<target_idx>"`, `"run"`, `"pass"`, `"item_used"`. Parsed by splitting on `:` during resolution.
- **All rendering is currently colored blocks** (Polygon2D / ColorRect). `SpriteCache` is wired and ready for PNG drops — the colored blocks are the fallback path.

## Tile system

Overworld uses the **Pipoya RPG World Tileset** (32×32 tiles) combined into `assets/sprites/tiles/pipoya_combined.png`. Atlas coordinates are defined as `Vector2i(col, row)` constants in `overworld.gd`. The full Pipoya source sheets are in `Pipoya/` at 32×32, 40×40, and 48×48 sizes.

Town still uses colored-block rendering (16×16 ColorRect tiles, no sprite atlas yet).

## Input actions

Defined in `project.godot`: `move_up/down/left/right` (WASD + arrows + gamepad), `interact` (E/Space/A), `cancel` (Escape/B), `battle_1-4` (1-4 keys), `battle_tab` (Tab), `menu` (Escape/Start).

## Adding new content

- **New enemy type:** Add template to `enemies.gd` `template()`, color to `battle.gd` `ENEMY_COLORS`, formation to a zone function, sprite to `assets/sprites/battle/enemies/<name>.png`
- **New tile type:** Add symbol to `MAP` array, entry to `TILE_ATLAS`/`COLORS`, add to `BLOCKED`/`ENCOUNTER` dicts as needed, sprite to `assets/sprites/tiles/<name>.png`
- **New class:** Add template to `classes.gd` `get_template()`, level-up stats to `level_up_stats()`, color to `battle.gd` `PARTY_COLORS`, sprite to `assets/sprites/battle/party/<class>.png`
- **New shop item:** Add to `items.gd` weapon/armor/item list, handle effect in `shop.gd`

## Developer documentation

- **`docs/QUICK_START.md`** — For new developers / vibe coders. Zero-to-understanding guide with examples.
- **`docs/DEVELOPER_GUIDE.md`** — Deep dive into every coding pattern in the codebase with educational "Coding Concept" boxes.
- Key code files have `[CODING CONCEPT]` inline comments explaining the patterns they use.

## Asset conventions

See `docs/godot-asset-conventions.md` for full details. Key points:
- All textures: Nearest filtering, no mipmaps, no repeat
- Tile size: 16×16 (town) / 32×32 (overworld Pipoya)
- Sprite names are snake_case, matching `SpriteCache` lookup paths
- Drop PNGs into `assets/sprites/` — auto-detected, no code change needed
