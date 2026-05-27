# Lanternhouse Roadmap

> A playable-first roadmap for building Lanternhouse with focused agent tasks,
> while using the real game as a way to learn GDScript.

---

## Working Agreement

Lanternhouse should stay playable on `main`. Every slice below is meant to produce
something visible in-game, not just infrastructure. Agents can help move faster, but
the project should still feel readable and teachable.

### Roles

- **Lead / Integrator:** Owns `main`, reviews patches, resolves conflicts, keeps the
  game booting, and explains the GDScript patterns after each slice.
- **Systems Agent:** Battle math, inventory rules, save/load, economy, quests,
  factions, encounters, and balance.
- **World Agent:** Overworld, town, cave, dock, home, village, transitions, NPC
  placement, and map interactions.
- **UI Agent:** HUD, menus, inventory, character sheet, quest journal, shop,
  settings, and battle log readability.
- **Content Agent:** Item data, enemy data, dialogue, quest text, NPC data, signs,
  loot tables, and tutorial copy.
- **QA Agent:** Scene sweeps, smoke tests, regression checks, bug reports, and
  reproduction steps.
- **Teacher Agent:** Short learning notes after a slice lands: what changed, what
  GDScript concept it demonstrates, and one tiny practice exercise.

### Agent Task Brief Template

Use this shape when handing work to an agent:

```text
Goal:
Files/modules owned:
Do not touch:
Expected player behavior:
Acceptance checks:
Test command:
Learning note requested:
```

### Merge Rule

Before pushing a slice, run at least:

```powershell
godot_console --headless --path "I:\code\lanternhouse" --quit
godot_console --headless --path "I:\code\lanternhouse" res://scenes/overworld/overworld.tscn --quit-after 2
```

For larger gameplay slices, run every scene:

```powershell
$scenes = Get-ChildItem -Path "I:\code\lanternhouse\scenes" -Recurse -Filter "*.tscn"
foreach ($scene in $scenes) {
  $res = "res://" + $scene.FullName.Substring("I:\code\lanternhouse\".Length).Replace("\", "/")
  godot_console --headless --path "I:\code\lanternhouse" $res --quit-after 2
}
```

---

## Slice 0 - Stability Baseline

**Player outcome:** The game opens, the title screen works, and all current scenes
can start without script errors.

**Scope**

- Keep `main` bootable.
- Verify title, overworld, town, home, dock, cave, battle, inventory, quest journal,
  settings, shop, forest clearing, and abandoned village.
- Keep generated Godot metadata committed when required for clean project loads.

**Agent split**

- QA Agent: run scene sweep and record failures.
- Lead / Integrator: fix blocking script errors and push.

**Done criteria**

- Godot project loads headlessly.
- Every `.tscn` under `scenes/` starts headlessly.
- No known parse errors or missing autoload references.

**Learning focus**

- Godot scene loading.
- Parse errors vs runtime errors.
- Autoloads and why shared state lives outside individual scenes.

---

## Slice 1 - First Playable Spine

**Player outcome:** A new player can start the game, walk the overworld, enter key
locations, return to the overworld, fight one battle, and save/load progress.

**Scope**

- New game flow from title into overworld.
- Retro overworld camera behavior: character-centered follow with map-edge clamp.
- Working transitions for town, home, dock, cave, forest clearing, and abandoned
  village.
- One battle can start, resolve, and return to the overworld.
- Save/load restores position, facing, party, inventory, gold, and basic flags.

**Agent split**

- World Agent: transition checks and overworld interaction polish.
- Systems Agent: save/load completeness and battle return flow.
- QA Agent: smoke test the full route.
- Teacher Agent: explain scene transitions and autoload persistence.

**Done criteria**

- Start new game from title.
- Move at least ten overworld steps.
- Enter and exit every major location.
- Win or escape one battle.
- Save, quit scene, load, and confirm position/inventory are restored.

**Learning focus**

- Scene switching.
- `Vector2i` tile positions.
- Dictionaries for persistent game state.
- Input handling through `_unhandled_input`.

---

## Slice 2 - First Quest Arc

**Player outcome:** The player receives a quest, travels somewhere, completes an
objective, returns for a reward, and sees the quest journal update.

**Recommended quest:** Help restore a small beacon supply route between Brindlewick
and the nearby shore.

**Scope**

- One NPC offers a quest in town or home.
- Quest journal shows active and completed states.
- Objective can be completed through a simple action: gather item, defeat enemy, or
  light/check a beacon.
- Reward grants copper, item, reputation, or skill progress.
- Save/load preserves quest state.

**Agent split**

- Content Agent: quest text, NPC dialogue, reward text.
- Systems Agent: quest flag and reward logic.
- UI Agent: journal clarity.
- QA Agent: complete quest from fresh save and from loaded save.
- Teacher Agent: explain quest state and data-driven quest definitions.

**Done criteria**

- Quest can be accepted once.
- Quest cannot be rewarded infinitely.
- Journal changes from available to active to completed.
- Save/load works at each stage.

**Learning focus**

- State machines with string or enum states.
- Data scripts as lookup tables.
- `match` statements.
- Guard clauses to prevent duplicate rewards.

---

## Slice 3 - Combat Feel Pass

**Player outcome:** Battles are understandable, fair, and satisfying enough that
testing combat is fun instead of confusing.

**Scope**

- Clear battle log messages.
- Player command flow is obvious.
- Enemy targeting and enemy turns are readable.
- Rewards screen or reward summary after victory.
- Party defeat has a clear consequence.
- Early enemy stats are tuned for a first session.

**Agent split**

- Systems Agent: battle flow, rewards, defeat handling, balance.
- UI Agent: log formatting, selected command display, HP readability.
- Content Agent: enemy names, enemy behavior descriptions, reward flavor.
- QA Agent: run repeated battle smoke tests.
- Teacher Agent: explain turn order, arrays of combatants, and command state.

**Done criteria**

- Player can attack, use item, and resolve a turn.
- Enemy action is visible in the log.
- Victory grants XP/gold/items.
- Defeat returns to a safe place or produces an intentional game-over flow.
- Three sample battles complete without script errors.

**Learning focus**

- Arrays of dictionaries.
- Turn loops.
- Randomness with `RandomNumberGenerator`.
- Separating data from behavior.

---

## Slice 4 - Inventory, Shops, and Economy Loop

**Player outcome:** The player can earn currency, buy useful items, use items, sell
trade goods, and understand why money matters.

**Scope**

- Tonics and ethers are useful in and out of combat.
- Shop buy/sell flow is reliable.
- Trade goods have clear prices and sell values.
- Currency display is readable.
- Inventory limits are visible before they frustrate the player.

**Agent split**

- Systems Agent: item effects, bag limits, currency math.
- UI Agent: shop/inventory readability.
- Content Agent: item descriptions and merchant lines.
- QA Agent: buy, sell, use, save/load, repeat.
- Teacher Agent: explain item dictionaries and helper functions.

**Done criteria**

- Player can buy a tonic and use it.
- Player cannot buy items without enough currency.
- Bag-full state is handled gracefully.
- Save/load preserves purchased and sold items.

**Learning focus**

- Helper functions.
- Shared item data.
- Defensive checks before mutating state.
- Formatting values for UI.

---

## Slice 5 - Home Base Loop

**Player outcome:** The home scene feels useful: rest, cook, store items, tinker, or
prepare before going back out.

**Scope**

- Resting has a clear effect.
- Cooking uses fish or ingredients and creates useful consumables.
- Storage can deposit/withdraw at least one item category.
- Alchemy/tinkering has one complete useful recipe.
- Home state persists.

**Agent split**

- Systems Agent: cooking, storage, recipe effects.
- UI Agent: home menus and feedback messages.
- Content Agent: recipe names and flavor text.
- QA Agent: use each station and save/load after changes.
- Teacher Agent: explain scene-local UI state vs global inventory state.

**Done criteria**

- Player can rest and see party HP recover.
- Player can create one item from gathered materials.
- Storage does not duplicate or delete items incorrectly.
- Save/load preserves home-related state.

**Learning focus**

- Scene-specific interaction modes.
- Resource consumption.
- Mutating arrays safely.
- Keeping UI and data synchronized.

---

## Slice 6 - World Exploration Layer

**Player outcome:** The overworld starts to feel like a place: signs, gathering,
weather, fog, beacons, and point-of-interest feedback all work together.

**Scope**

- Signs and landmarks give useful hints.
- Gathering herbs/materials has consistent feedback.
- Beacon states affect fog or route access.
- Weather and day/night remain visual and non-disruptive.
- Minimap reflects useful known information.

**Agent split**

- World Agent: map interactions, gates, landmarks.
- Systems Agent: gather rates, beacon state effects.
- UI Agent: minimap and HUD feedback.
- Content Agent: sign text and location names.
- QA Agent: walk routes and verify blocked/unblocked paths.
- Teacher Agent: explain tile maps and coordinate-driven interactions.

**Done criteria**

- At least three landmarks have useful interactions.
- At least one route changes based on beacon state.
- Gatherable resources work in at least two terrain types.
- Fog/day/night overlays do not block UI or input.

**Learning focus**

- Tile lookup from map strings.
- Coordinate dictionaries.
- Using constants to make map logic readable.
- Lightweight procedural checks.

---

## Slice 7 - NPCs, Factions, and Consequences

**Player outcome:** NPCs react to player choices, and faction reputation begins to
matter in simple, visible ways.

**Scope**

- At least two factions have visible reputation.
- NPC dialogue changes based on reputation or quest state.
- One shop or service price changes based on reputation.
- One choice increases one reputation and lowers another.

**Agent split**

- Systems Agent: faction math and price modifiers.
- Content Agent: dialogue variations and faction flavor.
- World Agent: NPC placement and interaction hooks.
- UI Agent: reputation display.
- QA Agent: test reputation before and after a choice.
- Teacher Agent: explain branching dialogue and reputation as numeric state.

**Done criteria**

- Reputation changes are visible.
- Dialogue has at least neutral/friendly/hostile variation.
- Save/load preserves reputation.
- Reputation affects at least one practical system.

**Learning focus**

- Conditional dialogue.
- Numeric thresholds.
- Shared systems used by multiple scenes.
- Avoiding hardcoded one-off branches.

---

## Slice 8 - Content Expansion

**Player outcome:** The first playable spine expands into a short session with
multiple things to do.

**Scope**

- Add two to three quests.
- Add several enemies with distinct behavior.
- Add a few useful items or recipes.
- Add one small dungeon or cave objective.
- Add optional NPC flavor interactions.

**Agent split**

- Content Agent: quest, item, enemy, NPC data.
- Systems Agent: wire new effects or enemy behaviors.
- World Agent: place objectives.
- QA Agent: verify each content path.
- Teacher Agent: explain how adding content differs from adding systems.

**Done criteria**

- A fresh player has 20-30 minutes of guided play.
- New content reuses existing systems where possible.
- No new content path blocks progression permanently.
- Scene sweep passes.

**Learning focus**

- Data-driven design.
- Reuse over new code.
- When to add a new system vs a new data entry.
- Content validation.

---

## Slice 9 - Presentation Polish

**Player outcome:** The game feels more cohesive: better readability, audio cues,
visual feedback, and a stronger retro RPG mood.

**Scope**

- Battle and overworld feedback sounds.
- UI panels feel consistent.
- Text colors are intentional and readable.
- Movement and transitions feel responsive.
- Save/load and error messages are player-friendly.

**Agent split**

- UI Agent: menus, panels, typography, layout.
- World Agent: map visual feedback and transitions.
- Content Agent: concise player-facing copy.
- QA Agent: readability and route smoke tests.
- Teacher Agent: explain polish as small feedback loops.

**Done criteria**

- No important UI text overlaps or disappears.
- Common actions produce clear feedback.
- Scene transitions feel intentional.
- Basic audio cues are not overwhelming.

**Learning focus**

- Player feedback loops.
- UI nodes and layout.
- Timers and simple animation.
- Separating flavor text from logic.

---

## Slice 10 - Exportable Demo

**Player outcome:** Lanternhouse can be packaged as a small demo build someone else
can download and try.

**Scope**

- Clean project settings.
- Export preset.
- Versioned demo build.
- Start screen with basic controls.
- Known issues list.
- Smoke test exported build.

**Agent split**

- Lead / Integrator: export settings and release checklist.
- QA Agent: run exported build and record bugs.
- UI Agent: title/start screen polish.
- Teacher Agent: explain Godot export workflow.

**Done criteria**

- Exported build launches.
- New player can reach and complete the first quest arc.
- Save/load works in exported build.
- Known issues are documented.

**Learning focus**

- Project settings.
- Export presets.
- Difference between editor behavior and exported behavior.
- Release discipline.

---

## Immediate Backlog

These are the next concrete tasks that should feed Slice 1 and Slice 2.

- [x] Write a fresh-player smoke test route. See `docs/SMOKE_TESTS.md`.
- [ ] Verify title -> new game -> overworld -> town -> overworld.
- [ ] Verify one battle can start and return cleanly.
- [x] Pick the first quest NPC and objective: Elder -> The Dead Wick -> lighthouse beacon.
- [x] Audit save/load fields against current `GameData`.
- [x] Add a short `docs/LEARNING_LOG.md` format for slice debriefs.
- [ ] Decide whether generated `.uid` and `.import` files should all stay tracked.
