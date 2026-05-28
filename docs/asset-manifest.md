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
| `assets/sprites/town/buildings/elder_hall.png` | 96x96 | 1 | PixelLab 3/4 Elder Hall building |
| `assets/sprites/town/buildings/weapon_shop.png` | 80x80 | 1 | PixelLab 3/4 weapon shop building |
| `assets/sprites/town/buildings/armor_shop.png` | 80x80 | 1 | PixelLab 3/4 armor shop building |
| `assets/sprites/town/buildings/inn.png` | 96x96 | 1 | PixelLab 3/4 inn building |
| `assets/sprites/town/buildings/tavern.png` | 96x96 | 1 | PixelLab 3/4 tavern building |
| `assets/sprites/town/buildings/workshop.png` | 96x96 | 1 | PixelLab 3/4 tinkerer workshop building |
| `assets/sprites/town/buildings/chapel.png` | 80x80 | 1 | PixelLab 3/4 chapel/healer building |
| `assets/sprites/town/buildings/small_house.png` | 64x64 | 1 | PixelLab 3/4 reusable small house |
| `assets/sprites/town/buildings/large_house.png` | 96x96 | 1 | PixelLab 3/4 reusable larger house |
| `assets/sprites/town/buildings/door_stoop_pieces.png` | 96x96 | 1 | PixelLab modular doors and stoops |
| `assets/sprites/town/buildings/facade_blocks.png` | 128x128 | 1 | Pending PixelLab plaster, stone, balcony, window, and flower-box modules |
| `assets/sprites/town/buildings/wall_construction_tiles.png` | 128x128 | 1 | PixelLab wall, stone, timber, post, trim, and balcony construction sheet |
| `assets/sprites/town/buildings/warm_wall_construction_tiles.png` | 128x128 | 1 | PixelLab warm wall construction candidate sheet |
| `assets/sprites/town/buildings/roof_blocks.png` | 128x128 | 1 | Pending corrected PixelLab red clay roof, dormer, eave, and chimney modules |
| `assets/sprites/town/buildings/roof_construction_tiles.png` | 128x128 | 1 | PixelLab roof center, ridge, eave, edge, corner, and trim construction sheet |
| `assets/sprites/town/buildings/roof_texture_tiles.png` | 128x128 | 1 | PixelLab red clay roof-only 16x16 tile sheet |
| `assets/sprites/town/buildings/roof_accessories.png` | 128x128 | 1 | Pending PixelLab roof accessory module sheet |
| `assets/sprites/town/buildings/window_door_tiles.png` | 128x128 | 1 | PixelLab window, shutter, flower box, door, frame, and stoop construction sheet |
| `assets/sprites/town/buildings/window_door_tiles_expanded.png` | 128x128 | 1 | PixelLab expanded window, door, shutter, flower box, frame, and stoop sheet |
| `assets/sprites/town/buildings/foundation_tiles.png` | 128x128 | 1 | PixelLab foundation, moss strip, threshold, shadow, corner, and vent construction sheet |
| `assets/sprites/town/buildings/assembled_facade_tests.png` | 192x128 | 1 | PixelLab reference-only assembled facade test sheet |
| `assets/sprites/town/buildings/upper_floor_tiles.png` | 128x128 | 1 | PixelLab upper-floor wall, balcony, window, flower box, and eave-shadow candidate sheet |
| `assets/sprites/town/buildings/shopfront_tiles.png` | 128x128 | 1 | PixelLab shopfront counter, display, blank sign, awning, post, and icon plaque sheet |
| `assets/sprites/town/buildings/mechanical_facade_tiles.png` | 128x128 | 1 | PixelLab stricter flat facade construction chunk sheet |
| `assets/sprites/town/buildings/mechanical_roof_tiles.png` | 128x128 | 1 | PixelLab stricter flat roof tile module sheet |
| `assets/sprites/town/buildings/horizontal_wall_strips.png` | 128x128 | 1 | PixelLab horizontal wall strip texture candidate |
| `assets/sprites/town/buildings/vertical_wall_strips.png` | 128x128 | 1 | PixelLab straight vertical wall strip sheet |
| `assets/sprites/town/buildings/horizontal_construction_modules.png` | 128x128 | 1 | PixelLab separated horizontal construction module sheet |
| `assets/sprites/town/buildings/roof_trim_modules.png` | 128x128 | 1 | PixelLab roof trim, eave, cap, corner, and fascia modules |
| `assets/sprites/town/buildings/chimney_dormer_modules.png` | 128x128 | 1 | PixelLab chimney, dormer, vent, cap, and roof lantern modules |
| `assets/sprites/town/buildings/wall_fill_tiles.png` | 128x128 | 1 | PixelLab plaster and stone fill tile variants |
| `assets/sprites/town/buildings/modular_building_previews.png` | 192x192 | 1 | PixelLab modular building preview/reference sheet |
| `assets/sprites/town/buildings/door_window_variant_modules.png` | 128x128 | 1 | PixelLab extra door/window module sheet |
| `assets/sprites/town/buildings/timber_trim_modules.png` | 128x128 | 1 | PixelLab timber post, beam, brace, rail, lintel, cap, and bracket sheet |
| `assets/sprites/town/buildings/stone_foundation_variants.png` | 128x128 | 1 | PixelLab stone foundation variant module sheet |
| `assets/sprites/town/buildings/roof_corner_edge_variants.png` | 128x128 | 1 | PixelLab roof corner and edge variant module sheet |
| `assets/sprites/town/buildings/facade_ornament_modules.png` | 128x128 | 1 | PixelLab facade ornament module candidate sheet |
| `assets/sprites/town/buildings/coherent_inn_preview.png` | 96x96 | 1 | PixelLab reference-only coherent inn preview |
| `assets/sprites/town/buildings/coherent_shop_preview.png` | 80x80 | 1 | PixelLab reference-only coherent shop preview |
| `assets/sprites/town/buildings/facade_ornament_modules_retry.png` | 128x128 | 1 | PixelLab facade ornament module retry sheet |
| `assets/sprites/town/buildings/gable_roof_front_modules.png` | 128x128 | 1 | PixelLab gable roof front module candidate sheet |
| `assets/sprites/town/buildings/wall_lantern_sign_modules.png` | 128x128 | 1 | PixelLab wall lantern and sign bracket module sheet |
| `assets/sprites/town/buildings/modular_construction_previews_2.png` | 192x192 | 1 | PixelLab modular building construction preview sheet |
| `assets/sprites/town/buildings/final_building_tile_cohesion.png` | 128x128 | 1 | PixelLab final building tile cohesion candidate sheet |
| `assets/sprites/town/buildings/roof_color_variants.png` | 128x128 | 1 | PixelLab roof color variant module candidate sheet |
| `assets/sprites/town/buildings/shop_identity_modules.png` | 128x128 | 1 | PixelLab no-text shop identity facade candidate sheet |
| `assets/sprites/town/buildings/shop_plaque_modules.png` | 128x128 | 1 | PixelLab no-text shop plaque candidate sheet |
| `assets/sprites/town/buildings/modular_wall_kit.png` | 128x128 | 1 | PixelLab modular wall kit candidate |
| `assets/sprites/town/buildings/modular_roof_kit.png` | 128x128 | 1 | PixelLab modular roof kit candidate |
| `assets/sprites/town/buildings/isolated_shop_symbols.png` | 128x128 | 1 | PixelLab isolated no-text shop symbol candidate |
| `assets/sprites/town/buildings/isolated_wall_swatches.png` | 128x128 | 1 | PixelLab isolated wall material swatches |
| `assets/sprites/town/buildings/isolated_roof_swatches.png` | 128x128 | 1 | PixelLab isolated roof material swatch candidate |
| `assets/sprites/town/buildings/isolated_shop_symbols_retry.png` | 96x96 | 1 | PixelLab isolated no-text shop symbol retry |
| `assets/sprites/town/buildings/pure_roof_swatches_retry.png` | 96x96 | 1 | PixelLab pure red roof swatch retry |
| `assets/sprites/town/buildings/facade_test_strip.png` | 128x128 | 1 | PixelLab reusable facade test strip |
| `assets/sprites/town/buildings/door_hardware_trim.png` | 96x96 | 1 | PixelLab door hardware and trim module sheet |
| `assets/sprites/town/buildings/window_trim_modules.png` | 96x96 | 1 | PixelLab window trim candidate sheet |
| `assets/sprites/town/buildings/roof_weathering_decals.png` | 96x96 | 1 | PixelLab roof weathering candidate sheet |
| `assets/sprites/town/buildings/outline_mask_modules.png` | 96x96 | 1 | PixelLab black outline helper module sheet |
| `assets/sprites/town/buildings/wood_construction_swatches.png` | 96x96 | 1 | PixelLab isolated wood construction swatches |
| `assets/sprites/town/buildings/stone_construction_swatches.png` | 96x96 | 1 | PixelLab isolated stone construction swatches |
| `assets/sprites/town/buildings/tiny_construction_accents.png` | 96x96 | 1 | PixelLab tiny construction accent candidate sheet |
| `assets/sprites/town/buildings/blank_sign_boards.png` | 96x96 | 1 | PixelLab blank sign board sheet |
| `assets/sprites/town/buildings/facade_strip_pack.png` | 128x128 | 1 | PixelLab assembled facade strip pack |
| `assets/sprites/town/buildings/roof_strip_pack.png` | 128x128 | 1 | PixelLab assembled roof strip pack |
| `assets/sprites/town/buildings/practical_building_assembly_reference.png` | 128x128 | 1 | PixelLab final practical building assembly reference |
| `assets/sprites/town/buildings/tile_helper_icon_swatches.png` | 96x96 | 1 | PixelLab no-text construction helper swatch candidate |
| `assets/sprites/town/buildings/wide_facade_variations.png` | 192x192 | 1 | PixelLab wide reusable facade variation reference |
| `assets/sprites/town/buildings/narrow_facade_variations.png` | 192x192 | 1 | PixelLab narrow reusable facade variation reference |
| `assets/sprites/town/buildings/wide_facade_variations_2.png` | 192x192 | 1 | PixelLab wide reusable facade variation reference v2 |
| `assets/sprites/town/buildings/public_facade_variations.png` | 192x192 | 1 | PixelLab public facade variation reference |
| `assets/sprites/town/buildings/service_facade_reference.png` | 192x192 | 1 | PixelLab service facade reference sheet |
| `assets/sprites/town/buildings/residential_facade_reference.png` | 192x192 | 1 | PixelLab residential facade reference sheet |
| `assets/sprites/town/buildings/final_facade_polish_reference.png` | 192x192 | 1 | PixelLab final facade polish reference |
| `assets/sprites/town/buildings/final_roof_polish_reference.png` | 128x128 | 1 | PixelLab final roof polish reference |
| `assets/sprites/town/buildings/runtime_building_variants.png` | 256x256 | 1 | PixelLab runtime-ready building variant sheet |
| `assets/sprites/town/buildings/runtime_compact_building_variants.png` | 256x256 | 1 | PixelLab runtime-ready compact building variant sheet |
| `assets/sprites/town/buildings/cohesive_construction_tiles.png` | 256x256 | 1 | PixelLab cohesive building construction reference/candidate sheet |
| `assets/sprites/town/buildings/shopfront_facade_modules.png` | 256x256 | 1 | PixelLab shopfront facade reference/candidate strip |
| `assets/sprites/town/buildings/residential_building_modules.png` | 256x256 | 1 | PixelLab residential building reference/candidate sheet |
| `assets/sprites/town/buildings/isolated_wall_tiles.png` | 128x128 | 1 | PixelLab isolated wall/foundation tile grid |
| `assets/sprites/town/buildings/isolated_roof_tiles.png` | 128x128 | 1 | PixelLab isolated roof tile candidate |
| `assets/sprites/town/buildings/isolated_door_window_tiles.png` | 128x128 | 1 | PixelLab isolated door/window tile candidate |
| `assets/sprites/town/buildings/final_public_buildings.png` | 256x256 | 1 | PixelLab final public building candidate sheet |
| `assets/sprites/town/buildings/final_shop_buildings.png` | 256x256 | 1 | PixelLab final shop building candidate sheet |
| `assets/sprites/town/buildings/final_residential_buildings.png` | 256x256 | 1 | PixelLab final residential building candidate sheet |
| `assets/sprites/town/buildings/final_shop_buildings_retry.png` | 256x256 | 1 | PixelLab stricter south-facing shop building candidate |
| `assets/sprites/town/buildings/entrance_storefront_details.png` | 128x128 | 1 | PixelLab entrance and storefront detail candidate modules |
| `assets/sprites/town/buildings/exterior_prop_details.png` | 128x128 | 1 | PixelLab building exterior dressing modules |
| `assets/sprites/town/props/market_stall_shop_exterior_kit.png` | 128x128 | 1 | PixelLab market stall and shop exterior kit |
| `assets/sprites/town/ground/road_edge_building_helpers.png` | 128x128 | 1 | PixelLab road edge and building placement helper candidate |
| `assets/sprites/town/props/town_sign_shop_icon_kit.png` | 128x128 | 1 | PixelLab no-text town sign and shop icon candidate |
| `assets/sprites/town/props/town_sign_shop_icon_kit_retry.png` | 128x128 | 1 | PixelLab improved no-text shop icon and sign sheet |
| `assets/sprites/town/ground/road_edge_tile_grid_retry.png` | 128x128 | 1 | PixelLab improved road edge tile candidate |
| `assets/sprites/town/props/waterfront_well_side_props.png` | 128x128 | 1 | PixelLab waterfront and well-side prop candidate |
| `assets/sprites/town/props/final_plaza_decoration_pack.png` | 128x128 | 1 | PixelLab final town plaza decoration candidate |
| `assets/sprites/town/ground/final_building_shadow_threshold_tiles.png` | 128x128 | 1 | PixelLab building shadow/threshold reference candidate |
| `assets/sprites/town/buildings/final_roof_chimney_accessories.png` | 128x128 | 1 | PixelLab final roof and chimney accessory sheet |
| `assets/sprites/town/props/plaza_small_props_retry.png` | 128x128 | 1 | PixelLab stricter plaza small props sheet |
| `assets/sprites/town/ground/building_threshold_tiles_retry.png` | 128x128 | 1 | PixelLab stricter building threshold tile sheet |
| `assets/sprites/town/props/cohesive_town_tile_preview_mockup.png` | 192x192 | 1 | PixelLab cohesive town tile preview mockup |
| `assets/sprites/town/props/final_street_furniture_pack.png` | 128x128 | 1 | PixelLab final street furniture candidate |
| `assets/sprites/town/ground/final_cobblestone_plaza_transitions.png` | 128x128 | 1 | PixelLab final cobblestone plaza transition candidate |
| `assets/sprites/town/props/final_house_garden_props.png` | 128x128 | 1 | PixelLab final house garden prop sheet |
| `assets/sprites/town/props/street_furniture_pack_retry.png` | 128x128 | 1 | PixelLab stricter street furniture sprite sheet |
| `assets/sprites/town/props/town_entry_gate_fence_kit.png` | 128x128 | 1 | PixelLab town entry gate and fence kit |
| `assets/sprites/town/ground/town_path_clutter_decals.png` | 128x128 | 1 | PixelLab town path clutter candidate |
| `assets/sprites/town/ground/tiny_path_decal_grid_retry.png` | 128x128 | 1 | PixelLab stricter tiny path decal grid |
| `assets/sprites/town/props/lamplight_evening_accents.png` | 128x128 | 1 | PixelLab lamplight and evening town accent sheet |
| `assets/sprites/town/props/final_town_assembly_reference.png` | 192x192 | 1 | PixelLab final town assembly reference |
| `assets/sprites/town/buildings/doorway_exterior_transitions.png` | 128x128 | 1 | PixelLab doorway/exterior transition candidate |
| `assets/sprites/town/ground/seasonal_flower_foliage_accents.png` | 128x128 | 1 | PixelLab seasonal flower and foliage accents |
| `assets/sprites/town/props/coastal_town_crossover_props.png` | 128x128 | 1 | PixelLab coastal-town crossover prop sheet |
| `assets/sprites/town/buildings/runtime_shop_split_sheet.png` | 320x320 | 1 | PixelLab runtime shop sprite split sheet |
| `assets/sprites/town/buildings/runtime_home_split_sheet.png` | 320x320 | 1 | PixelLab runtime home sprite split sheet |
| `assets/sprites/town/buildings/runtime_public_split_sheet.png` | 320x320 | 1 | PixelLab runtime public building split sheet |
| `assets/sprites/town/buildings/modular_building_atlas.png` | 128x64 | 1 | Curated 16x16 modular building atlas used by `scripts/town.gd` |
| `assets/sprites/town/buildings/modular_facade_construction_atlas_pixellab.png` | 256x256 | 1 | PixelLab modular facade reference/candidate |
| `assets/sprites/town/buildings/modular_roof_wall_atlas_pixellab.png` | 256x256 | 1 | PixelLab modular roof/wall reference/candidate |
| `assets/sprites/town/buildings/modular_shop_sign_awning_atlas_pixellab.png` | 128x128 | 1 | PixelLab modular shop sign/awning reference/candidate |
| `assets/sprites/town/ground/threshold_shadow_atlas_pixellab.png` | 128x128 | 1 | PixelLab threshold/shadow reference candidate |
| `assets/sprites/town/buildings/modular_roof_polish_sheet_pixellab.png` | 128x128 | 1 | PixelLab modular roof polish reference/candidate |
| `assets/sprites/town/buildings/modular_facade_polish_sheet_pixellab.png` | 128x128 | 1 | PixelLab modular facade polish reference/candidate |
| `assets/sprites/town/buildings/modular_town_atlas_improvement_reference.png` | 192x192 | 1 | PixelLab modular town atlas improvement reference |
| `assets/sprites/town/buildings/modular_atlas_next_pass_reference.png` | 192x192 | 1 | PixelLab modular atlas next-pass reference |
| `assets/sprites/town/buildings/log_building_modular_atlas_pixellab.png` | 128x128 | 1 | PixelLab log building reference candidate |
| `assets/sprites/town/buildings/castle_stone_modular_atlas_pixellab.png` | 128x128 | 1 | PixelLab castle stone reference candidate |
| `assets/sprites/town/buildings/castle_wall_tower_construction_pixellab.png` | 192x192 | 1 | PixelLab castle wall and tower reference sheet |
| `assets/sprites/town/buildings/log_cabin_construction_tiles_pixellab.png` | 128x128 | 1 | PixelLab log cabin construction reference candidate |
| `assets/sprites/town/buildings/castle_construction_tiles_pixellab.png` | 128x128 | 1 | PixelLab castle construction reference candidate |
| `assets/sprites/town/buildings/log_building_runtime_reference.png` | 256x256 | 1 | PixelLab log building runtime reference sheet |
| `assets/sprites/town/buildings/castle_runtime_reference.png` | 256x256 | 1 | PixelLab castle runtime reference sheet |
| `assets/sprites/town/buildings/log_cabin_true_modular_tiles_pixellab.png` | 128x128 | 1 | PixelLab log cabin reference candidate |
| `assets/sprites/town/buildings/castle_true_modular_tiles_pixellab.png` | 128x128 | 1 | PixelLab castle reference candidate |
| `assets/sprites/town/props/castle_dungeon_exterior_props.png` | 128x128 | 1 | PixelLab castle/dungeon prop candidate |
| `assets/sprites/town/props/log_village_props.png` | 128x128 | 1 | PixelLab log village prop sheet |
| `assets/sprites/town/buildings/fortress_village_transition_kit.png` | 128x128 | 1 | PixelLab fortress/village transition kit |
| `assets/sprites/town/buildings/castle_doorway_kit.png` | 128x128 | 1 | PixelLab castle doorway kit |
| `assets/sprites/town/buildings/log_cabin_doorway_kit.png` | 128x128 | 1 | PixelLab log cabin doorway/interior reference |
| `assets/sprites/town/buildings/log_wall_true_tile_atlas_pixellab.png` | 128x128 | 1 | PixelLab log wall tile reference sheet |
| `assets/sprites/town/buildings/castle_wall_true_tile_atlas_pixellab.png` | 128x128 | 1 | PixelLab castle wall reference candidate |
| `assets/sprites/town/props/castle_courtyard_props.png` | 128x128 | 1 | PixelLab castle courtyard prop sheet |
| `assets/sprites/town/props/woodland_log_village_decorations.png` | 128x128 | 1 | PixelLab woodland log village decoration candidate |
| `assets/sprites/town/buildings/practical_castle_kit_reference.png` | 192x192 | 1 | PixelLab practical castle kit reference |
| `assets/sprites/town/buildings/practical_log_kit_reference.png` | 192x192 | 1 | PixelLab practical log kit reference |
| `assets/sprites/town/ground/castle_log_ground_transitions.png` | 128x128 | 1 | PixelLab castle/log ground transition sheet |
| `assets/sprites/town/buildings/castle_gate_expansion_sheet.png` | 192x192 | 1 | PixelLab castle gate expansion sheet |
| `assets/sprites/town/buildings/log_roof_wall_expansion_sheet.png` | 192x192 | 1 | PixelLab log roof/wall expansion candidate |
| `assets/sprites/town/props/fortified_village_palisade_kit.png` | 128x128 | 1 | PixelLab fortified village palisade kit |
| `assets/sprites/town/props/castle_settlement_final_props.png` | 128x128 | 1 | PixelLab castle settlement final prop pack |
| `assets/sprites/town/props/log_settlement_final_props.png` | 128x128 | 1 | PixelLab log settlement final prop pack |
| `assets/sprites/town/ground/castle_wall_damage_moss_decals.png` | 128x128 | 1 | PixelLab castle wall damage/moss decal candidate |
| `assets/sprites/town/buildings/clean_log_cabin_modular_atlas.png` | 128x128 | 1 | PixelLab clean log cabin reference candidate |
| `assets/sprites/town/buildings/clean_castle_modular_atlas.png` | 128x128 | 1 | PixelLab clean castle tower reference candidate |
| `assets/sprites/town/props/warm_shopfront_modular_detail_atlas.png` | 128x128 | 1 | PixelLab warm shopfront reference candidate |
| `assets/sprites/town/buildings/castle_village_entrance_gate_kit.png` | 128x128 | 1 | PixelLab castle village entrance/gate reference kit |
| `assets/sprites/town/buildings/ultra_strict_log_module_grid.png` | 128x128 | 1 | PixelLab compact log house reference candidate |
| `assets/sprites/town/buildings/ultra_strict_castle_module_grid.png` | 128x128 | 1 | PixelLab small castle/courtyard reference candidate |
| `assets/sprites/town/ground/modular_exterior_doorway_threshold_kit.png` | 128x128 | 1 | PixelLab sparse exterior doorway threshold candidate |
| `assets/sprites/town/props/rustic_castle_town_connective_props.png` | 128x128 | 1 | PixelLab rustic castle-town connective prop sheet |
| `assets/sprites/town/buildings/separate_log_material_swatch_strip.png` | 128x128 | 1 | PixelLab log cabin reference candidate |
| `assets/sprites/town/buildings/separate_castle_material_swatch_strip.png` | 128x128 | 1 | PixelLab sparse castle material reference candidate |
| `assets/sprites/town/props/brindlewick_plaza_micro_props.png` | 128x128 | 1 | PixelLab Brindlewick plaza micro props |
| `assets/sprites/town/props/castle_town_wall_cap_fence_details.png` | 128x128 | 1 | PixelLab castle town wall cap/fence details |
| `assets/sprites/town/buildings/modular_log_facade_pieces.png` | 160x160 | 1 | PixelLab modular stone/ruin reference candidate |
| `assets/sprites/town/buildings/modular_castle_facade_pieces.png` | 160x160 | 1 | PixelLab modular castle/stone reference candidate |
| `assets/sprites/town/props/inn_tavern_exterior_detail_kit.png` | 128x128 | 1 | PixelLab sparse inn/tavern exterior detail candidate |
| `assets/sprites/town/props/healer_chapel_workshop_detail_kit.png` | 128x128 | 1 | PixelLab sparse healer/chapel/workshop detail candidate |
| `assets/sprites/town/buildings/log_workshop_building_parts.png` | 160x160 | 1 | PixelLab log workshop building parts/reference |
| `assets/sprites/town/buildings/castle_tower_wall_parts.png` | 160x160 | 1 | PixelLab castle tower and wall reference |
| `assets/sprites/town/buildings/town_roof_variant_modules.png` | 128x128 | 1 | PixelLab sparse roof/house reference candidate |
| `assets/sprites/town/buildings/town_door_window_variant_modules.png` | 128x128 | 1 | PixelLab town door/window variant modules |
| `assets/sprites/town/buildings/residential_wall_kit.png` | 160x160 | 1 | PixelLab residential facade reference candidate |
| `assets/sprites/town/buildings/public_hall_facade_kit.png` | 160x160 | 1 | PixelLab public hall/shop facade reference candidate |
| `assets/sprites/town/ground/castle_courtyard_ground_details.png` | 128x128 | 1 | PixelLab castle courtyard ground reference candidate |
| `assets/sprites/town/ground/log_village_ground_details.png` | 128x128 | 1 | PixelLab sparse log village ground detail candidate |
| `assets/sprites/town/buildings/shop_wall_kit.png` | 160x160 | 1 | PixelLab lanternlit shop reference candidate |
| `assets/sprites/town/buildings/castle_gatehouse_polish_kit.png` | 160x160 | 1 | PixelLab compact castle gatehouse reference candidate |
| `assets/sprites/town/ground/town_plaza_transition_curb_kit.png` | 128x128 | 1 | PixelLab sparse town plaza transition/curb candidate |
| `assets/sprites/town/props/warm_town_night_accent_overlay_kit.png` | 128x128 | 1 | PixelLab warm town night reference candidate |
| `assets/sprites/town/props/market_stall_modular_kit.png` | 128x128 | 1 | PixelLab market stall reference candidate |
| `assets/sprites/town/buildings/castle_village_service_buildings_reference.png` | 192x192 | 1 | PixelLab castle village service buildings reference |
| `assets/sprites/town/buildings/log_village_service_buildings_reference.png` | 192x192 | 1 | PixelLab log village service buildings reference |
| `assets/sprites/town/props/final_town_furnishing_fill_sheet.png` | 128x128 | 1 | PixelLab sparse town furnishing candidate |
| `assets/sprites/town/props/final_coherent_brindlewick_block_reference.png` | 192x192 | 1 | PixelLab final coherent Brindlewick block reference |
| `assets/sprites/town/buildings/final_castle_approach_reference.png` | 192x192 | 1 | PixelLab final castle approach reference |
| `assets/sprites/town/buildings/final_log_hamlet_reference.png` | 192x192 | 1 | PixelLab final log hamlet reference |
| `assets/sprites/town/props/town_shop_icon_plaque_final_sheet.png` | 128x128 | 1 | PixelLab sparse town shop icon plaque candidate |
| `assets/sprites/town/ground/final_brindlewick_street_edge_kit.png` | 128x128 | 1 | PixelLab final Brindlewick street edge reference candidate |
| `assets/sprites/town/props/final_castle_modular_prop_cleanup.png` | 128x128 | 1 | PixelLab final castle modular prop cleanup |
| `assets/sprites/town/props/final_log_village_modular_prop_cleanup.png` | 128x128 | 1 | PixelLab sparse final log village prop candidate |
| `assets/sprites/town/ground/final_building_threshold_shadow_kit.png` | 128x128 | 1 | PixelLab final building threshold shadow reference |
| `assets/sprites/town/props/morning_handoff_town_kit_summary_reference.png` | 192x192 | 1 | PixelLab morning handoff town kit summary reference |
| `assets/sprites/town/props/final_no_text_service_sign_retry_sheet.png` | 128x128 | 1 | PixelLab sparse final no-text service sign candidate |
| `assets/sprites/town/ground/final_coastal_town_bridge_kit.png` | 128x128 | 1 | PixelLab final coastal town bridge reference |
| `assets/sprites/town/props/final_doorway_dressing_props.png` | 128x128 | 1 | PixelLab final doorway dressing props |
| `assets/sprites/town/props/final_morning_brindlewick_missing_bits.png` | 128x128 | 1 | PixelLab final morning Brindlewick missing bits |
| `assets/sprites/town/props/final_morning_castle_missing_bits.png` | 128x128 | 1 | PixelLab final morning castle missing bits |
| `assets/sprites/town/props/final_morning_log_hamlet_missing_bits.png` | 128x128 | 1 | PixelLab sparse final morning log hamlet candidate |
| `assets/sprites/town/ground/final_walkable_threshold_tile_cleanup.png` | 128x128 | 1 | PixelLab sparse final walkable threshold candidate |
| `assets/sprites/town/props/sunrise_brindlewick_polish_reference.png` | 192x192 | 1 | PixelLab sunrise Brindlewick polish reference |
| `assets/sprites/town/buildings/sunrise_castle_kit_polish_reference.png` | 192x192 | 1 | PixelLab sunrise castle kit polish reference |
| `assets/sprites/town/buildings/sunrise_log_hamlet_kit_polish_reference.png` | 192x192 | 1 | PixelLab sunrise log hamlet kit polish reference |
| `assets/sprites/ui/icons/town_item_icons_pixellab.png` | 128x128 | 1 | PixelLab sparse tiny UI town item icon candidate |
| `assets/sprites/town/props/breakfast_brindlewick_garden_yard_props.png` | 128x128 | 1 | Pending PixelLab breakfast Brindlewick garden yard props |
| `assets/sprites/town/buildings/breakfast_castle_wall_trim_modules.png` | 128x128 | 1 | Pending PixelLab breakfast castle wall trim modules |
| `assets/sprites/town/buildings/breakfast_log_wall_trim_modules.png` | 128x128 | 1 | Pending PixelLab breakfast log wall trim modules |
| `assets/sprites/ui/icons/town_item_icons_retry_pixellab.png` | 128x128 | 1 | Pending PixelLab breakfast UI item icon retry sheet |
| `assets/sprites/town/buildings/roof_blocks_candidate.png` | 128x128 | 1 | PixelLab roof/building style reference; not final modular sheet |
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

Rebuild the modular Brindlewick building atlas used by `scripts/town.gd` with:

```powershell
python scripts/dev/build_town_modular_building_atlas.py
```

## Town Ground Kit

| File | Size | Frames | Notes |
|---|---|---|---|
| `assets/sprites/town/ground/cobblestone_plaza.png` | 96x96 | 1 | PixelLab cobblestone plaza tile variants |
| `assets/sprites/town/ground/packed_dirt_road.png` | 96x96 | 1 | PixelLab packed dirt road tile variants |
| `assets/sprites/town/ground/stone_path_border.png` | 128x128 | 1 | PixelLab stone path border and corner sheet |
| `assets/sprites/town/ground/stone_street_blocks.png` | 128x128 | 1 | PixelLab blue-gray street, curb, cracked stone, and plaza edge modules |
| `assets/sprites/town/ground/raised_grass_plaza.png` | 128x128 | 1 | PixelLab raised grass island, curb, shrub, and connector modules |
| `assets/sprites/town/ground/plaza_edge_corners.png` | 128x128 | 1 | PixelLab blue-gray plaza edge, corner, curb, and crack modules |
| `assets/sprites/town/ground/stairs_curb_connectors.png` | 128x128 | 1 | Pending PixelLab stone stairs, curb breaks, plank thresholds, and connector pieces |
| `assets/sprites/town/ground/canal_stone_edges.png` | 128x128 | 1 | PixelLab town canal water and stone embankment edge sheet |
| `assets/sprites/town/ground/bridge_plank_connectors.png` | 128x128 | 1 | PixelLab wooden bridge, stone lip, rail, end cap, and shadow sheet |
| `assets/sprites/town/ground/foundation_shadows.png` | 128x128 | 1 | PixelLab building foundation, moss trim, and shadow modules |
| `assets/sprites/town/ground/street_clutter_decals.png` | 128x128 | 1 | Pending PixelLab street clutter decal sheet |

## Town Props

| File | Size | Frames | Notes |
|---|---|---|---|
| `assets/sprites/town/props/lantern_post.png` | 32×32 | 1 | PixelLab brass lantern post |
| `assets/sprites/town/props/signpost.png` | 32x32 | 1 | PixelLab blank wooden signpost |
| `assets/sprites/town/props/fence_pieces.png` | 128x128 | 1 | PixelLab modular wooden fence sheet |
| `assets/sprites/town/props/market_props.png` | 128x128 | 1 | PixelLab market props sheet |
| `assets/sprites/town/props/shrub_planters.png` | 128x128 | 1 | PixelLab shrub and planter sheet |
| `assets/sprites/town/props/lantern_details.png` | 128x128 | 1 | PixelLab lantern and street detail sheet |
| `assets/sprites/town/props/shop_awning_banners.png` | 128x128 | 1 | Pending PixelLab awning, blank sign, and icon plaque sheet |
| `assets/sprites/town/props/plaza_centerpieces.png` | 128x128 | 1 | PixelLab plaza centerpiece prop sheet |
| `assets/sprites/town/buildings/doorway_shop_details.png` | 128x128 | 1 | PixelLab doorway, stoop, blank sign, and icon plaque sheet |
| `assets/sprites/town/props/plaza_layout_mockup.png` | 192x192 | 1 | Pending PixelLab reference-only plaza composition mockup |
| `assets/sprites/town/props/well.png` | 48×48 | 1 | PixelLab stone well |
| `assets/sprites/town/props/notice_board.png` | 32×32 | 1 | PixelLab notice board |
| `assets/sprites/town/props/crate_stack.png` | 32×32 | 1 | PixelLab crate stack |
| `assets/sprites/town/props/barrel_pair.png` | 32×32 | 1 | PixelLab barrel pair |
| `assets/sprites/town/props/bench.png` | 40×40 | 1 | PixelLab bench |
| `assets/sprites/town/props/flower_box.png` | 32×32 | 1 | PixelLab flower box |
| `assets/sprites/town/props/herb_planter.png` | 32×32 | 1 | PixelLab herb planter |
| `assets/sprites/town/props/breakfast_brindlewick_garden_yard_props.png` | 128x128 | 1 | PixelLab garden/raised grass candidate; prompt produced a single useful swatch instead of a full prop sheet |
| `assets/sprites/town/buildings/breakfast_castle_wall_trim_modules.png` | 128x128 | 1 | PixelLab castle gatehouse/trim reference with battlements, arched door, and stone palette |
| `assets/sprites/town/buildings/breakfast_log_wall_trim_modules.png` | 128x128 | 1 | PixelLab log cabin/shop trim reference with log walls, doorway, window, and foundation language |
| `assets/sprites/ui/icons/town_item_icons_retry_pixellab.png` | 128x128 | 1 | PixelLab town item icon sheet with readable small inventory candidates |
| `assets/sprites/town/props/late_morning_brindlewick_entry_gate_fence_polish.png` | 128x128 | 1 | PixelLab assembled Brindlewick gate/fence reference with threshold and lantern language |
| `assets/sprites/town/buildings/late_morning_castle_courtyard_transition_reference.png` | 128x128 | 1 | PixelLab compact castle chapel/gatehouse reference with arched entry and courtyard threshold |
| `assets/sprites/town/props/late_morning_log_village_workyard_reference.png` | 128x128 | 1 | PixelLab sparse log workyard candidate with stacked log prop and ground swatch |
| `assets/sprites/ui/icons/ui_material_tiny_icon_cleanup_pixellab.png` | 128x128 | 1 | PixelLab tiny material icon sheet for wood, stone, ore, herb, tools, and small item candidates |
| `assets/sprites/town/buildings/midday_modular_brindlewick_house_facade_parts.png` | 128x128 | 1 | PixelLab Brindlewick house reference used for curated building palette/proportions |
| `assets/sprites/town/buildings/midday_modular_castle_wall_tower_parts.png` | 128x128 | 1 | PixelLab compact castle wall/tower reference used for castle palette and wall depth |
| `assets/sprites/town/buildings/midday_modular_log_cabin_facade_parts.png` | 128x128 | 1 | PixelLab log cabin mixed module/reference sheet with separable doors, posts, and props |
| `assets/sprites/town/ground/midday_town_foundation_doorstep_tile_modules.png` | 128x128 | 1 | PixelLab foundation/plaza candidate; useful as material reference rather than a strict module sheet |
| `assets/sprites/town/buildings/curated_modular_extraction_helper_sheet.png` | 128x128 | 1 | PixelLab sparse Brindlewick helper sheet with sign/plaque, door, and ornament candidates |
| `assets/sprites/town/buildings/curated_castle_extraction_helper_sheet.png` | 128x128 | 1 | PixelLab sparse castle helper sheet with small pillar/stone post candidates |
| `assets/sprites/town/buildings/curated_log_extraction_helper_sheet.png` | 128x128 | 1 | PixelLab compact log/thatched facade cap candidate sheet |
| `assets/sprites/town/props/curated_town_prop_extraction_helper_sheet.png` | 128x128 | 1 | PixelLab useful town prop sheet with barrels, bench, lanterns, planters, fences, signs, bucket, and woodpile candidates |

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
