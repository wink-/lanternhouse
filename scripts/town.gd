# Town — interior map with NPCs, weapon shop, armor shop, inn
extends Node2D

const TILE_SIZE := 16

const MAP := [
	"########################",
	"#......................#",
	"#..WW................AA#",
	"#..WW................AA#",
	"#..WW......@@........AA#",
	"#..........@@..........#",
	"#..........@@..........#",
	"#..II......@@..........#",
	"#..II......@@..........#",
	"#......................#",
	"#..SS...........EE.....#",
	"#..SS...........EE.....#",
	"#......................#",
	"########################",
]

const COLORS := {
	"#": Color("8b7355"), ".": Color("c49b56"), "@": Color("a08050"),
	"W": Color("27ae60"), "A": Color("27ae60"), "I": Color("3498db"),
	"S": Color("9b59b6"), "E": Color("e67e22"),
}
const BLOCKED := {"#":true}
const NPC_POSITIONS := {
	Vector2i(3, 3): "weapon_merchant",
	Vector2i(21, 3): "armor_merchant",
	Vector2i(3, 8): "innkeeper",
	Vector2i(20, 10): "elder",
}

var pos: Vector2i = Vector2i(12, 12)
var facing: Vector2i = Vector2i.DOWN
var walking: bool = false
var walk_timer: float = 0.0

@onready var map_layer: Node2D = $MapLayer
@onready var player_sprite: Node2D = $PlayerSprite
@onready var dialog: RichTextLabel = $Dialog

func _ready() -> void:
	_draw_map()
	_update_player()

func _draw_map() -> void:
	for y in range(MAP.size()):
		for x in range(MAP[y].length()):
			var tile: String = MAP[y].substr(x, 1)
			var rect := ColorRect.new()
			rect.color = COLORS.get(tile, Color.MAGENTA)
			rect.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
			rect.size = Vector2(TILE_SIZE, TILE_SIZE)
			map_layer.add_child(rect)
	# Draw NPC markers
	for npc_pos in NPC_POSITIONS:
		var marker := ColorRect.new()
		marker.color = Color.WHITE
		marker.position = Vector2(npc_pos * TILE_SIZE) + Vector2(2, 2)
		marker.size = Vector2(12, 12)
		map_layer.add_child(marker)

func _update_player() -> void:
	player_sprite.position = Vector2(pos * TILE_SIZE) + Vector2(TILE_SIZE / 2, TILE_SIZE / 2)

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

func _try_move(dir: Vector2i) -> void:
	facing = dir
	var next := pos + dir
	if _is_blocked(next):
		_say("Can't walk there.")
		return
	pos = next
	_update_player()
	_check_exit()

func _is_blocked(grid: Vector2i) -> bool:
	if grid.x < 0 or grid.x >= MAP[0].length() or grid.y < 0 or grid.y >= MAP.size():
		return true
	return BLOCKED.has(MAP[grid.y].substr(grid.x, 1))

func _check_exit() -> void:
	# Bottom edge of map = exit to overworld
	if pos.y >= MAP.size() - 1:
		get_tree().change_scene_to_file("res://scenes/overworld/overworld.tscn")

func _interact() -> void:
	var target := pos + facing
	var npc: String = NPC_POSITIONS.get(target, "")

	match npc:
		"weapon_merchant":
			GameData.set_meta("shop_type", "weapons")
			get_tree().change_scene_to_file("res://scenes/shop/shop.tscn")
		"armor_merchant":
			GameData.set_meta("shop_type", "armor")
			get_tree().change_scene_to_file("res://scenes/shop/shop.tscn")
		"innkeeper":
			GameData.full_heal()
			_say("Innkeeper: Rest well! All HP and magic restored.")
		"elder":
			_say("Elder: Beware the forest to the north. The mountain cave holds great treasure — and great danger.")
		_:
			_say("Nothing here.")

func _say(msg: String) -> void:
	dialog.text = "[b]Town[/b]    Gold: %dg    Tonics: %d\n\n%s" % [GameData.gold, GameData.tonics, msg]
