# PixelLab Town Building Module Prompt Log

This log records the prompts used to create the PixelLab module sheets behind
`assets/sprites/town/buildings/modular_building_atlas_v2.png`. The canonical
asset-local prompt log is
`assets/sprites/town/buildings/pixellab_candidates/PROMPTS.md`.

The goal is to learn which prompts produce usable reusable building modules for
Lanternhouse. The runtime rule is strict: no single-building sprites, no
standalone facade sprites, and no complete assembled buildings. The town
renderer should compose buildings from reusable 16x16 roof, wall, foundation,
door, window, plaque, trim, and detail modules.

## Shared Settings

All prompts below used PixelLab `create_tiles_pro` with:

```text
tile_type: square_topdown
tile_view: top-down
tile_size: 16
outline_mode: segmentation
```

## Evaluation Notes

What worked:

- Focused 16-item prompts worked better than one large all-in-one prompt.
- Repeating "reusable separated modules only" and "no complete building sprites" helped keep outputs modular.
- The detail and forge sheets produced strong separated doors, windows, plaques, lanterns, forge walls, and workshop props.
- Keeping PixelLab source tiles under `assets/sprites/town/buildings/pixellab_candidates/` makes the runtime atlas reproducible.

What did not work:

- The first 48-item prompt only produced 16 variations, so it could not cover the requested module set.
- Structure prompts can still drift into larger roof chunks or partial assembled pieces; select tiles manually instead of accepting the whole sheet.
- One overloaded prompt is harder to evaluate because failures mix coverage, style, and modularity problems together.

Next prompt experiments:

- Split roof edges, corners, caps, moss, dormers, and chimneys into their own sheet.
- Split wall/foundation/threshold pieces into their own sheet.
- Generate a dedicated trim/decal sheet for cracks, soot, moss, roof chips, beam caps, and corner posts.
- Try style-reference chaining from the accepted detail sheet if PixelLab supports `style_images` cleanly for this use case.

## Prompt 0: All-In-One Module Attempt

Result:

- PixelLab job: `6ecafce8-0a67-4177-8f1f-0e95f39bed51`
- Seed: `6202026`
- Output: completed, 16 variations.
- Evaluation: good style direction and modular enough, but failed coverage because the prompt asked for 48 modules and PixelLab returned 16 tiles. Kept only as a learning reference, not as runtime source.

Prompt:

```text
Modern 16-bit JRPG modular town building construction tiles for Lanternhouse, high quality pixel art, crisp pixel-perfect clusters, 1px selective dark outlines, top-down 3/4 RPG facade language on a rectangular 16x16 grid. IMPORTANT: create reusable separated modules only, no complete building sprites, no standalone house/shop facade, no assembled buildings, no text, no letters, no signs with words, no isometric diamond perspective, no 3D render, no antialiasing, no smooth gradients. Transparent or clean isolated tile backgrounds. Numbered tiles: 1). red clay roof left edge module with tile rows 2). red clay roof middle module with tile rows 3). red clay roof right edge module with tile rows 4). red clay roof ridge cap module 5). red clay roof eave underside module 6). mossy red roof variant patch module 7). brick chimney module 8). blank transparent spacer 9). warm cream plaster wall fill tile 10). cream plaster wall with dark timber side posts 11). diagonal timber brace wall tile 12). shaded eave wall shadow tile 13). gray stone foundation block tile 14). mossy gray stone foundation tile 15). dark contact shadow foundation tile 16). stone doorstep threshold tile 17). wood plank door module centered 18). dark open doorway module 19). square warm window module 20). arched warm window module 21). window with flower box module 22). blank wooden plaque module, no text 23). hanging wall lantern module 24). flower box module 25). sword icon plaque module, no text 26). shield icon plaque module, no text 27). tankard icon plaque module, no text 28). gear icon plaque module, no text 29). bed icon plaque module, no text 30). candle or healer leaf icon plaque module, no text 31). forge dark metal roof left edge module 32). forge dark metal roof middle module 33). forge dark metal roof right edge module 34). forge metal eave underside module 35). forge chunky chimney module 36). forge tan stone wall fill module 37). forge wall with timber side posts 38). forge dark stone foundation module 39). forge double door left module 40). forge square window module 41). forge weapon rack module 42). forge anvil plaque module, no text 43). forge double door right module 44). plain timber beam trim horizontal module 45). stone corner post module 46). small roof corner cap module 47). tiny cracked plaster decal module 48). tiny roof weathering decal module
```

## Prompt 1: Roof, Wall, Foundation, Threshold

Result:

- PixelLab job: `144b6eec-4c16-41d0-b3ad-d5c8903eb34a`
- Seed: `6202027`
- Output: completed, 16 variations.
- Evaluation: usable but mixed. Roof texture, plaster, timber, stone foundation, mossy foundation, and threshold were good enough for first integration. Some roof pieces drifted toward larger assembled chunks, so the atlas selects specific tiles from the sheet.

Prompt:

```text
Modern 16-bit JRPG modular town building construction tiles for Lanternhouse. Create exactly reusable separated 16x16 building modules only, no complete building sprites, no standalone house/shop facade, no assembled buildings, no words or text, no isometric diamond perspective, no 3D render, no antialiasing, no smooth gradients. Match the quality of high-end SNES/PS1 JRPG pixel art: crisp pixel clusters, selective 1px dark outlines, warm red clay roofs, cream plaster walls, brown timber trim, blue-gray stone. Numbered tiles: 1). red clay roof left edge module with tile rows and dark left outline 2). red clay roof middle module with varied clay tile clusters 3). red clay roof right edge module with dark right outline 4). red clay roof ridge cap module 5). red clay eave underside module with timber shadow 6). mossy red roof patch module 7). red roof corner cap module 8). brick chimney module 9). warm cream plaster wall fill tile with subtle texture 10). cream plaster wall with dark timber side posts 11). diagonal timber brace wall tile 12). shaded eave wall shadow tile 13). gray stone foundation block tile 14). mossy gray stone foundation tile 15). dark contact shadow foundation tile 16). stone doorstep threshold tile
```

## Prompt 2: Doors, Windows, Plaques, Details

Result:

- PixelLab job: `e0e17ab4-d78f-4234-9e5c-3fd9ef6e746d`
- Seed: `6202028`
- Output: completed, 16 variations.
- Evaluation: strongest sheet of this pass. Doors, windows, plaques, flower box, and lantern are separated modules with no readable text. Plaque icons are usable for shop identity and better than procedural symbols.

Prompt:

```text
Modern 16-bit JRPG modular town building detail tiles for Lanternhouse. Reusable separated 16x16 modules only, no complete building sprites, no standalone facade, no assembled buildings, no text, no letters, no readable signs, no isometric diamond perspective, no 3D render, no antialiasing, no smooth gradients. Crisp pixel clusters, selective 1px dark outlines, warm cream plaster/timber material, no backgrounds beyond the tile module itself. Numbered tiles: 1). centered wood plank door module 2). dark open doorway module 3). double wood door left half module 4). double wood door right half module 5). square warm lit window module 6). arched warm lit window module 7). window with red flower box module 8). flower box module alone 9). blank wooden plaque board module with no text 10). sword icon plaque module no text 11). shield icon plaque module no text 12). tankard icon plaque module no text 13). gear icon plaque module no text 14). bed icon plaque module no text 15). candle or healer leaf icon plaque module no text 16). hanging wall lantern module
```

## Prompt 3: Forge And Workshop Modules

Result:

- PixelLab job: `edf0c894-c136-48b9-af70-6d16b5c7f886`
- Seed: `6202029`
- Output: completed, 16 variations.
- Evaluation: usable. The dark metal roof, forge wall, foundation, door, window, weapon rack, and anvil plaque read as workshop modules rather than a whole building. This sheet gave the weapon shop a stronger identity while preserving modular composition.

Prompt:

```text
Modern 16-bit JRPG modular forge and workshop building construction tiles for Lanternhouse. Reusable separated 16x16 modules only, no complete building sprites, no standalone facade, no assembled buildings, no text, no letters, no isometric diamond perspective, no 3D render, no antialiasing, no smooth gradients. Crisp pixel clusters, selective 1px dark outlines, dark metal roof, tan stone wall, brown timber, blue-gray stone, small warm ember accents. Numbered tiles: 1). dark metal forge roof left edge module 2). dark metal forge roof middle module 3). dark metal forge roof right edge module 4). forge metal eave underside module 5). chunky forge chimney module with ember detail 6). tan stone forge wall fill module 7). forge wall with timber side posts 8). forge dark stone foundation module 9). forge double wood door left module 10). forge double wood door right module 11). forge square warm window module 12). forge weapon rack module 13). forge anvil plaque module no text 14). plain horizontal timber beam trim module 15). stone corner post module 16). tiny soot and roof weathering decal module
```

## Runtime Selection

The selected tiles are recorded in:

```text
assets/sprites/town/buildings/modular_building_atlas_v2.json
```

The compositor that rebuilds the runtime atlas from PixelLab source tiles is:

```text
scripts/dev/build_town_modular_building_atlas.py
```

Rebuild with:

```powershell
python scripts/dev/build_town_modular_building_atlas.py
```
