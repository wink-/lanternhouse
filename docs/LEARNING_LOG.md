# Lanternhouse Learning Log

Use this template after each playable slice to turn real Lanternhouse changes into
small GDScript lessons. Keep entries short, concrete, and tied to code that
actually changed.

## Slice

- Name:
- Date:
- Playable goal:

## What Changed

- Player-facing change:
- Systems or content added:
- Bug or design problem solved:

## Files to Read

List the most useful files for learning from this slice.

- `res://path/to/file.gd` - why this file matters
- `res://path/to/scene.tscn` - what to inspect in the scene tree

## GDScript Concepts

Focus on concepts that appear in the slice's actual code.

- Concept:
- Where it appears:
- What to notice:

Examples to consider:

- Signals and connected callbacks
- `@export` variables for tuning in the editor
- Typed variables, arrays, dictionaries, or resources
- `_ready`, `_process`, and `_physics_process`
- Scene instancing and node references
- Input handling and state changes

## Why This Pattern

Explain the local Lanternhouse pattern, not a generic rule.

- Problem this pattern solves:
- Why it fits this slice:
- Tradeoff or thing to watch:

## Tiny Exercise

Make one small change that reinforces the lesson.

- Task:
- Expected result in-game:
- Hint:

## Questions to Revisit

Capture anything that should become clearer after future slices.

- Question:
- Why it matters:
- When to revisit:

---

## Slice

- Name: Slice 1 foundation pass
- Date: 2026-05-27
- Playable goal: Make the current loop safer to launch, move through, save, load, and recover from edge cases.

## What Changed

- Player-facing change: The project has clearer smoke-test coverage for the roadmap-critical flow, safer interior exits, and fewer ways to land in broken overworld or battle states.
- Systems or content added: Save/load hardening, interior exit checks, overworld map safety guards, and battle-loop safety checks.
- Bug or design problem solved: Slice 1 focused on defensive behavior around transitions and state restoration so future content can build on a steadier base.

## Files to Read

List the most useful files for learning from this slice.

- `ROADMAP.md` - see which Slice 1 goals were turned into concrete checks.
- `docs/SMOKE_TESTS.md` - scan the smoke routes that describe the expected playable path.
- `res://scripts/save_manager.gd` - look for validation around saved data and restore paths.
- `res://scripts/town.gd` and `res://scripts/home.gd` - inspect how exits route the player back out of interior scenes.
- `res://scripts/overworld.gd` - look for guards that keep map movement and transitions valid.
- `res://scripts/battle.gd` - find the checks that keep battle state from continuing after it should stop.

## GDScript Concepts

Focus on concepts that appear in the slice's actual code.

- Concept: Guard clauses
- Where it appears: Save/load, exits, overworld transitions, and battle-loop state checks.
- What to notice: Many safety fixes are small early returns that prevent invalid data or impossible state from flowing deeper into the game.

Examples to consider:

- Signals and connected callbacks
- `@export` variables for tuning in the editor
- Typed variables, arrays, dictionaries, or resources
- `_ready`, `_process`, and `_physics_process`
- Scene instancing and node references
- Input handling and state changes

## Why This Pattern

Explain the local Lanternhouse pattern, not a generic rule.

- Problem this pattern solves: Slice 1 has several scene transitions and state changes that can fail quietly if data is missing or stale.
- Why it fits this slice: Defensive checks make the playable loop more predictable before adding more rooms, map content, and battle variation.
- Tradeoff or thing to watch: Too many scattered checks can hide the real source of bad state, so future slices should keep moving shared rules into one obvious owner.

## Tiny Exercise

Make one small change that reinforces the lesson.

- Task: Pick one guard clause in a save/load, exit, overworld, or battle script and add a `push_warning()` message before it returns.
- Expected result in-game: Normal play should behave the same, but the Godot output panel should explain the skipped unsafe action when that edge case happens.
- Hint: Keep the warning specific enough to name the missing value or invalid state, for example an empty destination scene or missing saved position.

## Questions to Revisit

Capture anything that should become clearer after future slices.

- Question: Which safety checks should become shared helpers instead of staying inside individual scripts?
- Why it matters: Shared helpers can make future content faster to build and easier to test.
- When to revisit: After the next playable slice adds more rooms, map routes, or battle outcomes.
