# Visual QA Workflow

Use the visual scene capture harness when a change needs screenshot-based review
instead of only console smoke tests.

## Capture A Scene

```bash
xvfb-run -a godot --rendering-driver opengl3 --path . scenes/dev/visual_scene_capture.tscn -- --target town --output artifacts/screenshots/town.png
xvfb-run -a godot --rendering-driver opengl3 --path . scenes/dev/visual_scene_capture.tscn -- --target overworld --output artifacts/screenshots/overworld.png
xvfb-run -a godot --rendering-driver opengl3 --path . scenes/dev/visual_scene_capture.tscn -- --target battle --output artifacts/screenshots/battle.png
```

Screenshots are written relative to the repo unless an absolute, `res://`, or
`user://` path is provided. Generated screenshots under `artifacts/screenshots/`
are intentionally ignored by git.

Use `xvfb-run` for screenshots in WSL/headless Linux. Godot's `--headless`
display driver uses dummy textures, so viewport screenshot captures are empty.
The `opengl3` rendering driver avoids llvmpipe Vulkan crashes seen under Xvfb.

## Options

| Option | Default | Notes |
|---|---|---|
| `--target` | `town` | Named target from the harness: `town`, `overworld`, `battle`, `home`, `cave`, `dock`, `forest_clearing`. |
| `--scene` | Target scene | Direct scene path override, such as `res://scenes/town/town.tscn`. |
| `--output` | `artifacts/screenshots/<target>.png` | Screenshot path. |
| `--frames` | `8` | Number of process frames to wait before capture. Increase for animation, particles, or deferred loading. |

## Development Loop

1. Capture the scene screenshot.
2. Inspect the image for scale, layering, door alignment, prop placement, sprite readability, and tile seams.
3. Patch the relevant data or renderer code.
4. Rebuild generated art/layout previews when needed with `python scripts/dev/build_world_art.py`.
5. Capture again and compare.
6. Finish with the smallest relevant smoke tests.

For layout-only town previews, `python scripts/dev/build_world_art.py` also
renders schematic previews for every `assets/world/towns/*.layout.json` file.

## Terrain Checks

When changing town ground/path art, capture the town and inspect:

1. Path cells should read as walkable dirt, not a wall, river, or void.
2. Grass-to-dirt edges should be soft enough for village paths unless a raised
   curb is intentional.
3. Plain grass should keep texture variation and should not become a flat color
   field.
4. Door thresholds should still visibly connect to nearby paths.
5. UI guidance text should remain readable over busy roofs or ground tiles.

Current Brindlewick terrain integration can be checked with:

```bash
xvfb-run -a godot --rendering-driver opengl3 --path . scenes/dev/visual_scene_capture.tscn -- --target town --output artifacts/screenshots/town_wang_terrain.png
```
