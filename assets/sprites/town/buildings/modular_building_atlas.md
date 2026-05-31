# Modular Building Atlas

Curated from PixelLab town construction outputs. Tile IDs match `scripts/town.gd`.

| Tile | Rect | Source |
|---|---|---|
| `roof_left` | `0,0,16,16` | red-clay residential reset palette from `small_house_direction_preview.png` + `roof_tileset.png` |
| `roof_mid` | `16,0,16,16` | red-clay residential reset palette from `small_house_direction_preview.png` + `roof_tileset.png` |
| `roof_right` | `32,0,16,16` | red-clay residential reset palette from `small_house_direction_preview.png` + `roof_tileset.png` |
| `roof_ridge` | `48,0,16,16` | red-clay front gable/attic tile for the single-door cottage read |
| `roof_eave` | `64,0,16,16` | red-clay eave and under-roof shadow band |
| `roof_moss` | `80,0,16,16` | red-clay alternate/weathered roof tile |
| `chimney` | `96,0,16,16` | red-brown brick chimney matched to the reset palette |
| `blank` | `112,0,16,16` | transparent blank |
| `wall` | `0,16,16,16` | assets/sprites/town/buildings/final_building_tile_cohesion.png cell 4,3 |
| `wall_timber` | `16,16,16,16` | assets/sprites/town/buildings/final_building_tile_cohesion.png cell 5,3 |
| `wall_brace` | `32,16,16,16` | assets/sprites/town/buildings/final_building_tile_cohesion.png cell 3,3 |
| `wall_shadow` | `48,16,16,16` | assets/sprites/town/buildings/final_building_tile_cohesion.png cell 4,3 shadow mask |
| `foundation` | `64,16,16,16` | assets/sprites/town/buildings/final_building_tile_cohesion.png cell 3,5 |
| `foundation_moss` | `80,16,16,16` | assets/sprites/town/buildings/final_building_tile_cohesion.png cell 4,5 |
| `foundation_shadow` | `96,16,16,16` | assets/sprites/town/buildings/final_building_tile_cohesion.png cell 3,5 shadow mask |
| `threshold` | `112,16,16,16` | assets/sprites/town/buildings/final_building_tile_cohesion.png cell 5,5 |
| `door` | `0,32,16,16` | assets/sprites/town/buildings/window_door_tiles_expanded.png palette-inspired composed door |
| `door_open` | `16,32,16,16` | assets/sprites/town/buildings/window_door_tiles_expanded.png palette-inspired composed open door |
| `window` | `32,32,16,16` | assets/sprites/town/buildings/window_door_tiles_expanded.png palette-inspired composed square window |
| `window_arch` | `48,32,16,16` | assets/sprites/town/buildings/window_door_tiles_expanded.png palette-inspired composed arched window |
| `window_flower` | `64,32,16,16` | assets/sprites/town/buildings/window_door_tiles_expanded.png palette-inspired composed arched window |
| `plaque_blank` | `80,32,16,16` | assets/sprites/town/buildings/blank_sign_boards.png palette-inspired composed blank plaque |
| `lantern` | `96,32,16,16` | hand-composed from PixelLab lantern palette |
| `flower_box` | `112,32,16,16` | assets/sprites/town/buildings/window_door_tiles_expanded.png palette-inspired composed flower box |
| `plaque_sword` | `0,48,16,16` | assets/sprites/town/buildings/isolated_shop_symbols_retry.png sword on curated plaque |
| `plaque_shield` | `16,48,16,16` | assets/sprites/town/buildings/isolated_shop_symbols_retry.png shield on curated plaque |
| `plaque_tankard` | `32,48,16,16` | assets/sprites/town/buildings/isolated_shop_symbols_retry.png tankard on curated plaque |
| `plaque_gear` | `48,48,16,16` | assets/sprites/town/buildings/isolated_shop_symbols_retry.png gear on curated plaque |
| `plaque_bed` | `64,48,16,16` | assets/sprites/town/buildings/isolated_shop_symbols_retry.png bed on curated plaque |
| `plaque_candle` | `80,48,16,16` | assets/sprites/town/buildings/isolated_shop_symbols_retry.png candle on curated plaque |

## Small House Direction Reset

The previous green-roof `small_house.png` direction is not the production target. The visual target for the rebuilt Brindlewick small house is the top-left cottage in `final_residential_buildings.png`, with a simpler, more coherent single-entrance read.

### House recipe
- Footprint: approx. 5x4 base tiles with roof overhang
- Perspective: 3/4 JRPG, south-facing facade
- Roof family: use the red-clay runtime `modular_building_atlas.png` family rebuilt from this direction; treat the old green family as rejected for the Brindlewick small house
- Walls: cream plaster, dark timber trim, small side windows, one obvious front door
- Foundation: cool gray stone apron with a visible contact shadow
- Grounding: a single threshold/stoop tile and a short shadow band under the eaves

### Recommended module usage
- Roof: `roof_left`, `roof_mid`, `roof_right`, `roof_ridge`, `roof_eave`
- Structure: `wall`, `wall_timber`, `wall_shadow`, `foundation`, `threshold`
- Openings: `door`, `window`, `window_arch`, `flower_box` only where it reinforces the single-front-door read

### What to avoid
- No second door read or shopfront ambiguity
- No pasted collage layers or floating roof/wall pieces
- No bright green roof as the default Brindlewick residential direction
- No extra ornament that competes with the main entrance

### Godot integration note
Use `small_house_direction_preview.png` as the art-direction reference while the runtime house is assembled from reusable modules. The preview is not a replacement for the modular kit; it is the coherence target for the kit.
