# Overworld — island map with pixel art tiles, 4-directional movement
extends Node2D

const TILE_SIZE := 32

# ── Terrain atlas tile coordinates (col, row in 32x32 grid) ──────────────
# terrain_simple.png is 224x32 → 7 tiles across, 1 row
const T_WATER_DEEP   := Vector2i(0, 0)
const T_WATER_SHALLOW:= Vector2i(1, 0)
const T_SAND         := Vector2i(2, 0)
const T_GRASS        := Vector2i(3, 0)
const T_FOREST       := Vector2i(4, 0)
const T_HILL         := Vector2i(5, 0)
const T_MOUNTAIN     := Vector2i(6, 0)

# ── Island map (40x40) ────────────────────────────────────────────────────
#  ~ = water    . = sand beach    , = grass
#  T = forest   ^ = hill          M = mountain
#  # = impassable peak           = = dirt path
#  h = house    L = lighthouse

const MAP := [
	"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
	"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
	"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
	"~~~~~~~~~~~~~.......~~~~~~~~~~~~~~~~~~~~",
	"~~~~~~~~~~~~.,,,,,,,,.~~~~~~~~~~~~~~~~~~",
	"~~~~~~~~~~~~,,,,,,,,,,,~~~~~~~~~~~~~~~~~",
	"~~~~~~~~~~~,,,,,,,,,,,,,,~~~~~~~~~~~~~~~",
	"~~~~~~~~~~.,,,,,,,,,,,,,,,.~~~~~~~~~~~~~",
	"~~~~~~~~~.,,,,,,=,,,,,,,,,,,,~~~~~~~~~~~",
	"~~~~~~~~.,,,,,,,=,,,,,TTTTT,,.~~~~~~~~~",
	"~~~~~~~~,,,,,,===,,,TTTTTTTT,,,~~~~~~~~",
	"~~~~~~.,,,,,,,,,=,,,TTTTTTTTTT,,,~~~~~~",
	"~~~~~~,,,,,,,,,,,,,,,TTTTTTTTTT,,,.~~~~",
	"~~~~~.,,,,,,,,,,,,,,,TTTT!=TTTT,,,,.~~~",
	"~~~~~,,,,,,,,,,,,,,,,,TTTTTTTT,,,,,,~~~",
	"~~~~~,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,~~~",
	"~~~~~~,,,,,,,,,=,,,,,,,^^^^^,,,,,,,,~~~",
	"~~~~~~.,,,,,,,===,,,,,^^^^^^^^,,,,,,~~~",
	"~~~~~~~~,,,,,,,,,,,,^^^^^^^^^^^,,,~~~~~",
	"~~~~~~~~~.,,,,,,,,,,,,,,^^^^^^,,,,,~~~~",
	"~~~~~~~~~~.,,,,h,,,,,,,,,,,,,,,,,,~~~~~",
	"~~~~~~~~~~~~,,,,,,,,,,,,,,,,,,,,,,~~~~~",
	"~~~~~~~~~~~~.,,,,,,,,,,,,,,=,,,,,,.~~~",
	"~~~~~~~~~~~~~~,,,,,,,,,,,,,=,,..~~~~~~~",
	"~~~~~~~~~~~~~~.,,,,,,,,,,,=..~~~~~~~~~",
	"~~~~~~~~~~~~~~~~.,,,,,,,,.~~~~~~~~~~~~~",
	"~~~~~~~~~~~~~~~~~~,,,,,,~~~~~~~~~~~~~~~",
	"~~~~~~~~~~~~~~~~~~.,,,,,~~~~~~~~~~~~~~~",
	"~~~~~~~~~~~~~~~~~~~~.,,,~~~~~~~~~~~~~~~",
	"~~~~~~~~~~~~~~~~~~~~~~,.~~~~~~~~~~~~~~~",
	"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
	"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
	"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
	"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
	"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
	"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
	"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
	"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
	"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
	"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
]

# ── Tile mappings ──────────────────────────────────────────────────────────
const TILE_ATLAS := {
	"~": T_WATER_DEEP,
	".": T_SAND,
	",": T_GRASS,
	"T": T_FOREST,
	"^": T_HILL,
	"M": T_MOUNTAIN,
	"#": T_MOUNTAIN,
}

const BLOCKED := {"~": true, "M": true, "#": true}
const ENCOUNTER := {"T": true}
const MAP_W := 40
const MAP_H := 40

# ── State ──────────────────────────────────────────────────────────────────
var pos: Vector2i = GameData.overworld_position
var facing: Vector2i = GameData.overworld_facing
var walking: bool = false
var walk_timer: float = 0.0
var walk_duration: float = 0.18
var rng := RandomNumberGenerator.new()
var step_count: int = 0

# ── Nodes ──────────────────────────────────────────────────────────────────
@onready var tilemap: TileMap = $TileMap
@onready var camera: Camera2D = $Camera2D
@onready var player_sprite: Node2D = $PlayerSprite
@onready var player_body: Polygon2D = $PlayerSprite/Body
@onready var player_face: ColorRect = $PlayerSprite/Face
@onready var hud: RichTextLabel = $HUD
@onready var debug_label: Label = $DebugLabel

# ── Debug ───────────────────────────────────────────────────────────────────
var debug_visible: bool = false

# ── Init ───────────────────────────────────────────────────────────────────
func _ready() -> void:
	rng.seed = hash("lanternhouse_overworld")
	_build_tileset()
	_draw_map()
	_update_player_visual()
	_update_camera()
	_update_hud()
	print("Overworld ready. Player at ", pos, " (tile: ", _tile(pos), ")")

	if debug_label:
		debug_label.hide()

func _build_tileset() -> void:
	var tex: Texture2D = load("res://assets/sprites/tiles/terrain_simple.png")
	if not tex:
		push_error("Failed to load terrain atlas!")
		print("ERROR: terrain_atlas.png not found!")
		# Fallback: render map with colors
		_fallback_draw()
		return

	print("terrain_atlas loaded: ", tex.get_width(), "x", tex.get_height())

	var ts := TileSet.new()
	var source := TileSetAtlasSource.new()
	source.texture = tex
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	source.use_texture_padding = true

	# Register every tile we reference
	for key: String in TILE_ATLAS:
		var coord: Vector2i = TILE_ATLAS[key]
		if source.has_tile(coord):
			continue
		source.create_tile(coord)
		print("  added tile '", key, "' at atlas ", coord)

	ts.add_source(source, 0)
	tilemap.tileset = ts

	# Ensure layer 0 exists
	if tilemap.get_layers_count() == 0:
		tilemap.add_layer(-1)
	print("TileSet built with ", TILE_ATLAS.size(), " tile types")

func _draw_map() -> void:
	var tile_count: int = 0
	for y in range(MAP_H):
		for x in range(MAP_W):
			var tile_char: String = MAP[y].substr(x, 1)
			var atlas_coord: Vector2i = TILE_ATLAS.get(tile_char, T_GRASS)
			tilemap.set_cell(0, Vector2i(x, y), 0, atlas_coord)
			tile_count += 1
	print("Map drawn: ", tile_count, " tiles")

func _fallback_draw() -> void:
	"""Draw colored rectangles if tileset failed to load."""
	print("Using colored-block fallback")
	for y in range(MAP_H):
		for x in range(MAP_W):
			var tile_char: String = MAP[y].substr(x, 1)
			var color := Color.GRAY
			match tile_char:
				"~": color = Color("1a3a5c")
				".": color = Color("c8b070")
				",": color = Color("4c9040")
				"T": color = Color("1c5730")
				"^": color = Color("8a8a6a")
				"M": color = Color("69677a")
				"#": color = Color("4a4858")
				"=": color = Color("a08050")
				"h": color = Color("8b6914")
				"L": color = Color("fbf236")
			var rect := ColorRect.new()
			rect.color = color
			rect.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
			rect.size = Vector2(TILE_SIZE, TILE_SIZE)
			add_child(rect)

# ── Player visual ──────────────────────────────────────────────────────────
func _update_player_visual() -> void:
	var target := Vector2(pos * TILE_SIZE) + Vector2(TILE_SIZE / 2, TILE_SIZE / 2)
	player_sprite.position = target
	var base_color := Color("f0d46a")
	player_body.color = base_color
	if walking:
		player_sprite.position.y -= 2

func _update_camera() -> void:
	if camera:
		camera.position = player_sprite.position

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
	elif event.keycode == KEY_F3:
		_toggle_debug()
		return

	if dir != Vector2i.ZERO:
		_try_move(dir)

# ── Movement ───────────────────────────────────────────────────────────────
func _try_move(dir: Vector2i) -> void:
	facing = dir
	var next := pos + dir
	if _is_blocked(next):
		_update_hud_with_msg("Can't go that way.")
		return

	pos = next
	walking = true
	walk_timer = walk_duration
	_update_player_visual()
	_update_camera()
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

	if tile == "L":
		_interact_lighthouse()
	if ENCOUNTER.has(tile):
		if rng.randi_range(1, 6) == 1:
			_start_battle("forest")

	GameData.overworld_position = pos
	GameData.overworld_facing = facing

func _interact() -> void:
	var target := pos + facing
	var tile := _tile(target)
	if tile == "L":
		_interact_lighthouse()
	elif tile == "h":
		_update_hud_with_msg("A small cottage. The door is locked.")
	else:
		_update_hud_with_msg("Nothing here.")

func _interact_lighthouse() -> void:
	if not GameData.beacon_lit:
		GameData.beacon_lit = true
		_update_hud_with_msg("You light the ancient beacon! The coast is safe.")
	else:
		_update_hud_with_msg("The beacon burns bright against the dark.")

func _start_battle(zone: String) -> void:
	GameData.overworld_position = pos
	GameData.overworld_facing = facing
	GameData.set_meta("battle_zone", zone)
	GameData.set_meta("battle_surprise", rng.randi_range(1, 10) <= 1)
	get_tree().change_scene_to_file("res://scenes/battle/battle.tscn")

# ── Process ────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if walking:
		walk_timer -= delta
		if walk_timer <= 0:
			walking = false
		_update_player_visual()

	if debug_visible and debug_label and debug_label.visible:
		_update_debug()

# ── HUD ────────────────────────────────────────────────────────────────────
func _update_hud() -> void:
	var lines: Array = []
	for m: Dictionary in GameData.party:
		if m["alive"]:
			var bar := _hp_string(m["hp"], m["max_hp"], 8)
			lines.append("Lv%d %-10s %s" % [m["level"], m["name"], bar])
		else:
			lines.append("Lv%d %-10s [color=red]KO[/color]" % [m["level"], m["name"]])
	var beacon_status: String = "[color=cyan]LIT[/color]" if GameData.beacon_lit else "[color=gray]UNLIT[/color]"
	lines.append("Gold: %d    Tonics: %d    Beacon: %s" % [GameData.gold, GameData.tonics, beacon_status])
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

# ── Debug ──────────────────────────────────────────────────────────────────
func _toggle_debug() -> void:
	debug_visible = not debug_visible
	if debug_label:
		debug_label.visible = debug_visible
		if debug_visible:
			_update_debug()

func _update_debug() -> void:
	if not debug_label:
		return
	var tile_char := _tile(pos)
	var fps := Engine.get_frames_per_second()
	var tt := tick_count
	debug_label.text = (
		"[F3] Debug\n"
		+ "Pos: (%d, %d)\n" % [pos.x, pos.y]
		+ "Tile: '%s'\n" % tile_char
		+ "Facing: %s\n" % _dir_name(facing)
		+ "FPS: %d\n" % fps
		+ "Tiles: %d x %d\n" % [MAP_W, MAP_H]
		+ "Steps: %d\n" % step_count
		+ "Beacon: %s" % ("Lit" if GameData.beacon_lit else "Unlit")
	)

var tick_count: int = 0

func _dir_name(d: Vector2i) -> String:
	match d:
		Vector2i.UP: return "Up"
		Vector2i.DOWN: return "Down"
		Vector2i.LEFT: return "Left"
		Vector2i.RIGHT: return "Right"
	return "?"

