# House Interior — shared interior scene for all residential house types.
# The "house_id" GameData meta key identifies which house was entered
# (small_house, large_house, house_timber, house_mossy) for flavor text.
# The "house_door_pos" meta key records the town tile to return to on exit.
extends Node2D

const TILE_SIZE := 16
const MAP := [
	"################",
	"#..............#",
	"#..BB....TT....#",
	"#..BB....TT....#",
	"#..............#",
	"#...CC.........#",
	"#..............#",
	"#..............#",
	"#.......==.....#",
	"################",
]
const COLORS := {
	"#": Color("5a4a3a"), ".": Color("c8a87a"),
	"B": Color("7a4a3a"), "T": Color("8b6914"),
	"C": Color("6a5a4a"), "=": Color("ad7e48"),
}
const TILE_RECTS := {
	"#": Rect2i(Vector2i(0, 0), Vector2i(TILE_SIZE, TILE_SIZE)),
	".": Rect2i(Vector2i(16, 0), Vector2i(TILE_SIZE, TILE_SIZE)),
	"B": Rect2i(Vector2i(96, 0), Vector2i(TILE_SIZE, TILE_SIZE)),
	"T": Rect2i(Vector2i(0, 16), Vector2i(TILE_SIZE, TILE_SIZE)),
	"C": Rect2i(Vector2i(32, 16), Vector2i(TILE_SIZE, TILE_SIZE)),
	"=": Rect2i(Vector2i(16, 0), Vector2i(TILE_SIZE, TILE_SIZE)),
}
const BLOCKED := {"#": true, "B": true, "T": true, "C": true}
const EXIT_ROW := 8
const EXIT_COL := 8

# House-type flavor text shown when entering
const HOUSE_FLAVOR := {
	"small_house":  "A modest home. A fire crackles in the hearth. Someone has left bread on the table.",
	"large_house":  "A spacious house. Shelves of preserved jars line the walls. Everything is very tidy.",
	"house_timber": "The smell of sawdust and pine lingers. Woodworking tools hang above a workbench.",
	"house_mossy":  "Dried herbs dangle from the rafters. A battered mortar and pestle sits on the table.",
}
const HOUSE_RESIDENT := {
	"small_house":  "This home belongs to a local family.",
	"large_house":  "This belongs to one of the wealthier residents of Brindlewick.",
	"house_timber": "The carpenter who lives here is known for their excellent furniture.",
	"house_mossy":  "An herbalist lives here, gathering plants from the nearby forest.",
}

var pos: Vector2i = Vector2i(EXIT_COL, EXIT_ROW - 1)
var facing: Vector2i = Vector2i.DOWN
var walking: bool = false
var walk_timer: float = 0.0
var _house_id: String = ""
var _door_return_pos: Vector2i = Vector2i.ZERO
var _interior_atlas: Texture2D
var _world_origin: Vector2 = Vector2.ZERO
var _player_idle_textures: Dictionary = {}

@onready var map_layer: Node2D = $MapLayer
@onready var player_sprite: Node2D = $PlayerSprite
@onready var dialog: RichTextLabel = $Dialog

func _ready() -> void:
	_house_id = GameData.get_meta("house_id", "small_house")
	_door_return_pos = GameData.get_meta("house_door_pos", Vector2i(0, 0))
	GameData.remove_meta("house_id")
	GameData.remove_meta("house_door_pos")

	_interior_atlas = SpriteCache.get_asset("town.home.interior")
	_init_player_sprite()
	_draw_map()
	_layout_interior()
	_update_player()
	get_viewport().size_changed.connect(_layout_interior)
	_show_welcome()

func _process(delta: float) -> void:
	if walking:
		walk_timer -= delta
		if walk_timer <= 0.0:
			walking = false
		_update_player()

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

func _draw_map() -> void:
	for y in range(MAP.size()):
		for x in range(MAP[y].length()):
			_draw_tile(MAP[y].substr(x, 1), Vector2i(x, y))

func _draw_tile(tile: String, grid: Vector2i) -> void:
	if _interior_atlas and TILE_RECTS.has(tile):
		var sprite := Sprite2D.new()
		sprite.texture = _interior_atlas
		sprite.region_enabled = true
		sprite.region_rect = TILE_RECTS.get(tile, TILE_RECTS["."])
		sprite.centered = false
		sprite.position = Vector2(grid * TILE_SIZE)
		map_layer.add_child(sprite)
	else:
		var rect := ColorRect.new()
		rect.color = COLORS.get(tile, Color.MAGENTA)
		rect.position = Vector2(grid * TILE_SIZE)
		rect.size = Vector2(TILE_SIZE, TILE_SIZE)
		map_layer.add_child(rect)

func _try_move(dir: Vector2i) -> void:
	facing = dir
	if dir == Vector2i.DOWN and pos.y >= EXIT_ROW - 1 and pos.x == EXIT_COL:
		_exit_to_town()
		return
	var next := pos + dir
	if _is_blocked(next):
		_update_player()
		return
	pos = next
	walking = true
	walk_timer = 0.12
	_update_player()
	# Trigger exit when stepping onto exit row
	if pos.y >= EXIT_ROW:
		_exit_to_town()

func _is_blocked(grid: Vector2i) -> bool:
	if grid.x < 0 or grid.x >= MAP[0].length() or grid.y < 0 or grid.y >= MAP.size():
		return true
	return BLOCKED.has(_tile(grid))

func _tile(grid: Vector2i) -> String:
	if grid.x < 0 or grid.x >= MAP[0].length() or grid.y < 0 or grid.y >= MAP.size():
		return "#"
	return MAP[grid.y].substr(grid.x, 1)

func _interact() -> void:
	var target := pos + facing
	var tile := _tile(target)
	match tile:
		"T":
			_say("[b]Table[/b]\n\n" + HOUSE_RESIDENT.get(_house_id, "Someone lives here."))
		"B":
			_say("[b]Bed[/b]\n\nA simple straw mattress. Looks like it hasn't been slept in recently.")
		"C":
			_say("[b]Chair[/b]\n\nA worn wooden chair, smoothed by years of use.")
		_:
			if pos.y >= EXIT_ROW - 1 or target.y >= MAP.size() - 1:
				_exit_to_town()
			else:
				_say(HOUSE_FLAVOR.get(_house_id, "A cozy home."))

func _exit_to_town() -> void:
	# Return player to the tile below the door they entered through
	if _door_return_pos != Vector2i.ZERO:
		GameData.set_meta("town_spawn_pos", _door_return_pos)
	GameData.set_meta("town_spawn_facing", Vector2i.UP)
	SceneTransition.change_scene("res://scenes/town/town.tscn")

func _layout_interior() -> void:
	var viewport_size := get_viewport_rect().size
	var map_size := Vector2(MAP[0].length() * TILE_SIZE, MAP.size() * TILE_SIZE)
	_world_origin = ((viewport_size - map_size) * 0.5).floor()
	_world_origin.x = maxf(0.0, _world_origin.x)
	_world_origin.y = maxf(0.0, _world_origin.y)
	map_layer.position = _world_origin
	_update_player()

func _update_player() -> void:
	player_sprite.position = _world_origin + Vector2(pos * TILE_SIZE) + Vector2(TILE_SIZE / 2, TILE_SIZE / 2)
	_update_player_texture()

func _init_player_sprite() -> void:
	if not player_sprite.has_node("Sprite"):
		var sprite := Sprite2D.new()
		sprite.name = "Sprite"
		player_sprite.add_child(sprite)
	_load_player_textures()
	_update_player_texture()

func _load_player_textures() -> void:
	for dir_name in ["south", "east", "north", "west"]:
		_player_idle_textures[dir_name] = SpriteCache.character_rotation("player", dir_name)

func _update_player_texture() -> void:
	var sprite := player_sprite.get_node_or_null("Sprite") as Sprite2D
	if not sprite:
		return
	var texture: Texture2D = _player_idle_textures.get(
		_direction_name(facing), _player_idle_textures.get("south", null))
	if not texture:
		return
	sprite.texture = texture
	sprite.centered = true
	sprite.region_enabled = false
	sprite.scale = Vector2(0.42, 0.42)
	sprite.z_index = 4
	if player_sprite.has_node("Body"):
		player_sprite.get_node("Body").hide()
	if player_sprite.has_node("Face"):
		player_sprite.get_node("Face").hide()

func _direction_name(dir: Vector2i) -> String:
	match dir:
		Vector2i.UP:    return "north"
		Vector2i.DOWN:  return "south"
		Vector2i.LEFT:  return "west"
		Vector2i.RIGHT: return "east"
	return "south"

func _show_welcome() -> void:
	_say("[b]%s[/b]\n\n%s\n\n[color=#f0d46a]Move south:[/color] leave" % [
		HOUSE_RESIDENT.get(_house_id, "Residential House"),
		HOUSE_FLAVOR.get(_house_id, "A cozy home.")
	])

func _say(msg: String) -> void:
	dialog.text = msg
