# Lanternhouse Art Replacement Plan

This plan tracks replacement of placeholder and prototype art with PixelLab-generated pixel art. The target style is the existing cat asset: cute but grounded top-down RPG pixel art, clean dark outline, readable silhouette, medium detail, and basic shading.

## Priority 1: Playable Characters In Core Loops

| Need | Current Usage | Target Asset Path | Notes |
|---|---|---|---|
| Player overworld/town sprite | `scripts/overworld.gd`, `scripts/town.gd` | `assets/sprites/characters/player/rotations/*.png` | Shared PixelLab rotations for town and overworld. Overworld falls back to `assets/sprites/overworld/player.png`. |
| Town weapon merchant | `scripts/town.gd` NPC marker | `assets/sprites/characters/town_npcs/weapon_merchant/rotations/*.png` | Greta Ironforge, blacksmith silhouette. |
| Town elder | `scripts/town.gd` NPC marker | `assets/sprites/characters/town_npcs/elder/rotations/*.png` | Old Thatch, purple shawl and candle/staff. |

## Priority 2: Remaining Town Readability

| Need | Current Usage | Target Asset Path | Notes |
|---|---|---|---|
| Innkeeper, armor merchant, tavern keeper, healer, tinkerer, realtor | `scripts/town.gd` atlas NPC regions | `assets/sprites/characters/town_npcs/<npc_id>/rotations/*.png` | Add each NPC one-by-one with the same loader path. |
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

## Current PixelLab Batch

| Asset | PixelLab ID | Status |
|---|---|---|
| Lanternhouse Player Adventurer | `77ee0770-b5a5-4eb5-a903-13fd7f0eca57` | Processing |
| Greta Ironforge Weapon Merchant | `4b17b7f2-06b2-4f9a-bc57-af84afb9d31a` | Processing |
| Old Thatch Elder | `ce3344ff-ab05-421e-8700-a1d7bde0f55c` | Processing |
