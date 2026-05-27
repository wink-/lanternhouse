# Lanternhouse Vocabulary

This document defines shared project terms so design notes, code comments, art requests, and future learning docs all use the same language.

## World And Scene Terms

| Term | Meaning In Lanternhouse | Examples |
|---|---|---|
| Overworld | The outer map where the player travels between places. It is not inside a town, dungeon, house, shop, or other focused location. | Coastline, forests, mountains, roads, beacons, town icons, cave icons, encounter zones. |
| Town | A settlement scene where the player walks around among NPCs, shops, buildings, and services. | Brindlewick in `scenes/town/town.tscn`. |
| Interior | A focused indoor or close-up location that is smaller than a town. | Home, inn room, shop, guild hall, house. |
| Dungeon | A dangerous exploration scene with obstacles, encounters, treasure, or a boss. | Cave, lighthouse interior, ruins, sealed places. |
| Battle | The combat screen where party members and enemies take actions. | `scenes/battle/battle.tscn`. |
| Landmark | A notable overworld destination or visual marker. | Lighthouse, beacon, dock, cave, ruins, camp. |
| Prop | A non-character object that decorates or clarifies a place. | Barrel, signpost, bed, anvil, crate, pier posts. |
| Tile | A small repeatable map image used to build terrain or floors. | Water, beach, grass, forest, mountain, path. |
| Atlas | A single image containing many tiles or sprites arranged in a grid. | `assets/sprites/tiles/lanternhouse_overworld.png`. |

## Gameplay Terms

| Term | Meaning In Lanternhouse | Examples |
|---|---|---|
| Party | The player-controlled group used in battles and progression. | Fighter, thief, mage, recruited companions. |
| NPC | A non-player character the player can talk to or interact with. | Greta Ironforge, Old Thatch, innkeeper. |
| Encounter | A battle trigger or enemy group found through exploration. | Random forest battle, visible monster den. |
| Quest | A tracked goal with dialogue, progress, and rewards. | Visit Brindlewick, light beacons, defeat a boss. |
| Faction | A group with reputation and story meaning. | Keepers Guild, Harbor Compact, Grey Chapel, The Unlit. |
| Resource | A gathered or spendable item used by systems. | Copper, fish, herbs, materials, tonics. |

## Art Pipeline Terms

| Term | Meaning In Lanternhouse | Examples |
|---|---|---|
| Source output | The original file downloaded from PixelLab or another art source. Keep it for provenance and future rebuilds. | `pixellab_source.zip`, PixelLab tileset PNGs and metadata JSON. |
| Runtime asset | The file the Godot game actually loads during play. | Normalized `rotations/*.png`, `lanternhouse_overworld.png`. |
| Replacement pass | A focused round of replacing placeholder/prototype art while preserving gameplay. | Player + two NPCs, coastline atlas pass. |
| Style target | The reference quality and style for new art. | The PixelLab orange tabby cat: cute but grounded, clean outline, readable small silhouette. |
| Integration | Wiring an asset into scenes/scripts so it appears in the game. | Updating loaders, rebuilding an atlas, adding paths to docs. |
| Verification | Running Godot checks after an integration. | Headless project load, smoke scenes, direct scene launch. |

## Code Terms

| Term | Meaning In Lanternhouse | Examples |
|---|---|---|
| Scene | A Godot `.tscn` file containing nodes. Usually one playable screen or mode. | `overworld.tscn`, `town.tscn`, `battle.tscn`. |
| Script | A `.gd` file attached to a scene or used as a data/helper module. | `overworld.gd`, `game_data.gd`, `npcs.gd`. |
| Autoload | A global singleton Godot loads once and keeps available everywhere. | `GameData`, `SpriteCache`, `AudioManager`. |
| Data script | A script used mostly as a lookup table. | `scripts/data/items.gd`, `scripts/data/enemies.gd`. |
| Fallback | A backup behavior used when an asset is missing. | Colored blocks or old atlas regions when PixelLab sprites are absent. |
| Smoke test | A small automated scene/script that checks one workflow still runs. | `scenes/dev/smoke_battle_basic.tscn`. |

## Naming Guidelines

- Use `overworld` only for the outer travel map.
- Use `town`, `interior`, or `dungeon` for focused locations entered from the overworld.
- Use `source` or `pixellab` folders for original generated/downloaded art.
- Use clear runtime paths under `assets/sprites/<category>/...`.
- Prefer names that teach what the thing is: `coastal_dock`, `beach_to_grass`, `weapon_merchant`.
