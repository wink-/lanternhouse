# Overworld — continent map, player movement, encounters, town entrance
extends Node2D

const TILE_SIZE := 16

# Continent map legend:
#  ~ = ocean       . = grassland    T = forest
#  ^ = mountain    @ = town         = = path
#  C = cave        B = bridge       ! = visible encounter

const MAP := [
	"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
	"~~~~~~~~~~~~~~~^^^^^^^^^^~~~~~~~",
	"~~~~~~~~~~~~~^^^^^^^^^^^^^^~~~~~",
	"~~~~~~~~~~~~^^^^^^^^^^^^^^^^~~~~",
	"~~~~~~~~~~~^^^^^^^^^^^^^^^^^^~~~",
	"~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^~~",
	"~~~~~~~~~~~^^^^~~~^^^^^^^^^^^^~~",
	"~~~~~~~~~~~~^^~~~~~^^~~~~~~~^~~~",
	"~~~~~~~~~TTTTTT~~~~~~TT~~~~^~~~~",
	"~~~~~~~~TTTTTTTTT~~~TTTT~~~~~~~~",
	"~~~~~~~TTTTTTTTTTT~~TTTT~~~~~~~~",
	"~~~~~~TTTTTTTTTTTTTTTTTT~~~~~~~~",
	"~~~~~TTTTTTT!!TTTTTTTTTTT~~~~~~~",
	"~~~~~TTTTTT!!!!TTTTTTTTTT~~~~~~~",
	"~~~~~~TTTTTTTTTTTTTTTTTTT~~~^^~~",
	"~~~~~~~TTTTTTTTTTT==TTTTT~~~^^~~",
	"~~~~~~~~~TTTTTTT====TTTTTTTT~~~~",
	"~~~~~~~~@@TTTT======TTTTTTTTTT~~",
	"~~~~~~~~@@TT==TT====TTTTTTTTTTT",
	"~~~~~~~~@@TT==TTTTTTTTTTBBTTTTT",
	"~~~~~~~~~~~~==TTTTTTTTTBBTTTTT~",
	"~~~~~~~~~~~~~~TTTTTTTTTTTT~~~~~~",
	"~~~~~~~~~~~~~~~TTTTTTTT~~~~~~~~~",
	"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
]

const COLORS := {
	"~": Color("1a3a5c"), ".": Color("4c9040"), "T": Color("1c5730"),
	"^": Color("69677a"), "@": Color("8b6914"), "=": Color("a08050"),
	"C": Color("3a3a4a"), "B": Color("8b6914"), "!": Color("a64b46"),
}

const BLOCKED := {"~":true, "^":true, "T":true}
const ENCOUNTER := {"T":true, "!":true}   # forest = random, ! = visible
const TOWN_TILE := "@"
const CAVE_TILE := "C"
const MAP_W := 32
const MAP_H := 24

# ── State ──────────────────────────────────────────────────────────────────
var pos: Vector2i = GameData.overworld_position
var facing: Vector2i = GameData.overworld_facing
var walking: bool = false
var walk_timer: float = 0.0
var walk_duration: float = 0.18
var rng := RandomNumberGenerator.new()
var step_count: int = 0

# ── Nodes ──────────────────────────────────────────────────────────────────
@onready var map_layer: Node2D = $MapLayer
@onready var player_sprite: Node2D = $PlayerSprite
@onready var player_body: Polygon2D = $PlayerSprite/Body
@onready var player_face: ColorRect = $PlayerSprite/Face
@onready var hud: RichTextLabel = $HUD

# ── Init ───────────────────────────────────────────────────────────────────
func _ready() -> void:
	rng.seed = hash("lanternhouse_overworld")
	_draw_map()
	_update_player_visual()
	_update_hud()

func _draw_map() -> void:
	for y in range(MAP_H):
		for x in range(MAP_W):
			var tile: String = MAP[y].substr(x, 1)
			var rect := ColorRect.new()
			rect.color = COLORS.get(tile, Color.MAGENTA)
			rect.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
			rect.size = Vector2(TILE_SIZE, TILE_SIZE)
			map_layer.add_child(rect)

# ── Player visual ──────────────────────────────────────────────────────────
func _update_player_visual() -> void:
	var target := Vector2(pos * TILE_SIZE) + Vector2(TILE_SIZE / 2, TILE_SIZE / 2)
	player_sprite.position = target
	# Color based on facing
	var base_color := Color("f0d46a")  # gold-yellow
	player_body.color = base_color
	# Bob the sprite while walking
	if walking:
		player_sprite.position.y -= 2

# ── Input ──────────────────────────────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if walking:
		return

	var dir := Vector2i.ZERO
	if Input.is_action_just_pressed("move_up"):    dir = Vector2i.UP
	elif Input.is_action_just_pressed("move_down"):  dir = Vector2i.DOWN
	elif Input.is_action_just_pressed("move_left"):  dir = Vector2i.LEFT
	elif Input.is_action_just_pressed("move_right"): dir = Vector2i.RIGHT
	elif Input.is_action_just_pressed("interact"):
		_interact()
		return

	if dir != Vector2i.ZERO:
		_try_move(dir)

# ── Movement ───────────────────────────────────────────────────────────────
func _try_move(dir: Vector2i) -> void:
	facing = dir
	var next := pos + dir
	if _is_blocked(next):
		_update_hud_with_msg("Blocked by terrain.")
		return

	pos = next
	walking = true
	walk_timer = walk_duration
	_update_player_visual()
	_step_effects()

func _is_blocked(grid: Vector2i) -> bool:
	if grid.x < 0 or grid.x >= MAP_W or grid.y < 0 or grid.y >= MAP_H:
		return true
	return BLOCKED.has(_tile(grid))

func _tile(grid: Vector2i) -> String:
	return MAP[grid.y].substr(grid.x, 1)

func _step_effects() -> void:
	step_count += 1
	var tile := _tile(pos)

	# Town entrance
	if tile == TOWN_TILE:
		_enter_town()

	# Cave entrance
	if tile == CAVE_TILE:
		_update_hud_with_msg("The cave mouth is dark and foreboding... (not yet implemented)")

	# Random encounters on forest tiles
	if ENCOUNTER.has(tile) and tile != "!":
		if rng.randi_range(1, 6) == 1:  # ~17% chance per step in forest
			_start_battle(_zone_for_tile(tile))

	# Save position for persistence
	GameData.overworld_position = pos
	GameData.overworld_facing = facing

func _zone_for_tile(tile: String) -> String:
	match tile:
		"T": return "forest"
		"!": return "forest"  # visible encounters still forest zone
	return "grassland"

func _interact() -> void:
	var target := pos + facing
	var tile := _tile(target)

	if tile == "!":
		_start_battle("forest")
	elif tile == "@" and target.distance_to(pos) <= 1:
		_enter_town()
	elif tile == "C":
		_update_hud_with_msg("The cave entrance looms... (not yet implemented)")
	else:
		# Check for town NPC or sign nearby
		_update_hud_with_msg("Nothing here.")

func _enter_town() -> void:
	GameData.visited_town = true
	GameData.overworld_position = pos
	GameData.overworld_facing = facing
	get_tree().change_scene_to_file("res://scenes/town/town.tscn")

func _start_battle(zone: String) -> void:
	GameData.overworld_position = pos
	GameData.overworld_facing = facing
	# Pass zone info to battle via GameData
	GameData.set_meta("battle_zone", zone)
	GameData.set_meta("battle_surprise", rng.randi_range(1, 10) <= 1)  # 10% ambush
	get_tree().change_scene_to_file("res://scenes/battle/battle.tscn")

# ── Process ────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if walking:
		walk_timer -= delta
		if walk_timer <= 0:
			walking = false
		_update_player_visual()

# ── HUD ────────────────────────────────────────────────────────────────────
func _update_hud() -> void:
	var lines: Array = []
	for m: Dictionary in GameData.party:
		if m["alive"]:
			var bar := _hp_string(m["hp"], m["max_hp"], 8)
			lines.append("Lv%d %-10s %s" % [m["level"], m["name"], bar])
		else:
			lines.append("Lv%d %-10s [color=red]KO[/color]" % [m["level"], m["name"]])
	lines.append("Gold: %d    Tonics: %d" % [GameData.gold, GameData.tonics])
	hud.text = "\n".join(lines)

func _update_hud_with_msg(msg: String) -> void:
	_update_hud()
	hud.text += "\n\n[i]%s[/i]" % msg

func _hp_string(hp: int, max_hp: int, width: int) -> String:
	var n := int(ceil(float(hp) / max_hp * width))
	n = clamp(n, 0, width)
	var s := "[color=#4c9040]"
	for _i in range(n): s += "█"
	s += "[/color][color=#555]"
	for _i in range(width - n): s += "░"
	s += "[/color]"
	return s
