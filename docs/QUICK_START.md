# Quick Start for New Developers

> Never coded before? This guide gets you from zero to understanding the codebase.

---

## What You Need

1. **Godot 4.6** — Download from [godotengine.org](https://godotengine.org). The "standard" version is fine.
2. **A text editor** — Godot has a built-in script editor. VS Code with the GDScript extension also works.
3. **This project** — Open the folder in Godot (click "Import" → select `project.godot`).

## What Language Is This?

**GDScript** — Godot's built-in language. It looks like Python with some differences:

```gdscript
# This is a comment
var gold = 500           # A variable
const MAX_LEVEL = 40     # A constant (can't change)
var party: Array = []    # A variable with a type hint

func heal(target: Dictionary) -> void:
    # A function. "void" means it doesn't return anything.
    target["hp"] = target["max_hp"]
```

Key differences from Python:
- Uses **tabs** for indentation (not spaces)
- Has `match` instead of `switch/case`
- Variables can have type hints (`: int`, `: String`, `: Array`)
- Uses `@onready` and `@export` annotations

## The Big Picture

Shared project terms are defined in [`vocabulary.md`](vocabulary.md). In short,
**overworld** means the outer travel map, while towns, interiors, dungeons, and
battles are separate focused scenes.

Think of the game as a play with actors and a script:

| Concept | What It Is | Example File |
|---------|-----------|--------------|
| **Scenes** | Screens/pages of the game (like acts of a play) | `battle.tscn`, `town.tscn` |
| **Scripts** | Code that controls a scene (like the script actors follow) | `battle.gd`, `town.gd` |
| **Autoloads** | Always running, like the stage lighting — visible everywhere | `game_data.gd` |
| **Data files** | Recipe books — define what things *are* but don't do anything themselves | `data/enemies.gd`, `data/items.gd` |

## The Most Important File: `game_data.gd`

Every game needs to *remember things* — your gold, your HP, what items you have. `game_data.gd` is the game's memory. It's an **autoload singleton** — Godot loads it once at startup and every other script can access it:

```gdscript
# Any script can read or write game data:
GameData.gold = 1000                    # Set gold
var current_hp = GameData.party[0]["hp"] # Read first character's HP
GameData.tonics += 1                     # Give the player a tonic
```

Party members are stored as **dictionaries** (like a card with stats written on it):

```gdscript
# A party member looks like this:
{
    "name": "Fighter",
    "hp": 38,          # current health
    "max_hp": 38,       # maximum health
    "str": 12,          # strength (attack power)
    "def": 9,           # defense (damage reduction)
    "level": 1,         # current level
    "xp": 0,            # experience points
    "alive": true,      # false = knocked out
}
```

## How to Read the Code

### Start with the data files (easiest)

1. **`scripts/data/classes.gd`** — Defines character classes. Just lists of numbers.
2. **`scripts/data/enemies.gd`** — Defines enemies. Same idea.
3. **`scripts/data/items.gd`** — Defines weapons and armor.

These files use `static func` — they're lookup tables. No game logic here, just "what does a Slime look like?" type data.

### Then read a scene script

4. **`scripts/shop.gd`** — The simplest interactive scene. Buy things, see prices.
5. **`scripts/town.gd`** — Slightly more complex. NPCs, dialogue, scene transitions.
6. **`scripts/battle.gd`** — The most complex. Turn-based combat with a state machine.

### Finally the overworld

7. **`scripts/overworld.gd`** — The main map. Movement, encounters, day/night cycle.

## How to Make Changes

### Change a number (easy)

Open `scripts/data/enemies.gd` and find the Slime:
```gdscript
"Slime": return {"hp":6, "atk":2, "def":0, ...}
```
Change `hp` to `60` — now the Slime is a tank. Run the game and fight one.

### Add a new weapon (easy)

Open `scripts/data/items.gd`, find `weapon_list()`, and add to the array:
```gdscript
{"id":"uber_sword", "name": "Uber Sword", "atk": 50, "price": 9999},
```

### Add a new enemy type (medium)

1. Add stats to `data/enemies.gd` `template()` function
2. Add a color to `battle.gd`'s `ENEMY_COLORS` dictionary
3. Add to a formation function (e.g., `forest_formations()`)
4. Optionally add AI behavior to `AI_BEHAVIORS`

### Add a new dialogue (medium)

Find the NPC in `town.gd` and add a new branch to their dialogue `match` statement. Dialogue is just text strings.

### Add a new tile type (harder)

1. Add the character to the MAP array in `overworld.gd`
2. Add it to `TILE_ATLAS` with a sprite coordinate
3. Add to `BLOCKED` or `ENCOUNTER_ZONES` if needed

## Key Coding Patterns to Learn

As you read the code, you'll see these patterns repeated everywhere:

| Pattern | What It Looks Like | Where to See It |
|---------|-------------------|-----------------|
| **State machine** | A variable that controls which "mode" the code is in | `battle.gd` line 31 (`round_phase`) |
| **Lookup table** | `match` statement returning fixed data | `data/enemies.gd` `template()` |
| **Dictionary as object** | `{"name": "Fighter", "hp": 38}` | `game_data.gd` party members |
| **Event handler** | `_unhandled_input(event)` — runs when player presses a key | Every scene script |
| **Game loop** | `_process(delta)` — runs every frame | `overworld.gd`, `battle.gd` |
| **Parallel arrays** | Same-length arrays where index i in each refers to the same entity | `game_data.gd` equipped_weapon/equipped_head/etc. |

## Common GDScript Gotchas

- **Tabs, not spaces.** GDScript *requires* tab indentation. If you paste code from a tutorial that uses spaces, convert it first.
- **`null` not `None`.** GDScript uses `null` for "nothing here", not Python's `None`.
- **Arrays start at 0.** `party[0]` is the first member, not `party[1]`.
- **Dictionaries return `null` for missing keys.** `data.get("key", default)` is safer than `data["key"]` because it won't crash on missing keys.
- **`_ready()` runs once.** When a scene loads. `_process(delta)` runs every frame.

## Next Steps

- Read the full **[Developer Guide](DEVELOPER_GUIDE.md)** for deep dives into each system
- Look for `[CODING CONCEPT]` comments in the code — they explain the *why* behind patterns
- Press **F3** in-game for a debug overlay showing game state
- Press **F5** to save, **F7** to load — experiment freely
