# Lanternhouse Asset Manifest

Complete list of every sprite file the codebase expects, with dimensions
and frame counts.

## Overworld Sprites

| File | Size | Frames | Notes |
|---|---|---|---|
| `assets/sprites/overworld/player.png` | 64×64 | 16 (4 dir × 4) | Walk cycle |
| `assets/sprites/overworld/npc_merchant.png` | 64×64 | 16 | Shop NPC |
| `assets/sprites/overworld/npc_elder.png` | 64×64 | 16 | Quest NPC |
| `assets/sprites/overworld/npc_innkeeper.png` | 64×64 | 16 | Inn NPC |

## PixelLab Character Assets

These assets may use original PixelLab frame folders instead of legacy sheets.
They are integrated by scene scripts that scale or animate the frames directly.

| File or folder | Size | Frames | Notes |
|---|---|---|---|
| `assets/sprites/characters/cat/rotations/` | 68×68 each | 8 directional stills | Current style benchmark |
| `assets/sprites/characters/cat/walk/` | 68×68 each | 4 directions × 6 frames | Used by `town.gd` roaming cat |

## Battle Sprites — Party

| File | Size | Frames | Notes |
|---|---|---|---|
| `assets/sprites/battle/party/fighter.png` | 64×48 | 2 idle | Front-facing |
| `assets/sprites/battle/party/thief.png` | 64×48 | 2 idle | |
| `assets/sprites/battle/party/blackbelt.png` | 64×48 | 2 idle | |
| `assets/sprites/battle/party/redmage.png` | 64×48 | 2 idle | |

## Battle Sprites — Enemies

| File | Size | Frames | Notes |
|---|---|---|---|
| `assets/sprites/battle/enemies/slime.png` | 96×48 | 2 (idle + hit) | Grassland |
| `assets/sprites/battle/enemies/imp.png` | 96×48 | 2 | Grassland/Forest |
| `assets/sprites/battle/enemies/wolf.png` | 96×48 | 2 | Grassland/Forest |
| `assets/sprites/battle/enemies/ghoul.png` | 96×48 | 2 | Forest/Mountain |
| `assets/sprites/battle/enemies/skeleton.png` | 96×48 | 2 | Mountain/Cave |
| `assets/sprites/battle/enemies/ogre.png` | 96×48 | 2 | Mountain/Cave |
| `assets/sprites/battle/enemies/wraith.png` | 96×48 | 2 | Mountain/Cave |
| `assets/sprites/battle/enemies/drake.png` | 96×48 | 2 | Cave (mini-boss) |
| `assets/sprites/battle/enemies/golem.png` | 96×48 | 2 | Cave (boss-tier) |

## Terrain Tiles

| File | Size | Frames | Notes |
|---|---|---|---|
| `assets/sprites/tiles/water.png` | 16×64 | 4 animated | Wave shimmer |
| `assets/sprites/tiles/grass.png` | 16×16 | 1 | Warm green |
| `assets/sprites/tiles/forest.png` | 16×16 | 1 | Dense canopy |
| `assets/sprites/tiles/mountain.png` | 16×16 | 1 | Rocky peak |
| `assets/sprites/tiles/town.png` | 16×16 | 1 | Building icon |
| `assets/sprites/tiles/path.png` | 16×16 | 1 | Dirt path |
| `assets/sprites/tiles/cave.png` | 16×16 | 1 | Dark entrance |
| `assets/sprites/tiles/bridge.png` | 16×16 | 1 | Wooden bridge |
| `assets/sprites/tiles/lighthouse.png` | 16×16 | 1 | Coastal beacon |

## UI (Future)

| File | Size | Frames | Notes |
|---|---|---|---|
| `assets/sprites/ui/cursor.png` | 16×16 | 1 | Menu pointer |
| `assets/sprites/ui/frame_border.png` | 8×8 | 1 | Dialog border tiles |
| `assets/sprites/ui/icons/spell_fire.png` | 16×16 | 1 | Fire spell |
| `assets/sprites/ui/icons/spell_cure.png` | 16×16 | 1 | Cure spell |
| `assets/sprites/ui/icons/spell_thunder.png` | 16×16 | 1 | Thunder spell |
| `assets/sprites/ui/icons/spell_blind.png` | 16×16 | 1 | Blind spell |
| `assets/sprites/ui/icons/spell_fira.png` | 16×16 | 1 | Fira spell |
| `assets/sprites/ui/icons/spell_cura.png` | 16×16 | 1 | Cura spell |
| `assets/sprites/ui/icons/spell_firaga.png` | 16×16 | 1 | Firaga spell |
| `assets/sprites/ui/icons/spell_curaga.png` | 16×16 | 1 | Curaga spell |

## Summary

| Category | Count |
|---|---|
| Overworld sprites | 4 |
| PixelLab characters | 1 |
| Battle party | 4 |
| Battle enemies | 9 |
| Terrain tiles | 8 |
| UI (future) | 10 |
| **Total** | **36 tracked groups** |
