@tool
extends SceneTree

const ATLAS_PATH := "res://assets/sprites/tiles/lanternhouse_overworld.png"
const SOURCE_DIR := "res://assets/sprites/tiles/pixellab/coastline"
const ARCHIVE_DIR := "res://assets/sprites/tiles/source/coastline_pass"
const TILE_SIZE := 32

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ARCHIVE_DIR))
	_archive_current_atlas()

	var atlas := Image.create(256, 128, false, Image.FORMAT_RGBA8)
	atlas.fill(Color.TRANSPARENT)

	var ocean_beach := _load_image("%s/ocean_to_beach.png" % SOURCE_DIR)
	var beach_grass := _load_image("%s/beach_to_grass.png" % SOURCE_DIR)
	var dock := _load_image("%s/coastal_dock.png" % SOURCE_DIR)
	var cave := _load_image("%s/coastal_cave.png" % SOURCE_DIR)

	_blit_tile(atlas, ocean_beach, Vector2i(0, 0), Vector2i(0, 0)) # water
	_blit_tile(atlas, ocean_beach, Vector2i(1, 1), Vector2i(1, 0)) # beach
	_blit_tile(atlas, beach_grass, Vector2i(3, 3), Vector2i(2, 0)) # grass
	_draw_forest(atlas, Vector2i(3, 0))
	_draw_mountain(atlas, Vector2i(4, 0), false)
	_draw_mountain(atlas, Vector2i(5, 0), true)
	_draw_mountain(atlas, Vector2i(6, 0), true)
	_draw_path(atlas, Vector2i(7, 0))

	_draw_town(atlas, Vector2i(0, 1))
	_draw_lighthouse(atlas, Vector2i(1, 1))
	_draw_beacon(atlas, Vector2i(2, 1))
	_draw_sign(atlas, Vector2i(3, 1))
	_draw_encounter(atlas, Vector2i(4, 1))
	_draw_camp(atlas, Vector2i(5, 1))
	_blit_centered(atlas, cave, Vector2i(6, 1), 0.5)
	_blit_centered(atlas, dock, Vector2i(7, 1), 0.5)
	_draw_clearing(atlas, Vector2i(0, 2))
	_draw_ruins(atlas, Vector2i(1, 2))

	atlas.save_png(ATLAS_PATH)
	atlas.save_png("%s/lanternhouse_overworld_coastline_pass.png" % ARCHIVE_DIR)
	print("COASTLINE_ATLAS_BUILT")
	quit()

func _archive_current_atlas() -> void:
	var backup := "%s/lanternhouse_overworld_before_coastline.png" % ARCHIVE_DIR
	if FileAccess.file_exists(ATLAS_PATH) and not FileAccess.file_exists(backup):
		var image := _load_image(ATLAS_PATH)
		image.save_png(backup)

func _load_image(path: String) -> Image:
	var image := Image.new()
	var err := image.load(path)
	if err != OK:
		push_error("Could not load %s" % path)
	return image

func _blit_tile(atlas: Image, source: Image, source_tile: Vector2i, dest_tile: Vector2i) -> void:
	atlas.blit_rect(source, Rect2i(source_tile * TILE_SIZE, Vector2i(TILE_SIZE, TILE_SIZE)), dest_tile * TILE_SIZE)

func _blit_centered(atlas: Image, source: Image, dest_tile: Vector2i, scale: float) -> void:
	var scaled := source.duplicate()
	scaled.resize(int(source.get_width() * scale), int(source.get_height() * scale), Image.INTERPOLATE_NEAREST)
	var dest := dest_tile * TILE_SIZE + Vector2i((TILE_SIZE - scaled.get_width()) / 2, (TILE_SIZE - scaled.get_height()) / 2)
	atlas.blit_rect(scaled, Rect2i(Vector2i.ZERO, scaled.get_size()), dest)

func _tile_origin(tile: Vector2i) -> Vector2i:
	return tile * TILE_SIZE

func _set_rect(image: Image, rect: Rect2i, color: Color) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			image.set_pixel(x, y, color)

func _draw_forest(image: Image, tile: Vector2i) -> void:
	var o := _tile_origin(tile)
	_set_rect(image, Rect2i(o, Vector2i(TILE_SIZE, TILE_SIZE)), Color("208338"))
	for y in [7, 16, 25]:
		for x in [5, 14, 23]:
			_draw_triangle(image, o + Vector2i(x, y - 6), o + Vector2i(x - 5, y + 4), o + Vector2i(x + 5, y + 4), Color("1f7a3f"))

func _draw_mountain(image: Image, tile: Vector2i, snow: bool) -> void:
	var o := _tile_origin(tile)
	_set_rect(image, Rect2i(o, Vector2i(TILE_SIZE, TILE_SIZE)), Color("34a847"))
	for p in [[7, 23, 15, 5, 25, 25], [0, 30, 8, 10, 17, 30], [17, 29, 25, 9, 33, 29]]:
		_draw_triangle(image, o + Vector2i(p[0], p[1]), o + Vector2i(p[2], p[3]), o + Vector2i(p[4], p[5]), Color("8d7240"))
		_draw_triangle(image, o + Vector2i(p[2], p[3]), o + Vector2i(p[2] + 4, 18), o + Vector2i(p[2] - 1, 16), Color("d2b75d"))
		if snow:
			_draw_triangle(image, o + Vector2i(p[2], p[3]), o + Vector2i(p[2] - 4, 12), o + Vector2i(p[2] + 4, 12), Color("d6f1ff"))

func _draw_path(image: Image, tile: Vector2i) -> void:
	var o := _tile_origin(tile)
	_set_rect(image, Rect2i(o, Vector2i(TILE_SIZE, TILE_SIZE)), Color("34a847"))
	_draw_quad(image, [o + Vector2i(10, 0), o + Vector2i(23, 0), o + Vector2i(20, 31), o + Vector2i(7, 31)], Color("9b6b38"))

func _draw_town(image: Image, tile: Vector2i) -> void:
	var o := _tile_origin(tile)
	_set_rect(image, Rect2i(o, Vector2i(TILE_SIZE, TILE_SIZE)), Color("34a847"))
	_set_rect(image, Rect2i(o + Vector2i(7, 14), Vector2i(18, 13)), Color("d8bb78"))
	_draw_triangle(image, o + Vector2i(5, 15), o + Vector2i(16, 5), o + Vector2i(27, 15), Color("90422e"))
	_set_rect(image, Rect2i(o + Vector2i(14, 20), Vector2i(4, 7)), Color("111827"))

func _draw_lighthouse(image: Image, tile: Vector2i) -> void:
	var o := _tile_origin(tile)
	_set_rect(image, Rect2i(o, Vector2i(TILE_SIZE, TILE_SIZE)), Color("d9ad55"))
	_set_rect(image, Rect2i(o + Vector2i(13, 9), Vector2i(7, 18)), Color("d7d4c6"))
	_set_rect(image, Rect2i(o + Vector2i(11, 5), Vector2i(11, 5)), Color("90422e"))
	_draw_triangle(image, o + Vector2i(16, 1), o + Vector2i(3, 8), o + Vector2i(29, 8), Color("ffe36e"))

func _draw_beacon(image: Image, tile: Vector2i) -> void:
	var o := _tile_origin(tile)
	_set_rect(image, Rect2i(o, Vector2i(TILE_SIZE, TILE_SIZE)), Color("34a847"))
	_set_rect(image, Rect2i(o + Vector2i(13, 12), Vector2i(7, 16)), Color("8f8c7a"))
	_set_rect(image, Rect2i(o + Vector2i(11, 7), Vector2i(11, 6)), Color("d8cf8b"))
	_set_rect(image, Rect2i(o + Vector2i(14, 3), Vector2i(5, 5)), Color("ffe36e"))

func _draw_sign(image: Image, tile: Vector2i) -> void:
	var o := _tile_origin(tile)
	_set_rect(image, Rect2i(o, Vector2i(TILE_SIZE, TILE_SIZE)), Color("34a847"))
	_set_rect(image, Rect2i(o + Vector2i(15, 12), Vector2i(2, 15)), Color("7a4b25"))
	_set_rect(image, Rect2i(o + Vector2i(8, 9), Vector2i(17, 6)), Color("b2773e"))

func _draw_encounter(image: Image, tile: Vector2i) -> void:
	_draw_forest(image, tile)
	var o := _tile_origin(tile)
	_set_rect(image, Rect2i(o + Vector2i(12, 10), Vector2i(9, 12)), Color("b72d2d"))

func _draw_camp(image: Image, tile: Vector2i) -> void:
	var o := _tile_origin(tile)
	_set_rect(image, Rect2i(o, Vector2i(TILE_SIZE, TILE_SIZE)), Color("34a847"))
	_draw_triangle(image, o + Vector2i(5, 24), o + Vector2i(13, 10), o + Vector2i(22, 24), Color("b0733a"))
	_draw_triangle(image, o + Vector2i(23, 23), o + Vector2i(26, 17), o + Vector2i(29, 23), Color("ffe36e"))

func _draw_clearing(image: Image, tile: Vector2i) -> void:
	var o := _tile_origin(tile)
	_set_rect(image, Rect2i(o, Vector2i(TILE_SIZE, TILE_SIZE)), Color("34a847"))
	_set_rect(image, Rect2i(o + Vector2i(7, 7), Vector2i(18, 17)), Color("78d66d"))

func _draw_ruins(image: Image, tile: Vector2i) -> void:
	var o := _tile_origin(tile)
	_set_rect(image, Rect2i(o, Vector2i(TILE_SIZE, TILE_SIZE)), Color("d9ad55"))
	_set_rect(image, Rect2i(o + Vector2i(6, 17), Vector2i(7, 8)), Color("6f6780"))
	_set_rect(image, Rect2i(o + Vector2i(19, 12), Vector2i(6, 13)), Color("6f6780"))

func _draw_triangle(image: Image, a: Vector2i, b: Vector2i, c: Vector2i, color: Color) -> void:
	var min_x: int = mini(mini(a.x, b.x), c.x)
	var max_x: int = maxi(maxi(a.x, b.x), c.x)
	var min_y: int = mini(mini(a.y, b.y), c.y)
	var max_y: int = maxi(maxi(a.y, b.y), c.y)
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var p := Vector2i(x, y)
			if _point_in_triangle(p, a, b, c) and x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
				image.set_pixel(x, y, color)

func _draw_quad(image: Image, points: Array, color: Color) -> void:
	_draw_triangle(image, points[0], points[1], points[2], color)
	_draw_triangle(image, points[0], points[2], points[3], color)

func _point_in_triangle(p: Vector2i, a: Vector2i, b: Vector2i, c: Vector2i) -> bool:
	var area: int = abs((b.x - a.x) * (c.y - a.y) - (c.x - a.x) * (b.y - a.y))
	var area1: int = abs((a.x - p.x) * (b.y - p.y) - (b.x - p.x) * (a.y - p.y))
	var area2: int = abs((b.x - p.x) * (c.y - p.y) - (c.x - p.x) * (b.y - p.y))
	var area3: int = abs((c.x - p.x) * (a.y - p.y) - (a.x - p.x) * (c.y - p.y))
	return area == area1 + area2 + area3
