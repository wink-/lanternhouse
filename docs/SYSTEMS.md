# Lanternhouse — Systems Design Notes

> Design decisions from brainstorming session (May 26, 2026)

---

## Core Philosophy

Evergreen, persistent MMO-scale world in a Dragon Quest flavor. Leveling is a side effect of surviving, not the main goal.

---

## Leveling & Progression

- **Hard level cap:** 40
- **Pacing:** First 10 levels ~1 hour each, then ~2 hours per level
- **After cap:** Grindy way to keep gaining power with diminishing returns (stat boosts / perk points, no more levels)
- **Stat scaling:** Tight — HP doesn't balloon. Endgame range should keep every hit meaningful.

## Skill System

- **Open skill web:** Anyone can learn anything through use
- **Classes** give starting bonuses and small learning rate bonuses, but don't lock anything
- Skills grow naturally — using an axe while fishing/fighting makes you better at axes

## Currency & Economy

- **Standard coin:** Copper → Silver → Gold
- **Faction currencies:** Each major faction has its own currency (not interchangeable at standard rates)
- **Shady exchange vendors:** Found in ports, back alleys, unlit towns — convert between faction currencies at variable rates
- **Real estate market:** Property values driven by beacon coverage
  - Land lit by a beacon = high value
  - Unlit land = cheap, viable for players who thrive in darkness
- **Home purchase:** The main character buys their own home (separate from the Lanternhouse)
  - Functions: storage, rest, planting/gardening, guest quarters for party members
  - Cooking a meal at home gives a party-wide buff

## Party System

- **Max active size:** 4 members
- **Start:** Solo. Supporting even one party member is hard early on — a milestone when you're established.
- **Wages:** Sliding scale of pay-to-loyalty. Rates are negotiated per member.
- **Loyalty:** Can be earned through favors, gifts, gear, completing personal quests
- **Permanence:** Party members can leave permanently if neglected, underpaid, or mistreated too long
- **NPC uniqueness:** All non-generic NPCs have unique names and slightly randomized skills. Not every Fighter has the same +1 axe.

## Death Penalty

- Lose carried loot (fish, quest items, harvest, etc.)
- Keep equipped gear
- Lose some currency (respawn at a healer who demands payment)
- Respawn at home or nearest healer

## World Feel

- Unique-name NPCs with subtly different skills — gives a personal feel
- Faction currency forces engagement with the world's politics
- Beacon-lit vs unlit land creates natural economic and moral choice
