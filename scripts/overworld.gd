# Overworld — island map with pixel art tiles, 4-directional movement
extends Node2D

const TILE_SIZE := 32

# ── Terrain atlas tile coordinates (col, row in 32x32 grid) ──────────────
# terrain_atlas.png is 1024x1024 → 32x32 tiles
# These will be refined as we test
const T_WATER_DEEP   := Vector2i(3, 9)
const T_WATER_SHALLOW:= Vector2i(7, 9)
const T_SAND         := Vector2i(2, 9)
const T_SAND_WATER   := Vector2i(0, 11)  # sand touching water edge
const T_GRASS        := Vector2i(6, 9)
const T_GRASS_FLOWER := Vector2i(4, 21)
const T_FOREST       := Vector2i(5, 20)  # pine tree
const T_TREE         := Vector2i(4, 20)  # deciduous tree
const T_HILL         := Vector2i(8, 17)
const T_HILL_GRASS   := Vector2i(7, 17)
const T_MOUNTAIN     := Vector2i(1, 16)
const T_MOUNTAIN_HI  := Vector2i(2, 16)
const T_CLIFF        := Vector2i(1, 0)
const T_DIRT_PATH    := Vector2i(0, 11)
const T_BRIDGE       := Vector2i(10, 7)
const T_LIGHTHOUSE   := Vector2i(8, 7)  # lighthouse-like structure
const T_HOUSE        := Vector2i(1, 20)  # farm house
const T_FENCE        := Vector2i(9, 7)
const T_DOCK         := Vector2i(10, 8)

# ── Island map (40x40) ────────────────────────────────────────────────────
# Legend:
#  ~ = deep water   ~ = shallow water   . = sand beach
#  , = grass        T = forest          ^ = hill
#  M = mountain     # = impassable peak  = = path
#  h = house        b = bridge          d = dock
#  L = lighthouse encounter zone

const MAP := [
	"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
	"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
	"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
	"~~~~~~~~~~~~~.......~~~~~~~~~~~~~~~~~~~~",
	"~~~~~~~~~~~~.,,,,,,,,.~~~~~~~~~~~~~~~~~~",
	"~~~~~~~~~~~~,,,,,,,,,,,~~~~~~~~~~~~~~~~~",
	"~~~~~~~~~~~,,,,,,,,,,,,,,~~~~~~~~~~~~~~~",
	"~~~~~~~~~~.,,,,,,,,,,,,,,,.~~~~~~~~~~~~~",
	"~~~~~~~~~.,,,,,=,,,,,,,,,,,,~~~~~~~~~~~~",
	"~~~~~~~~.,,,,,,=,,,,,TTTTT,,.~~~~~~~~~~",
	"~~~~~~~~,,,,,,===,,,TTTTTTTT,,,~~~~~~~~",
	"~~~~~~.,,,,,,,,,=,,,TTTTTTTTTT,,,~~~~~~",
	"~~~~~~,,,,,,,,,,,,,,,TTTTTTTTTT,,,.~~~~",
	"~~~~~.,,,,,,,,,,,,,,,TTTT!=TTTT,,,,.~~~",
	"~~~~~,,,,,,,,,,,,,,,,,TTTTTTTT,,,,,,~~~",
	"~~~~~,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,~~~",
	"~~~~~~,,,,,,,,=,,,,,,,^^^^^,,,,,,,,~~~~",
	"~~~~~~.,,,,,,===,,,,,^^^^^^^^,,,,,,~~~~",
	"~~~~~~~~,,,,,,,,,,,,^^^^^^^^^^^,,,~~~~~",
	"~~~~~~~~~.,,,,,,,,,,,,,,^^^^^^,,,,,~~~~",
	"~~~~~~~~~~.,,,,h,,,,,,,,,,,,,,,,,,,~~~~",
	"~~~~~~~~~~~~,,,,,,,,,,,,,,,,,,,,,,,,~~~",
	"~~~~~~~~~~~~.,,,,,,,,,,,,,=,,,,,,,..~~~",
	"~~~~~~~~~~~~~~,,,,,,,,,,,,=,,..~~~~~~~~",
	"~~~~~~~~~~~~~~.,,,,,,,,,,,=..~~~~~~~~~~",
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
	"#": T_MOUNTAIN_HI,
	"=": T_DIRT_PATH,
	"h": T_HOUSE,
	"b": T_BRIDGE,
	"d": T_DOCK,
	"L": T_LIGHTHOUSE,
}

const BLOCKED := {
	"~": true, "M": true, "#": true, "h": true, "L": true, "b": true, "d": true,
}

const ENCOUNTER := {"T": true}  # forest = random encounters
const TOWN_TILE := "h"
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
@onready var player_sprite: Node2D = $PlayerSprite
@onready var player_body: Polygon2D = $PlayerSprite/Body
@onready var player_face: ColorRect = $PlayerSprite/Face
@onready var hud: RichTextLabel = $HUD

# ── Init ───────────────────────────────────────────────────────────────────
func _ready() -> void:
	rng.seed = hash("lanternhouse_overworld")
	_build_tileset()
	_draw_map()
	_update_player_visual()
	_update_hud()

func _build_tileset() -> void:
	"""Create a TileSet from the terrain atlas at runtime."""
	var tex: Texture2D = load("res://assets/sprites/tiles/terrain_atlas.png")
	if not tex:
		push_error("Failed to load terrain atlas!")
		return

	var ts := TileSet.new()
	var source := TileSetAtlasSource.new()
	source.texture = tex
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	source.use_texture_padding = true

	# Add all tiles we use
	for key: String in TILE_ATLAS:
		var coord: Vector2i = TILE_ATLAS[key]
		source.create_tile(coord)
		source.set_tile_animation_columns(coord, 1)

	ts.add_source(source, 0)
	tilemap.tileset = ts

func _tile_atlas_coord(tile_char: String) -> Vector2i:
	return TILE_ATLAS.get(tile_char, T_GRASS)

func _draw_map() -> void:
	for y in range(MAP_H):
		for x in range(MAP_W):
			var tile_char: String = MAP[y].substr(x, 1)
			var atlas_coord: Vector2i = _tile_atlas_coord(tile_char)
			tilemap.set_cell(0, Vector2i(x, y), 0, atlas_coord)

# ── Player visual ──────────────────────────────────────────────────────────
func _update_player_visual() -> void:
	var target := Vector2(pos * TILE_SIZE) + Vector2(TILE_SIZE / 2, TILE_SIZE / 2)
	player_sprite.position = target
	var base_color := Color("f0d46a")
	player_body.color = base_color
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
		_update_hud_with_msg("Can't go that way.")
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

	if tile == "h":
		_update_hud_with_msg("A small cottage. (not yet enterable)")
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
		_update_hud_with_msg("The door is locked. Come back later.")
	else:
		_update_hud_with_msg("Nothing here.")

func _interact_lighthouse() -> void:
	if not GameData.beacon_lit:
		GameData.beacon_lit = true
		_update_hud_with_msg("You light the ancient beacon. The coast is safe.")
	else:
		_update_hud_with_msg("The beacon burns bright against the dark.")

func _enter_town() -> void:
	GameData.overworld_position = pos
	GameData.overworld_facing = facing
	get_tree().change_scene_to_file("res://scenes/town/town.tscn")

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
