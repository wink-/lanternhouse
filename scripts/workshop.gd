# Workshop — Brindlewick tinkerer interior.
extends Node2D

const TinkerDB := preload("res://scripts/data/tinkering.gd")

const TILE_SIZE := 16
const MAP := [
	"################",
	"#..............#",
	"#..WW....TT....#",
	"#..WW....TT....#",
	"#..............#",
	"#....@@........#",
	"#....@@........#",
	"#..............#",
	"#..CC....MM....#",
	"#..CC....MM....#",
	"#......==......#",
	"################",
]
const COLORS := {
	"#": Color("5a4a3a"), ".": Color("b08850"), "W": Color("6a4a3a"),
	"T": Color("f0d46a"), "@": Color("6a5a4a"), "C": Color("8b6914"),
	"M": Color("7f8c8d"), "=": Color("ad7e48"),
}
const TILE_RECTS := {
	"#": Rect2i(Vector2i(0, 0), Vector2i(TILE_SIZE, TILE_SIZE)),
	".": Rect2i(Vector2i(16, 0), Vector2i(TILE_SIZE, TILE_SIZE)),
	"W": Rect2i(Vector2i(96, 0), Vector2i(TILE_SIZE, TILE_SIZE)),
	"T": Rect2i(Vector2i(0, 16), Vector2i(TILE_SIZE, TILE_SIZE)),
	"@": Rect2i(Vector2i(32, 16), Vector2i(TILE_SIZE, TILE_SIZE)),
	"C": Rect2i(Vector2i(16, 16), Vector2i(TILE_SIZE, TILE_SIZE)),
	"M": Rect2i(Vector2i(80, 0), Vector2i(TILE_SIZE, TILE_SIZE)),
	"=": Rect2i(Vector2i(16, 0), Vector2i(TILE_SIZE, TILE_SIZE)),
}
const BLOCKED := {"#": true, "W": true, "T": true, "@": true, "C": true, "M": true}
const EXIT_POS := Vector2i(7, 10)

var pos: Vector2i = Vector2i(7, 9)
var facing: Vector2i = Vector2i.DOWN
var walking: bool = false
var walk_timer: float = 0.0
var tinkering_mode: bool = false
var tinker_idx: int = 0
var _interior_atlas: Texture2D
var _world_origin: Vector2 = Vector2.ZERO
var _player_idle_textures: Dictionary = {}

@onready var map_layer: Node2D = $MapLayer
@onready var player_sprite: Node2D = $PlayerSprite
@onready var dialog: RichTextLabel = $Dialog

func _ready() -> void:
	_interior_atlas = SpriteCache.get_asset("town.home.interior")
	_init_player_sprite()
	_draw_map()
	_layout_interior()
	_update_player()
	_update_hud()
	get_viewport().size_changed.connect(_layout_interior)

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
	if tinkering_mode:
		_handle_tinkering_input(event.keycode)
		return
	var dir := Vector2i.ZERO
	if Input.is_action_just_pressed("move_up"): dir = Vector2i.UP
	elif Input.is_action_just_pressed("move_down"): dir = Vector2i.DOWN
	elif Input.is_action_just_pressed("move_left"): dir = Vector2i.LEFT
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
	if dir == Vector2i.DOWN and pos == EXIT_POS:
		_exit_to_town()
		return
	var next := pos + dir
	if _is_blocked(next):
		_update_player()
		_update_hud()
		return
	pos = next
	walking = true
	walk_timer = 0.12
	_update_player()
	_update_hud()

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
		"W", "T", "C", "M", "@":
			tinkering_mode = true
			tinker_idx = 0
			_show_tinkering()
		_:
			if pos == EXIT_POS or target.y >= MAP.size() - 1:
				_exit_to_town()
			else:
				_say("Tools, wire, and half-finished lantern parts cover every surface.")

func _exit_to_town() -> void:
	GameData.set_meta("town_spawn_pos", Vector2i(25, 18))
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
	var texture: Texture2D = _player_idle_textures.get(_direction_name(facing), _player_idle_textures.get("south", null))
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
		Vector2i.UP:
			return "north"
		Vector2i.DOWN:
			return "south"
		Vector2i.LEFT:
			return "west"
		Vector2i.RIGHT:
			return "east"
	return "south"

func _update_hud() -> void:
	var lines := [
		"[b]Fenn Copperwick's Workshop[/b]",
		"",
		"[color=#f0d46a]Interact:[/color] use the workbench",
		"[color=#f0d46a]Move south:[/color] leave"
	]
	_say("\n".join(lines))

func _say(msg: String) -> void:
	dialog.text = msg

func _show_tinkering() -> void:
	var lines: Array = []
	lines.append("[b]Tinkering Workbench[/b]")
	lines.append("")
	var skill_level := GameData.get_skill_bonus("tinkering")
	var recipes := TinkerDB.available_recipes(skill_level)
	if recipes.is_empty():
		lines.append("No recipes available. Gather materials to increase your skill.")
		lines.append("")
		lines.append("[Esc] Back")
		_say("\n".join(lines))
		return
	for i in range(recipes.size()):
		var recipe: Dictionary = recipes[i]
		var marker := ">" if i == tinker_idx else " "
		var can_craft := true
		var mat_str := ""
		for mat_id: int in recipe["materials"]:
			var needed: int = recipe["materials"][mat_id]
			var have: int = GameData.get_material_count(TinkerDB.get_material_info(mat_id)["id"])
			if have < needed:
				can_craft = false
			mat_str += "%s %d/%d  " % [TinkerDB.get_material_name(mat_id), have, needed]
		var dim := "" if can_craft else "[color=#666]"
		var dim_e := "" if can_craft else "[/color]"
		var sel_s := "[color=#f0d46a]" if i == tinker_idx else ""
		var sel_e := "[/color]" if i == tinker_idx else ""
		lines.append("%s%s %s%s%s — %s(x%d)%s" % [dim, marker, sel_s, recipe["name"], sel_e, mat_str, recipe.get("output_count", 1), dim_e])
	lines.append("")
	lines.append("Materials: %s" % _material_summary())
	lines.append("")
	lines.append("[1]/Enter to craft, arrows to browse, [Esc] back")
	_say("\n".join(lines))

func _material_summary() -> String:
	var mat_names: Array = []
	for mat_id: String in GameData.material_bag:
		var count: int = GameData.material_bag[mat_id]
		if count > 0:
			mat_names.append("%s x%d" % [mat_id.replace("_", " ").capitalize(), count])
	return ", ".join(mat_names) if not mat_names.is_empty() else "None"

func _handle_tinkering_input(keycode: int) -> void:
	match keycode:
		KEY_UP:
			tinker_idx = max(0, tinker_idx - 1)
			_show_tinkering()
		KEY_DOWN:
			var skill_level := GameData.get_skill_bonus("tinkering")
			var recipes := TinkerDB.available_recipes(skill_level)
			tinker_idx = min(max(recipes.size() - 1, 0), tinker_idx + 1)
			_show_tinkering()
		KEY_1, KEY_ENTER, KEY_SPACE:
			_try_tinker()
		KEY_ESCAPE:
			tinkering_mode = false
			_update_hud()

func _try_tinker() -> void:
	var skill_level := GameData.get_skill_bonus("tinkering")
	var recipes := TinkerDB.available_recipes(skill_level)
	if recipes.is_empty() or tinker_idx >= recipes.size():
		tinkering_mode = false
		return
	var recipe: Dictionary = recipes[tinker_idx]
	for mat_id: int in recipe["materials"]:
		var needed: int = recipe["materials"][mat_id]
		var mat_str: String = TinkerDB.get_material_info(mat_id)["id"]
		if GameData.get_material_count(mat_str) < needed:
			_say("Not enough %s!" % TinkerDB.get_material_name(mat_id))
			return
	for mat_id: int in recipe["materials"]:
		var needed: int = recipe["materials"][mat_id]
		var mat_str: String = TinkerDB.get_material_info(mat_id)["id"]
		GameData.remove_material(mat_str, needed)
	var count: int = recipe.get("output_count", 1)
	for _i in range(count):
		GameData.add_crafted_item(TinkerDB.create_crafted_item(recipe))
	GameData.track_skill_use("tinkering", 1)
	_say("[color=green]Crafted %s x%d![/color] %s" % [recipe["name"], count, recipe["desc"]])
	tinkering_mode = false
