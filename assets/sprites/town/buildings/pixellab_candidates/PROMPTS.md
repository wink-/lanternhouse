# PixelLab Building Module Prompts

This file records the exact PixelLab prompts submitted while building the
modular town-building component sheets in this folder.

Rule for this pass: these are reusable 16x16 component tiles only. Do not use
single-building sprites, standalone facades, or complete assembled buildings as
runtime town art.

## Shared PixelLab Settings

All jobs below used `create_tiles_pro` with:

```text
tile_type: square_topdown
tile_view: top-down
tile_size: 16
outline_mode: segmentation
```

## Job 6ecafce8

- Job id: `6ecafce8-0a67-4177-8f1f-0e95f39bed51`
- Seed: `6202026`
- Source directory: not retained
- Result: completed, 16 variations
- Use: rejected as runtime source because the prompt requested 48 items and
  PixelLab returned only 16 tiles.

Submitted prompt:

```text
Modern 16-bit JRPG modular town building construction tiles for Lanternhouse, high quality pixel art, crisp pixel-perfect clusters, 1px selective dark outlines, top-down 3/4 RPG facade language on a rectangular 16x16 grid. IMPORTANT: create reusable separated modules only, no complete building sprites, no standalone house/shop facade, no assembled buildings, no text, no letters, no signs with words, no isometric diamond perspective, no 3D render, no antialiasing, no smooth gradients. Transparent or clean isolated tile backgrounds. Numbered tiles: 1). red clay roof left edge module with tile rows 2). red clay roof middle module with tile rows 3). red clay roof right edge module with tile rows 4). red clay roof ridge cap module 5). red clay roof eave underside module 6). mossy red roof variant patch module 7). brick chimney module 8). blank transparent spacer 9). warm cream plaster wall fill tile 10). cream plaster wall with dark timber side posts 11). diagonal timber brace wall tile 12). shaded eave wall shadow tile 13). gray stone foundation block tile 14). mossy gray stone foundation tile 15). dark contact shadow foundation tile 16). stone doorstep threshold tile 17). wood plank door module centered 18). dark open doorway module 19). square warm window module 20). arched warm window module 21). window with flower box module 22). blank wooden plaque module, no text 23). hanging wall lantern module 24). flower box module 25). sword icon plaque module, no text 26). shield icon plaque module, no text 27). tankard icon plaque module, no text 28). gear icon plaque module, no text 29). bed icon plaque module, no text 30). candle or healer leaf icon plaque module, no text 31). forge dark metal roof left edge module 32). forge dark metal roof middle module 33). forge dark metal roof right edge module 34). forge metal eave underside module 35). forge chunky chimney module 36). forge tan stone wall fill module 37). forge wall with timber side posts 38). forge dark stone foundation module 39). forge double door left module 40). forge square window module 41). forge weapon rack module 42). forge anvil plaque module, no text 43). forge double door right module 44). plain timber beam trim horizontal module 45). stone corner post module 46). small roof corner cap module 47). tiny cracked plaster decal module 48). tiny roof weathering decal module
```

## Job 144b6eec

- Job id: `144b6eec-4c16-41d0-b3ad-d5c8903eb34a`
- Seed: `6202027`
- Source directory: `modular_tileset_144b6eec`
- Result: completed, 16 variations
- Use: accepted for selected roof, wall, foundation, chimney, and threshold
  modules.

Submitted prompt:

```text
Modern 16-bit JRPG modular town building construction tiles for Lanternhouse. Create exactly reusable separated 16x16 building modules only, no complete building sprites, no standalone house/shop facade, no assembled buildings, no words or text, no isometric diamond perspective, no 3D render, no antialiasing, no smooth gradients. Match the quality of high-end SNES/PS1 JRPG pixel art: crisp pixel clusters, selective 1px dark outlines, warm red clay roofs, cream plaster walls, brown timber trim, blue-gray stone. Numbered tiles: 1). red clay roof left edge module with tile rows and dark left outline 2). red clay roof middle module with varied clay tile clusters 3). red clay roof right edge module with dark right outline 4). red clay roof ridge cap module 5). red clay eave underside module with timber shadow 6). mossy red roof patch module 7). red roof corner cap module 8). brick chimney module 9). warm cream plaster wall fill tile with subtle texture 10). cream plaster wall with dark timber side posts 11). diagonal timber brace wall tile 12). shaded eave wall shadow tile 13). gray stone foundation block tile 14). mossy gray stone foundation tile 15). dark contact shadow foundation tile 16). stone doorstep threshold tile
```

## Job e0e17ab4

- Job id: `e0e17ab4-d78f-4234-9e5c-3fd9ef6e746d`
- Seed: `6202028`
- Source directory: `modular_tileset_e0e17ab4`
- Result: completed, 16 variations
- Use: accepted for selected doors, windows, plaques, lantern, and flower-box
  modules.

Submitted prompt:

```text
Modern 16-bit JRPG modular town building detail tiles for Lanternhouse. Reusable separated 16x16 modules only, no complete building sprites, no standalone facade, no assembled buildings, no text, no letters, no readable signs, no isometric diamond perspective, no 3D render, no antialiasing, no smooth gradients. Crisp pixel clusters, selective 1px dark outlines, warm cream plaster/timber material, no backgrounds beyond the tile module itself. Numbered tiles: 1). centered wood plank door module 2). dark open doorway module 3). double wood door left half module 4). double wood door right half module 5). square warm lit window module 6). arched warm lit window module 7). window with red flower box module 8). flower box module alone 9). blank wooden plaque board module with no text 10). sword icon plaque module no text 11). shield icon plaque module no text 12). tankard icon plaque module no text 13). gear icon plaque module no text 14). bed icon plaque module no text 15). candle or healer leaf icon plaque module no text 16). hanging wall lantern module
```

## Job edf0c894

- Job id: `edf0c894-c136-48b9-af70-6d16b5c7f886`
- Seed: `6202029`
- Source directory: `modular_tileset_edf0c894`
- Result: completed, 16 variations
- Use: accepted for selected forge roof, wall, door, window, weapon rack, and
  anvil-plaque modules.

Submitted prompt:

```text
Modern 16-bit JRPG modular forge and workshop building construction tiles for Lanternhouse. Reusable separated 16x16 modules only, no complete building sprites, no standalone facade, no assembled buildings, no text, no letters, no isometric diamond perspective, no 3D render, no antialiasing, no smooth gradients. Crisp pixel clusters, selective 1px dark outlines, dark metal roof, tan stone wall, brown timber, blue-gray stone, small warm ember accents. Numbered tiles: 1). dark metal forge roof left edge module 2). dark metal forge roof middle module 3). dark metal forge roof right edge module 4). forge metal eave underside module 5). chunky forge chimney module with ember detail 6). tan stone forge wall fill module 7). forge wall with timber side posts 8). forge dark stone foundation module 9). forge double wood door left module 10). forge double wood door right module 11). forge square warm window module 12). forge weapon rack module 13). forge anvil plaque module no text 14). plain horizontal timber beam trim module 15). stone corner post module 16). tiny soot and roof weathering decal module
```

## Evaluation Summary

- Focused 16-item prompts worked better than the first oversized 48-item prompt.
- The detail-sheet prompt was the strongest: it produced separated, readable
  doors, windows, plaques, and accessory modules with no baked-in text.
- The structure sheet needed manual tile selection because a few outputs drifted
  toward large roof chunks.
- The forge prompt worked because it stayed material-specific and listed
  separated workshop parts instead of asking for a shop sprite.
- The `3a488c08` wall/foundation sheet is the strongest sheet of the 6202030
  continuation pass.
- The `6dba82d7` shop-detail sheet has good icon plaque and awning candidates,
  with a few bottom-row dressing chunks to use selectively.
- The `c5b96b12` roof sheet has usable roof texture/trim pieces but still drifts
  into mini facade chunks; future roof prompts should be even stricter and
  material-only.
- The `3eb16325` filled roof swatch prompt is the best roof result so far:
  removing edges, eaves, gables, dormers, chimneys, transparency, and empty
  space produced a usable material sheet.
- The `style_images` experiment failed before queueing with a PixelLab image
  stream error, so the successful 6202030-6202032 jobs used normal shape mode.

## Failed Style Reference Attempt 6202030

- Seed: `6202030`
- Result: PixelLab rejected the request before queueing a job with
  `broken data stream when reading image file`.
- Use: not a generated source sheet, but useful prompt/process evidence. The
  same roof prompt was resubmitted without `style_images` as job `c5b96b12`.

Submitted prompt:

```text
Modern 16-bit JRPG modular red clay roof component tiles for Lanternhouse. Reusable separated 16x16 building modules only, no complete building sprites, no standalone facade, no assembled buildings, no full roofs, no text, no letters, no isometric diamond perspective, no 3D render, no antialiasing, no smooth gradients. Match the provided style references: crisp pixel clusters, selective 1px dark outlines, warm red clay, muted moss, blue-gray shadow accents, hand-placed pixel feel. Numbered tiles: 1). red clay roof center tile with varied clay shingles 2). red clay roof left edge tile with dark outer outline 3). red clay roof right edge tile with dark outer outline 4). red clay roof top ridge horizontal tile 5). ridge left end cap tile 6). ridge right end cap tile 7). lower eave underside tile with timber shadow 8). left eave corner cap tile 9). right eave corner cap tile 10). small triangular gable peak module 11). gable face timber trim module 12). small roof dormer module without full roof 13). brick chimney module 14). mossy roof patch module 15). chipped cracked roof tile decal module 16). dark roof cast-shadow strip module
```

## Job c5b96b12

- Job id: `c5b96b12-d4cd-46ed-a95b-cdd8cb97e5a8`
- Seed: `6202030`
- Source directory: `modular_tileset_c5b96b12`
- Result: completed, 16 variations
- Use: candidate roof, gable, chimney, moss, and roof-damage modules. Mixed
  result: some tiles are useful, while several drift into miniature facade
  chunks.

Submitted prompt:

```text
Modern 16-bit JRPG modular red clay roof component tiles for Lanternhouse. Reusable separated 16x16 building modules only, no complete building sprites, no standalone facade, no assembled buildings, no full roofs, no text, no letters, no isometric diamond perspective, no 3D render, no antialiasing, no smooth gradients. Match the current Brindlewick building atlas style: crisp pixel clusters, selective 1px dark outlines, warm red clay, muted moss, blue-gray shadow accents, hand-placed pixel feel. Numbered tiles: 1). red clay roof center tile with varied clay shingles 2). red clay roof left edge tile with dark outer outline 3). red clay roof right edge tile with dark outer outline 4). red clay roof top ridge horizontal tile 5). ridge left end cap tile 6). ridge right end cap tile 7). lower eave underside tile with timber shadow 8). left eave corner cap tile 9). right eave corner cap tile 10). small triangular gable peak module 11). gable face timber trim module 12). small roof dormer module without full roof 13). brick chimney module 14). mossy roof patch module 15). chipped cracked roof tile decal module 16). dark roof cast-shadow strip module
```

## Job 3a488c08

- Job id: `3a488c08-1b4e-4d15-8511-62ab9e80de28`
- Seed: `6202031`
- Source directory: `modular_tileset_3a488c08`
- Result: completed, 16 variations
- Use: accepted candidate plaster wall, timber, foundation, shadow, threshold,
  and stoop modules. Strongest sheet of this continuation pass.

Submitted prompt:

```text
Modern 16-bit JRPG modular plaster wall, timber, foundation, and threshold component tiles for Lanternhouse. Reusable separated 16x16 building modules only, no complete building sprites, no standalone facade, no assembled buildings, no full walls, no text, no letters, no isometric diamond perspective, no 3D render, no antialiasing, no smooth gradients. Match the current Brindlewick building atlas style: crisp pixel clusters, selective 1px dark outlines, warm cream plaster, dark brown timber, blue-gray stone, subtle age and moss. Numbered tiles: 1). plain cream plaster wall fill tile 2). cream plaster wall with light weathering clusters 3). cream plaster wall with left timber post 4). cream plaster wall with right timber post 5). vertical timber post tile 6). horizontal timber beam trim tile 7). diagonal timber brace rising tile 8). diagonal timber brace falling tile 9). dark eave shadow over wall tile 10). gray stone foundation center block tile 11). stone foundation left edge tile 12). stone foundation right edge tile 13). mossy stone foundation tile 14). dark contact shadow base strip tile 15). centered stone doorstep threshold tile 16). small two-step stone stoop module
```

## Job 6dba82d7

- Job id: `6dba82d7-aebe-4456-9805-bfd62c6a9d9e`
- Seed: `6202032`
- Source directory: `modular_tileset_6dba82d7`
- Result: completed, 16 variations
- Use: accepted candidate shop identity plaques, awnings, lanterns, flower box,
  crate, and small decal modules. Good sheet, with a few larger dressing chunks
  to use selectively.

Submitted prompt:

```text
Modern 16-bit JRPG modular shop identity and exterior detail component tiles for Lanternhouse town buildings. Reusable separated 16x16 building modules only, no complete building sprites, no standalone facade, no assembled buildings, no readable text, no letters, no words, no isometric diamond perspective, no 3D render, no antialiasing, no smooth gradients. Match the current Brindlewick building atlas style: crisp pixel clusters, selective 1px dark outlines, warm wood, cream plaster, muted red cloth, brass lantern glow, hand-placed pixel feel. Numbered tiles: 1). blank wooden hanging sign plaque no text 2). crossed swords icon plaque no text 3). shield icon plaque no text 4). hammer and tongs forge icon plaque no text 5). tankard icon plaque no text 6). bed icon plaque no text 7). candle healer icon plaque no text 8). book scroll elder hall icon plaque no text 9). hanging wall lantern module 10). unlit wall lantern module 11). red cloth awning left tile 12). red cloth awning middle tile 13). red cloth awning right tile 14). small flower box module 15). small barrel or crate exterior module 16). tiny moss crack soot decal module
```

## Job 453896c3

- Job id: `453896c3-883d-448f-9ef6-983a749c1c2b`
- Seed: `6202033`
- Source directory: `modular_tileset_453896c3`
- Result: completed, 16 variations
- Use: rejected as a replacement roof sheet. It reduced some prompt scope but
  still produced mini facade chunks, large dark bands, and an empty/transparent
  tile. Keep as learning evidence, not preferred runtime source.

Submitted prompt:

```text
Modern 16-bit JRPG pure red clay roof tile modules for Lanternhouse. Reusable separated 16x16 roof material modules only. No complete building sprites, no standalone facade, no assembled buildings, no walls, no doors, no windows, no gables, no dormers, no chimneys, no signs, no text, no letters, no props, no isometric diamond perspective, no 3D render, no antialiasing, no smooth gradients. Match the current Brindlewick building atlas style: crisp pixel clusters, selective 1px dark outlines only on tile edges where needed, warm red clay, muted moss, blue-gray underside shadows. Numbered tiles: 1). plain red clay roof center swatch with varied shingles 2). alternate red clay roof center swatch 3). red clay roof left edge swatch 4). red clay roof right edge swatch 5). horizontal roof ridge center swatch 6). roof ridge left end cap swatch 7). roof ridge right end cap swatch 8). lower eave strip swatch 9). eave left corner swatch 10). eave right corner swatch 11). dark wooden fascia underside swatch 12). dark roof cast shadow underside swatch 13). moss patch overlay for red roof 14). chipped roof tile decal 15). soot stain decal for roof 16). subtle rain wear streak decal for roof
```

## Job 3eb16325

- Job id: `3eb16325-6122-4b26-b807-d8d6ef000106`
- Seed: `6202034`
- Source directory: `modular_tileset_3eb16325`
- Result: completed, 16 variations
- Use: accepted as the preferred roof material sheet from this pass. This prompt
  avoided facade drift by asking only for filled roof texture swatches.

Submitted prompt:

```text
Modern 16-bit JRPG filled red clay roof texture swatches for Lanternhouse. Each tile must be a full 16x16 square filled entirely with red clay roof material. Reusable seamless-ish roof texture tiles only. No complete building sprites, no facade, no assembled buildings, no walls, no doors, no windows, no gables, no dormers, no chimneys, no signs, no props, no edges, no corners, no eaves, no black shadow bands, no transparent background, no empty space, no text, no letters, no isometric diamond perspective, no 3D render, no antialiasing, no smooth gradients. Crisp pixel clusters, hand-placed shingles, warm red and orange clay, subtle dark grout lines, a few muted moss pixels only where requested. Numbered tiles: 1). plain red clay shingle texture swatch 2). red clay shingle texture swatch alternate pattern 3). red clay shingle texture swatch darker rows 4). red clay shingle texture swatch lighter sun-worn rows 5). red clay shingle texture swatch with tiny chips 6). red clay shingle texture swatch with sparse moss flecks 7). red clay shingle texture swatch with diagonal age variation 8). red clay shingle texture swatch with dense small tiles 9). red clay shingle texture swatch with larger tile rows 10). red clay shingle texture swatch with old uneven rows 11). red clay shingle texture swatch with warm highlight clusters 12). red clay shingle texture swatch with cool shadow clusters 13). red clay shingle texture swatch with two small cracked tiles 14). red clay shingle texture swatch with subtle soot specks 15). red clay shingle texture swatch with muted moss seam 16). red clay shingle texture swatch clean base variant
```
