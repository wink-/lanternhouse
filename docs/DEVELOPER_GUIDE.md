# Lanternhouse — Developer Guide

> **New to coding? Start here.** This guide walks through every script in the game,
> explains the patterns used, and teaches programming concepts as they appear in real code.

---

## How to Read This Guide

Each section covers a group of related files. We explain:
- **What the code does** (the feature)
- **How it works** (the pattern or technique)
- **Why it's done that way** (the design decision)
- **Coding concept** boxes that connect the pattern to general programming knowledge

Skim the [Architecture Overview](#architecture-overview) first, then dive into whichever
system interests you. Each section is self-contained.

---

## Architecture Overview

For shared project terminology, see [`vocabulary.md`](vocabulary.md). Most
importantly: **overworld** means the outer travel map, not towns, interiors,
dungeons, or battle scenes.

Lanternhouse is a **Godot 4.6** project written entirely in **GDScript** (Godot's built-in
language, similar to Python). There is no C++, no build step — Godot compiles `.gd` files
automatically when you press Play.

### The Scene Tree

```
Title Screen → Overworld (main game loop)
                    ├──→ Town (NPCs, shops, inn)
                    │       └──→ Shop (buy/sell)
                    ├──→ Battle (random encounters)
                    ├──→ Home (rest, cook, store items)
                    ├──→ Dock (fishing, currency exchange)
                    ├──→ Forest Clearing (herbs, hermit NPC)
                    ├──→ Cave (dungeon, boss)
                    └──→ Abandoned Village (The Unlit faction)
```

Each box is a **scene** (a `.tscn` file with a matching `.gd` script). When the player
walks onto a dock tile, the game switches from the Overworld scene to the Dock scene.
Data survives scene switches because it lives in **autoload singletons**.

### The Three Layers

| Layer | Files | Purpose |
|-------|-------|---------|
| **Autoloads** | `game_data.gd`, `sprite_cache.gd`, `audio_manager.gd`, `save_manager.gd`, `scene_transition.gd` | Global singletons that persist across every scene. Like a shared brain. |
| **Scene scripts** | `overworld.gd`, `town.gd`, `battle.gd`, `shop.gd`, `home.gd`, etc. | One script per scene. Handles input, rendering, and game logic for that screen. |
| **Data scripts** | `data/classes.gd`, `data/enemies.gd`, `data/items.gd`, `data/npcs.gd`, `data/quests.gd`, `data/factions.gd` | Static lookup tables. No instances — just `static func` that return dictionaries. |

```
┌─────────────────────────────────────────────────────┐
│  Autoloads (always loaded, shared state)            │
│  GameData  SpriteCache  AudioManager  SaveManager   │
├─────────────────────────────────────────────────────┤
│  Scene Scripts (one active at a time)               │
│  overworld.gd → town.gd → battle.gd → shop.gd      │
├─────────────────────────────────────────────────────┤
│  Data Scripts (pure functions, no state)            │
│  classes.gd  enemies.gd  items.gd  npcs.gd  quests  │
└─────────────────────────────────────────────────────┘
```

### Build Philosophy

Lanternhouse is being built in playable slices. The usual order is:

1. Make the loop work with simple data, maps, and placeholders.
2. Add smoke coverage or a quick headless launch check for risky changes.
3. Replace the roughest placeholder art with PixelLab-generated sprites.
4. Keep the game bootable by preserving cheap fallbacks where they already exist.
5. Document the local pattern after it proves useful in-game.

The town cat is the first PixelLab benchmark asset. It is intentionally integrated
as real runtime art, not just parked in the asset folder. Future art passes should
follow the same pattern: download the asset, put it under `assets/sprites/`, wire
it into the scene, and verify that the scene still launches.

For parallel work, see `docs/worktree-workflow.md`. It explains how the gameplay,
art, docs, and main integration folders fit together and how to merge a finished
lane back into `main`.

### Coding Concept: Singletons

A **singleton** is a single shared instance of an object. In Godot, autoloads are
singletons — the engine creates them once at startup and they never get destroyed.

Why does this matter? When the player walks from the overworld into town, the
overworld scene is destroyed and the town scene is created. If party HP was stored
on the overworld script, it would vanish. By storing it on `GameData` (an autoload),
it survives every scene transition.

```gdscript
# This is available in EVERY script, in EVERY scene:
GameData.gold += 50
```

---

## File Map (every script, ranked by line count)

| File | Lines | What it does |
|------|-------|-------------|
| `scripts/battle.gd` | ~1430 | Turn-based combat engine |
| `scripts/town.gd` | ~1310 | Town interior with 8 NPCs |
| `scripts/overworld.gd` | ~1060 | Island map, movement, encounters |
| `scripts/home.gd` | ~770 | Player home (bed, kitchen, storage, garden) |
| `scripts/data/npcs.gd` | ~500 | NPC definitions, dialogue trees, recruitable roster |
| `scripts/game_data.gd` | ~490 | All persistent game state |
| `scripts/dock.gd` | ~440 | Fishing, currency exchange |
| `scripts/abandoned_village.gd` | ~420 | The Unlit faction hideout |
| `scripts/data/quests.gd` | ~410 | Quest definitions, prerequisites, rewards |
| `scripts/inventory.gd` | ~365 | Inventory screen (items, equipment, trade goods) |
| `scripts/shop.gd` | ~300 | Buy weapons/armor/items, sell trade goods |
| `scripts/cave.gd` | ~300 | Dungeon exploration, chests, boss fight |
| `scripts/forest_clearing.gd` | ~235 | Herb gathering, hermit NPC |
| `scripts/charactersheet.gd` | ~185 | Party roster stats display |
| `scripts/audio_manager.gd` | ~170 | Procedural sound generation |
| `scripts/save_manager.gd` | ~180 | Save/load to JSON file |
| `scripts/data/enemies.gd` | ~160 | Enemy templates and formations |
| `scripts/title.gd` | ~143 | Title screen (New Game / Continue / Settings) |
| `scripts/settings.gd` | ~127 | Volume, text speed, window mode |
| `scripts/data/items.gd` | ~65 | Weapons, armor, shop items |
| `scripts/data/alchemy.gd` | ~110 | Potion recipes |
| `scripts/data/tinkering.gd` | ~110 | Tool crafting recipes |
| `scripts/data/factions.gd` | ~50 | Faction reputation tiers and price modifiers |
| `scripts/data/classes.gd` | ~45 | Character class templates and spells |
| `scripts/data/fish.gd` | ~45 | Fish species and zone tables |
| `scripts/minimap.gd` | ~90 | Tab-toggled fog-of-war map |
| `scripts/sprite_cache.gd` | ~47 | Runtime PNG loading with cache |
| `scripts/scene_transition.gd` | ~42 | Fade-to-black scene changes |
| `scripts/questjournal.gd` | ~170 | Quest status display |

---

## Pattern 1: The Data Script Pattern

**Files:** `data/classes.gd`, `data/enemies.gd`, `data/items.gd`, `data/npcs.gd`, `data/quests.gd`

### What it does

Data scripts are **lookup tables** — you give them a name, they give you back a
dictionary of stats. They have no internal state and are never instantiated.

### Example: `data/classes.gd`

```gdscript
class_name CharDB

static func get_template(cls_name: String) -> Dictionary:
    match cls_name:
        "Fighter":   return {"str":12, "def":9,  "agi":5,  "hp":38, "magic_levels":{}}
        "Thief":     return {"str":8,  "def":5,  "agi":10, "hp":28, "magic_levels":{}}
        "RedMage":   return {"str":7,  "def":6,  "agi":7,  "hp":26, "magic_levels":{1:3}}
    return {}
```

### Coding Concept: `static func`

In GDScript, `static func` means the function belongs to the **class itself**, not to
an instance. You call it directly on the class name:

```gdscript
var template := CharDB.get_template("Fighter")
```

You never write `var db = CharDB.new()` — there's no `.new()`. This is useful for
pure data lookups where you don't need to store any state.

### Coding Concept: Dictionaries as Data Records

Notice every character template is a **Dictionary** — GDScript's equivalent of a
JSON object or a Python dict. Keys are strings (`"str"`, `"hp"`), values are numbers
or nested dictionaries.

Why not use a class? Because GDScript dictionaries are flexible — you can add new
keys at runtime without changing the definition. This makes it easy to add
temporary battle state (`"alive": true`, `"command": "fight:0"`) to the same
dictionary that holds the base stats.

```gdscript
# Start with the template
var character := CharDB.get_template("Fighter").duplicate(true)
# Add runtime state
character["hp"] = character["hp"]  # current HP
character["alive"] = true
character["name"] = "Kael"
```

The `.duplicate(true)` call makes a **deep copy** — without it, every Fighter would
share the same dictionary object and modifying one would change them all.

### How enemies use the same pattern

`data/enemies.gd` uses the same lookup pattern but adds **level scaling**:

```gdscript
static func scaled_template(enemy_name: String, party_level: int) -> Dictionary:
    var base := template(enemy_name)
    var scale := 1.0 + (party_level - 1) * 0.12  # 12% stronger per level
    return {
        "name": enemy_name,
        "hp":   int(base["hp"] * scale),
        "atk":  int(base["atk"] * scale),
        # ... etc
    }
```

This is a **pure function** — it takes inputs (enemy name, party level) and returns
an output without modifying anything else. Pure functions are easy to test and
reason about because they always produce the same output for the same input.

---

## Pattern 2: The Autoload Singleton

**File:** `scripts/game_data.gd` (~490 lines)

### What it does

`GameData` is the game's shared brain. It holds:
- Party members and their stats
- Gold and faction currencies
- Equipment (what's in the bag + what's equipped)
- World flags (beacon states, visited towns, quest progress)
- Play time tracking, wage timers, property market simulation

### How it works

Because `GameData` is registered as an autoload in `project.godot`, Godot creates it
once at startup and keeps it alive for the entire game session. Any script can access
it globally:

```gdscript
# In ANY script, in ANY scene:
GameData.gold += 100
GameData.party[0]["hp"] -= 15
```

### Coding Concept: Global State vs Local State

`GameData` holds **global state** — data that needs to survive between scenes.
Individual scripts hold **local state** — data that only matters on the current screen.

```gdscript
# Global: survives scene changes
GameData.gold = 500

# Local: destroyed when the scene changes
var selected_menu_item = 0
```

Too much global state makes code hard to debug (anything can change anything).
Too little global state means you lose data on scene transitions. The pattern here
is intentional: `GameData` only stores things the player would care about losing —
their party, their money, their progress. Menu selections and animation timers stay
local.

### How party members work

Each party member is a Dictionary stored in `GameData.party` (an Array of up to 4):

```gdscript
{
    "name": "Fighter",
    "class": "Fighter",
    "hp": 38,           # current HP
    "max_hp": 38,       # maximum HP
    "str": 12,          # strength (physical damage)
    "def": 9,           # defense (damage reduction)
    "agi": 5,           # agility (turn order, flee chance)
    "level": 1,
    "xp": 0,
    "next_xp": 18,      # XP needed for next level
    "magic_levels": {},  # {level_number: {"charges": N, "max": N}}
    "alive": true,
    "command": "",       # battle command string, e.g. "fight:0"
    "command_label": "", # display text for the command
    "wage": 0,           # weekly wage (0 for starting party)
    "loyalty": 50,       # 0-100, affects stats and departure risk
}
```

### Coding Concept: The Array-as-Table Pattern

`GameData.party` is an Array (list) of Dictionaries. Access a member by index:

```gdscript
GameData.party[0]          # first party member
GameData.party[0]["hp"]    # their current HP
GameData.party[0]["hp"] -= 10  # take damage
```

Equipment is tracked with **parallel arrays** — one array per equipment slot, where
each element is an index into the equipment bag:

```gdscript
var equipped_weapon: Array = [-1, -1, -1, -1]  # -1 = nothing equipped
var weapons_bag: Array = []                      # available weapons

# Party member 0 has weapon at index 2 in the bag:
equipped_weapon[0] = 2

# To find their weapon's attack bonus:
var wi: int = equipped_weapon[0]
if wi >= 0:
    var atk: int = weapons_bag[wi]["atk"]
```

Why parallel arrays instead of putting equipment info inside each character?
Because two characters can't share the same sword — the array index naturally
prevents duplication. If member 0 has weapon index 2, and member 1 also gets set
to index 2, the equipping code swaps them (gives member 1 the old weapon from
member 0).

### The Currency System

Gold is stored as a single integer in **copper pieces**. Display functions convert:

```gdscript
var gold: int = 50000  # stored as copper

func gold_pieces() -> int:
    return gold / 10000  # → 5 gold

func silver_pieces() -> int:
    return (gold % 10000) / 100  # → 0 silver

func copper_pieces() -> int:
    return gold % 100  # → 0 copper
```

### Coding Concept: Integer Division and Modulo

The `%` operator (modulo) gives you the **remainder** after division. The `/` operator
on integers in GDScript rounds down (truncates).

```
50000 / 10000 = 5         (gold pieces)
50000 % 10000 = 0         (remainder → used to calculate silver)
0 / 100 = 0               (silver pieces)
0 % 100 = 0               (remainder → copper pieces)
```

This is a common pattern for converting between units (copper → silver → gold is
like cents → dollars, or seconds → minutes → hours).

---

## Pattern 3: The State Machine

**File:** `scripts/battle.gd` (~1430 lines)

### What it does

The battle system is the most complex script. It manages turn-based combat using a
**state machine** — a string variable (`round_phase`) that tracks which phase of
battle the player is currently in.

### The States

```gdscript
var round_phase: String = ""
# Possible values:
#   "command"        → player picks an action for the current character
#   "fight_target"   → player picks which enemy to attack
#   "magic_target"   → player picks a target for a spell
#   "resolution"     → actions execute in agility order
#   "between"        → pause between turns
#   "victory"        → enemies defeated, show rewards
#   "endgame_choice" → climactic story choice after final boss
#   "defeat"         → party wiped out
#   "ran"            → party fled
```

### How input is routed

The `_unhandled_input()` function uses a `match` statement (GDScript's switch/case)
to route keyboard input differently depending on the current state:

```gdscript
func _unhandled_input(event: InputEvent) -> void:
    if not (event is InputEventKey and event.pressed and not event.echo):
        return

    match round_phase:
        "command":
            _handle_command(event.keycode)
        "fight_target":
            _handle_fight_target(event.keycode)
        "magic_target":
            _handle_magic_target(event.keycode)
        "resolution":
            pass  # no input during resolution
        "endgame_choice":
            _handle_endgame_choice(event.keycode)
        "victory", "defeat", "ran":
            _handle_end(event.keycode)
```

### Coding Concept: State Machines

A **state machine** is one of the most important patterns in game development. The
idea: instead of one giant function that handles everything, you split your logic
into states. Only the active state's code runs.

Without a state machine, every key press would need to check every possible situation:
"Is the player choosing a command? Or a target? Or are we showing victory?" With a
state machine, the `round_phase` variable answers that question once, and the
correct handler runs.

The flow through states looks like:

```
command → fight_target → resolution → between → command (next character)
command → magic_target → resolution → between → command
command → resolution → victory → (exit battle)
command → resolution → defeat → (return to overworld)
```

Each arrow is triggered by player input or automatic progression. The battle
progresses by changing `round_phase` and calling `_update_display()`.

### How damage is calculated

```gdscript
func _calc_dmg(atk: int, defense: int, variance: int = 3) -> int:
    var base := atk - defense
    var dmg := base + rng.randi_range(-variance, variance)
    return maxi(dmg, 1)  # minimum 1 damage
```

### Coding Concept: Separation of Calculation from Display

Notice that `_calc_dmg()` only returns a number. It doesn't log text, animate
anything, or modify HP. The calling code does all that:

```gdscript
var dmg := _calc_dmg(attacker_atk, defender_def)
target["hp"] = max(0, target["hp"] - dmg)
_push_log("Fighter hits Slime for %d dmg!" % dmg)
_show_damage_number(position, str(dmg), Color.GOLD)
```

This separation makes the code testable — you could call `_calc_dmg()` in a loop
to balance combat without triggering any visual effects.

---

## Pattern 4: The ASCII Map

**File:** `scripts/overworld.gd` (~1060 lines)

### What it does

The overworld is a 40×40 grid of tiles, defined as an array of strings where each
character represents a terrain type:

```gdscript
const MAP := [
    "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
    "~~~~~~.,,,,,,,,,=,,,TTTTT!TTTT,,,~~~~~~",
    "~~~~~~,,,,,,,,S,,,,,,TT!TTTTTTT,,,.~~~~",
    # ... 40 rows total
]
```

| Character | Terrain | Walkable? | Encounters? |
|-----------|---------|-----------|-------------|
| `~` | Water | No | No |
| `.` | Sand/beach | Yes | Low rate |
| `,` | Grass | Yes | Medium rate |
| `T` | Forest | Yes | High rate |
| `^` | Hills | Yes | High rate |
| `M` | Mountain | No | No |
| `=` | Dirt path | Yes | No |
| `B` | Beacon tower | Yes (interact) | No |
| `L` | Lighthouse | Yes (interact) | No |
| `D` | Dock | Yes (scene transition) | No |
| `!` | Visible encounter | Yes (triggers fight) | No |

### How it works

When the game starts, `_ready()` reads each character and sets the corresponding
tile on a `TileMapLayer` node:

```gdscript
func _build_map() -> void:
    for y: int in range(MAP_H):
        for x: int in range(MAP_W):
            var tile: String = MAP[y].substr(x, 1)
            if TILE_ATLAS.has(tile):
                tilemap.set_cell(Vector2i(x, y), 0, TILE_ATLAS[tile])
```

### Coding Concept: Encoding Data as Text

Using characters to represent map tiles is a classic game dev technique. It's
human-readable (you can see the island shape in the code), compact, and easy to
modify. The same pattern appears in roguelikes (NetHack, Dwarf Fortress).

The lookup tables convert characters to visual tiles:
```gdscript
const TILE_ATLAS := {
    "~": Vector2i(4, 2),   # → water sprite at column 4, row 2 of the atlas
    ",": Vector2i(6, 9),   # → grass sprite
    "T": Vector2i(0, 18),  # → forest sprite
}
```

Each `Vector2i(col, row)` is a coordinate into the Pipoya tileset atlas — a single
PNG image containing hundreds of 32×32 pixel tiles arranged in a grid.

### How movement works

The player moves one tile at a time with a short animation:

```gdscript
func _try_move(dir: Vector2i) -> void:
    facing = dir
    var next := pos + dir

    if _is_blocked(next):
        return  # can't walk into water/mountains

    pos = next
    _update_player()
    _check_tile()  # encounters, NPCs, scene transitions
```

### Coding Concept: Grid Movement

The position is stored as `Vector2i` — a pair of integers (x, y). Each tile is 32×32
pixels. To convert grid position to screen position:

```gdscript
var screen_pos := Vector2(pos.x * TILE_SIZE, pos.y * TILE_SIZE)
```

The `_is_blocked()` function checks the tile character against a set of unwalkable
tiles:

```gdscript
const BLOCKED := {"~": true, "M": true, "#": true, "V": true, "A": true}

func _is_blocked(grid: Vector2i) -> bool:
    var tile: String = MAP[grid.y].substr(grid.x, 1)
    return BLOCKED.has(tile)
```

### How random encounters work

After each step on an encounter-eligible tile, a dice roll determines if a battle starts:

```gdscript
var base_rate: int = ENCOUNTER_RATE.get(zone, 8)  # e.g., forest = 6
if rng.randi_range(1, rate) == 1:
    _start_battle(zone)
```

For forests, `rate = 6`, so there's a 1-in-6 chance per step. Beaches are safer
(rate = 10, so 1-in-10). Sprinting makes encounters more frequent by lowering the
rate by 2.

### Coding Concept: Random Number Generation

`rng.randi_range(1, 6)` picks a random integer between 1 and 6 (inclusive). The
result `== 1` means "did we roll a 1?" — a simple probability check.

The game uses a `RandomNumberGenerator` instance instead of the global `randi()`
function. This is better because:
1. Each scene can have its own RNG without interfering with others
2. You can seed the RNG for reproducible testing

---

## Pattern 5: Scene Transitions

**Files:** `scripts/scene_transition.gd`, every scene that calls `change_scene()`

### What it does

`SceneTransition` is an autoload that fades the screen to black, swaps the scene,
then fades back in. This prevents visual glitches during scene changes.

### How to trigger a scene change

```gdscript
SceneTransition.change_scene("res://scenes/town/town.tscn")
```

### How it works internally

```gdscript
func change_scene(scene_path: String, fade_duration: float = 0.3) -> void:
    # 1. Fade to black
    _tween.tween_property(_overlay, "color:a", 1.0, fade_duration)
    await _tween.finished

    # 2. Swap scene while screen is black
    get_tree().change_scene_to_file(scene_path)

    # 3. Fade in
    _tween.tween_property(_overlay, "color:a", 0.0, fade_duration)
```

### Coding Concept: `await` and Asynchronous Code

The `await` keyword pauses the current function until something completes, without
freezing the game. While awaiting, other code (animations, physics) keeps running.

```gdscript
await _tween.finished  # wait for fade-out to complete
# code here runs after the fade finishes
```

This is similar to `async/await` in JavaScript or Python. The function effectively
splits into two parts: everything before `await` runs immediately, everything after
runs when the awaited signal fires.

---

## Pattern 6: Passing Data Between Scenes

### The Problem

When the player enters a shop from town, the shop needs to know what kind of shop
it is (weapons, armor, items). But the shop scene gets freshly created — it has no
memory of where the player came from.

### The Solution: `set_meta()` / `get_meta()`

```gdscript
# In town.gd, when the player talks to the weapon merchant:
GameData.set_meta("shop_type", "weapons")
SceneTransition.change_scene("res://scenes/shop/shop.tscn")

# In shop.gd, when it starts up:
func _ready() -> void:
    shop_type = GameData.get_meta("shop_type", "weapons")
```

`set_meta()` stores arbitrary key-value pairs on the `GameData` node. They survive
scene transitions because `GameData` is an autoload. The second argument to
`get_meta()` is a default value — used if the key was never set.

### Common meta keys

| Key | Set by | Read by | Purpose |
|-----|--------|---------|---------|
| `shop_type` | `town.gd` | `shop.gd` | Which shop screen to show |
| `battle_zone` | `overworld.gd` | `battle.gd` | Which enemy formations to use |
| `battle_surprise` | `overworld.gd` | `battle.gd` | Ambush or normal start |
| `endgame_choice` | `battle.gd` | overworld/NPCs | Which ending the player chose |
| `roster_pool` | `town.gd` | `game_data.gd` | Available recruitable NPCs |

---

## Pattern 7: The Dialogue Tree System

**File:** `scripts/data/npcs.gd` (~500 lines)

### What it does

Each NPC has dialogue organized by **context** — what they say depends on the game's
current state:

```gdscript
"elder": {
    "default": "The fog grows thicker each night...",
    "beacon_lit": "The light returns! But for how long?",
    "boss_defeated": "You've done what we thought impossible.",
    "honored": "Ah, a true friend of the Chapel.",
    "distrusted": "I have nothing to say to you.",
}
```

### How context is chosen

```gdscript
# In town.gd, when talking to an NPC:
var context := "default"

if faction_enum >= 0:
    var rep := GameData.get_faction_rep(faction_enum)
    if rep >= 20:
        context = "honored"
    elif rep <= -20:
        context = "distrusted"

if GameData.boss_defeated:
    context = "boss_defeated"
elif GameData.beacon_lit:
    context = "beacon_lit"
```

The checks go from most specific to least — boss_defeated overrides everything,
then beacon_lit, then faction reputation, falling back to default.

### Coding Concept: Priority-Based Selection

This pattern (check conditions in order, use the first match) is a simple form of
**priority**. More urgent game states override less urgent ones. It's the same idea
as CSS specificity or exception handling order.

---

## Pattern 8: The Quest System

**File:** `scripts/data/quests.gd` (~410 lines)

### What it does

Quests are defined as dictionaries with a `type` field that determines how progress
is tracked and when the quest completes:

| Type | Completes when... | Example |
|------|-------------------|---------|
| `beacon` | A specific beacon is lit | "The Dead Wick" |
| `flag` | A game flag is set to true | "Visit Brindlewick" |
| `kill` | Kill count reaches target | "Shadow Remnants" (kill 3 wisps) |
| `gather` | Gathering count reaches target | "Herbalist's Request" |
| `faction` | Faction reputation reaches target | "The Chapel's Secret" |
| `all_beacons` | Every beacon is lit | "Light All Beacons" |
| `trade` | Trade profit reaches target | "Trade Route" |
| `upgrade` | Home upgrades installed | "Home Improvement" |
| `member_quest` | A party member's personal goal is met | "Kael's Shadow" |

### How prerequisites work

Quests form a chain — you can't start "The Missing Keeper" until "The Dead Wick"
is complete:

```gdscript
const PREREQUISITES := {
    "the_missing_keeper": ["the_dead_wick"],
    "oil_for_the_line": ["the_missing_keeper"],
    "light_all_beacons": ["oil_for_the_line"],
    "cave_exploration": ["light_all_beacons"],
    # ... etc, building to the endgame
}
```

### Coding Concept: Dependency Graphs

This is a **directed acyclic graph** (DAG) — a tree of dependencies where each quest
points to the quests that must be completed before it. "Directed" because the
relationship goes one way (A requires B, not the reverse). "Acyclic" because there
are no circular dependencies (A requires B requires A).

The game checks prerequisites by walking the graph:

```gdscript
static func prerequisites_met(qid: String) -> bool:
    if PREREQUISITES.has(qid):
        for prereq: String in PREREQUISITES[qid]:
            if not GameData.is_quest_complete(prereq):
                return false
    return true
```

---

## Pattern 9: The Save System

**File:** `scripts/save_manager.gd` (~180 lines)

### What it does

Saves the entire game state to a JSON file. JSON is a text format that looks like
the dictionary literals you've seen throughout the code:

```json
{
    "gold": 50000,
    "party": [...],
    "beacon_states": {...},
    "quest_flags": {...}
}
```

### How it works

```gdscript
func save_game() -> bool:
    var data := {
        "version": 1,
        "party": GameData.party,
        "gold": GameData.gold,
        "beacon_states": GameData.beacon_states,
        # ... all persistent state
    }
    var json := JSON.stringify(data, "\t")  # pretty-printed with tabs
    file.store_string(json)
```

Loading reverses the process:

```gdscript
func load_game() -> bool:
    var result := JSON.parse_string(json_text)
    GameData.party = result["party"]
    GameData.gold = result["gold"]
    # ... restore all state
```

### Coding Concept: Serialization

**Serialization** means converting in-memory data (the game state) into a format
that can be stored (a text file). **Deserialization** is the reverse — reading the
file and reconstructing the data.

GDScript's `JSON.stringify()` handles dictionaries, arrays, numbers, strings, and
booleans automatically. But it can't handle some types directly:

```gdscript
# Vector2i can't be stored in JSON directly, so we convert it:
"overworld_position": {"x": GameData.overworld_position.x, "y": GameData.overworld_position.y}

# When loading, we reconstruct it:
var pos: Dictionary = result["overworld_position"]
GameData.overworld_position = Vector2i(pos["x"], pos["y"])
```

Game flags stored via `set_meta()` need special handling because `get_meta()` isn't
part of the serialization. The save system explicitly lists each flag:

```gdscript
"quest_flags": {
    "cave_opened": GameData.get_meta("cave_opened", false),
    "endgame_choice_made": GameData.get_meta("endgame_choice_made", false),
}
```

---

## Pattern 10: Procedural Audio

**File:** `scripts/audio_manager.gd` (~170 lines)

### What it does

Generates sound effects from code — no audio files needed. Each sound is a short
burst of math (a sine wave with an envelope):

```gdscript
func _play_tone(freq: float, duration: float, volume_db: float) -> void:
    var stream := AudioStreamGenerator.new()
    stream.mix_rate = 22050  # samples per second

    var frames := int(duration * 22050)
    var data := PackedVector2Array()
    data.resize(frames)

    var phase := 0.0
    var phase_inc := freq / 22050.0

    for i in range(frames):
        var env := clampf(float(frames - i) / frames, 0.0, 1.0)
        data[i] = Vector2(sin(phase) * env, sin(phase) * env)
        phase += phase_inc
```

### Coding Concept: Digital Audio

Sound is a wave — air pressure going up and down. In code, we represent this as a
sequence of numbers (samples). Each sample says "where is the wave right now?"

- **Frequency** (`freq`): How fast the wave oscillates. Higher = higher pitch.
  220 Hz is a low tone, 880 Hz is a high tone.
- **Phase** (`phase`): Where we are in the wave cycle. We advance it each sample.
- **Envelope** (`env`): A multiplier that fades the sound from loud to quiet.
  Without this, the sound would click on and off abruptly.

The `sin(phase)` function produces the classic sine wave shape. Multiplying by `env`
creates a fade-out. Different sounds use different frequencies and durations:

```gdscript
func play_footstep_grass() -> void:
    _play_tone(220.0 + randf() * 80.0, 0.04, -18.0)
    #   220-300 Hz, very short (0.04 sec), quiet (-18 dB)

func play_beacon_light() -> void:
    _play_chime(523.25, 0.15, 0.0)   # C5
    _play_chime(659.25, 0.15, 0.0)   # E5
    _play_chime(783.99, 0.3, 0.0)    # G5 — a C major triad
```

---

## How to Add New Content

### Add a new enemy type

1. Add a template to `data/enemies.gd` `template()`:
   ```gdscript
   "Goblin": {"hp": 18, "atk": 7, "def": 3, "agi": 6, "xp": 12, "gold": 8},
   ```

2. Add a color to `battle.gd` `ENEMY_COLORS`:
   ```gdscript
   "Goblin": Color("4a8c2a"),
   ```

3. Add the enemy to a zone formation in `enemies.gd`:
   ```gdscript
   {"name": "Goblin", "count": 2},
   ```

4. Optionally, add a sprite: `assets/sprites/battle/enemies/goblin.png`

### Add a new tile type

1. Add the character to the `MAP` array in `overworld.gd`
2. Add it to `TILE_ATLAS` with the atlas coordinates
3. Add it to `BLOCKED` or `ENCOUNTER_ZONES` if applicable

### Add a new quest

1. Add the quest dictionary to `data/quests.gd` `all_quests()`
2. Add prerequisites to `PREREQUISITES` if it has any
3. If a new quest type, add a handler in `battle.gd` `_check_quest_progress()`
4. Add any new meta flags to `save_manager.gd` save/load

### Add a new NPC

1. Add the NPC data to `data/npcs.gd` with dialogue contexts
2. Place the NPC in the town/village map in the scene script
3. Handle interaction in the scene's `_interact()` function

---

## GDScript Quick Reference for New Coders

### Variables
```gdscript
var x := 5           # type inferred from value (int)
var name: String = "" # explicit type
const MAX := 10       # can't be changed after declaration
```

### Functions
```gdscript
func heal(amount: int) -> void:
    hp += amount

static func get_damage() -> int:
    return 10
```

### Match (switch/case)
```gdscript
match command:
    "attack":
        do_attack()
    "defend":
        do_defend()
    _:
        do_default()  # else case
```

### Loops
```gdscript
for i in range(10):       # 0 through 9
    print(i)

for item in inventory:    # iterate over array
    print(item["name"])

while hp > 0:
    take_damage()
```

### Dictionaries
```gdscript
var d := {"name": "Fighter", "hp": 38}
d["hp"] = 30                     # set value
var name: String = d["name"]     # get value
var x: int = d.get("mp", 0)     # get with default (no crash if missing)
d.has("name")                    # check if key exists → true
```

### Arrays
```gdscript
var a := [1, 2, 3]
a.append(4)           # add to end → [1, 2, 3, 4]
a.remove_at(0)        # remove first → [2, 3, 4]
a.size()              # → 3
a.is_empty()          # → false
```

### Godot-specific
```gdscript
@onready var label = $MyLabel       # get node, wait until ready
preload("res://path/to/file.gd")    # load at compile time
load("res://path/to/file.tscn")     # load at runtime
get_tree().change_scene_to_file(...) # switch scenes
await get_tree().process_frame       # wait one frame
```

### String formatting
```gdscript
"Healed %d HP!" % 20              # → "Healed 20 HP!"
"%s hits %s for %d" % ["A", "B", 5]  # → "A hits B for 5"
```

---

## Common Gotchas

### 1. `.duplicate(true)` or share a bug

```gdscript
# BUG: all party members share the same dictionary
var template := CharDB.get_template("Fighter")
GameData.party.append(template)
GameData.party.append(template)  # same object!

# FIX: make a deep copy
GameData.party.append(CharDB.get_template("Fighter").duplicate(true))
GameData.party.append(CharDB.get_template("Fighter").duplicate(true))
```

### 2. Use tabs, not spaces

GDScript requires **tab indentation**. If you copy code from a browser or AI chat,
it may use spaces and Godot will throw indentation errors. Convert spaces to tabs
before saving.

### 3. `match` needs exact matches

```gdscript
# This won't match:
match "Fighter":
    "fighter":   # lowercase vs uppercase → no match

# Use the exact same string:
match "Fighter":
    "Fighter":   # correct
```

### 4. `_unhandled_input` vs `_input`

- `_input(event)` catches **every** input, even if a UI element already handled it
- `_unhandled_input(event)` only fires if nothing else consumed the input first

Use `_unhandled_input` for game controls so UI buttons don't accidentally trigger
game actions.

### 5. `maxi()` / `clampi()` for integers

GDScript has separate functions for integer and float math:
- `max(a, b)` / `min(a, b)` → float
- `maxi(a, b)` / `mini(a, b)` → int
- `clampf(val, lo, hi)` → float
- `clampi(val, lo, hi)` → int

Using the wrong one won't crash, but you'll get unexpected float results.

---

## Project Conventions

- **File naming:** `snake_case.gd` for scripts, `snake_case.tscn` for scenes
- **Directory structure:** Each scene gets its own folder under `scenes/`
- **Asset paths:** `assets/sprites/<category>/<name>.png` — drop PNGs, no code change
- **Constants for lookup tables:** `const` dictionaries for data that never changes at runtime
- **Dictionaries for game objects:** Characters, enemies, items, quests are all dictionaries, not classes
- **Autoloads are always available:** `GameData`, `SpriteCache`, `AudioManager`, `SaveManager`, `SceneTransition`
- **Tabs for indentation:** Spaces will cause syntax errors in GDScript
