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

## PixelLab Character Rotations

| File | Size | Frames | Notes |
|---|---|---|---|
| `assets/sprites/characters/player/rotations/*.png` | 56×56 | 8 directions | Player used by overworld and town |
| `assets/sprites/characters/town_npcs/weapon_merchant/rotations/*.png` | 52×52 | 8 directions | Greta Ironforge town NPC |
| `assets/sprites/characters/town_npcs/armor_merchant/rotations/*.png` | 48×48 | 8 directions | Bram Stonecoat town NPC |
| `assets/sprites/characters/town_npcs/innkeeper/rotations/*.png` | 48×48 | 8 directions | Maren Willow town NPC |
| `assets/sprites/characters/town_npcs/elder/rotations/*.png` | 48×48 | 8 directions | Old Thatch town NPC |
| `assets/sprites/characters/town_npcs/tavern_keeper/rotations/*.png` | 48×48 | 8 directions | Rolf Deepbarrel town NPC |
| `assets/sprites/characters/town_npcs/healer/rotations/*.png` | 40×40 | 8 directions | Sister Aldith town NPC |
| `assets/sprites/characters/town_npcs/tinkerer/rotations/*.png` | 52×52 | 8 directions | Fenn Copperwick town NPC |
| `assets/sprites/characters/town_npcs/realtor/rotations/*.png` | 52×52 | 8 directions | Hale Thorngate town NPC |

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
| `assets/sprites/battle/party/fighter.png` | 64×48 | 1 idle | Front-facing |
| `assets/sprites/battle/party/thief.png` | 64×48 | 1 idle | Front-facing |
| `assets/sprites/battle/party/blackbelt.png` | 64×48 | 1 idle | Front-facing |
| `assets/sprites/battle/party/redmage.png` | 64×48 | 1 idle | Front-facing |
| `assets/sprites/battle/party/whitemage.png` | 64×48 | 1 idle | Front-facing |
| `assets/sprites/battle/party/blackmage.png` | 64×48 | 1 idle | Front-facing |

Rebuild battle party sprites with:

```powershell
python scripts/dev/build_battle_party_sprites.py
```

## Battle Sprites — Enemies

| File | Size | Frames | Notes |
|---|---|---|---|
| `assets/sprites/battle/enemies/slime.png` | 96×48 | 1 idle | Grassland |
| `assets/sprites/battle/enemies/imp.png` | 96×48 | 1 idle | Grassland/Forest |
| `assets/sprites/battle/enemies/wolf.png` | 96×48 | 1 idle | Grassland/Forest |
| `assets/sprites/battle/enemies/ghoul.png` | 96×48 | 1 idle | Forest/Mountain |
| `assets/sprites/battle/enemies/skeleton.png` | 96×48 | 1 idle | Mountain/Cave |
| `assets/sprites/battle/enemies/ogre.png` | 96×48 | 1 idle | Mountain/Cave |
| `assets/sprites/battle/enemies/wraith.png` | 96×48 | 1 idle | Mountain/Cave |
| `assets/sprites/battle/enemies/drake.png` | 96×48 | 1 idle | Cave (mini-boss) |
| `assets/sprites/battle/enemies/golem.png` | 96×48 | 1 idle | Cave (boss-tier) |
| `assets/sprites/battle/enemies/crab.png` | 96×48 | 1 idle | Beach |
| `assets/sprites/battle/enemies/bat.png` | 96×48 | 1 idle | Forest/Mountain/Cave |
| `assets/sprites/battle/enemies/bandit.png` | 96×48 | 1 idle | Grassland |
| `assets/sprites/battle/enemies/serpent.png` | 96×48 | 1 idle | Beach/Mountain/Cave |
| `assets/sprites/battle/enemies/mossling.png` | 96×48 | 1 idle | Grassland/Forest |
| `assets/sprites/battle/enemies/jelly.png` | 96×48 | 1 idle | Beach |
| `assets/sprites/battle/enemies/shadow_wisp.png` | 96×48 | 1 idle | Post-seal |
| `assets/sprites/battle/enemies/dark_shade.png` | 96×48 | 1 idle | Boss summon |
| `assets/sprites/battle/enemies/mournlight_shade.png` | 128×96 | 1 idle | Cave boss |

Rebuild battle enemy sprites with:

```powershell
python scripts/dev/build_battle_enemy_sprites.py
```

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

## Town Ground Atlas

| Symbol | Atlas Coord | Tile | Notes |
|---|---|---|---|
| `.` | `(0, 0)` | Short grass | Default walkable town grass |
| `=` | `(1, 0)` | Packed dirt path | Main roads |
| `@` | `(2, 0)` | Town plaza cobble | Central service plaza |
| `,` | `(3, 0)` | Flower grass | Soft edge grass and open lots |
| `;` | `(4, 0)` | Muddy track | Wetter worn ground |
| `w` | `(5, 0)` | Wood decking | Porches and work platforms |
| `+` | `(6, 0)` | Stone path border | Road edging and thresholds |
| `g` | `(7, 0)` | Garden soil | Small planted lots |
| `s` | `(0, 1)` | Sanded path | Light footpaths near entries |
| `m` | `(1, 1)` | Mossy cobble | Aged plaza details |
| `b` | `(2, 1)` | Warm brick | Built-up plaza accents |
| `l` | `(3, 1)` | Leaf litter grass | Shady grass near trees/buildings |

Rebuild `assets/sprites/tiles/lanternhouse_town_readable.png` with:

```powershell
python scripts/dev/build_town_ground_atlas.py
```

## Town Shop Signs

| File | Size | Frames | Notes |
|---|---|---|---|
| `assets/sprites/town/shops/signs/weapon_shop.png` | 32×32 | 1 | PixelLab weapon shop sign |
| `assets/sprites/town/shops/signs/armor_shop.png` | 32×32 | 1 | PixelLab armor shop sign |
| `assets/sprites/town/shops/signs/inn.png` | 32×32 | 1 | PixelLab inn sign |
| `assets/sprites/town/shops/signs/tavern.png` | 32×32 | 1 | PixelLab tavern sign |
| `assets/sprites/town/shops/signs/workshop.png` | 32×32 | 1 | PixelLab workshop sign |
| `assets/sprites/town/shops/signs/chapel.png` | 32×32 | 1 | PixelLab chapel/healer sign |

## Town Shop Awnings

| File | Size | Frames | Notes |
|---|---|---|---|
| `assets/sprites/town/shops/awnings/weapon_shop.png` | 48×24 | 1 | Red-gold storefront awning |
| `assets/sprites/town/shops/awnings/armor_shop.png` | 48×24 | 1 | Blue-silver storefront awning |
| `assets/sprites/town/shops/awnings/inn.png` | 48×24 | 1 | Green-cream storefront awning |
| `assets/sprites/town/shops/awnings/tavern.png` | 48×24 | 1 | Amber-brown storefront awning |
| `assets/sprites/town/shops/awnings/workshop.png` | 48×24 | 1 | Copper storefront awning |
| `assets/sprites/town/shops/awnings/chapel.png` | 48×24 | 1 | Blue-green chapel awning |

## Town Shop Buildings

| File | Size | Frames | Notes |
|---|---|---|---|
| `assets/sprites/town/shops/buildings/elder_hall.png` | 96×64 | 1 | Project-owned elder hall facade |
| `assets/sprites/town/shops/buildings/weapon_shop.png` | 96×64 | 1 | Project-owned weapon shop facade |
| `assets/sprites/town/shops/buildings/armor_shop.png` | 96×64 | 1 | Project-owned armor shop facade |
| `assets/sprites/town/shops/buildings/inn.png` | 96×64 | 1 | Project-owned inn facade |
| `assets/sprites/town/shops/buildings/tavern.png` | 96×64 | 1 | Project-owned tavern facade |
| `assets/sprites/town/shops/buildings/workshop.png` | 96×64 | 1 | Project-owned workshop facade |
| `assets/sprites/town/shops/buildings/chapel.png` | 96×64 | 1 | Project-owned chapel facade |

Rebuild town shop facades with:

```powershell
python scripts/dev/build_town_shop_buildings.py
```

## Town Props

| File | Size | Frames | Notes |
|---|---|---|---|
| `assets/sprites/town/props/lantern_post.png` | 32×32 | 1 | PixelLab brass lantern post |
| `assets/sprites/town/props/well.png` | 48×48 | 1 | PixelLab stone well |
| `assets/sprites/town/props/notice_board.png` | 32×32 | 1 | PixelLab notice board |
| `assets/sprites/town/props/crate_stack.png` | 32×32 | 1 | PixelLab crate stack |
| `assets/sprites/town/props/barrel_pair.png` | 32×32 | 1 | PixelLab barrel pair |
| `assets/sprites/town/props/bench.png` | 40×40 | 1 | PixelLab bench |
| `assets/sprites/town/props/flower_box.png` | 32×32 | 1 | PixelLab flower box |
| `assets/sprites/town/props/herb_planter.png` | 32×32 | 1 | PixelLab herb planter |

## Town Interior Atlas

| Symbol | Atlas Coord | Tile | Notes |
|---|---|---|---|
| `#` | `(0, 0)` | Wall | Home boundary |
| `.` | `(1, 0)` | Wood floor | Default walkable interior floor |
| `B` | `(2, 0)` | Bed | Rest interactable |
| `K` | `(3, 0)` | Kitchen | Cooking interactable |
| `G` | `(4, 0)` | Garden | Herb garden interactable |
| `M` | `(5, 0)` | Map table | Beacon map interactable |
| `W` | `(6, 0)` | Workbench | Tinkering interactable |
| `R` | `(7, 0)` | Rug | Guest room area |
| `T` | `(0, 1)` | Trophy | Trophy interactable |
| `C` | `(1, 1)` | Chest | Storage chest upgrade |
| `@` | `(2, 1)` | Table | Blocked table/furniture |

Rebuild `assets/sprites/interiors/town/home_interior.png` with:

```powershell
python scripts/dev/build_home_interior_atlas.py
```

## PixelLab Coastline Sources

| File | Size | Frames | Notes |
|---|---|---|---|
| `assets/sprites/tiles/pixellab/coastline/ocean_to_beach.png` | 32×32 tiles | 16 | PixelLab Wang tileset source for water/beach coastline |
| `assets/sprites/tiles/pixellab/coastline/beach_to_grass.png` | 32×32 tiles | 16 | PixelLab Wang tileset source for beach/grass coastline |
| `assets/sprites/tiles/pixellab/coastline/coastal_dock.png` | 64×64 | 1 | PixelLab source object composed into overworld dock tile |
| `assets/sprites/tiles/pixellab/coastline/coastal_cave.png` | 64×64 | 1 | PixelLab source object composed into overworld cave tile |

## Expanded Overworld Atlas Slots

| Symbol | Atlas Coord | Terrain | Notes |
|---|---|---|---|
| `d` | `(2, 2)` | Desert | Saltglass Dunes biome |
| `;` | `(3, 2)` | Tall grass | Windgrass Fields biome |
| `*` | `(4, 2)` | Meadow | Lantern Meadow biome |
| `r` | `(5, 2)` | Rocky coast | Blocked coastline terrain |
| `p` | `(6, 2)` | Palm stand | Coastal decoration/walkable terrain |
| `m` | `(7, 2)` | Marsh | Reedmire Marsh biome |
| `.` + water neighbor mask | rows `3-4` | Sand shoreline variants | Runtime-selected beach edges for natural coastlines |
| `r` + water neighbor mask | rows `5-6` | Rocky shoreline variants | Runtime-selected rocky coast edges for blocked shoreline |

Rebuild `assets/sprites/tiles/lanternhouse_overworld.png` with:

```powershell
python scripts/dev/build_overworld_atlas.py
```

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
