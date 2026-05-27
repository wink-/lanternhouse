# Overworld — island map with pixel art tiles, 4-directional movement
#
# [CODING CONCEPT: ASCII Map → Visual Grid]
# The MAP constant is an array of strings where each character represents a tile:
# ~ = water, , = grass, T = forest, etc. _draw_map() reads each character,
# looks up the corresponding tile sprite from TILE_ATLAS, and places it on screen.
# This makes map editing as simple as typing characters in a text editor.
#
# [CODING CONCEPT: Game Loop (_process) vs Events (_unhandled_input)]
# Godot has two main ways to respond to things:
#   - _unhandled_input(event): fires once when a key is pressed. Used for movement
#     because you want one step per key press, not continuous sliding.
#   - _process(delta): fires every frame (~60 times/sec). Used for animations,
#     timers, and smooth movement because you need constant updates.
# The "walking" variable bridges the two: input sets walking=true, _process
# counts down the animation timer, then sets walking=false when done.
extends Node2D

const FactionDB := preload("res://scripts/data/factions.gd")
const QuestDB := preload("res://scripts/data/quests.gd")
const FishDB := preload("res://scripts/data/fish.gd")
const AlchemyDB := preload("res://scripts/data/alchemy.gd")
const TinkerDB := preload("res://scripts/data/tinkering.gd")

const TILE_SIZE := 32
const PLAYER_SPRITE_PATH := "res://assets/sprites/overworld/player.png"
const PLAYER_ROTATION_PATH := "res://assets/sprites/characters/player/rotations/%s.png"

# ── Terrain atlas tile coordinates (col, row in 32x32 grid) ──────────────
const OVERWORLD_ATLAS_PATH := "res://assets/sprites/tiles/lanternhouse_overworld.png"
const T_WATER_FULL := Vector2i(0, 0)
const T_SAND := Vector2i(1, 0)
const T_GRASS := Vector2i(2, 0)
const T_FOREST := Vector2i(3, 0)
const T_HILL := Vector2i(4, 0)
const T_MOUNTAIN := Vector2i(5, 0)
const T_SNOW_PEAK := Vector2i(6, 0)
const T_PATH := Vector2i(7, 0)
const T_TOWN := Vector2i(0, 1)
const T_LIGHTHOUSE := Vector2i(1, 1)
const T_BEACON := Vector2i(2, 1)
const T_SIGN := Vector2i(3, 1)
const T_ENCOUNTER := Vector2i(4, 1)
const T_CAMP := Vector2i(5, 1)
const T_CAVE := Vector2i(6, 1)
const T_DOCK := Vector2i(7, 1)
const T_CLEARING := Vector2i(0, 2)
const T_RUINS := Vector2i(1, 2)

# ── Island map (40x40) ────────────────────────────────────────────────────
#  ~ = water    . = sand beach    , = grass
#  T = forest   ^ = hill          M = mountain
#  # = impassable peak           = = dirt path
#  h = house    L = lighthouse    B = beacon tower
#  S = signpost

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
	"~~~~~~~~.,,,,,,,=,,,,,TTTTT,,.~~~~~~~~~~",
	"~~~~~~~~,,,,,,===,,,TTTTTTTT,,,~~~~~~~~~",
	"~~~~~~.,,,,,,,,,=,,,TTTTT!TTTT,,,~~~~~~~",
	"~~~~~~,,,,,,,,S,,,,,,TT!TTTTTTT,,,.~~~~~",
	"~~~~~.,,,,,,,,,,,,,,,TTfTB=TTTT,,,,.~~~~",
	"~~~~~,,,,,,,,,,,,,,,,,!TTTTTTT,,,,,,~~~~",
	"~~~~~,,,,,,,,,,,,,,,C,,,,,,,,,,,,,,,~~~~",
	"~~~~~~,,,,,,,,,=,,,,,,,^^^^^,,,,,,,,~~~~",
	"~~~~~~.,,,,,,,===,,,,S^^^^^VO,,,,,,~~~~~",
	"~~~~~~~~,,,,,,,,,,,,^^^^^^^^^^^,,,~~~~~~",
	"~~~~~~~~~.,,,,,,,,,,,,,,^^^^^B,,,,~~~~~~",
	"~~~~~~~~~~.,,,,h,,,,,,,,,,,,,,,,,,~~~~~~",
	"~~~~~~~~~~~~,,,S,,,,,,,,S,,,,,,,,,~~~~~~",
	"~~~~~~~~~~~~.,,,,,C,,,,,,,S=,,,,,,.~~~~~",
	"~~~~~~~~~~~~~~,,,,,,,,,,,,,=,,B..~~~~~~~",
	"~~~~~~~~~~~~~~.,,,,,,,,,,D=..~~~~~~~~~~~",
	"~~~~~~~~~~~.AA~.,C,,,,,,.~~~~~~~~~~~~~~~",
	"~~~~~~~~~~BA~~~~~S,,,,,~~~~~~~~~~~~~~~~~",
	"~~~~~~~~~~~~~~~~~~.,,,,,~~~~~~~~~~~~~~~~",
	"~~~~~~~~~~~~~~~~~~~~.,,,~~~~~~~~~~~~~~~~",
	"~~~~~~~~~~~~~~~~~~~~~~,.~~~~~~~~~~~~~~~~",
	"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
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
	"~": T_WATER_FULL,
	".": T_SAND,
	",": T_GRASS,
	"T": T_FOREST,
	"^": T_HILL,
	"M": T_MOUNTAIN,
	"#": T_SNOW_PEAK,
	"=": T_PATH,
	"h": T_TOWN,
	"L": T_LIGHTHOUSE,
	"B": T_BEACON,
	"S": T_SIGN,
	"!": T_ENCOUNTER,
	"C": T_CAMP,
	"V": T_CAVE,
	"A": T_RUINS,
	"D": T_DOCK,
	"f": T_CLEARING,
	"O": T_HILL,
}

const BLOCKED := {"~": true, "M": true, "#": true, "V": true, "A": true}
const ENCOUNTER_ZONES := {"T": "forest", "^": "mountain", ",": "grassland", ".": "beach", "!": "forest"}
const ENCOUNTER_RATE := {"forest": 6, "mountain": 5, "grassland": 8, "beach": 10, "post_seal": 5}
const MAP_W := 40
const MAP_H := 40
const BRINDLEWICK_POS := Vector2i(15, 20)
const BRINDLEWICK_EXIT_POS := BRINDLEWICK_POS + Vector2i.DOWN

# Positions blocked until a specific beacon is lit
const GATED_ROUTES := {
	Vector2i(28, 17): "hill_overlook",
	Vector2i(29, 17): "hill_overlook",
}


func _is_gate_blocked(grid: Vector2i) -> bool:
	var beacon_name: String = GATED_ROUTES.get(grid, "")
	if beacon_name == "":
		return false
	var beacon_pos: Vector2i = BEACON_POSITIONS.get(beacon_name, Vector2i(-1, -1))
	return not GameData.beacon_states.get(str(beacon_pos), false)

# Beacon positions on the map (col, row) — keyed by name
const BEACON_POSITIONS := {
	"lighthouse": Vector2i(25, 13),  # beacon near the old lighthouse
	"north_forest": Vector2i(17, 13),  # B in forest
	"hill_overlook": Vector2i(24, 19),  # B in hills
	"south_shore": Vector2i(24, 23),  # B on south shore
	"west_point": Vector2i(10, 26),  # B on west point
}

# Signpost texts — keyed by position string
const SIGNPOST_TEXTS := {
	"(24, 21)": "Brindlewick lies west. The lighthouse beacon stands north of this road.",
	"(15, 21)": "Brindlewick Village. The inn offers rest and healing.",
	"(14, 12)": "Forest of Mournlight. Tread carefully — the trees here are old and watchful.",
	"(21, 17)": "Mountain Pass. The beacon on the overlook controls access to the peaks.",
	"(26, 22)": "South Shore Beacon. The sea grows restless when the light fades.",
	"(17, 26)": "West Point. On clear nights you can see the mainland — or what remains of it.",
}

const LANDMARK_MARKERS := [
	{"pos": BRINDLEWICK_POS, "label": "Brindlewick", "color": Color(1.0, 0.86, 0.24, 0.95), "offset": Vector2(-44, -31)},
	{"pos": Vector2i(25, 13), "label": "Lighthouse", "color": Color(1.0, 0.95, 0.62, 0.95), "offset": Vector2(-46, -34)},
	{"pos": Vector2i(17, 13), "label": "North Beacon", "color": Color(0.62, 0.82, 1.0, 0.9), "offset": Vector2(-54, -34)},
	{"pos": Vector2i(24, 19), "label": "Hill Beacon", "color": Color(0.62, 0.82, 1.0, 0.9), "offset": Vector2(-48, -34)},
	{"pos": Vector2i(24, 23), "label": "South Beacon", "color": Color(0.62, 0.82, 1.0, 0.9), "offset": Vector2(-54, 10)},
	{"pos": Vector2i(10, 26), "label": "West Beacon", "color": Color(0.62, 0.82, 1.0, 0.9), "offset": Vector2(-50, -34)},
	{"pos": Vector2i(23, 24), "label": "Dock", "color": Color(0.55, 0.9, 1.0, 0.9), "offset": Vector2(-24, 10)},
	{"pos": Vector2i(21, 15), "label": "Camp", "color": Color(1.0, 0.55, 0.3, 0.9), "offset": Vector2(-24, -34)},
	{"pos": Vector2i(26, 17), "label": "Cave", "color": Color(0.78, 0.72, 1.0, 0.9), "offset": Vector2(-24, -34)},
	{"pos": Vector2i(18, 13), "label": "Clearing", "color": Color(0.6, 1.0, 0.65, 0.9), "offset": Vector2(-36, 10)},
	{"pos": Vector2i(10, 25), "label": "Ruins", "color": Color(1.0, 0.55, 0.75, 0.9), "offset": Vector2(-28, -34)},
]

# ── Day/Night cycle (real-time seconds) ────────────────────────────────────
const DAY_CYCLE_SECONDS := 300.0  # 5-minute full cycle
const TINT_DAWN  := Color(1.0, 0.85, 0.7, 0.12)
const TINT_DAY   := Color(1.0, 1.0, 1.0, 0.0)
const TINT_DUSK  := Color(1.0, 0.7, 0.5, 0.18)
const TINT_NIGHT := Color(0.15, 0.18, 0.35, 0.38)

# ── Fog ───────────────────────────────────────────────────────────────────
const FOG_BEACON_RADIUS := 6    # tiles cleared by a lit beacon
const FOG_MAX_ALPHA := 0.55
const FOG_DARKEN_COLOR := Color(0.02, 0.04, 0.12)

# ── Fog of war ────────────────────────────────────────────────────────────
const FOW_REVEAL_RADIUS := 3     # tiles revealed around player
var _fog_tiles: Array = []       # 2D array of ColorRect nodes

# ── Particles ─────────────────────────────────────────────────────────────
var _dust_particles: GPUParticles2D
var _mist_particles: GPUParticles2D
var _firefly_particles: GPUParticles2D

# ── State ──────────────────────────────────────────────────────────────────
var pos: Vector2i = GameData.overworld_position
var facing: Vector2i = GameData.overworld_facing
var walking: bool = false
var walk_timer: float = 0.0
var walk_duration: float = 0.18
var sprinting: bool = false
var rng := RandomNumberGenerator.new()
var step_count: int = 0
var steps_since_encounter: int = 0
var _auto_save_timer: float = 0.0
const AUTO_SAVE_INTERVAL := 60.0
var _player_idle_textures: Dictionary = {}

# Weather
var _raining: bool = false
var _rain_timer: float = 0.0
var _rain_duration: float = 0.0
var _next_weather_check: float = 30.0
var _encounter_respawn_timer: float = 0.0
const ENCOUNTER_RESPAWN_TIME := 120.0  # seconds before cleared encounters can respawn
var _rain_particles: GPUParticles2D

# ── Nodes ──────────────────────────────────────────────────────────────────
@onready var tilemap: TileMapLayer = $TileLayer
@onready var location_markers: Node2D = $LocationMarkers
@onready var camera: Camera2D = $Camera2D
@onready var player_sprite: Node2D = $PlayerSprite
@onready var player_body: Polygon2D = $PlayerSprite/Body
@onready var player_face: ColorRect = $PlayerSprite/Face
@onready var player_texture: Sprite2D = $PlayerSprite/Sprite
@onready var hud: RichTextLabel = $UILayer/HUD
@onready var debug_label: Label = $UILayer/DebugLabel
@onready var char_sheet: CanvasLayer = $CharacterSheet
@onready var quest_journal: CanvasLayer = $QuestJournal
@onready var minimap: CanvasLayer = $Minimap
@onready var inventory_screen: CanvasLayer = $Inventory
@onready var settings_screen: CanvasLayer = $SettingsScreen
@onready var fishing_screen: CanvasLayer = $FishingScreen
@onready var day_night_overlay: ColorRect = $DayNightOverlay
@onready var fog_overlay: ColorRect = $FogOverlay
@onready var fog_of_war: Node2D = $FogOfWar

# ── Zone labels ───────────────────────────────────────────────────────────────
const ZONE_NAMES := {
	"~": "Mournlight Sound",
	".": "Brindlewick Shore",
	",": "Island Grasslands",
	"T": "Forest of Mournlight",
	"^": "Highland Ridge",
	"M": "Ironpeak Mountains",
	"#": "Frozen Summit",
	"=": "Dirt Path",
	"C": "Campfire Rest",
	"!": "Monster Den",
		"V": "Sealed Cave",
		"A": "The Unlit Village",
		"D": "Brindlewick Docks",
		"O": "Overlook Vista",
}

var _zone_label: Label
var _zone_label_timer: float = 0.0
var _last_zone_tile: String = ""

# ── Debug ───────────────────────────────────────────────────────────────────────
var debug_visible: bool = false
var admin_mode: bool = false

# ── Init ───────────────────────────────────────────────────────────────────
func _ready() -> void:
	rng.seed = hash("lanternhouse_overworld")
	_init_player_sprite()
	_warn_bad_map_rows()
	_build_tileset()
	_draw_map()
	_draw_location_markers()
	_init_overlays()
	_init_particles()
	_configure_camera_limits()
	_update_player_visual()
	_update_camera()
	_update_hud()
	_update_day_night()
	_update_fog()
	_init_fog_of_war()
	print("Overworld ready. Player at ", pos, " (tile: ", _tile(pos), ")")

	if GameData.boss_defeated and not GameData.get_meta("overworld_victory_msg", false):
		GameData.set_meta("overworld_victory_msg", true)
		_update_hud_with_msg("[color=cyan]The fog lifts. The Lantern Line burns bright. Brindlewick is safe.[/color]")

	# Zone label
	_zone_label = Label.new()
	_zone_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_zone_label.add_theme_font_size_override("font_size", 16)
	_zone_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	_zone_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	_zone_label.add_theme_constant_override("shadow_offset_x", 2)
	_zone_label.add_theme_constant_override("shadow_offset_y", 2)
	_zone_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_zone_label.position = Vector2(200, 60)
	_zone_label.size = Vector2(400, 30)
	hud.add_child(_zone_label)
	_zone_label.visible = false
	GameData.wage_paid.connect(_on_wage_paid)
	GameData.wage_failed.connect(_on_wage_failed)
	GameData.member_departed.connect(_on_member_departed)

	if debug_label:
		debug_label.hide()

func _build_tileset() -> void:
	var tex: Texture2D
	if FileAccess.file_exists(OVERWORLD_ATLAS_PATH):
		var image := Image.new()
		if image.load(OVERWORLD_ATLAS_PATH) == OK:
			tex = ImageTexture.create_from_image(image)
	if not tex:
		push_error("Failed to load overworld terrain atlas!")
		print("ERROR: overworld terrain atlas not found: ", OVERWORLD_ATLAS_PATH)
		# Fallback: render map with colors
		_fallback_draw()
		return

	print("overworld_atlas loaded: ", tex.get_width(), "x", tex.get_height())

	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
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
	tilemap.tile_set = ts
	print("TileSet built with ", TILE_ATLAS.size(), " tile types")

func _draw_map() -> void:
	var tile_count: int = 0
	for y in range(MAP_H):
		for x in range(MAP_W):
			var tile_char: String = _tile(Vector2i(x, y))
			var atlas_coord: Vector2i = TILE_ATLAS.get(tile_char, T_GRASS)
			tilemap.set_cell(Vector2i(x, y), 0, atlas_coord)
			tile_count += 1
	print("Map drawn: ", tile_count, " tiles")

func _draw_location_markers() -> void:
	if not location_markers:
		return
	for child in location_markers.get_children():
		child.queue_free()
	for marker: Dictionary in LANDMARK_MARKERS:
		_add_location_marker(
			marker["pos"],
			marker["label"],
			marker.get("color", Color(1.0, 0.86, 0.24, 0.9)),
			marker.get("offset", Vector2(-44, -31))
		)

func _add_location_marker(grid: Vector2i, label_text: String, marker_color: Color, label_offset: Vector2) -> void:
	var marker := Node2D.new()
	marker.position = Vector2(grid * TILE_SIZE) + Vector2(TILE_SIZE / 2, 2)

	var pin := Polygon2D.new()
	pin.color = marker_color
	pin.polygon = PackedVector2Array([
		Vector2(0, -10),
		Vector2(8, -2),
		Vector2(3, -2),
		Vector2(3, 8),
		Vector2(-3, 8),
		Vector2(-3, -2),
		Vector2(-8, -2)
	])
	marker.add_child(pin)

	var label := Label.new()
	label.text = label_text
	label.position = label_offset
	label.size = Vector2(108, 20)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(marker_color.r, marker_color.g, marker_color.b, 1.0))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	marker.add_child(label)

	location_markers.add_child(marker)

func _fallback_draw() -> void:
	"""Draw colored rectangles if tileset failed to load."""
	print("Using colored-block fallback")
	for y in range(MAP_H):
		for x in range(MAP_W):
			var tile_char: String = _tile(Vector2i(x, y))
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
	if player_body:
		var base_color := Color("f0d46a") if not sprinting else Color("f0a46a")
		player_body.color = base_color
	if walking:
		player_sprite.position.y -= 2
	if player_texture:
		if not _update_player_texture():
			player_texture.flip_h = facing == Vector2i.LEFT
		player_texture.modulate = Color(1.08, 1.06, 0.95) if sprinting else Color.WHITE

func _init_player_sprite() -> void:
	if not player_texture:
		return
	_load_player_textures()
	_update_player_texture()
	if player_texture.texture:
		player_texture.centered = true
		player_texture.position = Vector2.ZERO
		player_texture.z_index = 4
		if player_body:
			player_body.hide()
		if player_face:
			player_face.hide()
		return
	if not FileAccess.file_exists(PLAYER_SPRITE_PATH):
		return
	var image := Image.new()
	if image.load(PLAYER_SPRITE_PATH) != OK:
		return
	player_texture.texture = ImageTexture.create_from_image(image)
	player_texture.centered = true
	player_texture.position = Vector2.ZERO
	player_texture.z_index = 4
	if player_body:
		player_body.hide()
	if player_face:
		player_face.hide()

func _load_player_textures() -> void:
	for dir_name in ["south", "east", "north", "west"]:
		_player_idle_textures[dir_name] = _load_png_texture(PLAYER_ROTATION_PATH % dir_name)

func _load_png_texture(path: String) -> Texture2D:
	if not FileAccess.file_exists(path):
		return null
	var image := Image.new()
	if image.load(path) != OK:
		push_warning("Image could not be loaded: %s" % path)
		return null
	return ImageTexture.create_from_image(image)

func _update_player_texture() -> bool:
	if _player_idle_textures.is_empty():
		return false
	var texture: Texture2D = _player_idle_textures.get(_direction_name(facing), _player_idle_textures.get("south", null))
	if texture:
		player_texture.texture = texture
		player_texture.flip_h = false
		player_texture.scale = Vector2(0.58, 0.58)
		return true
	return false

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

func _update_camera() -> void:
	if camera:
		camera.global_position = player_sprite.global_position

func _configure_camera_limits() -> void:
	if not camera:
		return
	camera.anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	camera.limit_enabled = true
	var world_w: float = MAP_W * TILE_SIZE
	var world_h: float = MAP_H * TILE_SIZE
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(world_w)
	camera.limit_bottom = int(world_h)

# ── Input ──────────────────────────────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	if char_sheet and char_sheet.active:
		char_sheet._unhandled_input(event)
		return
	if quest_journal and quest_journal.active:
		quest_journal._unhandled_input(event)
		return
	if inventory_screen and inventory_screen.active:
		inventory_screen._unhandled_input(event)
		return
	if settings_screen and settings_screen.active:
		settings_screen._unhandled_input(event)
		return
	if fishing_screen and fishing_screen.active:
		fishing_screen._unhandled_input(event)
		return
	if minimap and minimap.visible:
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if walking:
		return

	var dir := Vector2i.ZERO
	if event.is_action("move_up"):         dir = Vector2i.UP
	elif event.is_action("move_down"):     dir = Vector2i.DOWN
	elif event.is_action("move_left"):     dir = Vector2i.LEFT
	elif event.is_action("move_right"):    dir = Vector2i.RIGHT
	elif event.is_action("interact"):
		_interact()
		return
	elif event.keycode == KEY_F5 or event.keycode == KEY_F6:
		if SaveManager.save_game():
			_update_hud_with_msg("Game saved!")
		else:
			_update_hud_with_msg("Save failed!")
		return
	elif event.keycode == KEY_F7 or event.keycode == KEY_F9:
		if SaveManager.load_game():
			pos = GameData.overworld_position
			facing = GameData.overworld_facing
			_update_player_visual()
			_update_camera()
			_refresh_fog_of_war()
			_update_hud()
			_update_hud_with_msg("Game loaded!")
		else:
			_update_hud_with_msg("No save found.")
		return
	elif event.keycode == KEY_F3:
		_toggle_debug()
		return
	elif event.keycode == KEY_F4:
		_toggle_admin_mode()
		return
	elif event.keycode == KEY_C or event.keycode == KEY_M:
		if char_sheet:
			if char_sheet.active:
				char_sheet.close()
			else:
				char_sheet.open()
		return
	elif event.keycode == KEY_J:
		if quest_journal:
			if quest_journal.active:
				quest_journal.close()
			else:
				quest_journal.open()
		return
	elif event.keycode == KEY_I:
		if inventory_screen:
			if inventory_screen.active:
				inventory_screen.close()
			else:
				inventory_screen.open()
		return
	elif event.keycode == KEY_ESCAPE:
		if settings_screen:
			if settings_screen.active:
				settings_screen.close()
			else:
				settings_screen.open()
		return

	if dir != Vector2i.ZERO:
		_try_move(dir)

# ── Movement ───────────────────────────────────────────────────────────────
func _try_move(dir: Vector2i) -> void:
	facing = dir
	var next := pos + dir
	if _is_blocked(next):
		if _is_gate_blocked(next):
			var beacon_name: String = GATED_ROUTES.get(next, "unknown")
			_update_hud_with_msg("The path is sealed. Light the %s beacon east of the mountain pass to pass." % beacon_name.replace("_", " "))
		else:
			_update_hud_with_msg("Can't go that way.")
		return

	sprinting = Input.is_key_pressed(KEY_SHIFT)
	pos = next
	walking = true
	walk_timer = walk_duration * (0.5 if sprinting else 1.0)
	_update_player_visual()
	_update_camera()
	_step_effects()

func _is_blocked(grid: Vector2i) -> bool:
	if grid.x < 0 or grid.x >= MAP_W or grid.y < 0 or grid.y >= MAP_H:
		return true
	if BLOCKED.has(_tile(grid)):
		return true
	if _is_gate_blocked(grid):
		return true
	return false

func _tile(grid: Vector2i) -> String:
	if grid.x < 0 or grid.x >= MAP_W or grid.y < 0 or grid.y >= MAP_H or grid.y >= MAP.size():
		return "~"
	var row: String = MAP[grid.y]
	if grid.x >= row.length():
		return "~"
	return row.substr(grid.x, 1)

func _warn_bad_map_rows() -> void:
	var bad_rows: Array[String] = []
	for y in range(MAP.size()):
		var row: String = MAP[y]
		if row.length() != MAP_W:
			bad_rows.append("%d:%d" % [y, row.length()])
	if MAP.size() != MAP_H:
		bad_rows.append("height:%d" % MAP.size())
	if not bad_rows.is_empty():
		push_warning("Overworld MAP shape differs from %dx%d; out-of-row cells render as water. Rows: %s" % [MAP_W, MAP_H, ", ".join(bad_rows)])

func _step_effects() -> void:
	step_count += 1
	steps_since_encounter += 1
	var tile := _tile(pos)

	# Zone transition label
	if tile != _last_zone_tile and ZONE_NAMES.has(tile):
		_last_zone_tile = tile
		if _zone_label:
			_zone_label.text = ZONE_NAMES[tile]
			_zone_label_timer = 2.5
	# Footstep sounds
	if step_count % 2 == 0:
		match tile:
			",": AudioManager.play_footstep_grass()
			"=": AudioManager.play_footstep_dirt()
			".": AudioManager.play_footstep_sand()
			"^": AudioManager.play_footstep_stone()
			"T": AudioManager.play_footstep_grass()

	if tile == "L":
		_interact_beacon("lighthouse", pos)
	elif tile == "B":
		_interact_beacon(_beacon_name_at(pos), pos)
	elif tile == "h":
		_enter_brindlewick()
		return
	# Admin mode and Fog in a Bottle block encounters.
	if admin_mode or GameData.get_meta("fog_active", false):
		return
	# Visible encounter markers — guaranteed combat
	if tile == "!" and not GameData.cleared_encounters.get(str(pos), false):
		_start_battle("forest")
		return
	# [CODING CONCEPT: Probability / Random Encounters]
	# Each zone has an encounter rate (lower = more encounters).
	# rng.randi_range(1, rate) picks a number 1 to rate. If it's 1,
	# combat starts. So rate=6 means a 1-in-6 chance per step in forest.
	# Sprinting makes encounters more likely by lowering the rate.
	# This is the classic Dragon Quest / Final Fantasy encounter system.
	if ENCOUNTER_ZONES.has(tile):
		var zone: String = ENCOUNTER_ZONES[tile]
		if GameData.boss_defeated and zone in ["forest", "mountain"]:
			zone = "post_seal"
		var base_rate: int = ENCOUNTER_RATE.get(zone, 8)
		var rate := base_rate
		if sprinting:
			rate = max(3, rate - 2)
		if rng.randi_range(1, rate) == 1:
			steps_since_encounter = 0
			_start_battle(zone)

	GameData.overworld_position = pos
	GameData.overworld_facing = facing

# [CODING CONCEPT: Interaction System via Tile Type]
# When the player presses the interact key, we check what tile is in front
# of them (pos + facing). Each tile type routes to a different function.
# This is simpler than having a list of interactable objects — the map IS
# the interaction database. Adding a new interaction is just: add a tile
# symbol to MAP, add a handler in this match statement.
func _interact() -> void:
	if _interact_current_tile():
		return
	var target := pos + facing
	var tile := _tile(target)
	if tile == "L":
		_interact_beacon("lighthouse", target)
	elif tile == "B":
		var beacon_name := _beacon_name_at(target)
		_interact_beacon(beacon_name, target)
	elif tile == "S":
		var msg: String = SIGNPOST_TEXTS.get(str(target), "An old signpost. The writing has faded.")
		_update_hud_with_msg(msg)
	elif tile == "C":
		_interact_campfire()
	elif tile == "V":
		_interact_cave(target)
	elif tile == "A":
		_interact_ruins(target)
	elif tile == "D":
		_interact_dock()
	elif tile == "O":
		_interact_overlook()
	elif tile == "f":
		_interact_forest_clearing()
	elif tile == "h":
		_enter_brindlewick()
	elif FishDB.can_fish(tile):
		var zone := FishDB.zone_for_tile(tile)
		if fishing_screen:
			fishing_screen.open(zone)
	elif AlchemyDB.can_gather(tile):
		_try_gather_herbs(target)
	elif TinkerDB.can_gather(tile):
		_try_gather_materials(target)
	else:
		_update_hud_with_msg("Nothing here.")

func _interact_current_tile() -> bool:
	var tile := _tile(pos)
	if tile == "L":
		_interact_beacon("lighthouse", pos)
		return true
	if tile == "B":
		_interact_beacon(_beacon_name_at(pos), pos)
		return true
	return false

func _enter_brindlewick() -> void:
	GameData.overworld_position = pos
	GameData.overworld_facing = facing
	GameData.set_meta("overworld_return_position", BRINDLEWICK_EXIT_POS)
	GameData.set_meta("overworld_return_facing", Vector2i.DOWN)
	if GameData.owns_home():
		SceneTransition.change_scene("res://scenes/home/home.tscn")
	else:
		SceneTransition.change_scene("res://scenes/town/town.tscn")

func _interact_beacon(beacon_name: String, beacon_pos: Vector2i) -> void:
	var key := str(beacon_pos)
	if not GameData.beacon_states.get(key, false):
		var quest_id := _active_beacon_quest_for(beacon_name)
		if _beacon_has_story_quest(beacon_name) and quest_id == "":
			_update_hud_with_msg(_inactive_story_beacon_msg(beacon_name))
			return
		GameData.beacon_states[key] = true
		GameData.beacon_lit = true
		GameData.change_faction_rep(FactionDB.Faction.KEEPERS_GUILD, 5)
		AudioManager.play_beacon_light()
		# Reveal fog of war around newly lit beacon
		for dy in range(-FOG_BEACON_RADIUS, FOG_BEACON_RADIUS + 1):
			for dx in range(-FOG_BEACON_RADIUS, FOG_BEACON_RADIUS + 1):
				var tx := beacon_pos.x + dx
				var ty := beacon_pos.y + dy
				if tx >= 0 and tx < MAP_W and ty >= 0 and ty < MAP_H:
					if Vector2(dx, dy).length() <= FOG_BEACON_RADIUS:
						GameData.explored_tiles[str(Vector2i(tx, ty))] = true
						if not _fog_tiles.is_empty():
							_fog_tiles[ty][tx].visible = false
		var msg := "You light the %s beacon! The surrounding darkness recedes." % beacon_name.replace("_", " ")
		if quest_id != "":
			var quest: Dictionary = QuestDB.get_quest(quest_id)
			GameData.active_quests[quest_id]["progress"] = 1
			msg = "%s\n[color=#f0d46a]%s[/color]" % [quest.get("event_text", msg), quest.get("turn_in", "Return to the Elder in Brindlewick.")]
		_update_hud_with_msg(msg)
		_check_all_beacons_event()
	else:
		_update_hud_with_msg("The %s beacon burns bright against the dark." % beacon_name.replace("_", " "))

func _active_beacon_quest_for(beacon_name: String) -> String:
	for qid: String in GameData.active_quests:
		if GameData.active_quests[qid].get("status", "") != "active":
			continue
		var quest: Dictionary = QuestDB.get_quest(qid)
		if quest.get("type", "") == "beacon" and quest.get("target", "") == beacon_name:
			return qid
	return ""

func _beacon_has_story_quest(beacon_name: String) -> bool:
	for qid: String in QuestDB.quest_ids():
		var quest: Dictionary = QuestDB.get_quest(qid)
		if quest.get("type", "") == "beacon" and quest.get("target", "") == beacon_name and quest.has("event_text"):
			return true
	return false

func _inactive_story_beacon_msg(beacon_name: String) -> String:
	match beacon_name:
		"lighthouse":
			return "The lighthouse wick is cold and stubborn. Old Thatch may know how to relight it."
		"north_forest":
			return "The North Forest beacon is dark. Something has been hidden here, but you need Old Thatch's story to know what to seek."
		_:
			return "This beacon is dark. Someone in Brindlewick may know why."

func _beacon_name_at(grid: Vector2i) -> String:
	for name: String in BEACON_POSITIONS:
		if BEACON_POSITIONS[name] == grid:
			return name
	return "unknown"

func _all_beacons_lit() -> bool:
	for bname: String in BEACON_POSITIONS:
		if not GameData.beacon_states.get(str(BEACON_POSITIONS[bname]), false):
			return false
	return true

func _check_all_beacons_event() -> void:
	if not GameData.boss_defeated and _all_beacons_lit() and not GameData.get_meta("all_beacons_triggered", false):
		GameData.set_meta("all_beacons_triggered", true)
		GameData.change_faction_rep(FactionDB.Faction.KEEPERS_GUILD, 25)
		_update_hud_with_msg("[color=cyan]All beacons are lit! The Lantern Line blazes to life! Something stirs in the mountain cave...[/color]")

func _start_battle(zone: String) -> void:
	GameData.overworld_position = pos
	GameData.overworld_facing = facing
	GameData.set_meta("battle_zone", zone)
	GameData.set_meta("battle_surprise", rng.randi_range(1, 10) <= 1)
	GameData.set_meta("battle_weather", "rain" if _raining else "clear")
	SceneTransition.change_scene("res://scenes/battle/battle.tscn")

# ── Cave / Ruins / Dock interactions ──────────────────────────────────────
func _interact_cave(target: Vector2i) -> void:
	if GameData.boss_defeated and GameData.is_quest_active("what_the_line_imprisons"):
		GameData.set_meta("cave_deep", true)
		GameData.overworld_position = pos
		GameData.overworld_facing = facing
		SceneTransition.change_scene("res://scenes/cave/cave.tscn")
	elif GameData.boss_defeated:
		_update_hud_with_msg("The cave is silent. The seal has been broken and whatever dwelled within is gone.")
	elif _all_beacons_lit():
		if not GameData.get_meta("cave_opened", false):
			GameData.set_meta("cave_opened", true)
			_update_hud_with_msg("[color=cyan]All beacons are lit! The seal cracks open![/color]")
		GameData.overworld_position = pos
		GameData.overworld_facing = facing
		SceneTransition.change_scene("res://scenes/cave/cave.tscn")
	else:
		_update_hud_with_msg("A sealed cave mouth. Ancient runes glow faintly across the entrance.\n[color=cyan]Light all the beacons to break the seal.[/color]")

func _interact_ruins(target: Vector2i) -> void:
	GameData.overworld_position = pos
	GameData.overworld_facing = facing
	SceneTransition.change_scene("res://scenes/abandoned_village/abandoned_village.tscn")

func _interact_dock() -> void:
	GameData.overworld_position = pos
	GameData.overworld_facing = facing
	SceneTransition.change_scene("res://scenes/dock/dock.tscn")

func _interact_forest_clearing() -> void:
	GameData.overworld_position = pos
	GameData.overworld_facing = facing
	SceneTransition.change_scene("res://scenes/forest_clearing/forest_clearing.tscn")

func _interact_overlook() -> void:
	var revealed := 0
	for dy in range(-8, 9):
		for dx in range(-8, 9):
			var tx := pos.x + dx
			var ty := pos.y + dy
			if tx >= 0 and tx < MAP_W and ty >= 0 and ty < MAP_H:
				if Vector2(dx, dy).length() <= 8:
					var key := str(Vector2i(tx, ty))
					if not GameData.explored_tiles.get(key, false):
						GameData.explored_tiles[key] = true
						revealed += 1
						if not _fog_tiles.is_empty():
							_fog_tiles[ty][tx].visible = false
	GameData.track_skill_use("exploration", 1)
	var explore_pct := int(float(GameData.explored_tiles.size()) / max(1, _count_land_tiles()) * 100)
	explore_pct = mini(explore_pct, 100)
	var msg := "From the overlook, the island stretches out before you.\n"
	msg += "Mournlight Sound glimmers to the east. The forest canopy hides old paths.\n"
	msg += "To the south, the lighthouse beam cuts through the dusk.\n\n"
	msg += "[color=cyan]Revealed %d new tiles![/color] Exploration: %d%%" % [revealed, explore_pct]
	if GameData.boss_defeated:
		msg += "\n\nThe fog has lifted entirely. The island breathes again."
	elif GameData.beacon_lit:
		msg += "\n\nThe beacons burn below like a string of stars against the dark."
	else:
		msg += "\n\nDarkness presses in from all sides. The beacons wait to be lit."
	_update_hud_with_msg(msg)

func _count_land_tiles() -> int:
	var count := 0
	for y in range(MAP_H):
		for x in range(MAP_W):
			if _tile(Vector2i(x, y)) != "~":
				count += 1
	return count


# ── Gathering (herbs & materials) ──────────────────────────────────────────
func _try_gather_herbs(target: Vector2i) -> void:
	var tile := _tile(target)
	var herbs := AlchemyDB.herbs_for_tile(tile)
	if herbs.is_empty():
		_update_hud_with_msg("Nothing to gather here.")
		return
	var skill_bonus := GameData.get_skill_bonus("alchemy")
	var chance := 0.4 + skill_bonus * 0.1
	if rng.randf() > chance:
		_update_hud_with_msg("You search the area but find nothing useful.")
		return
	var herb_id: int = herbs[rng.randi() % herbs.size()]
	var info: Dictionary = AlchemyDB.HERB_INFO[herb_id]
	var count := 1 + (1 if rng.randf() < 0.3 + skill_bonus * 0.05 else 0)
	GameData.add_herb(info["id"], count)
	GameData.track_skill_use("alchemy", 1)
	_update_hud_with_msg("Gathered %s x%d!" % [info["name"], count])

func _try_gather_materials(target: Vector2i) -> void:
	var tile := _tile(target)
	var materials := TinkerDB.materials_for_tile(tile)
	if materials.is_empty():
		_update_hud_with_msg("Nothing to scavenge here.")
		return
	var skill_bonus := GameData.get_skill_bonus("tinkering")
	var chance := 0.4 + skill_bonus * 0.1
	if rng.randf() > chance:
		_update_hud_with_msg("You search the area but find nothing useful.")
		return
	var mat_id: int = materials[rng.randi() % materials.size()]
	var info: Dictionary = TinkerDB.get_material_info(mat_id)
	var count := 1 + (1 if rng.randf() < 0.3 + skill_bonus * 0.05 else 0)
	GameData.add_material(info["id"], count)
	GameData.track_skill_use("tinkering", 1)
	_update_hud_with_msg("Scavenged %s x%d!" % [info["name"], count])


# ── Process ────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if walking:
		walk_timer -= delta
		if walk_timer <= 0:
			walking = false
		_update_player_visual()
	_update_camera()

	_auto_save_timer += delta
	if _auto_save_timer >= AUTO_SAVE_INTERVAL:
		_auto_save_timer = 0.0
		if SaveManager.save_game():
			_update_hud_with_msg("[color=#444]Auto-saved[/color]")
	_update_day_night()
	_update_fog()
	_update_fog_of_war()
	_update_particles()
	_update_weather(delta)
	_respawn_encounters(delta)

	# Fog in a Bottle timer
	if GameData.get_meta("fog_active", false):
		var fog_timer: float = GameData.get_meta("fog_timer", 0.0)
		fog_timer -= delta
		if fog_timer <= 0:
			GameData.set_meta("fog_active", false)
			GameData.set_meta("fog_timer", 0.0)
			_update_hud_with_msg("[color=gray]The fog dissipates...[/color]")
		else:
			GameData.set_meta("fog_timer", fog_timer)

	if debug_visible and debug_label and debug_label.visible:
		_update_debug()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		_configure_camera_limits()

# ── Overlays (day/night, fog) ──────────────────────────────────────────────
func _init_overlays() -> void:
	var vp_size := Vector2(MAP_W * TILE_SIZE, MAP_H * TILE_SIZE)
	if day_night_overlay:
		day_night_overlay.size = vp_size
		day_night_overlay.position = Vector2.ZERO
	if fog_overlay:
		fog_overlay.size = vp_size
		fog_overlay.position = Vector2.ZERO

# [CODING CONCEPT: Time-Based Visual Effects]
# fmod() is modulo for floats — it wraps the play_time around the cycle length.
# Dividing by cycle length gives a 0.0-1.0 progress value (where in the day we are).
# That value is used to interpolate (lerp) between color tints:
# dawn=warm orange, day=clear, dusk=orange-red, night=dark blue.
func _update_day_night() -> void:
	if not day_night_overlay:
		return
	var t := fmod(GameData.play_time, DAY_CYCLE_SECONDS) / DAY_CYCLE_SECONDS
	var base_color := _day_tint_at(t)
	if _raining:
		base_color = Color(base_color.r * 0.7, base_color.g * 0.7, base_color.b * 0.85, base_color.a + 0.08)
	day_night_overlay.color = base_color

func _day_tint_at(t: float) -> Color:
	if t < 0.2:
		return _lerp_color(TINT_NIGHT, TINT_DAWN, t / 0.2)
	elif t < 0.3:
		return _lerp_color(TINT_DAWN, TINT_DAY, (t - 0.2) / 0.1)
	elif t < 0.7:
		return TINT_DAY
	elif t < 0.8:
		return _lerp_color(TINT_DAY, TINT_DUSK, (t - 0.7) / 0.1)
	elif t < 0.9:
		return _lerp_color(TINT_DUSK, TINT_NIGHT, (t - 0.8) / 0.1)
	else:
		return TINT_NIGHT

func _lerp_color(a: Color, b: Color, t: float) -> Color:
	return Color(
		lerpf(a.r, b.r, t),
		lerpf(a.g, b.g, t),
		lerpf(a.b, b.b, t),
		lerpf(a.a, b.a, t)
	)

func _update_fog() -> void:
	if not fog_overlay:
		return
	var player_px := Vector2(pos)
	var min_dist := FOG_BEACON_RADIUS + 1.0
	for bname: String in BEACON_POSITIONS:
		var bp: Vector2i = BEACON_POSITIONS[bname]
		if not GameData.beacon_states.get(str(bp), false):
			continue
		var d := player_px.distance_to(Vector2(bp))
		if d < min_dist:
			min_dist = d
	if min_dist <= FOG_BEACON_RADIUS:
		fog_overlay.color = Color(FOG_DARKEN_COLOR.r, FOG_DARKEN_COLOR.g, FOG_DARKEN_COLOR.b, 0.0)
	else:
		var fog_alpha := clampf((min_dist - FOG_BEACON_RADIUS) / FOG_BEACON_RADIUS, 0.0, 1.0)
		fog_overlay.color = Color(FOG_DARKEN_COLOR.r, FOG_DARKEN_COLOR.g, FOG_DARKEN_COLOR.b, fog_alpha * FOG_MAX_ALPHA)

func _init_fog_of_war() -> void:
	if not fog_of_war:
		return
	_fog_tiles.clear()
	for y in range(MAP_H):
		var row: Array = []
		for x in range(MAP_W):
			var rect := ColorRect.new()
			rect.color = Color(0.01, 0.02, 0.06, 0.92)
			rect.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
			rect.size = Vector2(TILE_SIZE, TILE_SIZE)
			rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			fog_of_war.add_child(rect)
			row.append(rect)
		_fog_tiles.append(row)
	# Reveal tiles around lit beacons
	for bname: String in BEACON_POSITIONS:
		var bp: Vector2i = BEACON_POSITIONS[bname]
		if GameData.beacon_states.get(str(bp), false):
			for dy in range(-FOG_BEACON_RADIUS, FOG_BEACON_RADIUS + 1):
				for dx in range(-FOG_BEACON_RADIUS, FOG_BEACON_RADIUS + 1):
					var tx := bp.x + dx
					var ty := bp.y + dy
					if tx >= 0 and tx < MAP_W and ty >= 0 and ty < MAP_H:
						if Vector2(dx, dy).length() <= FOG_BEACON_RADIUS:
							GameData.explored_tiles[str(Vector2i(tx, ty))] = true
	_update_fog_of_war()

func _update_fog_of_war() -> void:
	if _fog_tiles.is_empty():
		return
	for dy in range(-FOW_REVEAL_RADIUS, FOW_REVEAL_RADIUS + 1):
		for dx in range(-FOW_REVEAL_RADIUS, FOW_REVEAL_RADIUS + 1):
			var tx := pos.x + dx
			var ty := pos.y + dy
			if tx >= 0 and tx < MAP_W and ty >= 0 and ty < MAP_H:
				if Vector2(dx, dy).length() <= FOW_REVEAL_RADIUS:
					var key := str(Vector2i(tx, ty))
					if not GameData.explored_tiles.get(key, false):
						GameData.explored_tiles[key] = true
					_fog_tiles[ty][tx].visible = false

func _refresh_fog_of_war() -> void:
	if _fog_tiles.is_empty():
		return
	for y in range(MAP_H):
		for x in range(MAP_W):
			_fog_tiles[y][x].visible = not GameData.explored_tiles.get(str(Vector2i(x, y)), false)
	_update_fog_of_war()



# ── Particles (dust, mist, fireflies) ─────────────────────────────────────
func _init_particles() -> void:
	_dust_particles = _make_particles(8, Color("a09070"), Vector2(4, 2), 0.4, Vector2(0, -8))
	_mist_particles = _make_particles(30, Color("8a8a9a"), Vector2(20, 10), 2.5, Vector2(-12, -4))
	_mist_particles.draw_order = GPUParticles2D.DRAW_ORDER_LIFETIME
	_firefly_particles = _make_particles(12, Color("f0e860"), Vector2(6, 6), 1.8, Vector2(4, -6))
	add_child(_dust_particles)
	add_child(_mist_particles)
	add_child(_firefly_particles)
	_dust_particles.emitting = false
	_firefly_particles.emitting = false
	_mist_particles.z_index = 48
	_firefly_particles.z_index = 51

func _make_particles(count: int, color: Color, size: Vector2, lifetime: float, velocity: Vector2) -> GPUParticles2D:
	var p := GPUParticles2D.new()
	p.amount = count
	p.lifetime = lifetime
	p.explosiveness = 0.0
	p.randomness = 0.6
	p.local_coords = false
	var mat := ParticleProcessMaterial.new()
	mat.particle_flag_disable_z = true
	mat.direction = Vector3(velocity.x, velocity.y, 0)
	mat.spread = 30.0
	mat.initial_velocity_min = 4.0
	mat.initial_velocity_max = 12.0
	mat.gravity = Vector3.ZERO
	mat.scale_min = size.x
	mat.scale_max = size.y
	var gradient := Gradient.new()
	gradient.add_point(1.0, Color(color.r, color.g, color.b, 0.0))
	gradient.set_color(0, Color(color.r, color.g, color.b, 0.0))
	gradient.set_color(1, color)
	gradient.set_color(2, Color(color.r, color.g, color.b, 0.0))
	gradient.set_offset(0, 0.0)
	gradient.set_offset(1, 0.3)
	gradient.set_offset(2, 1.0)
	var gradient_texture := GradientTexture1D.new()
	gradient_texture.gradient = gradient
	mat.color_ramp = gradient_texture
	p.process_material = mat
	return p

func _update_weather(delta: float) -> void:
	if _raining:
		_rain_timer -= delta
		if _rain_timer <= 0.0:
			_raining = false
	else:
		_next_weather_check -= delta
		if _next_weather_check <= 0.0:
			_next_weather_check = rng.randf_range(40.0, 120.0)
			if rng.randf() < 0.25:
				_raining = true
				_rain_timer = rng.randf_range(20.0, 60.0)
	if _rain_particles:
		_rain_particles.emitting = _raining
		_rain_particles.global_position = player_sprite.position

func _update_particles() -> void:
	var player_world := player_sprite.position
	if _dust_particles:
		_dust_particles.global_position = player_world
		_dust_particles.emitting = walking and _tile(pos) == "="
	if _mist_particles:
		_mist_particles.global_position = player_world
	if _firefly_particles:
		_firefly_particles.global_position = player_world
		var near_beacon := false
		for bname: String in BEACON_POSITIONS:
			var bp: Vector2i = BEACON_POSITIONS[bname]
			if pos.distance_to(bp) <= FOG_BEACON_RADIUS:
				near_beacon = true
				break
		_firefly_particles.emitting = near_beacon and not _is_night()

func _is_night() -> bool:
	var t := fmod(GameData.play_time, DAY_CYCLE_SECONDS) / DAY_CYCLE_SECONDS
	return t >= 0.8 or t < 0.15

# ── Encounter respawn ────────────────────────────────────────────────────
func _respawn_encounters(delta: float) -> void:
	if admin_mode:
		return
	_encounter_respawn_timer += delta
	if _encounter_respawn_timer < ENCOUNTER_RESPAWN_TIME:
		return
	_encounter_respawn_timer = 0.0
	for y in range(MAP_H):
		for x in range(MAP_W):
			var key := str(Vector2i(x, y))
			if GameData.cleared_encounters.has(key) and _tile(Vector2i(x, y)) == ",":
				if rng.randf() < 0.3:
					GameData.cleared_encounters.erase(key)
					tilemap.set_cell(Vector2i(x, y), 0, TILE_ATLAS["!"])
					break

# ── HUD ────────────────────────────────────────────────────────────────────
func _update_hud() -> void:
	var lines: Array = []
	var beacon_status: String = "[color=cyan]LIT[/color]" if GameData.beacon_lit else "[color=gray]UNLIT[/color]"
	lines.append("%s    Tonics:%d    Ethers:%d    Beacon:%s" % [GameData.format_money_short(), GameData.tonics, GameData.ethers, beacon_status])
	if admin_mode:
		lines.append("[color=yellow]ADMIN MODE[/color]    Encounters off")
	else:
		var danger := clampi(steps_since_encounter / 3, 0, 5)
		var danger_bar := ""
		for d in range(5):
			danger_bar += "[color=red]|[/color]" if d < danger else "[color=gray].[/color]"
		lines.append("Danger: %s" % danger_bar)
	# Exploration percentage
	var land_tiles := 0
	for y in range(MAP_H):
		for x in range(MAP_W):
			if _tile(Vector2i(x, y)) != "~":
				land_tiles += 1
	var explored := GameData.explored_tiles.size()
	var pct := int(float(explored) / max(land_tiles, 1) * 100)
	lines.append("Explored:%d%%    [M] Party    [J] Journal    [I] Items" % mini(pct, 100))
	hud.text = "\n".join(lines)


func _interact_campfire() -> void:
	if GameData.tonics <= 0:
		_update_hud_with_msg("The campfire crackles warmly, but you have no tonics to rest with.")
		return
	GameData.tonics -= 1
	for m: Dictionary in GameData.party:
		if m["alive"]:
			var heal := int(m["max_hp"] * 0.3)
			m["hp"] = mini(m["hp"] + heal, m["max_hp"])
			if m.has("loyalty") and m.get("wage", 0) > 0:
				m["loyalty"] = mini(m["loyalty"] + 1, 100)
	_update_hud_with_msg("You rest by the campfire... [-1 tonic] Party healed 30%% HP.")

func _update_hud_with_msg(msg: String) -> void:
	_update_hud()
	hud.text += "\n\n[i]%s[/i]" % _wrap_hud_message(msg, 76)

func _wrap_hud_message(msg: String, max_chars: int) -> String:
	var wrapped_lines: Array = []
	for raw_line: String in msg.split("\n"):
		var line := raw_line.strip_edges()
		while line.length() > max_chars:
			var split_at := line.rfind(" ", max_chars)
			if split_at <= 0:
				split_at = max_chars
			wrapped_lines.append(line.substr(0, split_at))
			line = line.substr(split_at).strip_edges()
		wrapped_lines.append(line)
	return "\n".join(wrapped_lines)


func _on_wage_paid(npc_name: String, amount: int) -> void:
	_update_hud_with_msg("Paid %dc wage to %s." % [amount, npc_name])

func _on_wage_failed(npc_name: String) -> void:
	_update_hud_with_msg("%s's wage went unpaid! Loyalty decreased." % npc_name)

func _on_member_departed(npc_name: String) -> void:
	_update_hud_with_msg("[color=red]%s has left the party permanently![/color]" % npc_name)
	GameData.remove_departed_members()
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

func _toggle_admin_mode() -> void:
	admin_mode = not admin_mode
	steps_since_encounter = 0
	_update_hud_with_msg("[color=yellow]Admin mode %s. Encounters %s.[/color]" % [
		"enabled" if admin_mode else "disabled",
		"disabled" if admin_mode else "enabled",
	])
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
		+ "Admin: %s\n" % ("ON" if admin_mode else "OFF")
		+ "Time: %s\n" % _format_time(GameData.play_time)
		+ "Period: %s\n" % _day_period_name()
		+ "Beacon: %s\n" % ("Lit" if GameData.beacon_lit else "Unlit")
		+ "Skills:\n"
		+ "  Weapon: %s (%d)\n" % [GameData.get_skill_tier("weapon"), GameData.skill_uses.get("weapon", 0)]
		+ "  Magic: %s (%d)\n" % [GameData.get_skill_tier("magic"), GameData.skill_uses.get("magic", 0)]
		+ "  Healing: %s (%d)" % [GameData.get_skill_tier("healing"), GameData.skill_uses.get("healing", 0)]
		)

var tick_count: int = 0

func _dir_name(d: Vector2i) -> String:
	match d:
		Vector2i.UP: return "Up"
		Vector2i.DOWN: return "Down"
		Vector2i.LEFT: return "Left"
		Vector2i.RIGHT: return "Right"
	return "?"

func _format_time(seconds: float) -> String:
	var s := int(seconds)
	return "%d:%02d" % [(s / 60), (s % 60)]

func _day_period_name() -> String:
	var t := fmod(GameData.play_time, DAY_CYCLE_SECONDS) / DAY_CYCLE_SECONDS
	if t < 0.15: return "Night"
	elif t < 0.2: return "Dawn"
	elif t < 0.3: return "Morning"
	elif t < 0.7: return "Day"
	elif t < 0.8: return "Dusk"
	elif t < 0.9: return "Evening"
	return "Night"

