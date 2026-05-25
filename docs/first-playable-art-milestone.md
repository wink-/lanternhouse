# First Playable Art Milestone

The minimum pixel art needed to replace all colored-block placeholders and
deliver a cohesive visual experience for a first playable demo.

---

## Phase 1: Overworld Walkable (10 assets)

- [ ] `tiles/grass.png` — 16×16 warm green tuft
- [ ] `tiles/path.png` — 16×16 packed dirt
- [ ] `tiles/forest.png` — 16×16 dense canopy top
- [ ] `tiles/mountain.png` — 16×16 rocky peak
- [ ] `tiles/water.png` — 16×64 (4-frame animated wave strip)
- [ ] `tiles/town.png` — 16×16 small building icon with lit window
- [ ] `tiles/bridge.png` — 16×16 wooden plank over blue
- [ ] `overworld/player.png` — 64×64 walk cycle (4 dir × 4 frames)
- [ ] `tiles/cave.png` — 16×16 dark cliff entrance with torch glow
- [ ] `overworld/monster_encounter.png` — 64×64 optional encounter icon

## Phase 2: Town Interior (8 assets)

- [ ] `tiles/wall.png` — 16×16 stone wall with torch
- [ ] `tiles/floor.png` — 16×16 wooden plank floor
- [ ] `tiles/counter.png` — 16×16 shop counter with goods
- [ ] `overworld/npc_merchant.png` — 64×64 NPC sheet
- [ ] `overworld/npc_elder.png` — 64×64 NPC sheet
- [ ] `overworld/npc_innkeeper.png` — 64×64 NPC sheet
- [ ] Tile for weapon shop area — anvil/backdrop
- [ ] Tile for armor shop area — armor stand/backdrop

## Phase 3: Battle (7 assets)

- [ ] `battle/party/fighter.png` — 64×48 (2 idle frames)
- [ ] `battle/party/thief.png` — 64×48
- [ ] `battle/party/blackbelt.png` — 64×48
- [ ] `battle/party/redmage.png` — 64×48
- [ ] `battle/enemies/slime.png` — 96×48 (idle + hit flash)
- [ ] `battle/enemies/imp.png` — 96×48
- [ ] `battle/enemies/wolf.png` — 96×48

## Phase 4: Remaining Enemies (6 assets)

- [ ] `battle/enemies/ghoul.png` — 96×48
- [ ] `battle/enemies/skeleton.png` — 96×48
- [ ] `battle/enemies/ogre.png` — 96×48
- [ ] `battle/enemies/wraith.png` — 96×48
- [ ] `battle/enemies/drake.png` — 96×48
- [ ] `battle/enemies/golem.png` — 96×48

## Phase 5: UI Polish (4 assets)

- [ ] `ui/cursor.png` — 16×16 arrow/pointer
- [ ] `ui/frame_border.png` — 8×8 border tiles for dialog boxes
- [ ] `ui/icons/spell_fire.png` — 16×16 spell icon
- [ ] `ui/icons/spell_cure.png` — 16×16 spell icon

---

## Total: 35 assets for first playable

### Priority Order

1. **Overworld tiles + player** — the first thing players see
2. **Battle party sprites** — next most visible
3. **First 3 enemies** (slime, imp, wolf) — covers early encounters
4. **Town tiles + NPCs** — town exploration
5. **Remaining enemies** — mountain and cave content
6. **UI elements** — polish pass

### Integration Notes

- Assets drop into `assets/sprites/` with no code changes needed.
- `SpriteCache` automatically picks up PNG files that match expected paths.
- Until art exists, colored blocks render as before — incremental replacement.
