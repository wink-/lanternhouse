extends Node

const EnemyDB := preload("res://scripts/data/enemies.gd")
const CharDB := preload("res://scripts/data/classes.gd")
const FactionDB := preload("res://scripts/data/factions.gd")
const ItemDB := preload("res://scripts/data/items.gd")

# Reference to the main battle script
var battle: Node2D

# ── Styling and Color Palettes ─────────────────────────────────────────────
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

const PARTY_SPRITE_IDS := {
	"Fighter": "fighter",
	"Thief": "thief",
	"BlackBelt": "blackbelt",
	"RedMage": "redmage",
	"WhiteMage": "whitemage",
	"BlackMage": "blackmage",
}

# ── Dynamic visual variables ────────────────────────────────────────────────
var _floating_labels: Array = []
var _screen_flash_timer: float = 0.0
var _screen_flash_color: Color = Color.WHITE
var _screen_shake_timer: float = 0.0
var _screen_shake_intensity: float = 0.0
var _enemy_sprite_textures: Dictionary = {}
var _party_sprite_textures: Dictionary = {}

const FLOAT_DURATION := 1.2
var rng := RandomNumberGenerator.new()

# ── Node References via parent (battle) ────────────────────────────────────
var enemy_area: Node2D:
	get: return battle.get_node("EnemyArea") as Node2D

var party_area: Node2D:
	get: return battle.get_node("PartyArea") as Node2D

var panel: Panel:
	get: return battle.get_node("Panel") as Panel

var text_display: RichTextLabel:
	get: return battle.get_node("Panel/TextDisplay") as RichTextLabel

var enemy_status_panel: Panel:
	get: return battle.get_node("EnemyStatusPanel") as Panel

var enemy_status_text: RichTextLabel:
	get: return battle.get_node("EnemyStatusPanel/EnemyStatusText") as RichTextLabel

var party_status_panel: Panel:
	get: return battle.get_node("PartyStatusPanel") as Panel

var party_status_text: RichTextLabel:
	get: return battle.get_node("PartyStatusPanel/PartyStatusText") as RichTextLabel

var background: ColorRect:
	get: return battle.get_node("Background") as ColorRect

func _ready() -> void:
	rng.seed = hash("battle_renderer_%d" % Time.get_ticks_msec())

# ── Floating damage numbers, flash, and shakes process loop ───────────────
func _process(delta: float) -> void:
	if not battle:
		return

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
		var orig: Color = ZONE_BG.get(battle.zone, ZONE_BG["grassland"])
		var blend: Color = _screen_flash_color if _screen_flash_timer > 0 else orig
		if background:
			background.color = blend
			if _screen_flash_timer <= 0:
				background.color = orig
	else:
		if background:
			background.color = ZONE_BG.get(battle.zone, ZONE_BG["grassland"])

	# Screen shake
	if _screen_shake_timer > 0:
		_screen_shake_timer -= delta
		if enemy_area:
			enemy_area.position = Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * _screen_shake_intensity
		if party_area:
			party_area.position = Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * _screen_shake_intensity
		if _screen_shake_timer <= 0:
			if enemy_area: enemy_area.position = Vector2.ZERO
			if party_area: party_area.position = Vector2.ZERO

# ── Styling functions ──────────────────────────────────────────────────────
func setup_visuals() -> void:
	var bg_color: Color = ZONE_BG.get(battle.zone, ZONE_BG["grassland"])
	if battle.weather == "rain":
		bg_color = bg_color.darkened(0.15)
	if background:
		background.color = bg_color
	_style_battle_panels()

func _style_battle_panels() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.03, 0.05, 0.86)
	style.border_color = Color("d8d0a0")
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	for p in [panel, enemy_status_panel, party_status_panel]:
		if p:
			p.add_theme_stylebox_override("panel", style)

# ── Spawning Visual Effects ─────────────────────────────────────────────────
func show_damage_number(world_pos: Vector2, text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.position = world_pos
	label.z_index = 100
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 18)
	battle.add_child(label)
	_floating_labels.append({"node": label, "timer": FLOAT_DURATION, "start_y": world_pos.y})

func screen_flash(color: Color = Color.WHITE) -> void:
	_screen_flash_timer = 0.12
	_screen_flash_color = color

func screen_shake(intensity: float = 3.0) -> void:
	_screen_shake_timer = 0.15
	_screen_shake_intensity = intensity

func spawn_spell_effect(pos: Vector2, color: Color) -> void:
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
	battle.add_child(particles)
	var tween := battle.create_tween()
	tween.tween_interval(0.5)
	tween.tween_callback(particles.queue_free)

func spawn_slash_effect(pos: Vector2) -> void:
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
	battle.add_child(slash)
	var tween := battle.create_tween()
	tween.tween_property(slash, "modulate:a", 0.0, 0.25)
	tween.tween_callback(slash.queue_free)

# ── Spawning and Drawing Sprites ────────────────────────────────────────────
func draw_sprites() -> void:
	if not enemy_area or not party_area:
		return

	_clear_children(enemy_area)
	_clear_children(party_area)

	# Draw enemies
	for i in range(battle.enemies.size()):
		var e: Dictionary = battle.enemies[i]
		var py := _enemy_pos(i).y
		var base_color: Color = ENEMY_COLORS.get(e["name"], Color.GRAY)
		if not e["alive"]:
			base_color = Color("333333")
		if not _draw_enemy_sprite(enemy_area, e["name"], Vector2(battle._enemy_x, py), e["alive"]):
			_draw_block(enemy_area, Vector2(battle._enemy_x, py), base_color, 24)
		
		# Show target indicator
		if battle.round_phase in ["fight_target", "magic_target"]:
			var is_selected := false
			if battle.round_phase == "fight_target" and i == battle.fight_target_idx:
				is_selected = true
			elif battle.round_phase == "magic_target" and i == battle.pending_spell.get("target_idx", -1):
				is_selected = true
			if is_selected and e["alive"]:
				_draw_target_arrow(enemy_area, Vector2(battle._enemy_x, py - 34))

	# Draw party
	for i in range(GameData.party.size()):
		var m: Dictionary = GameData.party[i]
		var py := _party_pos(i).y
		var color: Color = PARTY_COLORS.get(m["class"], Color.GRAY)
		if not m["alive"]:
			color = Color("555555")
		if not _draw_party_sprite(party_area, m["class"], Vector2(battle._party_x, py), m["alive"]):
			_draw_block(party_area, Vector2(battle._party_x, py), color, 20)

func _enemy_pos(i: int) -> Vector2:
	var spacing: float = 60.0 if battle.enemies.size() <= 4 else (300.0 / max(battle.enemies.size() - 1, 1))
	return Vector2(battle._enemy_x, 80.0 + i * spacing - 30.0)

func _party_pos(i: int) -> Vector2:
	return Vector2(battle._party_x, 80.0 + i * 60.0 - 30.0)

func _draw_party_sprite(target_parent: Node2D, party_class: String, draw_pos: Vector2, is_alive: bool) -> bool:
	var texture: Texture2D = _load_party_sprite(party_class)
	if not texture:
		return false
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = true
	sprite.position = draw_pos
	sprite.scale = Vector2(0.82, 0.82)
	if not is_alive:
		sprite.modulate = Color("777777")
	target_parent.add_child(sprite)
	return true

func _draw_enemy_sprite(target_parent: Node2D, enemy_name: String, draw_pos: Vector2, is_alive: bool) -> bool:
	var texture: Texture2D = _load_enemy_sprite(enemy_name)
	if not texture:
		return false
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = true
	sprite.position = draw_pos
	sprite.scale = Vector2(0.9, 0.9)
	if not is_alive:
		sprite.modulate = Color("555555")
	target_parent.add_child(sprite)
	return true

func _load_enemy_sprite(enemy_name: String) -> Texture2D:
	var key: String = enemy_name.to_snake_case()
	if _enemy_sprite_textures.has(key):
		return _enemy_sprite_textures[key]
	var texture := SpriteCache.enemy_sprite(key)
	_enemy_sprite_textures[key] = texture
	return texture

func _load_party_sprite(party_class: String) -> Texture2D:
	var key: String = PARTY_SPRITE_IDS.get(party_class, party_class.to_snake_case())
	if _party_sprite_textures.has(key):
		return _party_sprite_textures[key]
	var texture := SpriteCache.party_sprite(key)
	_party_sprite_textures[key] = texture
	return texture

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

# ── Update HUD & Status Panels ─────────────────────────────────────────────
func update_status_panels() -> void:
	if not enemy_status_text or not party_status_text:
		return

	var enemy_lines: Array[String] = ["[b][color=#f0d46a]ENEMY[/color][/b]"]
	for e: Dictionary in battle.enemies:
		var is_selected := false
		if battle.round_phase == "fight_target" and battle.enemies.find(e) == battle.fight_target_idx:
			is_selected = true
		elif battle.round_phase == "magic_target" and battle.enemies.find(e) == battle.pending_spell.get("target_idx", -1):
			is_selected = true
		
		var marker := ">" if e["alive"] and is_selected else " "
		var enemy_name := _fixed_cell(e["name"], 11)
		var status := "[color=#666]DOWN[/color]" if not e["alive"] else "%s HP" % _make_hp_bar(e["hp"], e["max_hp"], 8)
		enemy_lines.append("%s %s %s" % [marker, enemy_name, status])
	enemy_status_text.text = "\n".join(enemy_lines)

	var party_lines: Array[String] = ["[b][color=#9fc5ff]PARTY[/color][/b]"]
	for i in range(GameData.party.size()):
		var m: Dictionary = GameData.party[i]
		var marker := ">" if i == battle.selecting_idx and battle.round_phase in ["command", "fight_target", "magic_target"] else " "
		var hp_status := "[color=#c0392b]KO[/color]" if not m["alive"] else "%d/%d" % [m["hp"], m["max_hp"]]
		var status := ""
		if battle._status_effects.has(m["name"]):
			status = " [color=#f0d46a]%s[/color]" % String(battle._status_effects[m["name"]]["type"]).to_upper()
		party_lines.append("%s %-10s Lv%-2d HP %s%s" % [marker, m["name"], m["level"], hp_status, status])
	party_status_text.text = "\n".join(party_lines)

func _fixed_cell(value: String, width: int) -> String:
	var clipped := value
	if clipped.length() > width:
		clipped = clipped.substr(0, max(width - 1, 0)) + "…"
	while clipped.length() < width:
		clipped += " "
	return clipped

func _make_hp_bar(hp: int, max_hp: int, width: int) -> String:
	var n := clampi(int(ceil(float(hp) / max_hp * width)), 0, width)
	var s := "[color=#4c9040]"
	for _i in range(n): s += "█"
	s += "[/color][color=#555]"
	for _i in range(width - n): s += "░"
	s += "[/color]"
	return s

func set_display_text(text: String) -> void:
	if text_display:
		text_display.text = text
