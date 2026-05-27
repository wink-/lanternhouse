# Lanternhouse Smoke Tests

> Short manual routes for keeping `main` playable while we build each roadmap
> slice. These are written for learning too: each route names the system it is
> exercising.

---

## Slice 1 - First Playable Spine

**Goal:** Confirm a fresh player can start, move around, enter locations, fight,
save, and load without breaking the game loop.

### Route A - Fresh Start And Home/Town Entry

1. Launch the project.
2. Choose **New Game** from the title screen.
3. Confirm the player appears on the overworld near Brindlewick.
4. Press **Interact** immediately.
5. Confirm the game enters town or home depending on ownership state.
6. Press **Esc** or use the scene's exit route to return to the overworld.

**Systems covered:** title reset, overworld spawn, facing direction, interaction
targeting, scene transition, persisted overworld return position.

### Route B - Overworld Movement And Camera

1. From the overworld, walk at least ten steps in different directions.
2. Confirm the player remains centered except near map edges.
3. Walk toward the north/west coast if possible.
4. Confirm the camera clamps at map edges and does not reveal empty space.

**Systems covered:** input, tile movement, camera follow, camera limits.

### Route C - Major Location Transitions

Visit each available location from the overworld and return:

- Brindlewick town/home via the `h` tile.
- Dock via the `D` tile.
- Forest clearing via the `f` tile.
- Abandoned village via an `A` tile.
- Cave interaction via the `V` tile. Early-game cave may remain sealed; the test
  passes if the seal message appears instead of a crash.

**Systems covered:** overworld interaction dispatch, scene switching, return
position, blocked/progression-gated locations.

### Route D - Battle Loop

1. Trigger a random encounter or step onto a visible encounter marker.
2. Choose simple attacks until the battle ends.
3. Confirm victory grants rewards and returns to the overworld.
4. Confirm defeat has an intentional result instead of a script error.

**Systems covered:** encounter start, battle scene, turn flow, rewards, return
scene.

### Route E - Save And Load

1. Move to a recognizable overworld position.
2. Collect or change at least one thing if available: gold, tonic count, herb,
   material, quest flag, or beacon state.
3. Save with **F5** or **F6**.
4. Move somewhere else.
5. Load with **F7** or **F9**.
6. Confirm position, facing, party, currency, inventory, and flags return to the
   saved state.

**Systems covered:** serialization, `Vector2i` conversion, inventory persistence,
quest/flag persistence.

---

## Automated Baseline

Run the project boot check:

```powershell
godot_console --headless --path "I:\code\lanternhouse" --quit
```

Run the overworld boot check:

```powershell
godot_console --headless --path "I:\code\lanternhouse" res://scenes/overworld/overworld.tscn --quit-after 2
```

Run every scene:

```powershell
$scenes = Get-ChildItem -Path "I:\code\lanternhouse\scenes" -Recurse -Filter "*.tscn"
foreach ($scene in $scenes) {
  $res = "res://" + $scene.FullName.Substring("I:\code\lanternhouse\".Length).Replace("\", "/")
  godot_console --headless --path "I:\code\lanternhouse" $res --quit-after 2
}
```

