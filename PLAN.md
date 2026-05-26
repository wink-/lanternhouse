# Lanternhouse — Production Plan

> A retro JRPG set in Mournlight Sound. Ordinary housemates keep a failing beacon
> network alive across a fog-haunted island chain. MMO-scale world, Dragon Quest soul.

---

## Overview

Lanternhouse is being built in Godot 4.6 (headless-capable) with pixel art assets.
The project is structured for an evergreen, persistent world with tight stat scaling
(Lv40 cap), open skill progression, a multi-currency economy, and a party system
built on negotiated wages and loyalty rather than destiny.

---

## Phase 0 — Foundation (Done)

- [x] Godot 4 project scaffold (`project.godot`, autoloads, scene tree)
- [x] `GameData` singleton — persistent state, party, inventory, flags, map position
- [x] `SpriteCache` autoload — runtime sprite loading from asset paths
- [x] Overworld scene — 40x40 island map with pixel art tiles (simple generated set)
- [x] Player movement — 4-directional cardinal (WASD / arrow keys / gamepad)
- [x] Input actions — move, interact, cancel, menu, battle commands
- [x] Camera2D — follows player across the island
- [x] F3 debug overlay — position, tile, facing, FPS
- [x] Basic overworld HUD — party HP, gold, tonics, beacon status
- [x] GitHub Pages story bible at `https://wink-.github.io/lanternhouse/`
- [x] Design doc at `docs/SYSTEMS.md`
- [x] Repo pushed to `github.com/wink-/lanternhouse`

---

## Phase 1 — Visual Foundation

The colored-block placeholder era is over. Replace with real pixel art that
establishes the Lanternhouse atmosphere: coastal, warm, haunted.

### 1.1 — Terrain Tileset (high priority)
- [ ] **Current state:** `terrain_simple.png` — procedurally generated 32x32 tiles
       (water, sand, grass, forest, hill, mountain). Works but looks basic.
- [ ] **Option A — Pipoya's Free RPG World Tileset (preferred):** 32x32/40x40/48x48 pixel
       tiles with proper art. Available on itch.io (name-your-own-price, free).
       Download from: https://pipoya.itch.io/pipoya-free-rpg-world-tileset-32x32-40x40-48x48
       Once downloaded, swap in as the TileSet texture and update atlas coordinates.
- [ ] **Option B — LPC (Liberated Pixel Cup) Tile Atlas (already on disk):**
       `terrain_atlas.png` + `base_out_atlas.png`. Very comprehensive (cliffs, caves,
       water, sand, grass, trees, hills, mountains, buildings, bridges, docks, props).
       License: CC-BY-SA 3.0 / GPL 3.0 (attribution required — `Attribution.txt` included).
       Tiles are organized as feature tiles (ponds, islands, set-pieces) rather than
       simple terrain squares, so mapping to a 40x40 tile grid requires custom work.
- [ ] **Decision needed:** Pick Option A (Pipoya) or Option B (LPC), or continue with
       generated tiles until custom art is made.
- [ ] Tiles needed regardless of option: deep water, shallow water, sand, grass (x3 variants),
       tall grass, forest (pine + deciduous), thick forest (blocking), forest edge,
       hills (slope transitions), mountains (faces + peak), dirt path, stone path,
       bridge (horizontal + vertical), cliffs, cave entrance, lighthouse segments

### 1.2 — Building Tileset
- [ ] Lanternhouse exterior (multi-tile building with tower attachment)
- [ ] Town buildings: chapel, general store, dockmaster's office, inn
- [ ] Cottage (player home exterior)
- [ ] Ruins, abandoned watchtower
- [ ] Door sprites (open/closed states)

### 1.3 — Character Sprites
- [ ] Player character spritesheet — 4-directional walk cycles (down/up/left/right)
- [ ] NPC spritesheet — generic villagers, keepers, merchants (4-directional idle)
- [ ] Party member portraits (for HUD and dialogue)
- [ ] **Integration:** Replace the gold Polygon2D player sprite

### 1.4 — UI Skin
- [ ] Window/panel borders (retro JRPG style)
- [ ] Menu backgrounds, fonts
- [ ] Button sprites, cursor/hand pointer
- [ ] HP/MP bar textures
- [ ] Item icons (tonic, oil, lenses, striker, maps)
- [ ] Coin icons (copper, silver, gold + faction variants)
- [ ] **Integration:** Apply to existing HUD and planned menus

### 1.5 — Environmental Particles & Effects
- [ ] Rain particle system (coastal storms)
- [ ] Fog overlay (sentient fog creeping)
- [ ] Beacon light glow (animated)
- [ ] Fireflies / lantern glow
- [ ] Water ripple shader on coast tiles
- [ ] Step dust on dirt paths

---

## Phase 2 — World Building

The Mournlight Sound archipelago needs to feel lived-in and worth exploring.

### 2.1 — Brindlewick Town
- [ ] Design 40x40 town map (docks, market, chapel, graveyard, tavern, homes)
- [ ] Town NPCs with unique names and randomized dispositions/skills
- [ ] Wandering NPC schedules (time of day / beacon state aware)
- [ ] Enterable buildings: general store, chapel, Lanternhouse, one home
- [ ] Lanternhouse interior: common room, storage, bedrooms, tower climb
- [ ] **Integration:** Wire the `h` (house) tile on the overworld to transition here
- [ ] Day/night tint (subtle — coastal mood, not punishing)

### 2.2 — Beacon Network
- [ ] Place 4-6 beacon towers across the overworld
- [ ] Each beacon has a "lit/unlit" state tracked in GameData
- [ ] Lit beacons clear fog, unlock routes, increase nearby property values
- [ ] Unlit beacons attract monsters, block paths, lower morale
- [ ] **Integration:** Lighthouse interaction (`L` tile) already prototyped

### 2.3 — Additional Island Zones
- [ ] Forest clearing — encounter zone with density variation
- [ ] Hills overlook — vista point, hidden items
- [ ] Mountain pass — blocked until certain beacons lit
- [ ] Sealed sea cave — mid-game dungeon
- [ ] Abandoned village (The Unlit faction hideout)
- [ ] Small islands accessible by bridge or later by boat

### 2.4 — World Persistence
- [ ] Save/load system (local file, JSON or Resource)
- [ ] Party position, world flags, inventory, gold persist across sessions
- [ ] Beacon states persist
- [ ] NPC states / quest progress persist
- [ ] Respawn logic: death → healer → home (lose carried loot + some coin)

---

## Phase 3 — Core Gameplay Systems

### 3.1 — Enhanced Movement & Interaction
- [ ] Smooth 32x32 grid movement (existing, but polish the feel)
- [ ] Interaction range check (face tile + press E/Space)
- [ ] Signpost text popups
- [ ] Zone transition with fade (overworld → town → interior → battle)
- [ ] Sprint toggle (Shift) — faster walk, higher encounter rate

### 3.2 — Encounter System
- [ ] Random encounter zones defined per tile type (forest, dark, beach, ruins)
- [ ] Encounter rate configurable per zone (steps between checks)
- [ ] Visible encounters on certain tiles (`!` marker on map)
- [ ] Unique enemy spawn tables per zone
- [ ] Enemy level scaling based on party's highest member (roughly)
- [ ] Surprise / ambush mechanic (existing 10% chance)

### 3.3 — Turn-Based Combat (existing, needs expansion)
- [x] Four-command battle menu (Attack, Guard, Tonic, Lantern Spark)
- [x] Enemy turns and hit/damage resolution
- [x] Victory/defeat (respawning at Lanternhouse with 1 HP)
- [x] XP, level-up, stat growth (HP/ATK/DEF)
- [ ] Expand to full command set: Attack, Guard, Magic, Item, Flee
- [ ] Skill growth through use (open skill web foundation)
- [ ] Multiple enemy groups per encounter
- [ ] Target selection (choose which enemy to hit)
- [ ] Battle animations (weapon swing, spell effect, damage numbers)
- [ ] Combat log (existing — expand with more detail)
- [ ] Flee success/failure with turn penalty
- [ ] Battle background art (forest, beach, cave, dark variants)

### 3.4 — Party System
- [ ] Party roster (max 4 active, pool of available NPCs)
- [ ] Recruitment — find NPCs in towns, negotiate wage
- [ ] Wage system — sliding scale, negotiated per member
- [ ] Loyalty tracking — influenced by pay, gifts, favors, quest completion
- [ ] Loyalty effects: stat bonuses at high loyalty, refusal to fight at low
- [ ] Permanent departure if loyalty drops too low
- [ ] Party member personal quests
- [ ] **Integration:** HUD shows all active members, ready to implement

---

## Phase 4 — Economy & Progression

### 4.1 — Currency System
- [ ] Copper/Silver/Gold (CSG) standard
- [ ] 100 copper = 1 silver, 100 silver = 1 gold
- [ ] Faction currencies: Keeper Guild marks, Harbor Compact tokens, Grey Chapel script
- [ ] Shady exchange NPCs — convert between currencies at fluctuating rates
- [ ] Prices influenced by beacon coverage (lit areas = more expensive)
- [ ] Item buy/sell with vendor-specific inventories
- [ ] Barter system for rare items (trade goods, favors)

### 4.2 — Leveling (Lv 40 cap)
- [x] XP gain from combat (existing)
- [ ] Hard cap at Level 40
- [ ] Pacing: Lv1-10 ~1hr each, Lv11-40 ~2hrs each
- [ ] After Lv40: diminishing returns grind (stat boosts, perk points, no more levels)
- [ ] Stat growth per level (HP, ATK, DEF, AGI modified by class/use)
- [ ] Leveling is a side effect of surviving, not the main goal

### 4.3 — Open Skill Web
- [ ] Skills learned through use (not level-up)
- [ ] Using an axe → axe skill increases
- [ ] Fishing → fishing skill increases
- [ ] Healing allies → mending skill increases
- [ ] Classes give starting bonuses + faster learning in their domain
- [ ] Skill tiers: Novice → Adept → Expert → Master
- [ ] Skill display in character sheet

### 4.4 — Tradeskills
- [ ] Fishing — find fishing spots on coast/docks, different fish by zone/weather
- [ ] Cooking — prepare meals at home for party buffs
- [ ] Alchemy / Tonic crafting — combine herbs into potions
- [ ] Tinkering — repair lenses, craft simple tools
- [ ] Trading — buy low in one town, sell high in another (faction-aware)
- [ ] Each tradeskill levels through use, unlocks new recipes/abilities
- [ ] Harvested/crafted goods are tradeable with NPCs and vendors

### 4.5 — Equipment & Inventory
- [ ] Weapon slots: main hand, off-hand
- [ ] Armor slots: head, body, accessory
- [ ] Inventory grid or list (bag limit by weight or slots)
- [ ] Equipment affects stats and sometimes skills
- [ ] Unique NPC gear (not all fighters have +1 axes)
- [ ] Item use from inventory (tonics currently, expand)

---

## Phase 5 — Home & Real Estate

### 5.1 — Home Purchase
- [ ] Home buying mechanic — visit real estate NPC in town
- [ ] Home prices vary by location (beacon-lit = premium, unlit = cheap)
- [ ] Starting home: small cottage (cheapest option)
- [ ] Upgradeable: add rooms, storage, workshop, garden, guest quarters
- [ ] Dark-aligned players can buy unlit land cheap and thrive in darkness

### 5.2 — Home Functions
- [ ] Storage chest (safe item storage, separate from inventory)
- [ ] Rest bed (full heal for party)
- [ ] Cooking station (craft meals from ingredients)
- [ ] Garden plot (grow herbs, vegetables)
- [ ] Guest rooms (house party members, affects loyalty)
- [ ] Trophies / displays (show off achievements, rare catches)
- [ ] Beacon map on wall (shows lit/unlit towers)

### 5.3 — Real Estate Market
- [ ] Multiple buyable properties per town/island
- [ ] Property values fluctuate with beacon coverage, trade routes, events
- [ ] Rent collection if owning commercial property
- [ ] Faction relationships affect which properties you can buy
- [ ] Property tax proportional to beacon coverage benefits

---

## Phase 6 — Story & Content

### 6.1 — Quest System
- [ ] Quest journal (active + completed)
- [ ] Quest types: main beacon missions, faction favors, party member quests, tradeskill challenges
- [ ] Quest giver NPCs with unique dialogue
- [ ] Quest rewards: gold, items, loyalty, faction reputation
- [ ] Moral choice branches (no clear villain — competing interests)

### 6.2 — Main Storyline
- [ ] Act 1: Relight the Lanternhouse beacon, find Mara Venn
- [ ] Quest: The Dead Wick (tutorial quest)
- [ ] Quest: The Missing Keeper (first overworld travel)
- [ ] Quest: Oil for the Line (first moral choice)
- [ ] Act 2: Travel between islands, fix beacons with local problems
- [ ] Act 3: Discover what the Lantern Line truly imprisons
- [ ] Endgame choice: restore seal, break it, or rebuild the Line

### 6.3 — Faction System
- [ ] **Keepers' Guild** — reputation gain through maintaining beacons, loss through neglect
- [ ] **Harbor Compact** — reputation via trade, shipping, oil supply
- [ ] **Grey Chapel** — reputation via rituals, burial rites, sea knowledge
- [ ] **The Unlit** — reputation via helping refugees, opposing the other factions
- [ ] Faction reputation affects pricing, quest access, dialogue, property eligibility

### 6.4 — NPC System
- [ ] All named NPCs have unique names and slightly randomized stats/skills
- [ ] Named NPCs have dialogue trees (at least 2-3 conversation topics)
- [ ] Some NPCs are potential party members
- [ ] NPC schedules: move between locations based on time/weather/events
- [ ] Faction-affiliated NPCs give faction-specific dialogue and quests

---

## Phase 7 — Polish & Testing

### 7.1 — Audio
- [ ] Overworld ambient (waves, wind, fog, distant bells)
- [ ] Town theme (cozy, warm, minor-key undertone)
- [ ] Battle theme (energetic 8-bit)
- [ ] Lanternhouse interior theme (safe haven)
- [ ] UI sound effects (confirm, cancel, menu open, item get)
- [ ] Footstep sounds per tile type (grass, wood, stone, water)
- [ ] Beacon lighting sound (triumphant chime)

### 7.2 — UI & Experience
- [ ] Title screen with pixel art
- [ ] Main menu (New Game, Continue, Settings)
- [ ] Character sheet screen (stats, skills, equipment)
- [ ] Inventory screen (items, equipment, key items)
- [ ] Quest journal screen
- [ ] Map screen (overworld view with explored/unexplored fog)
- [ ] Shop interface (buy/sell lists with portraits)
- [ ] Settings: volume, text speed, window mode

### 7.3 — Multiplayer (Long-term)
- [ ] LAN host/join (existing prototype in kanban workspace)
- [ ] Synchronized player roaming
- [ ] Party system with one leader controlling overworld movement
- [ ] Turn-based combat with per-player command selection
- [ ] AFK fallback mechanics

### 7.4 — Testing & Balance
- [ ] Economy balance: wages vs quest rewards vs item prices
- [ ] Level pacing: verify ~1hr/lvl early, ~2hr/lvl later
- [ ] Combat balance: enemy HP/damage vs party output
- [ ] Encounter frequency: feels right per zone
- [ ] Faction reputation gain/loss rates
- [ ] Tradeskill progression: not too fast, not too grindy
- [ ] Real estate pricing: achievable but aspirational

---

## Phase 8 — Release & Operations

- [ ] Packaging for Windows/Linux/macOS
- [ ] Hosted server option for persistent world
- [ ] Update pipeline (client patching)
- [ ] Community feedback collection
- [ ] Content updates: new islands, beacons, quests, fish, recipes

---

## Summary Timeline (Rough)

| Phase | Effort | Timeline |
|-------|--------|----------|
| 0 — Foundation | Done | Complete |
| 1 — Visual Foundation | Medium | 2-4 weeks |
| 2 — World Building | Large | 3-6 weeks |
| 3 — Core Systems | Large | 4-8 weeks |
| 4 — Economy & Progression | Medium | 3-5 weeks |
| 5 — Home & Real Estate | Medium | 2-4 weeks |
| 6 — Story & Content | Large | 4-8 weeks |
| 7 — Polish & Testing | Medium | 3-6 weeks |
| 8 — Release & Ops | Small | Ongoing |

---

## Key Principles

1. **Leveling is a side effect of surviving** — the world doesn't revolve around the player
2. **No clear villains** — every faction has a valid perspective, conflict is systemic
3. **Light ≠ Good, Dark ≠ Evil** — the theme is about what deserves to be lit and what's been hidden
4. **Party is earned** — starting solo, supporting even one member is a milestone
5. **Economy has weight** — wages, faction currencies, shady exchange, beacon-driven property values
6. **Skills through use** — you get better at what you actually do, not what you spend points in
7. **Nothing is permanent** — party members leave, property values shift, beacons go dark again
