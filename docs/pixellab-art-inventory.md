# PixelLab Art Inventory

This document tracks PixelLab-created art for Lanternhouse. Update it whenever a PixelLab asset is created, downloaded, integrated, replaced, or retired.

Style target: cute but grounded top-down 2D RPG pixel art, clean dark outline, readable at small size, medium detail, and basic shading. The existing PixelLab cat remains the rendering-quality reference, but player and town NPC batches should default to humans unless another ancestry is requested.

Character ancestry direction: current player and town NPCs are humans. Keep the cat as a roaming town animal and style benchmark only. Dwarves, gnomes, elves, and other fantasy ancestries are reserved for later batches.

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
| Lanternhouse Player Adventurer | `77ee0770-b5a5-4eb5-a903-13fd7f0eca57` | Integrated | `assets/sprites/characters/player/pixellab_source.zip` | `assets/sprites/characters/player/rotations/*.png` | 56x56 | 8 | `scripts/overworld.gd`, `scripts/town.gd` | Human adventurer. Shared player rotations. Overworld displays at `0.58` scale. |
| Greta Ironforge Weapon Merchant | `4b17b7f2-06b2-4f9a-bc57-af84afb9d31a` | Integrated | `assets/sprites/characters/town_npcs/weapon_merchant/pixellab_source.zip` | `assets/sprites/characters/town_npcs/weapon_merchant/rotations/*.png` | 52x52 | 8 | `scripts/town.gd` | Human weapon merchant; replaces the atlas marker when present. |
| Bram Stonecoat Armor Merchant | `aed6c118-1b4a-432b-805e-7f952fafa6b2` | Integrated | `assets/sprites/characters/town_npcs/armor_merchant/pixellab_source.zip` | `assets/sprites/characters/town_npcs/armor_merchant/rotations/*.png` | 48x48 | 8 | `scripts/town.gd` | Human armor merchant, blue padded vest, shield silhouette. |
| Maren Willow Innkeeper | `41a16f13-0625-4bb8-abf8-1ce261753637` | Integrated | `assets/sprites/characters/town_npcs/innkeeper/pixellab_source.zip` | `assets/sprites/characters/town_npcs/innkeeper/rotations/*.png` | 48x48 | 8 | `scripts/town.gd` | Human innkeeper, green dress and cream apron. |
| Old Thatch Elder | `ce3344ff-ab05-421e-8700-a1d7bde0f55c` | Integrated | `assets/sprites/characters/town_npcs/elder/pixellab_source.zip` | `assets/sprites/characters/town_npcs/elder/rotations/*.png` | 48x48 | 8 | `scripts/town.gd` | Human elder; replaces the atlas marker when present. |
| Rolf Deepbarrel Tavern Keeper | `9f8b9117-bbeb-4d37-be0a-b6605dbf764c` | Integrated | `assets/sprites/characters/town_npcs/tavern_keeper/pixellab_source.zip` | `assets/sprites/characters/town_npcs/tavern_keeper/rotations/*.png` | 48x48 | 8 | `scripts/town.gd` | Human tavern keeper, brown vest, tankard silhouette. |
| Sister Aldith Healer | `62d413b9-d325-43c7-b2bf-d0f297464737` | Integrated | `assets/sprites/characters/town_npcs/healer/pixellab_source.zip` | `assets/sprites/characters/town_npcs/healer/rotations/*.png` | 40x40 | 8 | `scripts/town.gd` | Human healer, pale robe, green sash, chapel healer. |
| Fenn Copperwick Tinkerer | `ca873162-5fd1-4661-8f68-77fffd364cbd` | Integrated | `assets/sprites/characters/town_npcs/tinkerer/pixellab_source.zip` | `assets/sprites/characters/town_npcs/tinkerer/rotations/*.png` | 52x52 | 8 | `scripts/town.gd` | Human tinkerer, copper goggles, work coat, tool belt. |
| Hale Thorngate Realtor | `74e38be1-eaa8-484a-b3e9-6a88bd692606` | Integrated | `assets/sprites/characters/town_npcs/realtor/pixellab_source.zip` | `assets/sprites/characters/town_npcs/realtor/rotations/*.png` | 52x52 | 8 | `scripts/town.gd` | Human realtor, orange waistcoat and ledger. |

## Style References

| Asset | PixelLab ID | Status | Runtime Path | Size | Directions/Animations | Usage | Notes |
|---|---|---|---|---|---|---|---|
| Orange tabby cat | `192115aa-b638-4770-8103-aace28f448df` | Integrated | `assets/sprites/characters/cat/` | 68x68 | 8 directions, walk frames | `scripts/town.gd` | Roaming town animal and current rendering-quality target for new PixelLab work. |

## Overworld Coastline

| Asset | PixelLab ID | Status | Source Output | Runtime Path | Size | Usage | Notes |
|---|---|---|---|---|---|---|---|
| Ocean to beach Wang tileset | `e8857225-3de3-4a6c-94c7-15d26b65290f` | Integrated | `assets/sprites/tiles/pixellab/coastline/ocean_to_beach.png` | `assets/sprites/tiles/lanternhouse_overworld.png` | 32x32 tiles, 16 tiles | Overworld water and beach atlas slots | Source metadata: `assets/sprites/tiles/pixellab/coastline/ocean_to_beach.json`. |
| Beach to grass Wang tileset | `179c6f90-fb40-4ca2-b0e0-607ffd6521ef` | Integrated | `assets/sprites/tiles/pixellab/coastline/beach_to_grass.png` | `assets/sprites/tiles/lanternhouse_overworld.png` | 32x32 tiles, 16 tiles | Overworld grass atlas slot | Source metadata: `assets/sprites/tiles/pixellab/coastline/beach_to_grass.json`. |
| Coastal dock | `04140612-af3a-4a76-be65-c7d8d4f57c64` | Integrated | `assets/sprites/tiles/pixellab/coastline/coastal_dock.png` | `assets/sprites/tiles/lanternhouse_overworld.png` | 64x64 source | Overworld dock atlas slot | Downscaled into the 32x32 dock tile by `scripts/dev/build_overworld_atlas.py`. |
| Coastal cave | `78502baa-e6bf-4522-8a5e-0ec0e72e8c0f` | Integrated | `assets/sprites/tiles/pixellab/coastline/coastal_cave.png` | `assets/sprites/tiles/lanternhouse_overworld.png` | 64x64 source | Overworld cave atlas slot | Downscaled into the 32x32 cave tile by `scripts/dev/build_overworld_atlas.py`. |
| Expanded overworld biome atlas pass | Local Pillow composition | Integrated | PixelLab coastline sources plus local generated biome tiles | `assets/sprites/tiles/lanternhouse_overworld.png` | 8x4 atlas of 32x32 tiles | Overworld desert, tall grass, meadow, rocky coast, palm, marsh, mountain, beach, grass, landmarks | Rebuild with `python scripts/dev/build_overworld_atlas.py`. |

## Town Ground And Shops

| Asset | PixelLab ID | Status | Source Output | Runtime Path | Size | Usage | Notes |
|---|---|---|---|---|---|---|---|
| Town ground atlas pass | Local Pillow composition | Integrated | `assets/sprites/tiles/source/town_ground/*.png` | `assets/sprites/tiles/lanternhouse_town_readable.png` | 8x2 atlas of 16x16 tiles | `scripts/town.gd` ground layer | Grass, dirt, plaza, flower grass, mud, decking, stone border, garden soil, sanded path, mossy cobble, brick, leaf litter. Rebuild with `python scripts/dev/build_town_ground_atlas.py`. |
| Weapon shop sign | `902b6d15-3bc4-4b2c-906d-672ce0ab84f7` | Integrated | `assets/sprites/town/shops/signs/weapon_shop.json` | `assets/sprites/town/shops/signs/weapon_shop.png` | 32x32 | `scripts/town.gd` prop layer | Crossed sword and hammer sign. |
| Armor shop sign | `70a3fb20-7083-4542-8dc5-601eeb16608b` | Integrated | `assets/sprites/town/shops/signs/armor_shop.json` | `assets/sprites/town/shops/signs/armor_shop.png` | 32x32 | `scripts/town.gd` prop layer | Shield sign. |
| Inn sign | `1175e480-dbb5-4867-89df-46c871144a68` | Integrated | `assets/sprites/town/shops/signs/inn.json` | `assets/sprites/town/shops/signs/inn.png` | 32x32 | `scripts/town.gd` prop layer | Bed and candle sign. |
| Tavern sign | `e21b10c8-1ad2-4bec-82af-92f5411a53f8` | Integrated | `assets/sprites/town/shops/signs/tavern.json` | `assets/sprites/town/shops/signs/tavern.png` | 32x32 | `scripts/town.gd` prop layer | Mug sign. |
| Workshop sign | `d3188f86-9c3a-47c9-8c39-fa93913586ae` | Integrated | `assets/sprites/town/shops/signs/workshop.json` | `assets/sprites/town/shops/signs/workshop.png` | 32x32 | `scripts/town.gd` prop layer | Copper gear sign. |
| Chapel healer sign | `7be0f355-5316-405d-9131-d29789526aa1` | Integrated | `assets/sprites/town/shops/signs/chapel.json` | `assets/sprites/town/shops/signs/chapel.png` | 32x32 | `scripts/town.gd` prop layer | Green lantern chapel sign. |
| Town shop awning overlays | Local Pillow composition | Integrated | `scripts/dev/build_town_shop_overlays.py` | `assets/sprites/town/shops/awnings/*.png` | 48x24 each | `scripts/town.gd` building layer | Service-colored storefront overlays for weapons, armor, inn, tavern, workshop, and chapel. |
| Town shop building facades | Local Pillow composition | Integrated | `scripts/dev/build_town_shop_buildings.py` | `assets/sprites/town/shops/buildings/*.png` | 96x64 each | `scripts/town.gd` building layer | Project-owned facades for elder hall, weapons, armor, inn, tavern, workshop, and chapel. Vendor buildings remain as fallback. |
| Home interior atlas pass | Local Pillow composition | Integrated | `assets/sprites/interiors/town/source/*.png` | `assets/sprites/interiors/town/home_interior.png` | 8x2 atlas of 16x16 tiles | `scripts/home.gd` map layer | Walls, wood floor, bed, kitchen, garden, map table, workbench, rug, trophy, chest, and table. Rebuild with `python scripts/dev/build_home_interior_atlas.py`. |

## Battle Sprites

| Asset | PixelLab ID | Status | Source Output | Runtime Path | Size | Usage | Notes |
|---|---|---|---|---|---|---|---|
| Battle party sprite pass | Local Pillow composition | Integrated | `scripts/dev/build_battle_party_sprites.py` | `assets/sprites/battle/party/*.png` | 64x48 each | `scripts/battle.gd` party draw path | Fighter, thief, blackbelt, redmage, whitemage, blackmage. Polygon blocks remain as fallback. |
| Battle enemy sprite pass | Local Pillow composition | Integrated | `scripts/dev/build_battle_enemy_sprites.py` | `assets/sprites/battle/enemies/*.png` | 96x48 each | `scripts/battle.gd` enemy draw path | Slime, imp, wolf, ghoul, skeleton, ogre, wraith, drake, golem. Polygon blocks remain as fallback. |
| Village lantern post | `47f315c5-931a-4930-bbeb-6bf1533c3280` | Integrated | `assets/sprites/town/props/lantern_post.json` | `assets/sprites/town/props/lantern_post.png` | 32x32 | `scripts/town.gd` prop layer | Warm brass lantern post. |
| Village well | `ce403f3e-b887-4d84-94cf-481bed565067` | Integrated | `assets/sprites/town/props/well.json` | `assets/sprites/town/props/well.png` | 48x48 | `scripts/town.gd` prop layer | Stone well with wooden roof. |
| Notice board | `56684de0-23b6-401e-ba55-a8d94196fe5e` | Integrated | `assets/sprites/town/props/notice_board.json` | `assets/sprites/town/props/notice_board.png` | 32x32 | `scripts/town.gd` prop layer | Wooden board with parchment notes. |
| Crate stack | `f8988fce-c7c1-4d2c-a558-92706216f754` | Integrated | `assets/sprites/town/props/crate_stack.json` | `assets/sprites/town/props/crate_stack.png` | 32x32 | `scripts/town.gd` prop layer | Market crates. |
| Barrel pair | `17dc35b5-17ec-445a-a3a6-e3cf87761ed8` | Integrated | `assets/sprites/town/props/barrel_pair.json` | `assets/sprites/town/props/barrel_pair.png` | 32x32 | `scripts/town.gd` prop layer | Small wooden barrels. |
| Village bench | `737e9293-6529-4e59-bda5-f2353b0c81d5` | Integrated | `assets/sprites/town/props/bench.json` | `assets/sprites/town/props/bench.png` | 40x40 | `scripts/town.gd` prop layer | Simple wooden bench. |
| Flower box | `924c2913-da1c-444e-b97e-95eb816f0bed` | Integrated | `assets/sprites/town/props/flower_box.json` | `assets/sprites/town/props/flower_box.png` | 32x32 | `scripts/town.gd` prop layer | Wooden box with yellow and pink flowers. |
| Herb planter | `3a988520-db1c-4e7f-a902-8f8124445145` | Integrated | `assets/sprites/town/props/herb_planter.json` | `assets/sprites/town/props/herb_planter.png` | 32x32 | `scripts/town.gd` prop layer | Small planter with green leaves. |

## Creation Prompts

### Lanternhouse Player Adventurer

Human Lanternhouse player adventurer for a top-down 2D pixel RPG, cute but grounded, clean dark outline, readable at small size, medium detail, basic shading, warm brown travel cloak, small brass lantern at belt, leather boots, friendly determined silhouette. Match the cat asset's clean outline, palette discipline, and small-sprite readability without making the character animal-like.

### Greta Ironforge Weapon Merchant

Human Lanternhouse town weapon merchant NPC, stout friendly blacksmith woman, red-brown apron, rolled sleeves, tiny hammer at belt, top-down 2D pixel RPG sprite, cute but grounded, clean dark outline, readable at 16 to 32 pixels, medium detail, basic shading. Match the cat asset's clean outline and readability without making the character animal-like.

### Old Thatch Elder

Human Lanternhouse town elder NPC, small old villager with purple shawl and long grey eyebrows, carrying a candle or walking stick, top-down 2D pixel RPG sprite, cute but grounded, clean dark outline, readable at 16 to 32 pixels, medium detail, basic shading. Match the cat asset's clean outline and readability without making the character animal-like.

### Ocean To Beach Wang Tileset

Deep blue ocean water with small white wave flecks to warm sandy coastline beach edge. Transition: white sea foam and wet golden sand shoreline.

### Beach To Grass Wang Tileset

Warm sandy beach to bright green island grass. Transition: uneven natural grass edge over sand with tiny stones.

### Coastal Dock

Top-down pixel art coastal dock, short wooden pier over blue water, clean dark outline, medium detail, basic shading, transparent background.

### Coastal Cave

Top-down pixel art rocky coastal cave entrance in tan cliff, dark opening with small white surf foam at base, clean dark outline, medium detail, transparent background.

### Town Shop Signs

Top-down pixel art hanging wooden service signs with simple readable icons, transparent background, cute but grounded RPG prop, clean dark outline, readable at 32 pixels, medium detail, basic shading.

### Town Prop Cluster

Top-down pixel art village props with transparent backgrounds, cute but grounded RPG prop style, clean dark outline, readable at 32 to 48 pixels, medium detail, basic shading.

## Integration Notes

- Keep downloaded PixelLab zips and `metadata.json` files next to the normalized runtime files.
- Normalize runtime rotations to `rotations/<direction>.png` under each asset folder.
- Prefer script fallbacks so missing art does not block gameplay.
- Run Godot headless checks after each integration.
- Rebuild the overworld atlas with `python scripts/dev/build_overworld_atlas.py`.
