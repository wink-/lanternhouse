# Lanternhouse Autonomous Workflow

This is the standard loop for Lanternhouse art/worldbuilding and visual polish work. It turns “let the workflow happen” into a repeatable production gate.

## Golden Path

```text
preflight profile/tools
→ artist/integrator task in a worktree
→ screenshot capture
→ visual-reviewer task
→ fix loop if blocked
→ clean integration pass
→ merge scoped commit
```

## Before Dispatch: Preflight

Run this from the repo root before spawning workers:

```bash
scripts/dev/lanternhouse_workflow_preflight.py
```

It verifies:

- repo root and visual QA wrapper
- Godot executable
- `xvfb-run`
- `2d-game` kanban board access
- required worker profile skills:
  - `artist`: `lanternhouse-art-pipeline`, `lanternhouse-visual-polish`, `godot-headless-validation`
  - `visual-reviewer`: `lanternhouse-visual-polish`, `godot-headless-validation`

If this fails, fix the profile/tooling first. Do not dispatch and hope the worker recovers.

## Standard Visual Fix Pair

Use the helper to queue an artist task plus gated visual review task:

```bash
scripts/dev/queue_visual_fix_pair.py cave "gray render failure"
scripts/dev/queue_visual_fix_pair.py battle "replace cave_dungeon portal background"
scripts/dev/queue_visual_fix_pair.py home "interior appears tiny in frame"
scripts/dev/queue_visual_fix_pair.py forest_clearing "scene is too empty"
```

The helper:

- runs preflight
- creates an `artist` worktree task
- creates a child `visual-reviewer` worktree task
- forces the relevant skills into each worker
- uses idempotency keys so accidental reruns do not duplicate the same pair

## Task Contract

Every visual task should include:

- Goal: one scene/issue.
- Scope: what files/assets can change.
- Non-goals: what not to touch.
- Acceptance:
  - preflight passes
  - before screenshot captured
  - after screenshot captured
  - Godot parse/import smoke passes
  - relevant validators pass
  - intentional commit only
- Handoff:
  - changed files
  - commands run
  - screenshot artifact paths
  - commit hash or explicit no-commit reason
  - known limitations

## Approval Policy

Workers should not block for taste questions. They should make the best judgment, capture screenshots, and iterate through visual review.

Block only for:

- crash/render failure
- missing assets
- invalid layouts/imports
- destructive merge conflict
- ambiguity that could destroy useful work
- credentials/secrets encountered

## Visual QA Gate

Use targeted captures, not generic title-screen captures:

```bash
scripts/dev/capture_visual_qa.sh town overworld battle
scripts/dev/capture_visual_qa.sh --all
```

Full visual gate targets:

```text
town, overworld, battle, home, cave, dock, forest_clearing
```

Review screenshots for:

- wrong scene
- gray/blank render
- missing/misaligned tiles
- unreadable labels/UI
- style-breaking assets
- empty focal areas
- scale/camera mismatch
- inconsistent shadows/grounding

## End-of-Batch Integration Pass

Run after an autonomous batch or before merging:

```bash
scripts/dev/daily_integration_pass.sh --visual-default
# or, before a bigger integration/merge:
scripts/dev/daily_integration_pass.sh --visual-all
```

This runs:

- preflight
- git status summary
- town layout validation
- Godot headless parse/import smoke
- visual QA capture
- kanban crash-loop watchdog

Artifacts land under:

```text
artifacts/logs/integration_YYYYMMDD_HHMMSS/
artifacts/screenshots/visual_qa_YYYYMMDD_HHMMSS/
```

## Crash-Loop Watchdog

Cron/no-agent friendly command:

```bash
scripts/dev/kanban_crash_watchdog.py --board 2d-game --threshold 3
```

It prints only new repeated-crash alerts by default. Empty output means nothing new to report.

Recommended cron delivery shape:

```text
script: /home/ubuntu/lanternhouse/scripts/dev/kanban_crash_watchdog.py --board 2d-game --threshold 3
no_agent: true
schedule: every 10m
```

## Current Visual Blocker Queue

The existing all-asset review identified these as the next fixes:

1. `cave`: gray render failure.
2. `battle`: cave_dungeon background reads as a glowing portal instead of cave floor.
3. `home`: room/camera scale too small in frame.
4. `forest_clearing`: scene too empty/minimal.
5. `overworld`: POI labels low-contrast on fog.
6. `battle`: tip text low contrast.

Use `queue_visual_fix_pair.py` for the first four, then rerun full visual QA.
