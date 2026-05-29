# Visual QA Workflow

Use this workflow whenever a change needs screenshot-grounded review instead of only console smoke tests. The goal is to verify the actual rendered scene before committing art, layout, HUD, or worldbuilding changes.

## Preferred Command

Use the wrapper script from the repo root:

```bash
scripts/dev/capture_visual_qa.sh town
scripts/dev/capture_visual_qa.sh town overworld battle
scripts/dev/capture_visual_qa.sh --all
```

By default it captures `town`, `overworld`, and `battle` into:

```text
artifacts/screenshots/visual_qa_YYYYMMDD_HHMMSS/
```

For each target it writes:

```text
<target>.png      rendered screenshot
<target>.json     capture manifest: target, scene, output, image size, main scene
<target>.log      Godot capture log with VISUAL_SCENE_CAPTURE_OK confirmation
```

Artifacts under `artifacts/screenshots/` are intentionally ignored by git.

## Why This Wrapper Exists

Do not rely on generic project/movie capture for scene QA. `project.godot` currently launches the title screen:

```text
run/main_scene="res://scenes/title/title.tscn"
```

A generic capture may produce a perfect title-screen screenshot when you meant to review Brindlewick. This happened once during the first worldbuilding pass. The wrapper prevents that by targeting named scenes and verifying the capture log contains the expected target.

## Targeted Harness Command

The wrapper calls the permanent Godot harness directly:

```bash
xvfb-run -a -s "-screen 0 1280x720x24" \
  "${GODOT_BIN:-$HOME/.local/bin/godot}" --rendering-driver opengl3 --audio-driver Dummy --path . \
  scenes/dev/visual_scene_capture.tscn -- \
  --target town \
  --output artifacts/screenshots/town.png \
  --manifest artifacts/screenshots/town.json \
  --frames 12
```

Known targets:

```text
town
overworld
battle
home
cave
dock
forest_clearing
```

Options accepted by `visual_scene_capture.tscn`:

| Option | Default | Notes |
|---|---|---|
| `--target` | `town` | Named target from the harness. Unknown targets fail fast. |
| `--scene` | target scene | Direct scene path override, e.g. `res://scenes/town/town.tscn`. |
| `--output` | `artifacts/screenshots/<target>.png` | Screenshot path. |
| `--manifest` | `<output basename>.json` | JSON proof of target, scene, image dimensions, and main scene. |
| `--frames` | `8` | Process frames to wait before capture. Increase for animation, deferred loading, particles, or UI that appears after timers. |

Wrapper-only options:

| Option | Default | Notes |
|---|---|---|
| `--all` | off | Capture all known targets. |
| `--output-dir DIR` | timestamped visual QA dir | Batch output directory. |
| `--frames N` | `12` | Passed to each target. |
| `--width N` / `--height N` | `1280` / `720` | Xvfb screen size. |
| `--godot PATH` | `$GODOT_BIN`, `~/.local/bin/godot`, `godot`, `~/.local/bin/godot4`, then `godot4` | Override Godot binary. |

## Required Review Loop

1. Capture the before screenshot for the scene you plan to modify.
2. Ask the visual reviewer to first identify the screenshot.
   - If the screenshot is not the intended scene, stop and recapture.
3. Implement one small visual pass.
4. Capture after screenshots with `scripts/dev/capture_visual_qa.sh`.
5. Visual-review the after screenshot.
6. If the reviewer says FAIL, fix or roll back the specific visual experiment.
7. Re-capture and review until the screenshot passes.
8. Run Godot parse/import validation.
9. Clean unintentional generated files before commit.
10. Commit source files and intentional assets only.

## Visual Reviewer Prompt Template

Use a prompt like this with the screenshot:

```text
First identify what scene this screenshot shows. If it is not <expected target>, say WRONG_SCENE and stop.

Then visually QA this <expected target> screenshot for a Dragon Warrior / Final Fantasy inspired 16-bit JRPG.
Give PASS/FAIL for:
- critical regressions
- UI readability
- focal point / scene life
- ground/path detail
- prop/building grounding
- character/NPC readability
- style consistency

List blocking fixes first. Non-blocking priorities last.
```

## Godot / Headless Pitfalls

- Use `xvfb-run`; do not use `--headless` for screenshot capture. Headless mode can skip real rendered frames.
- Use `--rendering-driver opengl3` for Xvfb capture. It is more reliable than Vulkan/lavapipe in this workflow.
- Use `--audio-driver Dummy` to avoid ALSA noise in logs.
- Use named targets or `--scene`; do not capture the project main scene unless you intentionally want the title screen.
- Unknown `--target` values fail fast. This prevents silently reviewing the wrong scene.

## Terrain Checks

When changing town ground/path art, capture the town and inspect:

1. Path cells should read as walkable dirt, not a wall, river, or void.
2. Grass-to-dirt edges should be soft enough for village paths unless a raised curb is intentional.
3. Plain grass should keep texture variation and should not become a flat color field.
4. Door thresholds should still visibly connect to nearby paths.
5. UI guidance text should remain readable over busy roofs or ground tiles.

Avoid procedural path-edge overlays unless they pass screenshot QA. A previous overlay looked plausible in code but created a repeating picket-fence artifact in-game. Prefer proper terrain/autotile edge assets for final path transitions.

## Development Loop Summary

```bash
# Before
scripts/dev/capture_visual_qa.sh town --output-dir artifacts/screenshots/before_town

# Implement visual pass...

# After
scripts/dev/capture_visual_qa.sh town --output-dir artifacts/screenshots/after_town

# Validate code/imports
"${GODOT_BIN:-$HOME/.local/bin/godot}" --headless --audio-driver Dummy --quit --path .
xvfb-run -a "${GODOT_BIN:-$HOME/.local/bin/godot}" --headless --audio-driver Dummy --import --quit --path .

git status --short
```
