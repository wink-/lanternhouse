extends CanvasLayer

const MAP_W := 40
const MAP_H := 40

@onready var map_display: ColorRect = $Panel/MapDisplay

func _ready() -> void:
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_TAB:
		visible = not visible
		if visible:
			_draw_map()
		get_viewport().set_input_as_handled()

func _draw_map() -> void:
	var map_scene: Node2D = get_tree().current_scene
	if not map_scene or not map_scene.has_method("_tile"):
		return

	var map_data: Array = map_scene.MAP
	var player_pos: Vector2i = map_scene.pos
	var beacons: Dictionary = map_scene.BEACON_POSITIONS

	var tile_size := mini(map_display.size.x / MAP_W, map_display.size.y / MAP_H)
	var offset_x := (map_display.size.x - tile_size * MAP_W) / 2.0
	var offset_y := (map_display.size.y - tile_size * MAP_H) / 2.0

	for child in map_display.get_children():
		child.queue_free()

	for y in range(MAP_H):
		for x in range(MAP_W):
			var key := str(Vector2i(x, y))
			var explored: bool = GameData.explored_tiles.get(key, false)
			if not explored:
				continue
			var tile_char: String = map_data[y].substr(x, 1)
			var color := _tile_color(tile_char)
			var rect := ColorRect.new()
			rect.color = color
			rect.size = Vector2(tile_size, tile_size)
			rect.position = Vector2(offset_x + x * tile_size, offset_y + y * tile_size)
			map_display.add_child(rect)

	# Draw beacon positions
	for bname: String in beacons:
		var bp: Vector2i = beacons[bname]
		var key := str(bp)
		if not GameData.explored_tiles.get(key, false):
			continue
		var lit: bool = GameData.beacon_states.get(key, false)
		var rect := ColorRect.new()
		rect.color = Color.CYAN if lit else Color("444444")
		rect.size = Vector2(tile_size * 2, tile_size * 2)
		rect.position = Vector2(offset_x + bp.x * tile_size - tile_size * 0.5, offset_y + bp.y * tile_size - tile_size * 0.5)
		map_display.add_child(rect)

	# Draw player
	var player := ColorRect.new()
	player.color = Color.YELLOW
	player.size = Vector2(tile_size * 2, tile_size * 2)
	player.position = Vector2(offset_x + player_pos.x * tile_size - tile_size * 0.5, offset_y + player_pos.y * tile_size - tile_size * 0.5)
	map_display.add_child(player)

func _tile_color(tile_char: String) -> Color:
	match tile_char:
		"~": return Color("1a3a5c")
		".": return Color("c8b070")
		",": return Color("4c9040")
		"T": return Color("1c5730")
		"^": return Color("8a8a6a")
		"M": return Color("69677a")
		"#": return Color("4a4858")
		"=": return Color("a08050")
		"h": return Color("8b6914")
		"L": return Color("fbf236")
		"B": return Color("44aaff")
		"S": return Color("aa8866")
		"C": return Color("ff6633")
		"!": return Color("2a4720")
		"O": return Color("ffcc00")
		_:
			return Color("333333")
