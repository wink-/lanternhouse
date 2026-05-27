# Lanternhouse Art Replacement Plan

This plan tracks replacement of placeholder and prototype art with PixelLab-generated pixel art. The current rendering-quality target is the existing cat asset: cute but grounded top-down RPG pixel art, clean dark outline, readable silhouette, medium detail, and basic shading. For player and town NPC batches, default to human characters unless a specific fantasy ancestry is requested.

Created/downloaded PixelLab assets are tracked in `docs/pixellab-art-inventory.md`.

## Priority 1: Playable Characters In Core Loops

| Need | Current Usage | Target Asset Path | Notes |
|---|---|---|---|
| Player overworld/town sprite | `scripts/overworld.gd`, `scripts/town.gd` | `assets/sprites/characters/player/rotations/*.png` | Shared PixelLab rotations for town and overworld. Overworld falls back to `assets/sprites/overworld/player.png`. |
| Town weapon merchant | `scripts/town.gd` NPC marker | `assets/sprites/characters/town_npcs/weapon_merchant/rotations/*.png` | Greta Ironforge, human blacksmith silhouette. |
| Town elder | `scripts/town.gd` NPC marker | `assets/sprites/characters/town_npcs/elder/rotations/*.png` | Old Thatch, human elder with purple shawl and candle/staff. |

## Priority 2: Remaining Town Readability

| Need | Current Usage | Target Asset Path | Notes |
|---|---|---|---|
| Innkeeper, armor merchant, tavern keeper, healer, tinkerer, realtor | `scripts/town.gd` atlas NPC regions | `assets/sprites/characters/town_npcs/<npc_id>/rotations/*.png` | Human townsfolk batch. Dwarves, gnomes, elves, and other fantasy ancestries are reserved for later passes. |
| Town ground tiles | `scripts/town.gd` `GROUND_TILE_RECTS` | `assets/sprites/tiles/lanternhouse_town_readable.png` | Rebuildable 16px atlas for grass, paths, plaza, mud, decking, garden soil, and accents. |
| Town shop signs | `scripts/town.gd` prop layer | `assets/sprites/town/shops/signs/<shop_id>.png` | PixelLab signs for weapons, armor, inn, tavern, workshop, chapel/healer. |
| Town props/buildings | `scripts/town.gd` Quiet Village vendor sheets | `assets/sprites/town/props/`, `assets/sprites/town/buildings/` | Replace vendor regions with project-owned PixelLab props when enough pieces exist. |
| Town tiles | `scripts/town.gd` `lanternhouse_town*.png` | `assets/sprites/tiles/lanternhouse_town*.png` | Keep current atlas until a coherent tileset is generated. |

## Priority 3: Combat Silhouette Pass

| Need | Current Usage | Target Asset Path | Notes |
|---|---|---|---|
| Battle party sprites | `scripts/battle.gd` colored blocks | `assets/sprites/battle/party/<class>.png` | Fighter, thief, blackbelt, redmage/blackmage/whitemage equivalents. |
| Battle enemies | `scripts/battle.gd` colored blocks | `assets/sprites/battle/enemies/<name>.png` | Start with common early encounters: slime, imp, wolf. |

## Priority 4: Overworld Landmarks And UI

| Need | Current Usage | Target Asset Path | Notes |
|---|---|---|---|
| Landmarks/props | `scripts/overworld.gd` atlas plus marker pins | `assets/sprites/overworld/landmarks/` | Lighthouse, beacons, camp, cave, dock, ruins. |
| UI icons/items | Menus are text-first | `assets/sprites/ui/icons/` | Useful after combat and inventory art paths are wired. |

## Completed Overworld Terrain Passes

| Pass | Assets | Gameplay Surface |
|---|---|---|
| Coastline | PixelLab ocean/beach and beach/grass tilesets, dock, cave | Rebuilt overworld atlas water, beach, dock, cave |
| Expanded biomes | Local Pillow atlas pass using PixelLab coastline sources | Added desert, tall grass, meadow, rocky coast, palm stand, and marsh terrain symbols to the overworld |

## Working Build Queue

| Order | Slice | Target Assets | Integration Notes |
|---|---|---|---|
| 1 | Town ground variety | `assets/sprites/tiles/lanternhouse_town_readable.png` | Expand walkable town terrain without changing town gameplay. |
| 2 | Shop identity pass | `assets/sprites/town/shops/signs/*.png` | Add readable signs and shop props above the current vendor building art. |
| 3 | Shop building replacements | `assets/sprites/town/shops/buildings/*.png` | Project-owned facades integrated with vendor buildings as fallback. |
| 4 | Town prop clusters | `assets/sprites/town/props/*.png` | PixelLab barrels, crates, benches, lantern posts, flower boxes, wells, notice board, herb planters integrated through `TOWN_PROPS`. |
| 5 | Town interior starter set | `assets/sprites/interiors/town/home_interior.png` | Home interior atlas integrated into `scripts/home.gd`; next pass can add shop/interior scenes as they become playable. |
| 6 | Battle party silhouettes | `assets/sprites/battle/party/*.png` | Fighter, thief, blackbelt, redmage, whitemage, blackmage integrated with polygon fallback. |
| 7 | Early enemy set | `assets/sprites/battle/enemies/*.png` | Slime, imp, wolf, ghoul, skeleton, ogre, wraith, drake, golem integrated with polygon fallback. |
| 8 | UI item icons | `assets/sprites/ui/icons/*.png` | Potions, herbs, fish, ore, spell icons after combat/inventory art paths settle. |

## Current PixelLab Batch

| Asset | PixelLab ID | Status |
|---|---|---|
| Lanternhouse Player Adventurer | `77ee0770-b5a5-4eb5-a903-13fd7f0eca57` | Downloaded and integrated |
| Greta Ironforge Weapon Merchant | `4b17b7f2-06b2-4f9a-bc57-af84afb9d31a` | Downloaded and integrated |
| Old Thatch Elder | `ce3344ff-ab05-421e-8700-a1d7bde0f55c` | Downloaded and integrated |
