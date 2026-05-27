# Battle — FF1-style combat with Guard, target selection, and zone-based enemies
#
# [CODING CONCEPT: State Machine]
# This entire file is driven by a string variable called round_phase.
# Possible values: "command", "fight_target", "magic_target", "resolution",
# "between", "victory", "defeat", "ran", "endgame_choice"
# Each phase has different input handling and display. When the player presses
# a key, _unhandled_input() checks round_phase and routes to the right handler.
# This pattern — one variable controlling which "state" the code is in — is
# called a Finite State Machine. It's the backbone of most game UI.
#
# [CODING CONCEPT: Turn-Based Game Loop]
# The battle loop goes: COMMAND phase (pick actions) → RESOLUTION phase
# (execute them in speed order) → BETWEEN phase (press key) → repeat.
# Commands are stored as strings like "fight:3" or "magic:1:0:2" — the
# colons separate parameters, parsed by splitting on ":" during resolution.
# String-based commands are flexible but error-prone; a real engine would
# use an enum + data object instead.
extends Node2D

const EnemyDB := preload("res://scripts/data/enemies.gd")
const CharDB := preload("res://scripts/data/classes.gd")
const FactionDB := preload("res://scripts/data/factions.gd")

const TILE_SIZE := 16
const MAX_LEVEL := 40

# ── Zone backgrounds ──────────────────────────────────────────────────────
const ZONE_BG := {
	"grassland": Color("2d5016"),
	"forest":    Color("1a3a10"),
	"mountain":  Color("4a4035"),
	"cave":      Color("1a1520"),
	"cave_boss": Color("0d0020"),
	"beach":     Color("4a6830"),
	"post_seal": Color("1a1030"),
	"cave_deep": Color("080015"),
}

# ── Damage numbers ────────────────────────────────────────────────────────
var _floating_labels: Array = []
var _enemy_x: float = 80.0
var _party_x: float = 720.0
const FLOAT_DURATION := 1.2

# ── Battle state ───────────────────────────────────────────────────────────
# The state machine lives here. round_phase controls which inputs are valid
# and what gets displayed. Think of it as the "mode" the battle is in.
# Commands like "fight:3" are stored on each party member/enemy until
# resolution phase reads and executes them.
var enemies: Array = []
var round_phase: String = ""     # "command", "fight_target", "magic_target", "resolution", "between", "victory", "defeat", "ran"
var selecting_idx: int = 0
var pending_spell: Dictionary = {}
var fight_target_idx: int = 0
var endgame_choice_idx: int = 0
var turn_order: Array = []
var turn_idx: int = 0
var combat_log: Array = []
var rng := RandomNumberGenerator.new()
var surprised: bool = false
var zone: String = "grassland"
var weather: String = "clear"
var _pre_buff_stats: Dictionary = {}
var _status_effects: Dictionary = {}  # party_name -> {"type": str, "turns": int, "dmg": int}
var _boss_special_idx: int = 0
var _enemy_spawn_queue: Array = []  # enemies to spawn mid-battle (boss summons)
var _screen_flash_timer: float = 0.0
var _screen_flash_color: Color = Color.WHITE
var _screen_shake_timer: float = 0.0
var _screen_shake_intensity: float = 0.0

# ── Visual nodes ───────────────────────────────────────────────────────────
@onready var enemy_area: Node2D = $EnemyArea
@onready var party_area: Node2D = $PartyArea
@onready var panel: Panel = $Panel
@onready var text_display: RichTextLabel = $Panel/TextDisplay
@onready var background: ColorRect = $Background

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
	"Mournlight Shade": Color("4a0080"),
	"ShadowWisp": Color("6a3aaa"),
	"AncientGrief": Color("2a1a4a"),
	"DarkShade": Color("2a0a3a"),
}
const PARTY_COLORS := {
	"Fighter":   Color("c0392b"),
	"Thief":     Color("27ae60"),
	"BlackBelt": Color("8b6914"),
	"RedMage":   Color("e74c3c"),
	"WhiteMage": Color("ecf0f1"),
	"BlackMage": Color("8e44ad"),
}

# ── Init ───────────────────────────────────────────────────────────────────
func _ready() -> void:
	rng.seed = hash("battle_%d" % Time.get_ticks_msec())
	zone = GameData.get_meta("battle_zone", "grassland")
	weather = GameData.get_meta("battle_weather", "clear")
	surprised = GameData.get_meta("battle_surprise", false)
	if surprised:
		_enemy_x = 720.0
		_party_x = 80.0
	if background:
		var bg_color: Color = ZONE_BG.get(zone, ZONE_BG["grassland"])
		if weather == "rain":
			bg_color = bg_color.darkened(0.15)
		background.color = bg_color
	_init_enemies()
	for m: Dictionary in GameData.party:
		_pre_buff_stats[m["name"]] = {"str": m["str"], "def": m["def"], "agi": m["agi"]}
	round_phase = "command"
	selecting_idx = _first_alive_party()
	fight_target_idx = _first_alive_enemy()
	_draw_sprites()
	_update_display()

# ── Floating damage numbers ──────────────────────────────────────────────────
func _process(delta: float) -> void:
	var remaining_labels: Array = []
	for entry in _floating_labels:
		entry["timer"] -= delta
		if entry["timer"] <= 0.0:
			entry["node"].queue_free()
		else:
			var progress: float = 1.0 - (entry["timer"] / FLOAT_DURATION)
			entry["node"].position.y = entry["start_y"] - progress * 30.0
			entry["node"].modulate.a = clampf(entry["timer"] / 0.4, 0.0, 1.0)
			remaining_labels.append(entry)
	_floating_labels = remaining_labels
	# Screen flash
	if _screen_flash_timer > 0:
		_screen_flash_timer -= delta
		if background:
			var orig: Color = ZONE_BG.get(zone, ZONE_BG["grassland"])
			var blend: Color = _screen_flash_color if _screen_flash_timer > 0 else orig
			background.color = blend
			if _screen_flash_timer <= 0:
				background.color = orig
	else:
		if background:
			background.color = ZONE_BG.get(zone, ZONE_BG["grassland"])
	# Screen shake via camera
	if _screen_shake_timer > 0:
		_screen_shake_timer -= delta
		if enemy_area:
			enemy_area.position = Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * _screen_shake_intensity
		if party_area:
			party_area.position = Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * _screen_shake_intensity
		if _screen_shake_timer <= 0:
			if enemy_area: enemy_area.position = Vector2.ZERO
			if party_area: party_area.position = Vector2.ZERO

func _show_damage_number(world_pos: Vector2, text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.position = world_pos
	label.z_index = 100
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 18)
	add_child(label)
	_floating_labels.append({"node": label, "timer": FLOAT_DURATION, "start_y": world_pos.y})

func _enemy_pos(i: int) -> Vector2:
	var spacing: float = 60.0 if enemies.size() <= 4 else (300.0 / max(enemies.size() - 1, 1))
	return Vector2(_enemy_x, 80.0 + i * spacing - 30.0)

func _party_pos(i: int) -> Vector2:
	return Vector2(_party_x, 80.0 + i * 60.0 - 30.0)

func _screen_flash(color: Color = Color.WHITE) -> void:
	_screen_flash_timer = 0.12
	_screen_flash_color = color

func _screen_shake(intensity: float = 3.0) -> void:
	_screen_shake_timer = 0.15
	_screen_shake_intensity = intensity

func _spawn_spell_effect(pos: Vector2, color: Color) -> void:
	var particles := CPUParticles2D.new()
	particles.position = pos
	particles.emitting = true
	particles.amount = 12
	particles.lifetime = 0.4
	particles.explosiveness = 0.8
	particles.direction = Vector2(0, -1)
	particles.spread = 45.0
	particles.initial_velocity_min = 20.0
	particles.initial_velocity_max = 60.0
	particles.gravity = Vector2(0, 40)
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.modulate = color

func _spawn_slash_effect(pos: Vector2) -> void:
	var slash := Line2D.new()
	slash.position = pos
	slash.width = 3.0
	slash.default_color = Color("ffffff")
	slash.z_index = 99
	var pts := PackedVector2Array()
	for i in range(8):
		var t := float(i) / 7.0
		pts.append(Vector2(-12 + t * 24, -8 + t * 16 + sin(t * PI) * -6))
	slash.points = pts
	add_child(slash)
	var tween := create_tween()
	tween.tween_property(slash, "modulate:a", 0.0, 0.25)
	tween.tween_callback(slash.queue_free)


# ── Enemy init ─────────────────────────────────────────────────────────────
func _init_enemies() -> void:
	var max_party_lvl := 1
	for m: Dictionary in GameData.party:
		max_party_lvl = maxi(max_party_lvl, m["level"])
	if zone == "cave_boss":
		var tmpl: Dictionary = EnemyDB.scaled_template("Mournlight Shade", max_party_lvl)
		enemies.append({
			"name": "Mournlight Shade",
			"hp": tmpl["hp"], "max_hp": tmpl["hp"],
			"atk": tmpl["atk"], "def": tmpl["def"], "agi": tmpl.get("agi", 6),
			"xp": tmpl["xp"], "gold": tmpl["gold"],
			"alive": true, "command": "",
		})
		return
	var new_enemies: Array = EnemyDB.get_formation(zone, max_party_lvl)
	var multi_chance: float = {"forest": 0.25, "mountain": 0.30, "cave": 0.35, "beach": 0.10}.get(zone, 0.15)
	if max_party_lvl >= 5 and rng.randf() < multi_chance:
		new_enemies.append_array(EnemyDB.get_formation(zone, max_party_lvl))
	while new_enemies.size() > 8:
		new_enemies.pop_back()
	for e: Dictionary in new_enemies:
		enemies.append({
			"name": e["name"],
			"hp": e["hp"], "max_hp": e["hp"],
			"atk": e["atk"], "def": e["def"], "agi": e.get("agi", 2),
			"xp": e["xp"], "gold": e["gold"],
			"alive": true, "command": "",
		})

func _draw_sprites() -> void:
	_clear_children(enemy_area)
	_clear_children(party_area)

	# Draw enemies
	var alive_enemies := _alive_enemy_indices()
	for i in range(enemies.size()):
		var e: Dictionary = enemies[i]
		var enemy_spacing: float = 60.0 if enemies.size() <= 4 else (300.0 / max(enemies.size() - 1, 1))
		var py: float = 80.0 + i * enemy_spacing
		var base_color: Color = ENEMY_COLORS.get(e["name"], Color.GRAY)
		if not e["alive"]:
			base_color = Color("333333")
		_draw_block(enemy_area, Vector2(_enemy_x, py), base_color, 24)
		# Show target indicator
		if round_phase in ["fight_target", "magic_target"]:
			var is_selected := false
			if round_phase == "fight_target" and i == fight_target_idx:
				is_selected = true
			elif round_phase == "magic_target" and i == pending_spell.get("target_idx", -1):
				is_selected = true
			if is_selected and e["alive"]:
				_draw_target_arrow(enemy_area, Vector2(_enemy_x, py - 34))
		_draw_label(enemy_area, Vector2(_enemy_x - 40, py + 30), e["name"], 80)
		var hp_bar := _make_hp_bar(e["hp"], e["max_hp"], 8)
		_draw_label(enemy_area, Vector2(_enemy_x - 40, py + 42), hp_bar, 80)

	# Draw party
	for i in range(GameData.party.size()):
		var m: Dictionary = GameData.party[i]
		var py: float = 80.0 + i * 60.0
		var color: Color = PARTY_COLORS.get(m["class"], Color.GRAY)
		if not m["alive"]:
			color = Color("555555")
		_draw_block(party_area, Vector2(_party_x, py), color, 20)
		var info := "%s\nLv%d %s" % [m["name"], m["level"], _hp_text(m["hp"], m["max_hp"])]
		var status_name: String = m["name"]
		if _status_effects.has(status_name):
			var eff: Dictionary = _status_effects[status_name]
			info += " [%s]" % eff["type"]
		if GameData.equipped_weapon[i] >= 0:
			var w: Dictionary = GameData.weapons_bag[GameData.equipped_weapon[i]]
			info += "\n%s" % w["name"]
		_draw_label(party_area, Vector2(_party_x - 50, py + 24), info, 100)

func _draw_target_arrow(parent: Node2D, pos: Vector2) -> void:
	var arrow := Polygon2D.new()
	arrow.color = Color("f0d46a")
	arrow.polygon = PackedVector2Array([
		Vector2(-6, 0), Vector2(6, 0), Vector2(0, 10)
	])
	arrow.position = pos
	parent.add_child(arrow)

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
		"fight_target":
			_handle_fight_target(event.keycode)
		"magic_target":
			_handle_target(event.keycode)
		"between":
			_advance_round()
		"endgame_choice":
			_handle_endgame_choice(event.keycode)
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
			# Fight — go to target selection
			if _alive_enemy_count() > 0:
				fight_target_idx = _first_alive_enemy()
				round_phase = "fight_target"
				_update_display()
		KEY_2:
			# Guard
			m["command"] = "guard"
			m["command_label"] = "Guard"
			_advance_selection()
		KEY_3:
			if _has_spells(m):
				pending_spell = {"level": _first_spell_level(m)}
				_update_display()
			else:
				_push_log("%s has no magic!" % m["name"])
				_update_display()
		KEY_4:
			# Item — tonic, ether, crafted potions, smoke bomb
			var used_item := false
			if GameData.tonics > 0:
				var tg := _lowest_hp_party()
				if tg["hp"] < tg["max_hp"]:
					GameData.tonics -= 1
					var heal: int = min(20, tg["max_hp"] - tg["hp"])
					tg["hp"] += heal
					m["command"] = "item_used"
					m["command_label"] = "Tonic → %s" % tg["name"]
					_push_log("%s uses a Tonic on %s! +%d HP" % [m["name"], tg["name"], heal])
					used_item = true
			if not used_item and GameData.ethers > 0:
				var tg: Variant = _lowest_mp_party()
				if tg != null:
					GameData.ethers -= 1
					for lvl: int in tg["magic_levels"]:
						tg["magic_levels"][lvl]["charges"] = tg["magic_levels"][lvl]["max"]
					m["command"] = "item_used"
					m["command_label"] = "Ether → %s" % tg["name"]
					_push_log("%s uses an Ether on %s! MP restored!" % [m["name"], tg["name"]])
					used_item = true
			# Crafted consumables from alchemy
			if not used_item:
				for ci in range(GameData.crafted_items.size() - 1, -1, -1):
					var crafted: Dictionary = GameData.crafted_items[ci]
					if crafted.get("type") != "consumable":
						continue
					var effect: Dictionary = crafted.get("effect", {})
					match effect.get("type", ""):
						"heal":
							var tg: Variant = _lowest_hp_party()
							if tg["hp"] < tg["max_hp"]:
								GameData.crafted_items.remove_at(ci)
								var heal: int = min(effect.get("hp", 15), tg["max_hp"] - tg["hp"])
								tg["hp"] += heal
								m["command"] = "item_used"
								m["command_label"] = "%s → %s" % [crafted["name"], tg["name"]]
								_push_log("%s uses %s on %s! +%d HP" % [m["name"], crafted["name"], tg["name"], heal])
								used_item = true
								break
						"ether":
							var tg: Variant = _lowest_mp_party()
							if tg != null:
								GameData.crafted_items.remove_at(ci)
								var charges: int = effect.get("charges", 2)
								for lvl: int in tg["magic_levels"]:
									tg["magic_levels"][lvl]["charges"] = mini(tg["magic_levels"][lvl]["charges"] + charges, tg["magic_levels"][lvl]["max"])
								m["command"] = "item_used"
								m["command_label"] = "%s → %s" % [crafted["name"], tg["name"]]
								_push_log("%s uses %s on %s! +%d charges" % [m["name"], crafted["name"], tg["name"], charges])
								used_item = true
								break
						"full_restore":
							GameData.crafted_items.remove_at(ci)
							var tg := _lowest_hp_party()
							tg["hp"] = tg["max_hp"]
							for lvl: int in tg["magic_levels"]:
								tg["magic_levels"][lvl]["charges"] = tg["magic_levels"][lvl]["max"]
							m["command"] = "item_used"
							m["command_label"] = "%s → %s" % [crafted["name"], tg["name"]]
							_push_log("%s uses %s on %s! Fully restored!" % [m["name"], crafted["name"], tg["name"]])
							used_item = true
							break
						"buff":
							GameData.crafted_items.remove_at(ci)
							var stat: String = effect.get("stat", "str")
							var amount: int = effect.get("amount", 3)
							m[stat] += amount
							m["command"] = "item_used"
							m["command_label"] = "%s (+%d %s)" % [crafted["name"], amount, stat.to_upper()]
							_push_log("%s uses %s! +%d %s for this battle!" % [m["name"], crafted["name"], amount, stat.to_upper()])
							used_item = true
							break
			if not used_item:
				for g in GameData.trade_goods:
					if g["id"] == "smoke_bomb":
						GameData.trade_goods.erase(g)
						m["command"] = "smoke_bomb"
						m["command_label"] = "Smoke Bomb"
						for m2: Dictionary in GameData.party:
							if m2["alive"] and m2["command"] == "":
								m2["command"] = "pass"
						_start_resolution()
						used_item = true
						break
			if used_item:
				_advance_selection()
			else:
				_push_log("No items available!")
				_update_display()

		KEY_5:
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

func _handle_fight_target(keycode: int) -> void:
	var alive := _alive_enemy_indices()
	if alive.is_empty():
		round_phase = "command"
		_update_display()
		return
	match keycode:
		KEY_UP, KEY_LEFT:
			var pos := alive.find(fight_target_idx)
			if pos < 0: pos = 0
			pos = (pos - 1 + alive.size()) % alive.size()
			fight_target_idx = alive[pos]
			_update_display()
		KEY_DOWN, KEY_RIGHT:
			var pos := alive.find(fight_target_idx)
			if pos < 0: pos = 0
			pos = (pos + 1) % alive.size()
			fight_target_idx = alive[pos]
			_update_display()
		KEY_1, KEY_ENTER, KEY_SPACE:
			var m: Dictionary = GameData.party[selecting_idx]
			m["command"] = "fight:%d" % fight_target_idx
			m["command_label"] = "Fight → %s" % enemies[fight_target_idx]["name"]
			round_phase = "command"
			_advance_selection()
		KEY_ESCAPE:
			round_phase = "command"
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
	var alive := _alive_enemy_indices()
	if alive.is_empty():
		pending_spell = {}
		round_phase = "command"
		_update_display()
		return
	var cur: int = pending_spell.get("target_idx", alive[0])
	match keycode:
		KEY_UP, KEY_LEFT:
			var pos := alive.find(cur)
			if pos < 0: pos = 0
			pos = (pos - 1 + alive.size()) % alive.size()
			pending_spell["target_idx"] = alive[pos]
			_update_display()
		KEY_DOWN, KEY_RIGHT, KEY_TAB:
			var pos := alive.find(cur)
			if pos < 0: pos = 0
			pos = (pos + 1) % alive.size()
			pending_spell["target_idx"] = alive[pos]
			_update_display()
		KEY_1, KEY_ENTER, KEY_SPACE:
			var m: Dictionary = GameData.party[selecting_idx]
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
			pending_spell = {}
			_update_display()

func _handle_endgame_choice(keycode: int) -> void:
	match keycode:
		KEY_UP:
			endgame_choice_idx = maxi(0, endgame_choice_idx - 1)
			_update_display()
		KEY_DOWN:
			endgame_choice_idx = mini(2, endgame_choice_idx + 1)
			_update_display()
		KEY_1, KEY_ENTER, KEY_SPACE:
			_confirm_endgame_choice()

func _confirm_endgame_choice() -> void:
	var choice_names := ["restore_seal", "break_seal", "rebuild_line"]
	var choice: String = choice_names[endgame_choice_idx]
	GameData.set_meta("endgame_choice", choice)
	GameData.set_meta("endgame_choice_made", true)
	match choice:
		"restore_seal":
			for key in GameData.beacon_states:
				GameData.beacon_states[key] = true
			GameData.beacon_lit = true
			GameData.change_faction_rep(FactionDB.Faction.KEEPERS_GUILD, 20)
			GameData.change_faction_rep(FactionDB.Faction.THE_UNLIT, -15)
			_push_log("[color=cyan]The seal is restored. Ancient grief returns to slumber.[/color]")
			_push_log("[color=gray]The fog settles back. The Line burns bright.[/color]")
			_push_log("[color=gray]But the Keepers know the truth now. Nothing will be the same.[/color]")
		"break_seal":
			GameData.beacon_lit = true
			GameData.change_faction_rep(FactionDB.Faction.THE_UNLIT, 20)
			GameData.change_faction_rep(FactionDB.Faction.KEEPERS_GUILD, -10)
			GameData.change_faction_rep(FactionDB.Faction.GREY_CHAPEL, -10)
			_push_log("[color=yellow]The seal shatters. Ancient grief dissipates.[/color]")
			_push_log("[color=gray]The fog lifts forever. The Line goes dark - no longer needed.[/color]")
			_push_log("[color=gray]Some say mercy. Others say recklessness. Time will judge.[/color]")
		"rebuild_line":
			for key in GameData.beacon_states:
				GameData.beacon_states[key] = true
			GameData.beacon_lit = true
			GameData.change_faction_rep(FactionDB.Faction.KEEPERS_GUILD, 10)
			GameData.change_faction_rep(FactionDB.Faction.GREY_CHAPEL, 10)
			GameData.change_faction_rep(FactionDB.Faction.HARBOR_COMPACT, 10)
			GameData.change_faction_rep(FactionDB.Faction.THE_UNLIT, 5)
			_push_log("[color=green]You rebuild the Line - not as prison, but as guardian.[/color]")
			_push_log("[color=gray]The grief is contained, not caged. All factions see the wisdom.[/color]")
			_push_log("[color=gray]Brindlewick enters a new age.[/color]")
	_check_quest_progress()
	round_phase = "victory"
	_update_display()

func _advance_selection() -> void:
	selecting_idx = _next_alive_party(selecting_idx)
	if _all_commands_set():
		_start_resolution()
	else:
		_update_display()

func _start_resolution() -> void:
	for ei in range(enemies.size()):
		if not enemies[ei]["alive"]:
			continue
		var ai: String = EnemyDB.get_ai(enemies[ei]["name"])
		var tg := _pick_enemy_target(ei, ai)
		var cmd_type := "fight"
		var spec: Dictionary = EnemyDB.get_special(enemies[ei]["name"])
		# Boss special attacks every other turn
		if spec.has("specials"):
			var specials: Array = spec["specials"]
			if specials.size() > 0 and _boss_special_idx % 2 == 1:
				cmd_type = "special:%s" % specials[_boss_special_idx / 2 % specials.size()]
			_boss_special_idx += 1
		enemies[ei]["command"] = "%s:%d" % [cmd_type, tg]
	# Process spawn queue from boss summons
	for spawn in _enemy_spawn_queue:
		var s: Dictionary = spawn.duplicate(true)
		enemies.append(s)
		_draw_sprites()
	_enemy_spawn_queue.clear()
	round_phase = "resolution"
	_build_turn_order()
	turn_idx = 0
	_resolve_next()

# [CODING CONCEPT: Sorting by Custom Criteria]
# Characters and enemies all act in one round, but WHO goes first matters.
# This function collects everyone's AGI (speed) stat, adds random jitter,
# then sorts fastest-first. sort_custom takes a comparison function —
# a tiny piece of code that says "a goes before b if a.speed > b.speed".
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
	if round_phase != "resolution":
		return
	if turn_idx >= turn_order.size():
		_end_round()
		return
	var entry: Dictionary = turn_order[turn_idx]
	turn_idx += 1
	if entry["type"] == "player":
		_execute_player(entry["index"])
	elif entry["type"] == "enemy":
		_execute_enemy(entry["index"])
	if round_phase != "resolution":
		return
	await get_tree().create_timer(0.05).timeout
	_resolve_next()

func _execute_player(pi: int) -> void:
	var m: Dictionary = GameData.party[pi]
	var cmd: String = m["command"]

	# Loyalty refusal check (only for recruited NPCs with wage/loyalty)
	if m.has("loyalty") and m.get("wage", 0) > 0:
		var loyalty: int = m["loyalty"]
		if loyalty <= 10:
			_push_log("%s refuses to fight!" % m["name"])
			_screen_flash(Color("555555"))
			m["command"] = "pass"
			cmd = "pass"
		elif loyalty <= 20 and rng.randf() < 0.4:
			_push_log("%s refuses to fight!" % m["name"])
			_screen_flash(Color("555555"))
			m["command"] = "pass"
			cmd = "pass"
		elif loyalty <= 35 and rng.randf() < 0.15:
			_push_log("%s hesitates..." % m["name"])
			m["command"] = "pass"
			cmd = "pass"

	if cmd.begins_with("fight:"):
		var tg := int(cmd.split(":")[1])
		if tg < enemies.size() and enemies[tg]["alive"]:
			var roll := rng.randf()
			var miss_chance := 0.05
			if _has_status(pi, "blind"):
				miss_chance += 0.30
			if weather == "rain":
				miss_chance += 0.08
			if roll < miss_chance:
				_push_log("%s attacks %s... but misses!" % [m["name"], enemies[tg]["name"]])
				_show_damage_number(_enemy_pos(tg), "MISS", Color.GRAY)
				_screen_shake(1.0)
			else:
				var dmg := _calc_dmg(_eff_str(pi), enemies[tg]["def"], 2) + GameData.get_skill_bonus("weapon")
				var is_crit := roll >= 0.90
				if is_crit:
					dmg *= 2
				enemies[tg]["hp"] = max(0, enemies[tg]["hp"] - dmg)
				if is_crit:
					_spawn_slash_effect(_enemy_pos(tg))
					_push_log("%s CRITICAL! %d dmg → %s" % [m["name"], dmg, enemies[tg]["name"]])
					_show_damage_number(_enemy_pos(tg), str(dmg), Color.GOLD)
					_screen_flash(Color("ffaa00"))
					_screen_shake(6.0)
					GameData.track_skill_use("weapon")
				else:
					_spawn_slash_effect(_enemy_pos(tg))
					_push_log("%s attacks! %d dmg → %s" % [m["name"], dmg, enemies[tg]["name"]])
					_show_damage_number(_enemy_pos(tg), str(dmg), Color.WHITE)
					_screen_flash(Color("ffffff"))
					_screen_shake(2.0)
					GameData.track_skill_use("weapon")
				if enemies[tg]["hp"] <= 0:
					enemies[tg]["alive"] = false
					GameData.track_kill(enemies[tg]["name"])
					_push_log("%s falls!" % enemies[tg]["name"])
	elif cmd == "guard":
		_push_log("%s takes a defensive stance!" % m["name"])
	elif cmd.begins_with("magic:"):
		if _has_status(pi, "silence"):
			_push_log("[color=purple]%s is silenced! Spell fizzles![/color]" % m["name"])
			_screen_flash(Color("555555"))
		else:
			var p := cmd.split(":")
			var lvl := int(p[1]); var si := int(p[2]); var tg := int(p[3])
			var spell: Dictionary = CharDB.spells_for_level(lvl)[si]
			if spell.get("target", "") == "enemy":
				if tg < enemies.size() and enemies[tg]["alive"]:
					var dmg: int = spell.get("dmg", 10) + rng.randi_range(-2, 2) + GameData.get_skill_bonus("magic")
					enemies[tg]["hp"] = max(0, enemies[tg]["hp"] - dmg)
					_show_damage_number(_enemy_pos(tg), str(dmg), Color("ff8844"))
					_spawn_spell_effect(_enemy_pos(tg), Color("ff8844"))
					_screen_flash(Color("ff6600"))
					GameData.track_skill_use("magic")
					GameData.set_meta("offensive_casts", GameData.get_meta("offensive_casts", 0) + 1)
					_push_log("%s casts %s! %d dmg → %s" % [m["name"], spell["name"], dmg, enemies[tg]["name"]])
					if enemies[tg]["hp"] <= 0:
						enemies[tg]["alive"] = false
						GameData.track_kill(enemies[tg]["name"])
						_push_log("%s falls!" % enemies[tg]["name"])
			else:
				if tg < GameData.party.size() and GameData.party[tg]["alive"]:
					var heal: int = spell.get("heal", 12) + rng.randi_range(-2, 2) + GameData.get_skill_bonus("healing")
					var actual: int = min(heal, GameData.party[tg]["max_hp"] - GameData.party[tg]["hp"])
					GameData.party[tg]["hp"] += actual
					_show_damage_number(_party_pos(tg), "+%d" % actual, Color("66ff66"))
					_spawn_spell_effect(_party_pos(tg), Color("66ff66"))
					GameData.track_skill_use("healing")
					GameData.set_meta("heal_casts", GameData.get_meta("heal_casts", 0) + 1)
					_push_log("%s casts %s! %s +%d HP" % [m["name"], spell["name"], GameData.party[tg]["name"], actual])
	elif cmd == "smoke_bomb":
		_push_log("%s throws a Smoke Bomb! Escaped!" % m["name"])
		round_phase = "ran"
		_update_display()
		return
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
			_push_log("Can't escape! Exposed!")
			_screen_shake(2.0)
			var alive_enemies: Array = []
			for ei in range(enemies.size()):
				if enemies[ei]["alive"]:
					alive_enemies.append(ei)
			if not alive_enemies.is_empty():
				var attacker_idx: int = alive_enemies[rng.randi() % alive_enemies.size()]
				var target_def: int = _eff_def(pi) - 2
				var dmg := _calc_dmg(enemies[attacker_idx]["atk"], target_def, 2)
				m["hp"] = max(0, m["hp"] - dmg)
				_show_damage_number(_party_pos(pi), str(dmg), Color("ff6666"))
				_push_log("%s strikes %s for %d dmg!" % [enemies[attacker_idx]["name"], m["name"], dmg])
				if m["hp"] <= 0:
					m["alive"] = false
					if m.has("loyalty"):
						m["loyalty"] = maxi(m["loyalty"] - 5, 0)
						if m["loyalty"] <= 0 and m.get("wage", 0) > 0:
							m["departed"] = true
							GameData.pending_departures.append(m["name"])
							_push_log("[color=red]%s's loyalty breaks! They will leave after battle![/color]" % m["name"])
					_push_log("%s falls!" % m["name"])
	elif cmd == "item_used":
		pass
	elif cmd == "pass":
		pass

	_check_end()

func _execute_enemy(ei: int) -> void:
	if ei < 0 or ei >= enemies.size() or not enemies[ei].get("alive", false):
		return
	var e: Dictionary = enemies[ei]
	var cmd: String = e["command"]
	if cmd.begins_with("special:"):
		_execute_boss_special(ei, cmd)
	elif cmd.begins_with("fight:"):
		var tg := int(cmd.split(":")[1])
		if tg < GameData.party.size() and GameData.party[tg]["alive"]:
			var target_def := _eff_def(tg)
			if GameData.party[tg]["command"] == "guard":
				target_def *= 2
			var dmg := _calc_dmg(e["atk"], target_def, 2)
			GameData.party[tg]["hp"] = max(0, GameData.party[tg]["hp"] - dmg)
			_show_damage_number(_party_pos(tg), str(dmg), Color("ff6666"))
			_screen_flash(Color("ff0000"))
			_screen_shake(3.0)
			var guard_msg := " (guarded!)" if GameData.party[tg]["command"] == "guard" else ""
			_push_log("%s attacks %s! %d dmg%s" % [e["name"], GameData.party[tg]["name"], dmg, guard_msg])
			# Status effect on hit
			var spec: Dictionary = EnemyDB.get_special(e["name"])
			if spec.has("effect") and rng.randf() < spec.get("chance", 0.0):
				_apply_status_effect(tg, spec["effect"])
			if GameData.party[tg]["hp"] <= 0:
				GameData.party[tg]["alive"] = false
				if GameData.party[tg].has("loyalty"):
					GameData.party[tg]["loyalty"] = maxi(GameData.party[tg]["loyalty"] - 5, 0)
					if GameData.party[tg]["loyalty"] <= 0 and GameData.party[tg].get("wage", 0) > 0:
						GameData.party[tg]["departed"] = true
						GameData.pending_departures.append(GameData.party[tg]["name"])
						_push_log("[color=red]%s\'s loyalty breaks! They will leave after battle![/color]" % GameData.party[tg]["name"])
				_push_log("%s falls!" % GameData.party[tg]["name"])
	_check_end()

func _execute_boss_special(ei: int, cmd: String) -> void:
	var e: Dictionary = enemies[ei]
	var parts := cmd.split(":")
	var tg_str := parts[parts.size() - 1]
	var tg := int(tg_str)
	var ability: String = parts[1]
	match ability:
		"shadow_bolt":
			if tg < GameData.party.size() and GameData.party[tg]["alive"]:
				var dmg := _calc_dmg(e["atk"] + 4, _eff_def(tg), 3)
				GameData.party[tg]["hp"] = max(0, GameData.party[tg]["hp"] - dmg)
				_show_damage_number(_party_pos(tg), str(dmg), Color("aa44ff"))
				_spawn_spell_effect(_party_pos(tg), Color("aa44ff"))
				_screen_flash(Color("6600aa"))
				_screen_shake(4.0)
				_push_log("[color=purple]%s fires a Shadow Bolt! %d dmg -> %s[/color]" % [e["name"], dmg, GameData.party[tg]["name"]])
				if GameData.party[tg]["hp"] <= 0:
					GameData.party[tg]["alive"] = false
					_push_log("%s falls!" % GameData.party[tg]["name"])
		"life_drain":
			if tg < GameData.party.size() and GameData.party[tg]["alive"]:
				var dmg := _calc_dmg(e["atk"], _eff_def(tg), 2)
				GameData.party[tg]["hp"] = max(0, GameData.party[tg]["hp"] - dmg)
				var heal := dmg / 2
				e["hp"] = mini(e["hp"] + heal, e["max_hp"])
				_show_damage_number(_party_pos(tg), str(dmg), Color("cc00cc"))
				_show_damage_number(_enemy_pos(ei), "+%d" % heal, Color("66ff66"))
				_spawn_spell_effect(_party_pos(tg), Color("cc00cc"))
				_screen_flash(Color("880088"))
				_push_log("[color=purple]%s drains life from %s! %d dmg, heals %d[/color]" % [e["name"], GameData.party[tg]["name"], dmg, heal])
				if GameData.party[tg]["hp"] <= 0:
					GameData.party[tg]["alive"] = false
					_push_log("%s falls!" % GameData.party[tg]["name"])
		"summon_shadows":
			var count := mini(2, 8 - enemies.size())
			for _i in range(count):
				_enemy_spawn_queue.append({
					"name": "DarkShade", "hp": 8, "max_hp": 8,
					"atk": 7, "def": 2, "agi": 4, "xp": 10, "gold": 3,
					"alive": true, "command": "",
				})
			_spawn_spell_effect(_enemy_pos(ei), Color("4400aa"))
			_screen_flash(Color("220044"))
			_push_log("[color=purple]%s summons dark shades![/color]" % e["name"])
		"sorrow_wave":
			# Hits all party members
			var total_dmg := 0
			for pi in range(GameData.party.size()):
				if GameData.party[pi]["alive"]:
					var dmg := _calc_dmg(e["atk"] - 2, _eff_def(pi), 2)
					GameData.party[pi]["hp"] = max(0, GameData.party[pi]["hp"] - dmg)
					total_dmg += dmg
					_show_damage_number(_party_pos(pi), str(dmg), Color("4444cc"))
					if GameData.party[pi]["hp"] <= 0:
						GameData.party[pi]["alive"] = false
						_push_log("%s falls!" % GameData.party[pi]["name"])
			_screen_flash(Color("000066"))
			_screen_shake(5.0)
			_push_log("[color=blue]%s releases a wave of sorrow! %d total dmg[/color]" % [e["name"], total_dmg])
		"entomb":
			if tg < GameData.party.size() and GameData.party[tg]["alive"]:
				var dmg := _calc_dmg(e["atk"] + 6, _eff_def(tg), 3)
				GameData.party[tg]["hp"] = max(0, GameData.party[tg]["hp"] - dmg)
				_show_damage_number(_party_pos(tg), str(dmg), Color("886644"))
				_screen_shake(6.0)
				_apply_status_effect(tg, "blind")
				_push_log("[color=brown]%s entombs %s in stone! %d dmg + blind[/color]" % [e["name"], GameData.party[tg]["name"], dmg])
				if GameData.party[tg]["hp"] <= 0:
					GameData.party[tg]["alive"] = false
					_push_log("%s falls!" % GameData.party[tg]["name"])
		"wail":
			# Chance to silence all party members
			for pi in range(GameData.party.size()):
				if GameData.party[pi]["alive"] and rng.randf() < 0.4:
					_apply_status_effect(pi, "silence")
			_spawn_spell_effect(_enemy_pos(ei), Color("2a1a4a"))
			_screen_flash(Color("1a0a3a"))
			_push_log("[color=purple]%s wails in ancient grief![/color]" % e["name"])
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
	_process_status_effects()
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
		total_xp += e["xp"]
		total_gold += e["gold"]
	GameData.add_copper(total_gold * 100)
	if zone == "cave_boss":
		GameData.boss_defeated = true
		_check_quest_progress()
	elif zone == "cave_deep":
		GameData.set_meta("deep_boss_active", false)
		_check_quest_progress()
		round_phase = "endgame_choice"
		endgame_choice_idx = 0
		_update_display()
		return
	_push_log("Victory! +%d XP, +%dc" % [total_xp, total_gold * 100])
	# Enemy loot drops
	_process_loot_drops()
	for m: Dictionary in GameData.party:
		if m["alive"]:
			m["xp"] += total_xp
			if m.has("loyalty") and m.get("wage", 0) > 0:
				m["loyalty"] = mini(m["loyalty"] + 1, 100)
			while m["xp"] >= m["next_xp"] and m["level"] < MAX_LEVEL:
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
				if m["level"] >= MAX_LEVEL:
					# Post-40: diminishing returns grind for small stat boosts
					if m["xp"] >= m["next_xp"]:
						m["xp"] -= m["next_xp"]
						var bonus := rng.randi_range(1, 3)
						match rng.randi_range(0, 3):
							0:
								m["max_hp"] += bonus
								m["hp"] = mini(m["hp"] + bonus, m["max_hp"])
								_push_log("%s: HP+%d (grind bonus)" % [m["name"], bonus])
							1:
								m["str"] += 1
								_push_log("%s: STR+1 (grind bonus)" % m["name"])
							2:
								m["def"] += 1
								_push_log("%s: DEF+1 (grind bonus)" % m["name"])
							_:
								m["agi"] += 1
								_push_log("%s: AGI+1 (grind bonus)" % m["name"])
	_update_display()

func _defeat() -> void:
	round_phase = "defeat"
	for m: Dictionary in GameData.party:
		m["hp"] = 1
		m["alive"] = true
		for lvl in m["magic_levels"]:
			m["magic_levels"][lvl]["charges"] = m["magic_levels"][lvl]["max"]
	GameData.tonics = 3
	GameData.overworld_position = Vector2i(14, 19)
	GameData.overworld_facing = Vector2i.UP
	var gold_loss := GameData.gold / 5
	GameData.gold = maxi(GameData.gold - gold_loss, 0)
	var lost_goods := GameData.trade_goods.size()
	GameData.trade_goods.clear()
	for m: Dictionary in GameData.party:
		if m.get("wage", 0) > 0:
			m["loyalty"] = maxi(m.get("loyalty", 50) - 5, 0)
	var msg := "Defeat... lost %dc" % gold_loss
	if lost_goods > 0:
		msg += " and %d trade good%s" % [lost_goods, "s" if lost_goods != 1 else ""]
	msg += ". Returned to Lanternhouse."
	_push_log(msg)
	_update_display()

func _return_to_overworld() -> void:
	for m: Dictionary in GameData.party:
		if _pre_buff_stats.has(m["name"]):
			var orig: Dictionary = _pre_buff_stats[m["name"]]
			m["str"] = orig["str"]
			m["def"] = orig["def"]
			m["agi"] = orig["agi"]
	_status_effects.clear()
	if round_phase == "victory":
		GameData.cleared_encounters[str(GameData.overworld_position)] = true
		GameData.remove_departed_members()
	SceneTransition.change_scene("res://scenes/overworld/overworld.tscn")

# ── Helpers ────────────────────────────────────────────────────────────────

func _grant_quest_reward(quest: Dictionary) -> void:
	var reward: int = quest.get("reward_gold", 0)
	GameData.add_copper(reward * 100)
	var xp: int = quest.get("reward_xp", 0)
	for m: Dictionary in GameData.party:
		if m["alive"]:
			m["xp"] += xp
	var fac: String = quest.get("reward_faction", "")
	var rep: int = quest.get("reward_rep", 0)
	if fac != "" and rep > 0:
		var faction_map := {"keepers_guild": 0, "harbor_compact": 1, "grey_chapel": 2, "the_unlit": 3}
		var faction_key: int = faction_map.get(fac, -1)
		if faction_key >= 0:
			GameData.change_faction_rep(faction_key, rep)
	_push_log("[color=cyan]Quest complete: %s! +%dc, +%d XP[/color]" % [quest["name"], reward, xp])

func _process_loot_drops() -> void:
	pass

func _check_quest_progress() -> void:
	const QuestDB := preload("res://scripts/data/quests.gd")
	for qid: String in GameData.active_quests.keys():
		if GameData.active_quests[qid]["status"] != "active":
			continue
		var quest: Dictionary = QuestDB.get_quest(qid)
		if quest.is_empty():
			continue
		var completed := false
		match quest["type"]:
			"kill":
				var target: String = quest["target"]
				var needed: int = quest.get("target_count", 1)
				var current: int = GameData.kill_counts.get(target, 0)
				GameData.active_quests[qid]["progress"] = mini(current, needed)
				completed = current >= needed
			"beacon":
				var beacon_pos: Vector2i = QuestDB.BEACON_POS.get(quest.get("target", ""), Vector2i(-1, -1))
				completed = GameData.beacon_states.get(str(beacon_pos), false)
			"flag":
				var ft: String = quest.get("target", "")
				completed = (GameData.get(ft) == true) if GameData.get(ft) != null else GameData.get_meta(ft, false)
			"gather":
				var current_g: int = GameData.get_quest_progress(qid)
				completed = current_g >= quest.get("target_count", 1)
			"faction":
				var ftarget: String = quest.get("target", "")
				var mapped := {"keepers_guild": 0, "harbor_compact": 1, "grey_chapel": 2, "the_unlit": 3}
				var fkey: int = mapped.get(ftarget, -1)
				var rep_b: int = GameData.faction_reputation.get(fkey, 0) if fkey >= 0 else 0
				completed = rep_b >= quest.get("target_count", 20)
			"all_beacons":
				completed = true
				for bname: String in QuestDB.BEACON_POS:
					if not GameData.beacon_states.get(str(QuestDB.BEACON_POS[bname]), false):
						completed = false
						break
			"explore_flag":
				completed = GameData.get_meta(quest.get("target", ""), false)
			"trade":
				var trade_profit: int = GameData.gather_counts.get("trade_profit", 0)
				GameData.active_quests[qid]["progress"] = mini(trade_profit, quest.get("target_count", 200))
				completed = trade_profit >= quest.get("target_count", 200)
			"upgrade":
				completed = GameData.home_upgrades.size() >= quest.get("target_count", 2) and GameData.owns_home()
			"member_quest":
				var member_name: String = quest.get("member", "")
				var in_party := false
				for pm in GameData.party:
					if pm["name"] == member_name:
						in_party = true
						if pm.get("loyalty", 50) < quest.get("required_loyalty", 50):
							in_party = false
						break
				if not in_party:
					continue
				var sub: String = quest.get("sub_type", "flag")
				match sub:
					"flag":
						completed = GameData.get_meta(quest.get("target", ""), false)
					"skill":
						var val: int = GameData.get_meta(quest.get("target", ""), 0)
						GameData.active_quests[qid]["progress"] = mini(val, quest.get("target_count", 1))
						completed = val >= quest.get("target_count", 1)
		if completed:
			GameData.complete_quest(qid)
			_grant_quest_reward(quest)

func _flee_chance(m: Dictionary) -> int:
	var leader_agi: int = m["agi"]
	var avg_enemy_agi: float = 0.0
	var ec := 0
	for e in enemies:
		if e["alive"]:
			avg_enemy_agi += e["agi"]
			ec += 1
	if ec > 0: avg_enemy_agi /= ec
	return int(clamp(0.2 + (leader_agi - avg_enemy_agi) * 0.06, 0.05, 0.85) * 100)

# [CODING CONCEPT: Damage Formula]
# Simple but effective: ATK - DEF + random variance. The max(1,...) ensures
# you always deal at least 1 damage even if DEF > ATK. The variance adds
# unpredictability — the same attack can deal 3 damage or 5. Many RPGs use
# this exact pattern (Final Fantasy, Dragon Quest, Pokemon).
func _calc_dmg(atk: int, target_def: int, variance: int) -> int:
	return max(1, atk - target_def + rng.randi_range(0, variance))

func _eff_str(pi: int) -> int:
	var base := GameData.get_effective_str(pi)
	var loyalty: int = GameData.party[pi].get("loyalty", 50)
	if loyalty >= 80: base += 2
	elif loyalty >= 60: base += 1
	elif loyalty <= 20: base -= 2
	elif loyalty <= 40: base -= 1
	return base

func _eff_def(pi: int) -> int:
	var base := GameData.get_effective_def(pi)
	var loyalty: int = GameData.party[pi].get("loyalty", 50)
	if loyalty >= 80: base += 2
	elif loyalty >= 60: base += 1
	elif loyalty <= 20: base -= 2
	elif loyalty <= 40: base -= 1
	return base

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

func _pick_enemy_target(ei: int, ai: String) -> int:
	var alive: Array = []
	for i in range(GameData.party.size()):
		if GameData.party[i]["alive"]:
			alive.append(i)
	if alive.is_empty():
		return 0
	match ai:
		"smart":
			# Target lowest-HP party member
			var best_idx: int = alive[0]
			for idx in alive:
				if GameData.party[idx]["hp"] < GameData.party[best_idx]["hp"]:
					best_idx = idx
			return best_idx
		"pack":
			# All pack members target the same random party member
			var pack_leader := -1
			for i in range(enemies.size()):
				if enemies[i]["alive"] and EnemyDB.get_ai(enemies[i]["name"]) == "pack":
					pack_leader = i
					break
			if pack_leader >= 0 and enemies[pack_leader].has("command"):
				var leader_cmd: String = enemies[pack_leader].get("command", "")
				if leader_cmd.begins_with("fight:") and pack_leader != ei:
					return int(leader_cmd.split(":")[1])
			return alive[rng.randi_range(0, alive.size() - 1)]
		"cunning":
			# Target party member with lowest defense
			var best_idx: int = alive[0]
			for idx in alive:
				if _eff_def(idx) < _eff_def(best_idx):
					best_idx = idx
			return best_idx
		_:
			return alive[rng.randi_range(0, alive.size() - 1)]

func _apply_status_effect(pi: int, effect_type: String) -> void:
	var m: Dictionary = GameData.party[pi]
	var name: String = m["name"]
	match effect_type:
		"poison":
			_status_effects[name] = {"type": "poison", "turns": 3, "dmg": 2 + rng.randi_range(0, 1)}
			_push_log("[color=green]%s is poisoned![/color]" % name)
		"blind":
			_status_effects[name] = {"type": "blind", "turns": 2}
			_push_log("[color=gray]%s is blinded![/color]" % name)
		"silence":
			_status_effects[name] = {"type": "silence", "turns": 2}
			_push_log("[color=purple]%s is silenced![/color]" % name)

func _process_status_effects() -> void:
	var to_remove: Array = []
	for name: String in _status_effects:
		var effect: Dictionary = _status_effects[name]
		var pi := _party_index_by_name(name)
		if pi < 0 or not GameData.party[pi]["alive"]:
			to_remove.append(name)
			continue
		var m: Dictionary = GameData.party[pi]
		match effect["type"]:
			"poison":
				var dmg: int = effect["dmg"]
				m["hp"] = max(0, m["hp"] - dmg)
				_show_damage_number(_party_pos(pi), str(dmg), Color("00aa00"))
				_push_log("[color=green]%s takes %d poison damage![/color]" % [name, dmg])
				if m["hp"] <= 0:
					m["alive"] = false
					_push_log("%s falls!" % name)
			"blind":
				pass  # Checked during attack resolution
			"silence":
				pass  # Checked during magic command
		effect["turns"] -= 1
		if effect["turns"] <= 0:
			to_remove.append(name)
			_push_log("%s's %s wears off" % [name, effect["type"]])
	for name in to_remove:
		_status_effects.erase(name)

func _party_index_by_name(name: String) -> int:
	for i in range(GameData.party.size()):
		if GameData.party[i]["name"] == name:
			return i
	return -1

func _has_status(pi: int, status_type: String) -> bool:
	var name: String = GameData.party[pi]["name"]
	return _status_effects.has(name) and _status_effects[name]["type"] == status_type

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

func _lowest_mp_party() -> Variant:
	var best = null
	var best_spent := 0
	for m: Dictionary in GameData.party:
		if not m["alive"]: continue
		var spent := 0
		for lvl: int in m["magic_levels"]:
			spent += m["magic_levels"][lvl]["max"] - m["magic_levels"][lvl]["charges"]
		if spent > best_spent:
			best_spent = spent
			best = m
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
	elif round_phase == "endgame_choice":
		lines.append("[b][color=#f0d46a]THE CHOICE[/color][/b]")
		lines.append("")
		lines.append("[color=gray]Ancient grief lies vanquished. The seal is broken.[/color]")
		lines.append("[color=gray]What will you do with this power?[/color]")
		lines.append("")
		var choices := [
			{"name": "Restore the Seal", "desc": "Imprison grief again. The fog returns. Safety at the cost of truth.", "color": "cyan"},
			{"name": "Break It Forever", "desc": "Let the grief disperse. The fog lifts. But the Line goes dark.", "color": "yellow"},
			{"name": "Rebuild the Line", "desc": "Reforged not as prison but guardian. All factions unite.", "color": "green"},
		]
		for i in range(choices.size()):
			var ch: Dictionary = choices[i]
			var marker := "[color=#f0d46a]>[/color]" if i == endgame_choice_idx else " "
			lines.append("%s [b][color=%s]%s[/color][/b]" % [marker, ch["color"], ch["name"]])
			lines.append("  [color=gray]%s[/color]" % ch["desc"])
			lines.append("")
		lines.append("[color=gray]Up/Down to choose  [1]/Enter to confirm[/color]")
	elif round_phase == "fight_target":
		var m: Dictionary = GameData.party[selecting_idx]
		var tgt_name: String = enemies[fight_target_idx]["name"] if fight_target_idx < enemies.size() else "?"
		lines.append("[b]%s — Choose target[/b]  ← → arrows  [1]/Enter confirm  [Esc] back  (→ %s)" % [m["name"], tgt_name])
	elif round_phase in ["command", "magic_target"]:
		var m: Dictionary = GameData.party[selecting_idx]
		if pending_spell.is_empty():
			var item_info := "T:%d E:%d" % [GameData.tonics, GameData.ethers]
			lines.append("[b]%s's turn[/b]  [1]Attack [2]Guard [3]Magic [4]Item(%s) [5]Run (%d%%) [Tab]Skip" % [m["name"], item_info, _flee_chance(m)])
		elif round_phase == "magic_target":
			var si: int = pending_spell.get("spell_idx", 0)
			var lvl: int = pending_spell.get("spell_level", 1)
			var sn: String = CharDB.spells_for_level(lvl)[si]["name"]
			lines.append("[b]Target for %s:[/b] ← → to switch, [1]/Enter to confirm" % sn)
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
