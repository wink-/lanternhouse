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

---

## Slice

- Name: First quest guidance pass
- Date: 2026-05-27
- Playable goal: Make The Dead Wick readable enough that a new player knows where to go, what changed, and when to return to the Elder.

## What Changed

- Player-facing change: The Elder now gives a clear objective and route hint when accepting The Dead Wick, the quest journal repeats the objective, and lighting the lighthouse beacon tells the player to return to Brindlewick.
- Systems or content added: Optional `objective`, `hint`, and `turn_in` quest fields now drive journal and dialogue text.
- Bug or design problem solved: The quest could technically be completed, but the game did not reliably tell the player the next step after accepting or lighting the beacon.

## Files to Read

- `res://scripts/data/quests.gd` - see how quest dictionaries can carry player-facing guidance alongside rewards and targets.
- `res://scripts/questjournal.gd` - inspect how optional dictionary fields become journal lines only when present.
- `res://scripts/town.gd` - look for the helper that assembles quest acceptance text.
- `res://scripts/overworld.gd` - find how the beacon interaction checks active quest state before adding a return-to-town prompt.

## GDScript Concepts

- Concept: Data-driven UI text
- Where it appears: Quest dictionaries now store objective/hint/turn-in text, while town, journal, and overworld scripts render those fields.
- What to notice: Adding optional fields with `quest.has()` and `quest.get()` lets one quest become clearer without forcing every older quest to be updated at once.

## Why This Pattern

- Problem this pattern solves: Quest guidance needs to show up in several places without copying the same route text into each scene.
- Why it fits this slice: The first demo loop depends on the player understanding the Elder's request and the lighthouse payoff.
- Tradeoff or thing to watch: Plain dictionaries are quick for learning, but as quests grow, custom `Resource` files may become easier to validate and edit.

## Tiny Exercise

- Task: Add an `objective` and `hint` to another quest in `res://scripts/data/quests.gd`.
- Expected result in-game: Accepting that quest and opening the journal should show the new guidance automatically.
- Hint: Copy the field names exactly: `objective`, `hint`, and optionally `turn_in`.

## Questions to Revisit

- Question: Should quest guidance eventually support map markers or compass arrows?
- Why it matters: Text hints work for a small demo, but larger maps may need stronger navigation help.
- When to revisit: After the lighthouse route and remaining overworld landmarks are polished.

---

## Slice

- Name: Overworld landmark readability pass
- Date: 2026-05-27
- Playable goal: Make the major overworld destinations easier to recognize while exploring the first demo route.

## What Changed

- Player-facing change: Brindlewick, the lighthouse, beacons, dock, cave, camp, clearing, and ruins now have readable world labels and pins under fog-of-war.
- Systems or content added: A `LANDMARK_MARKERS` data list feeds the existing location marker drawing code.
- Bug or design problem solved: Important locations relied mostly on small icon art, which made the lighthouse objective and optional landmarks too easy to miss.

## Files to Read

- `res://scripts/overworld.gd` - look at `LANDMARK_MARKERS`, `_draw_location_markers()`, and `_add_location_marker()`.

## GDScript Concepts

- Concept: Arrays of dictionaries as lightweight content data
- Where it appears: `LANDMARK_MARKERS` stores each marker's grid position, label, color, and label offset.
- What to notice: The drawing function does not need to know which landmark is which; it just loops through data and renders each entry the same way.

## Why This Pattern

- Problem this pattern solves: Adding labels one by one in code would create repeated marker setup logic.
- Why it fits this slice: The overworld still uses a simple ASCII map, so a simple parallel data list is enough to make landmarks readable.
- Tradeoff or thing to watch: If landmarks gain quest rules, discovery states, or custom icons, this data should probably move into a dedicated landmark database.

## Tiny Exercise

- Task: Change one landmark label color in `LANDMARK_MARKERS`.
- Expected result in-game: That destination's pin and label tint changes on the overworld.
- Hint: Colors are `Color(red, green, blue, alpha)` floats from `0.0` to `1.0`.

## Questions to Revisit

- Question: Should unexplored landmarks hide their labels until discovered?
- Why it matters: Always-visible labels help the demo, but discovery can make exploration feel more rewarding later.
- When to revisit: After the first quest arc has map markers or journal tracking.

---

## Slice

- Name: Battle readability and smoke pass
- Date: 2026-05-27
- Playable goal: Make the first battle easier to parse and prove the starter party can win a simple encounter.

## What Changed

- Player-facing change: Battles now show compact enemy and party HP summaries, an opening tip, longer combat log context, and gentler grassland formations.
- Systems or content added: A deterministic `smoke_battle_basic` scene checks that the starter party can defeat a Slime and receive rewards.
- Bug or design problem solved: Smoke Bomb no longer advances selection after starting escape resolution, and spell particles are now added to the scene before cleanup.

## Files to Read

- `res://scripts/battle.gd` - look for `_enemy_summary()`, `_party_summary()`, `_spawn_spell_effect()`, and `_update_display()`.
- `res://scripts/data/enemies.gd` - inspect the grassland formation list.
- `res://scripts/dev/smoke_battle_basic.gd` - see how a scene can instantiate a real battle and drive it from code.
- `res://scenes/dev/smoke_battle_basic.tscn` - the minimal scene wrapper for the automated smoke.

## GDScript Concepts

- Concept: Test scenes as executable scripts
- Where it appears: `smoke_battle_basic.gd` creates a known party, injects one Slime, assigns commands, and waits for the battle state to settle.
- What to notice: The test does not need a special framework; Godot scenes can be tiny executable harnesses that exit with success or failure.

## Why This Pattern

- Problem this pattern solves: Combat changes are risky because several systems move at once: party stats, enemy data, rewards, and scene transitions.
- Why it fits this slice: A deterministic Slime fight catches obvious breakage before each commit without forcing a manual playthrough.
- Tradeoff or thing to watch: This smoke proves one happy path, not overall balance. More encounter tests should be added as zones become important to the demo.

## Tiny Exercise

- Task: Change the smoke test enemy from `Slime` to `Imp` and run the scene.
- Expected result in-game: The starter party should still win, but the fight may last longer.
- Hint: Update both the enemy dictionary's `name` and its stat values together.

## Questions to Revisit

- Question: Which specific encounters should define "fair" for the 20-30 minute demo?
- Why it matters: Balance should be anchored to expected player route and level, not just individual enemy numbers.
- When to revisit: After the lighthouse objective and return-to-Elder reward are fully paced.

---

## Slice

- Name: Item shop and tonic loop pass
- Date: 2026-05-27
- Playable goal: Let a fresh player buy supplies, see clear shop feedback, use Tonics without waste, and trust save/load to preserve purchases.

## What Changed

- Player-facing change: Sister Aldith can now open the item shop, shop actions show success/failure messages, and Tonics do not get consumed when everyone is already at full HP.
- Systems or content added: Tonic healing uses a shared `ItemDB.TONIC_HEAL` constant, and `smoke_shop_inventory` verifies buy, save/load, and use behavior.
- Bug or design problem solved: The item shop existed in code but had no town entry point for demo players.

## Files to Read

- `res://scripts/data/npcs.gd` - see the new healer topic that routes to supplies.
- `res://scripts/town.gd` - inspect the `item_shop` topic handler.
- `res://scripts/shop.gd` - look for `last_message` and buy/sell feedback.
- `res://scripts/inventory.gd` - see the guard that prevents wasted Tonics.
- `res://scripts/dev/smoke_shop_inventory.gd` - follow the automated buy/use/save-load route.

## GDScript Concepts

- Concept: Shared constants
- Where it appears: `ItemDB.TONIC_HEAL` is used by item data, inventory use, and battle item use.
- What to notice: A single number now controls both behavior and player-facing descriptions, which prevents drift.

## Why This Pattern

- Problem this pattern solves: Item behavior, shop copy, inventory copy, and battle use can quietly disagree if they each hardcode their own value.
- Why it fits this slice: Tonics are the first demo's main safety valve, so their behavior should be obvious and consistent.
- Tradeoff or thing to watch: If item effects grow more complex, constants may give way to fully data-driven effect dictionaries.

## Tiny Exercise

- Task: Change `ItemDB.TONIC_HEAL` from `20` to `24` and run the shop/inventory smoke.
- Expected result in-game: Tonic descriptions and healing amount should both update.
- Hint: Search for `TONIC_HEAL` to see every place the constant is used.

## Questions to Revisit

- Question: Should Ethers restore one charge or all charges?
- Why it matters: The current shop description and behavior are close, but magic economy balance will matter once longer routes arrive.
- When to revisit: During the next content expansion or cave route pass.

---

## Slice

- Name: Home base utility pass
- Date: 2026-05-27
- Playable goal: Make the home useful as a reliable rest, storage, cooking, garden, and crafting hub without breaking save/load.

## What Changed

- Player-facing change: Basic bed text now matches what happens, the herb garden only harvests when the timer is ready, and the realtor can sell the Workbench upgrade used by the home scene.
- Systems or content added: `smoke_home_base` verifies rest, storage, cooking, garden harvest gating, and home save/load persistence.
- Bug or design problem solved: Garden harvesting could be repeated immediately, the Workbench existed in the home but could not be purchased, and property browsing displayed the wallet instead of each property price.

## Files to Read

- `res://scripts/home.gd` - look for `GARDEN_GROW_SECONDS`, `_garden_ready()`, `_harvest_garden()`, and `_interact_bed()`.
- `res://scripts/town.gd` - inspect the realtor `HOME_UPGRADES` and property browse display.
- `res://scripts/dev/smoke_home_base.gd` - see how the home scene is driven directly for an automated gameplay check.
- `res://scripts/dev/smoke_save_load.gd` - see the broader persistence assertions for home state.

## GDScript Concepts

- Concept: Scene-level smoke tests
- Where it appears: `smoke_home_base.gd` instantiates the real home scene, calls focused interaction methods, and exits Godot with a success or failure code.
- What to notice: The test uses real autoload state (`GameData` and `SaveManager`) instead of mocking, so it catches wiring problems between systems.

## Why This Pattern

- Problem this pattern solves: Home features touch inventory, healing, crafting ingredients, timers, and saves, so regressions can be subtle.
- Why it fits this slice: The home is a hub; proving the hub loop gives us confidence before adding more demo content around it.
- Tradeoff or thing to watch: Directly calling underscored methods is fine for smoke coverage, but future UI-heavy flows may need input-driven tests too.

## Tiny Exercise

- Task: Change `GARDEN_GROW_SECONDS` to `10.0` and run the home-base smoke.
- Expected result in-game: The garden should become ready faster, and the smoke should still pass because it uses the constant from the scene.
- Hint: Search for `GARDEN_GROW_SECONDS` to see both timer display and harvest gating.

## Questions to Revisit

- Question: Should the first cottage include a starter chest or kitchen automatically?
- Why it matters: Buying a home currently feels useful only after upgrades, which may be too slow for a 20-30 minute demo.
- When to revisit: When pacing the demo economy and first quest rewards.

---

## Slice

- Name: Lighthouse objective event pass
- Date: 2026-05-27
- Playable goal: Make the first beacon lighting feel like a completed quest objective and point clearly to the next story step.

## What Changed

- Player-facing change: Lighting the lighthouse now shows Dead Wick event text, the journal explains the lit objective is ready to turn in, and Elder completion points toward Mara Venn.
- Systems or content added: Beacon objectives now store active quest progress when lit, and The Missing Keeper has objective, hint, and turn-in copy.
- Bug or design problem solved: The Dead Wick smoke no longer fakes the beacon state; it drives the actual overworld beacon interaction and checks that rewards happen only at Elder turn-in.

## Files to Read

- `res://scripts/overworld.gd` - inspect `_interact_beacon()` and `_active_beacon_quest_for()`.
- `res://scripts/data/quests.gd` - see `event_text`, `objective_done`, and `next_breadcrumb`.
- `res://scripts/questjournal.gd` - see the lit-beacon journal line.
- `res://scripts/dev/smoke_dead_wick.gd` - follow the accept, light, repeat-light, turn-in, reward route.

## GDScript Concepts

- Concept: Runtime quest progress in dictionaries
- Where it appears: `_interact_beacon()` writes `GameData.active_quests[quest_id]["progress"] = 1` for the matching active beacon quest.
- What to notice: Static quest data lives in `QuestDB`, while mutable runtime state lives in `GameData.active_quests`.

## Why This Pattern

- Problem this pattern solves: A lit beacon affects map fog, faction rep, quest UI, and Elder rewards; separating “objective done” from “quest paid” keeps the story beat clear.
- Why it fits this slice: The first objective needs immediate confirmation without skipping the return-to-Elder payoff.
- Tradeoff or thing to watch: The overworld now sets generic beacon quest progress, so future multi-step beacon quests may need richer per-objective state.

## Tiny Exercise

- Task: Change The Dead Wick `event_text` and run the Dead Wick smoke.
- Expected result in-game: The smoke should still pass because it checks state and reward timing, not exact prose.
- Hint: The event copy lives in `QuestDB`, while the display happens in `overworld.gd`.

## Questions to Revisit

- Question: Should lighting the lighthouse play a short pause, flash, or chime before the HUD message?
- Why it matters: A small ceremony could make the first objective memorable without changing quest logic.
- When to revisit: During the visual effects/audio polish pass.

---

## Slice

- Name: Missing Keeper story pass
- Date: 2026-05-27
- Playable goal: Make the second story quest readable, payable, and smoke-tested after The Dead Wick.

## What Changed

- Player-facing change: The North Forest beacon now has Mara-specific event text, journal completion copy, and Elder breadcrumbing toward beacon oil.
- Systems or content added: `smoke_missing_keeper` verifies Dead Wick completion, Missing Keeper acceptance, North Forest beacon lighting, Elder turn-in, and the next story quest unlock.
- Bug or design problem solved: The second quest had a route hint, but no event text or automated coverage proving the chain from first quest to second quest.

## Files to Read

- `res://scripts/data/quests.gd` - inspect `the_missing_keeper` and `oil_for_the_line`.
- `res://scripts/dev/smoke_missing_keeper.gd` - follow the two-quest automated route.
- `res://scenes/dev/smoke_missing_keeper.tscn` - the tiny executable wrapper scene.

## GDScript Concepts

- Concept: Reusing generic systems through data
- Where it appears: The Missing Keeper uses the same beacon quest path as The Dead Wick, but different `event_text`, `objective_done`, and reward data.
- What to notice: No new quest engine code was needed; the quest feels different because its data is richer.

## Why This Pattern

- Problem this pattern solves: Story quests should be cheap to add once the generic quest type works.
- Why it fits this slice: The demo needs momentum after the first lighthouse beat, and data-driven copy is the fastest safe way to get there.
- Tradeoff or thing to watch: Beacon quests are still single-objective; multi-step investigations will need a richer quest model later.

## Tiny Exercise

- Task: Change the Missing Keeper reward from `125` to `150` and rerun `smoke_missing_keeper`.
- Expected result in-game: The smoke should adapt because it reads the reward from `QuestDB`.
- Hint: The reward field is converted to copper at Elder turn-in.

## Questions to Revisit

- Question: Should Mara's journal pages become an inventory key item?
- Why it matters: A key item would make the investigation feel more tangible, but it adds UI and save/load surface.
- When to revisit: When building the item/key-item pass for the first demo.
