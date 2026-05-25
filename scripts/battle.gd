# Battle — visual FF1-style combat: enemies on left, party on right, surprise reversal
extends Node2D

const EnemyDB := preload("res://scripts/data/enemies.gd")
const CharDB := preload("res://scripts/data/classes.gd")

const TILE_SIZE := 16

# ── Battle state ───────────────────────────────────────────────────────────
var enemies: Array = []          # Array[Dictionary]
var round_phase: String = ""     # "command", "resolution", "between", "victory", "defeat", "ran"
var selecting_idx: int = 0
var pending_spell: Dictionary = {}
var turn_order: Array = []
var turn_idx: int = 0
var combat_log: Array = []
var rng := RandomNumberGenerator.new()
var surprised: bool = false
var zone: String = "grassland"

# ── Visual nodes ───────────────────────────────────────────────────────────
@onready var enemy_area: Node2D = $EnemyArea
@onready var party_area: Node2D = $PartyArea
@onready var panel: Panel = $Panel
@onready var text_display: RichTextLabel = $Panel/TextDisplay

# ── Enemy color palette ────────────────────────────────────────────────────
const ENEMY_COLORS := {
	"Slime":    Color("3cb043"),
	"Imp":      Color("9b59b6"),
	"Wolf":     Color("8b7355"),
	"Ghoul":    Color("7db87d"),
	"Skeleton": Color("e8dcc8"),
	"Ogre":     Color("5c3a1e"),
	"Wraith":   Color("4a3066"),
	"Drake":    Color("c0392b"),
	"Golem":    Color("808080"),
}
const PARTY_COLORS := {
	"Fighter":   Color("c0392b"),
	"Thief":     Color("27ae60"),
	"BlackBelt": Color("8b6914"),
	"RedMage":   Color("e74c3c"),
}

# ── Init ───────────────────────────────────────────────────────────────────
func _ready() -> void:
	rng.seed = hash("battle_%d" % Time.get_ticks_msec())
	zone = GameData.get_meta("battle_zone", "grassland")
	surprised = GameData.get_meta("battle_surprise", false)
	_init_enemies()
	round_phase = "command"
	selecting_idx = _first_alive_party()
	_draw_sprites()
	_update_display()

# ── Enemy init ─────────────────────────────────────────────────────────────
func _init_enemies() -> void:
	var formations: Array = []
	match zone:
		"forest":   formations = EnemyDB.forest_formations()
		"mountain": formations = EnemyDB.mountain_formations()
		"cave":     formations = EnemyDB.cave_formations()
		_:          formations = EnemyDB.grassland_formations()
	var formation: Array = formations[rng.randi() % formations.size()]
	for entry in formation:
		var tmpl: Dictionary = EnemyDB.template(entry["name"]).duplicate(true)
		for _i in range(entry["count"]):
			enemies.append({
				"name": entry["name"],
				"hp": tmpl["hp"], "max_hp": tmpl["hp"],
				"atk": tmpl["atk"], "def": tmpl["def"], "agi": tmpl["agi"],
				"xp": tmpl["xp"], "gold": tmpl["gold"],
				"alive": true,
				"command": "",
			})

# ── Sprite drawing ─────────────────────────────────────────────────────────
func _draw_sprites() -> void:
	_clear_children(enemy_area)
	_clear_children(party_area)

	var is_reversed := surprised
	var enemy_x: float = 80.0 if not is_reversed else 720.0
	var party_x: float = 720.0 if not is_reversed else 80.0

	# Draw enemies
	for i in range(enemies.size()):
		var e: Dictionary = enemies[i]
		var py := 80.0 + i * 60.0
		_draw_block(enemy_area, Vector2(enemy_x, py), ENEMY_COLORS.get(e["name"], Color.GRAY), 24)
		_draw_label(enemy_area, Vector2(enemy_x - 40, py + 30), e["name"], 80)
		# HP bar
		var hp_bar := _make_hp_bar(e["hp"], e["max_hp"], 8)
		_draw_label(enemy_area, Vector2(enemy_x - 40, py + 42), hp_bar, 80)

	# Draw party
	for i in range(GameData.party.size()):
		var m: Dictionary = GameData.party[i]
		var py := 80.0 + i * 60.0
		var color := PARTY_COLORS.get(m["class"], Color.GRAY)
		if not m["alive"]:
			color = Color("555555")
		_draw_block(party_area, Vector2(party_x, py), color, 20)
		var info := "%s\nLv%d %s" % [m["name"], m["level"], _hp_text(m["hp"], m["max_hp"])]
		if GameData.equipped_weapon[i] >= 0:
			var w: Dictionary = GameData.weapons_bag[GameData.equipped_weapon[i]]
			info += "\n%s" % w["name"]
		_draw_label(party_area, Vector2(party_x - 50, py + 24), info, 100)

func _clear_children(node: Node2D) -> void:
	for c in node.get_children():
		c.queue_free()

func _draw_block(parent: Node2D, pos: Vector2, color: Color, size: float) -> void:
	var body := Polygon2D.new()
	body.color = color
	body.polygon = PackedVector2Array([
		Vector2(-size, -size*1.3), Vector2(size, -size*1.3),
		Vector2(size*1.3, size), Vector2(0, size*1.3), Vector2(-size*1.3, size)
	])
	body.position = pos
	parent.add_child(body)

func _draw_label(parent: Node2D, pos: Vector2, text: String, width: float) -> void:
	var lbl := RichTextLabel.new()
	lbl.bbcode_enabled = true
	lbl.text = text
	lbl.position = pos
	lbl.size = Vector2(width, 60)
	lbl.fit_content = true
	parent.add_child(lbl)

func _make_hp_bar(hp: int, max_hp: int, width: int) -> String:
	var n := clampi(int(ceil(float(hp) / max_hp * width)), 0, width)
	var s := "[color=#4c9040]"
	for _i in range(n): s += "█"
	s += "[/color][color=#555]"
	for _i in range(width - n): s += "░"
	s += "[/color]"
	return s

func _hp_text(hp: int, max_hp: int) -> String:
	return "%d/%d" % [hp, max_hp]

# ── Input ──────────────────────────────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match round_phase:
		"command":
			_handle_command(event.keycode)
		"magic_target":
			_handle_target(event.keycode)
		"between":
			_advance_round()
		"victory", "defeat", "ran":
			_return_to_overworld()

# ── Command phase ──────────────────────────────────────────────────────────
func _handle_command(keycode: int) -> void:
	var m: Dictionary = GameData.party[selecting_idx]

	if not pending_spell.is_empty():
		_handle_spell_menu(keycode)
		return

	match keycode:
		KEY_1:
			var tg := _first_alive_enemy()
			if tg >= 0:
				m["command"] = "fight:%d" % tg
				m["command_label"] = "Fight"
				_advance_selection()
		KEY_2:
			if _has_spells(m):
				pending_spell = {"level": _first_spell_level(m)}
				_update_display()
			else:
				_push_log("%s has no magic!" % m["name"])
				_update_display()
		KEY_3:
			if GameData.tonics > 0:
				var tg := _lowest_hp_party()
				GameData.tonics -= 1
				var heal: int = min(20, tg["max_hp"] - tg["hp"])
				tg["hp"] += heal
				m["command"] = "item_used"
				m["command_label"] = "Tonic → %s" % tg["name"]
				_push_log("%s uses a Tonic on %s! +%d HP" % [m["name"], tg["name"], heal])
				_advance_selection()
			else:
				_push_log("No tonics left!")
				_update_display()
		KEY_4:
			# Run
			m["command"] = "run"
			m["command_label"] = "Run"
			for m2: Dictionary in GameData.party:
				if m2["alive"] and m2["command"] == "":
					m2["command"] = "pass"
			_start_resolution()
		KEY_TAB:
			selecting_idx = _next_alive_party(selecting_idx)
			_update_display()

func _handle_spell_menu(keycode: int) -> void:
	var m: Dictionary = GameData.party[selecting_idx]
	var lvl: int = pending_spell["level"]
	var spells: Array = CharDB.spells_for_level(lvl)
	var charges: int = m["magic_levels"].get(lvl, {}).get("charges", 0)

	if charges <= 0:
		pending_spell = {}
		_update_display()
		return

	match keycode:
		KEY_1:
			if spells.size() >= 1:
				_pick_spell(m, lvl, 0, spells)
		KEY_2:
			if spells.size() >= 2:
				_pick_spell(m, lvl, 1, spells)
		KEY_3:
			if spells.size() >= 3:
				_pick_spell(m, lvl, 2, spells)
		KEY_ESCAPE:
			pending_spell = {}
			_update_display()
		KEY_TAB:
			var nl := _next_spell_level(m, lvl)
			if nl > 0:
				pending_spell["level"] = nl
			_update_display()

func _pick_spell(m: Dictionary, lvl: int, si: int, spells: Array) -> void:
	var spell: Dictionary = spells[si]
	if spell.get("target", "") == "ally":
		var tg := _lowest_hp_party()
		var ti := _party_index(tg)
		m["magic_levels"][lvl]["charges"] -= 1
		m["command"] = "magic:%d:%d:%d" % [lvl, si, ti]
		m["command_label"] = spell["name"]
		pending_spell = {}
		_advance_selection()
	else:
		pending_spell["spell_idx"] = si
		pending_spell["spell_level"] = lvl
		pending_spell["target_idx"] = _first_alive_enemy()
		round_phase = "magic_target"
		_update_display()

func _handle_target(keycode: int) -> void:
	var m: Dictionary = GameData.party[selecting_idx]
	var alive := _alive_enemy_indices()
	if alive.is_empty():
		pending_spell = {}
		round_phase = "command"
		_update_display()
		return
	var cur: int = pending_spell.get("target_idx", alive[0])
	match keycode:
		KEY_LEFT, KEY_RIGHT, KEY_TAB:
			var pos := alive.find(cur)
			if pos < 0: pos = 0
			pos = (pos + 1) % alive.size()
			pending_spell["target_idx"] = alive[pos]
			_update_display()
		KEY_1, KEY_ENTER, KEY_SPACE:
			var lvl: int = pending_spell["spell_level"]
			var si: int = pending_spell["spell_idx"]
			var ti: int = pending_spell["target_idx"]
			m["magic_levels"][lvl]["charges"] -= 1
			m["command"] = "magic:%d:%d:%d" % [lvl, si, ti]
			m["command_label"] = CharDB.spells_for_level(lvl)[si]["name"]
			pending_spell = {}
			round_phase = "command"
			_advance_selection()
		KEY_ESCAPE:
			round_phase = "command"
			_update_display()

func _advance_selection() -> void:
	selecting_idx = _next_alive_party(selecting_idx)
	if _all_commands_set():
		_start_resolution()
	else:
		_update_display()

func _start_resolution() -> void:
	# Enemy AI: pick random targets
	for ei in range(enemies.size()):
		if enemies[ei]["alive"]:
			var tg := _random_alive_party()
			enemies[ei]["command"] = "fight:%d" % tg
	round_phase = "resolution"
	_build_turn_order()
	turn_idx = 0
	_resolve_next()

func _build_turn_order() -> void:
	turn_order.clear()
	var entries := []
	for pi in range(GameData.party.size()):
		if GameData.party[pi]["alive"]:
			entries.append({"type":"player","index":pi,"speed":GameData.party[pi]["agi"] + rng.randi_range(0,20)})
	for ei in range(enemies.size()):
		if enemies[ei]["alive"]:
			entries.append({"type":"enemy","index":ei,"speed":enemies[ei]["agi"] + rng.randi_range(0,20)})
	entries.sort_custom(func(a, b): return a["speed"] > b["speed"])
	turn_order = entries

func _resolve_next() -> void:
	if turn_idx >= turn_order.size():
		_end_round()
		return
	var entry: Dictionary = turn_order[turn_idx]
	turn_idx += 1
	if entry["type"] == "player":
		_execute_player(entry["index"])
	elif entry["type"] == "enemy":
		_execute_enemy(entry["index"])
	await get_tree().create_timer(0.05).timeout
	_resolve_next()

func _execute_player(pi: int) -> void:
	var m: Dictionary = GameData.party[pi]
	var cmd: String = m["command"]
	if cmd.begins_with("fight:"):
		var tg := int(cmd.split(":")[1])
		if tg < enemies.size() and enemies[tg]["alive"]:
			var dmg := _calc_dmg(_eff_str(pi), enemies[tg]["def"], 2)
			enemies[tg]["hp"] = max(0, enemies[tg]["hp"] - dmg)
			_push_log("%s attacks! %d dmg → %s" % [m["name"], dmg, enemies[tg]["name"]])
			if enemies[tg]["hp"] <= 0:
				enemies[tg]["alive"] = false
				_push_log("%s falls!" % enemies[tg]["name"])
	elif cmd.begins_with("magic:"):
		var p := cmd.split(":")
		var lvl := int(p[1]); var si := int(p[2]); var tg := int(p[3])
		var spell: Dictionary = CharDB.spells_for_level(lvl)[si]
		if spell.get("target", "") == "enemy":
			if tg < enemies.size() and enemies[tg]["alive"]:
				var dmg: int = spell.get("dmg", 10) + rng.randi_range(-2, 2)
				enemies[tg]["hp"] = max(0, enemies[tg]["hp"] - dmg)
				_push_log("%s casts %s! %d dmg → %s" % [m["name"], spell["name"], dmg, enemies[tg]["name"]])
				if enemies[tg]["hp"] <= 0:
					enemies[tg]["alive"] = false
					_push_log("%s falls!" % enemies[tg]["name"])
		else:
			if tg < GameData.party.size() and GameData.party[tg]["alive"]:
				var heal: int = spell.get("heal", 12) + rng.randi_range(-2, 2)
				var actual: int = min(heal, GameData.party[tg]["max_hp"] - GameData.party[tg]["hp"])
				GameData.party[tg]["hp"] += actual
				_push_log("%s casts %s! %s +%d HP" % [m["name"], spell["name"], GameData.party[tg]["name"], actual])
	elif cmd == "run":
		var leader_agi: int = m["agi"]
		var avg_enemy_agi: float = 0.0
		var ec := 0
		for e in enemies:
			if e["alive"]:
				avg_enemy_agi += e["agi"]
				ec += 1
		if ec > 0: avg_enemy_agi /= ec
		var chance: float = clamp(0.2 + (leader_agi - avg_enemy_agi) * 0.06, 0.05, 0.85)
		if rng.randf() < chance:
			_push_log("Ran away safely!")
			round_phase = "ran"
			_update_display()
			return
		else:
			_push_log("Can't escape!")
	elif cmd == "item_used":
		pass  # already applied during command selection
	elif cmd == "pass":
		pass

	_check_end()

func _execute_enemy(ei: int) -> void:
	var e: Dictionary = enemies[ei]
	var cmd: String = e["command"]
	if cmd.begins_with("fight:"):
		var tg := int(cmd.split(":")[1])
		if tg < GameData.party.size() and GameData.party[tg]["alive"]:
			var dmg := _calc_dmg(e["atk"], _eff_def(tg), 2)
			GameData.party[tg]["hp"] = max(0, GameData.party[tg]["hp"] - dmg)
			_push_log("%s attacks %s! %d dmg" % [e["name"], GameData.party[tg]["name"], dmg])
			if GameData.party[tg]["hp"] <= 0:
				GameData.party[tg]["alive"] = false
				_push_log("%s falls!" % GameData.party[tg]["name"])
	_check_end()

func _check_end() -> void:
	if _alive_enemy_count() == 0:
		_victory()
	elif GameData.alive_count() == 0:
		_defeat()

func _end_round() -> void:
	for m: Dictionary in GameData.party:
		if m["alive"]:
			m["command"] = ""
			m["command_label"] = ""
	for e in enemies:
		e["command"] = ""
	if _alive_enemy_count() == 0:
		_victory()
		return
	if GameData.alive_count() == 0:
		_defeat()
		return
	round_phase = "between"
	_push_log("─ End of round ─")
	_update_display()

func _advance_round() -> void:
	round_phase = "command"
	selecting_idx = _first_alive_party()
	pending_spell = {}
	_push_log("─ Next round ─")
	_update_display()

# ── Victory / Defeat ───────────────────────────────────────────────────────
func _victory() -> void:
	round_phase = "victory"
	_draw_sprites()
	var total_xp := 0
	var total_gold := 0
	for e in enemies:
		var tmpl: Dictionary = EnemyDB.template(e["name"])
		total_xp += tmpl["xp"]
		total_gold += tmpl["gold"]
	GameData.gold += total_gold
	_push_log("Victory! +%d XP, +%dg" % [total_xp, total_gold])
	for m: Dictionary in GameData.party:
		if m["alive"]:
			m["xp"] += total_xp
			while m["xp"] >= m["next_xp"]:
				m["xp"] -= m["next_xp"]
				m["level"] += 1
				m["next_xp"] = int(round(m["next_xp"] * 1.4))
				var gains: Dictionary = CharDB.level_up_stats(m["class"], rng)
				m["max_hp"] += gains["hp"]
				m["str"] += gains["str"]
				m["def"] += gains["def"]
				m["agi"] += gains["agi"]
				m["hp"] = m["max_hp"]
				for lvl in m["magic_levels"]:
					m["magic_levels"][lvl]["charges"] = m["magic_levels"][lvl]["max"]
				_push_log("%s → Level %d! HP+%d" % [m["name"], m["level"], gains["hp"]])
	_update_display()

func _defeat() -> void:
	round_phase = "defeat"
	for m: Dictionary in GameData.party:
		m["hp"] = 1
		m["alive"] = true
		for lvl in m["magic_levels"]:
			m["magic_levels"][lvl]["charges"] = m["magic_levels"][lvl]["max"]
	GameData.tonics = 3
	_push_log("Defeat... returned to Lanternhouse.")
	_update_display()

func _return_to_overworld() -> void:
	if round_phase == "victory":
		GameData.cleared_encounters[str(GameData.overworld_position)] = true
	get_tree().change_scene_to_file("res://scenes/overworld/overworld.tscn")

# ── Helpers ────────────────────────────────────────────────────────────────
func _calc_dmg(atk: int, target_def: int, variance: int) -> int:
	return max(1, atk - target_def + rng.randi_range(0, variance))

func _eff_str(pi: int) -> int: return GameData.get_effective_str(pi)

func _eff_def(pi: int) -> int: return GameData.get_effective_def(pi)

func _first_alive_party() -> int:
	for i in range(GameData.party.size()):
		if GameData.party[i]["alive"]: return i
	return 0

func _next_alive_party(start: int) -> int:
	for i in range(start + 1, GameData.party.size()):
		if GameData.party[i]["alive"]: return i
	return _first_alive_party()

func _all_commands_set() -> bool:
	for m: Dictionary in GameData.party:
		if m["alive"] and m["command"] == "": return false
	return true

func _first_alive_enemy() -> int:
	for i in range(enemies.size()):
		if enemies[i]["alive"]: return i
	return -1

func _alive_enemy_indices() -> Array:
	var out: Array = []
	for i in range(enemies.size()):
		if enemies[i]["alive"]: out.append(i)
	return out

func _alive_enemy_count() -> int:
	var c := 0
	for e in enemies:
		if e["alive"]: c += 1
	return c

func _random_alive_party() -> int:
	var alive: Array = []
	for i in range(GameData.party.size()):
		if GameData.party[i]["alive"]: alive.append(i)
	return alive[rng.randi_range(0, alive.size()-1)] if not alive.is_empty() else 0

func _lowest_hp_party() -> Dictionary:
	var best: Dictionary = GameData.party[0]
	for m: Dictionary in GameData.party:
		if m["alive"] and m["hp"] < best["hp"]: best = m
	return best

func _party_index(m: Dictionary) -> int:
	for i in range(GameData.party.size()):
		if GameData.party[i] == m: return i
	return 0

func _has_spells(m: Dictionary) -> bool:
	for lvl in m["magic_levels"]:
		if m["magic_levels"][lvl]["charges"] > 0: return true
	return false

func _first_spell_level(m: Dictionary) -> int:
	for lvl in m["magic_levels"]:
		if m["magic_levels"][lvl]["charges"] > 0: return lvl
	return 0

func _next_spell_level(m: Dictionary, cur: int) -> int:
	var levels: Array = m["magic_levels"].keys()
	levels.sort()
	var found := false
	for lvl in levels:
		if found and m["magic_levels"][lvl]["charges"] > 0: return lvl
		if lvl == cur: found = true
	for lvl in levels:
		if m["magic_levels"][lvl]["charges"] > 0: return lvl
	return 0

func _push_log(msg: String) -> void:
	combat_log.append(msg)
	if combat_log.size() > 10: combat_log.pop_front()

# ── Display ────────────────────────────────────────────────────────────────
func _update_display() -> void:
	_draw_sprites()
	var lines: Array = []
	if surprised: lines.append("[color=#c0392b][b]AMBUSH! Enemies strike first![/b][/color]")

	if round_phase == "victory":
		lines.append("[b][color=#f0d46a]★★ VICTORY ★★[/color][/b]")
	elif round_phase == "defeat":
		lines.append("[b][color=#c0392b]★ DEFEAT ★[/color][/b]")
	elif round_phase == "ran":
		lines.append("[b]Ran away safely![/b]")
	elif round_phase in ["command", "magic_target"]:
		var m: Dictionary = GameData.party[selecting_idx]
		if pending_spell.is_empty():
			lines.append("[b]%s's turn[/b]  [1]Fight [2]Magic [3]Item [4]Run [Tab]Skip" % m["name"])
		elif round_phase == "magic_target":
			var si: int = pending_spell.get("spell_idx", 0)
			var lvl: int = pending_spell.get("spell_level", 1)
			var sn := CharDB.spells_for_level(lvl)[si]["name"]
			lines.append("[b]Target for %s:[/b] arrows to switch, [1]/Enter to confirm" % sn)
		else:
			var lvl: int = pending_spell["level"]
			var spells: Array = CharDB.spells_for_level(lvl)
			lines.append("[b]%s — Lv%d Magic[/b] %d charges" % [m["name"], lvl, m["magic_levels"].get(lvl,{}).get("charges",0)])
			for si in range(spells.size()):
				lines.append("  [%d]%s" % [si+1, spells[si]["name"]])
			lines.append("  [Esc]Back [Tab]Next lv")
	elif round_phase == "between":
		lines.append("[b]Press any key for next round...[/b]")

	# Combat log
	if not combat_log.is_empty():
		lines.append("")
		for msg in combat_log.slice(max(0, combat_log.size()-4)):
			lines.append("[i]%s[/i]" % msg)

	text_display.text = "\n".join(lines)
