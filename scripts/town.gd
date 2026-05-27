# Town — interior map with NPCs, weapon shop, armor shop, inn
#
# [CODING CONCEPT: Scene Transitions]
# When the player walks to the bottom of this map, the game switches to the
# overworld scene via SceneTransition.change_scene(). When they talk to a
# merchant, it switches to the shop scene. Each scene is independent — this
# script doesn't know how the shop works, and the shop doesn't know how the
# town map is drawn. They communicate through GameData (shared state) and
# GameData.set_meta()/get_meta() (one-time messages like "shop_type=weapons").
extends Node2D

const NPCDB := preload("res://scripts/data/npcs.gd")
const AlchemyDB := preload("res://scripts/data/alchemy.gd")
const TinkerDB := preload("res://scripts/data/tinkering.gd")
const FactionDB := preload("res://scripts/data/factions.gd")
const QuestDB := preload("res://scripts/data/quests.gd")
const NPC_FACTION_MAP := {
	"keepers": FactionDB.Faction.KEEPERS_GUILD,
	"harbor": FactionDB.Faction.HARBOR_COMPACT,
	"chapel": FactionDB.Faction.GREY_CHAPEL,
	"unlit": FactionDB.Faction.THE_UNLIT,
}

const CharDB := preload("res://scripts/data/classes.gd")
const TILE_SIZE := 16
const TOWN_ATLAS_PATH := "res://assets/sprites/tiles/lanternhouse_town.png"
const TOWN_GROUND_PATH := "res://assets/sprites/tiles/lanternhouse_town_readable.png"
const QUIET_TILES_PATH := "res://assets/sprites/vendor/quiet_village/Tiles.png"
const QUIET_BUILDINGS_PATH := "res://assets/sprites/vendor/quiet_village/Buildings.png"
const QUIET_PROPS_PATH := "res://assets/sprites/vendor/quiet_village/Props.png"
const GROUND_TILE_RECTS := {
	".": Rect2i(Vector2i(0, 0), Vector2i(TILE_SIZE, TILE_SIZE)),
	"=": Rect2i(Vector2i(16, 0), Vector2i(TILE_SIZE, TILE_SIZE)),
	"@": Rect2i(Vector2i(32, 0), Vector2i(TILE_SIZE, TILE_SIZE)),
	",": Rect2i(Vector2i(48, 0), Vector2i(TILE_SIZE, TILE_SIZE)),
	"H": Rect2i(Vector2i(0, 0), Vector2i(TILE_SIZE, TILE_SIZE)),
}
const TILE_RECTS := {
	"#": Rect2i(Vector2i(0, 0), Vector2i(TILE_SIZE, TILE_SIZE)),
	".": Rect2i(Vector2i(16, 0), Vector2i(TILE_SIZE, TILE_SIZE)),
	"@": Rect2i(Vector2i(32, 0), Vector2i(TILE_SIZE, TILE_SIZE)),
	"W": Rect2i(Vector2i(48, 0), Vector2i(TILE_SIZE, TILE_SIZE)),
	"A": Rect2i(Vector2i(64, 0), Vector2i(TILE_SIZE, TILE_SIZE)),
	"I": Rect2i(Vector2i(80, 0), Vector2i(TILE_SIZE, TILE_SIZE)),
	"S": Rect2i(Vector2i(96, 0), Vector2i(TILE_SIZE, TILE_SIZE)),
	"E": Rect2i(Vector2i(112, 0), Vector2i(TILE_SIZE, TILE_SIZE)),
	"R": Rect2i(Vector2i(112, 0), Vector2i(TILE_SIZE, TILE_SIZE)),
}
const NPC_RECTS := {
	"weapon_merchant": Rect2i(Vector2i(0, 32), Vector2i(TILE_SIZE, TILE_SIZE)),
	"armor_merchant": Rect2i(Vector2i(16, 32), Vector2i(TILE_SIZE, TILE_SIZE)),
	"innkeeper": Rect2i(Vector2i(32, 32), Vector2i(TILE_SIZE, TILE_SIZE)),
	"elder": Rect2i(Vector2i(48, 32), Vector2i(TILE_SIZE, TILE_SIZE)),
	"tavern_keeper": Rect2i(Vector2i(64, 32), Vector2i(TILE_SIZE, TILE_SIZE)),
	"healer": Rect2i(Vector2i(80, 32), Vector2i(TILE_SIZE, TILE_SIZE)),
	"tinkerer": Rect2i(Vector2i(96, 32), Vector2i(TILE_SIZE, TILE_SIZE)),
	"realtor": Rect2i(Vector2i(112, 32), Vector2i(TILE_SIZE, TILE_SIZE)),
}
const PLAYER_RECT := Rect2i(Vector2i(0, 48), Vector2i(TILE_SIZE, TILE_SIZE))

const MAP := [
	",,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,",
	",,......,,,,,.......,,,,,,,......,,,,,,,",
	",,.HHHHHH,,,,HHHHHHH,,,,,,,HHHHHHH,,,,,",
	",,.HHHHHH====HHHHHHH=======HHHHHHH,,,,,",
	",,.HHHHHH,,,,HHHHHHH,,,,,,,,,,,,,,,,,,,",
	",,.HHHHHH,,,,,,,==,,,,,,,,,,,,,,,,,,,,,",
	",,,,,,,,,,,,,,,====,,,,,,,,,,,,,,,,,,,,",
	",,,==============================,,,,,,",
	",,,==,,,,,,,,,,====,,,,,,,,,,==,,,,,,,,",
	",,,==,,,,,,,,@@@@@@@@,,,,,,,,==,,,,,,,,",
	",,,HHHHHH,,,,@@@@@@@@,,,,,,HHHHHH,,,,,,",
	",,,HHHHHH====@@@@@@@@======HHHHHH,,,,,,",
	",,,HHHHHH,,,,@@@@@@@@,,,,,,HHHHHH,,,,,,",
	",,,,,,,,,,,,,,,====,,,,,,,,,,,,,,,,,,,,",
	",,,,,,,,,,,,,,,====,,,,,,,,,,,,,,,,,,,,",
	",,,,,,,HHHHHH,,====,,,,,,,,,HHHHHH,,,,,",
	",,,,,,,HHHHHH,,====,,,,,,,,,HHHHHH,,,,,",
	",,,,,,,HHHHHH==========,,,,,HHHHHH,,,,,",
	",,,,,,,,,,,,,,,====,,,,,,,,,,,,,,,,,,,,",
	",,,,,,,,,,,,,,,====,,,,,,,,,,,,,,,,,,,,",
	",,,,,,,,,,,,,,,====,,,,,,,,,,,,,,,,,,,,",
	",,,,,,,,,,,,,,,,==,,,,,,,,,,,,,,,,,,,,,",
	",,,,,,,,,,,,,,,,==,,,,,,,,,,,,,,,,,,,,,",
	",,,,,,,,,,,,,,,,==,,,,,,,,,,,,,,,,,,,,,",
]

const COLORS := {
	"#": Color("8b7355"), ".": Color("c49b56"), "@": Color("a08050"),
	"W": Color("27ae60"), "A": Color("27ae60"), "I": Color("3498db"),
	"S": Color("9b59b6"), "E": Color("e67e22"), "R": Color("e67e22"),
}
const BLOCKED := {"#": true, "H": true}
const NPC_IDS := ["weapon_merchant", "armor_merchant", "innkeeper", "elder", "tavern_keeper", "healer", "tinkerer", "realtor"]
var npc_positions: Dictionary = {}
var _npc_markers: Dictionary = {}  # npc_id -> Sprite2D

var pos: Vector2i = Vector2i(20, 22)
var facing: Vector2i = Vector2i.DOWN
var walking: bool = false
var walk_timer: float = 0.0
var talking_to: String = ""
var recruit_mode: bool = false
var roster_idx: int = 0
var exchange_mode: bool = false
var exchange_idx: int = 0
var _wander_timer: float = 0.0
var _npc_wander_pos: Dictionary = {}
var _town_atlas: Texture2D
var _town_ground: Texture2D
var _quiet_buildings: Texture2D
var _quiet_props: Texture2D
const WANDER_INTERVAL := 2.5
const WANDER_RADIUS := 3

@onready var map_layer: Node2D = $MapLayer
@onready var building_layer: Node2D = $BuildingLayer
@onready var prop_layer: Node2D = $PropLayer
@onready var camera: Camera2D = $Camera2D
@onready var player_sprite: Node2D = $PlayerSprite
@onready var dialog: RichTextLabel = $UILayer/Dialog

func _ready() -> void:
	_load_town_atlas()
	_load_quiet_village_assets()
	_draw_map()
	_draw_buildings()
	_draw_props()
	_build_npc_positions()
	_draw_npcs()
	_configure_camera()
	GameData.visited_town = true
	# Auto-accept and complete Visit Brindlewick quest
	if not GameData.active_quests.has("visit_brindlewick"):
		GameData.accept_quest("visit_brindlewick")
	if GameData.is_quest_active("visit_brindlewick") and not GameData.is_quest_complete("visit_brindlewick"):
		GameData.complete_quest("visit_brindlewick")
		var quest: Dictionary = QuestDB.get_quest("visit_brindlewick")
		var reward: int = quest.get("reward_gold", 0)
		var xp: int = quest.get("reward_xp", 0)
		GameData.add_copper(reward * 100)
		for m in GameData.party:
			if m["alive"]:
				m["xp"] += xp
	_update_player()

func _load_town_atlas() -> void:
	if not FileAccess.file_exists(TOWN_ATLAS_PATH):
		push_warning("Town atlas missing: %s" % TOWN_ATLAS_PATH)
		return
	var image := Image.new()
	if image.load(TOWN_ATLAS_PATH) != OK:
		push_warning("Town atlas could not be loaded: %s" % TOWN_ATLAS_PATH)
		return
	_town_atlas = ImageTexture.create_from_image(image)

func _load_quiet_village_assets() -> void:
	_town_ground = _load_png_texture(TOWN_GROUND_PATH)
	_quiet_buildings = _load_png_texture(QUIET_BUILDINGS_PATH)
	_quiet_props = _load_png_texture(QUIET_PROPS_PATH)

func _load_png_texture(path: String) -> Texture2D:
	if not FileAccess.file_exists(path):
		push_warning("Image missing: %s" % path)
		return null
	var image := Image.new()
	if image.load(path) != OK:
		push_warning("Image could not be loaded: %s" % path)
		return null
	return ImageTexture.create_from_image(image)

func _draw_map() -> void:
	for y in range(MAP.size()):
		for x in range(MAP[y].length()):
			var tile: String = MAP[y].substr(x, 1)
			if _town_ground and GROUND_TILE_RECTS.has(tile):
				var sprite := Sprite2D.new()
				sprite.texture = _town_ground
				sprite.region_enabled = true
				sprite.region_rect = GROUND_TILE_RECTS.get(tile, GROUND_TILE_RECTS["."])
				sprite.centered = false
				sprite.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
				map_layer.add_child(sprite)
			elif _town_atlas:
				var sprite := Sprite2D.new()
				sprite.texture = _town_atlas
				sprite.region_enabled = true
				sprite.region_rect = TILE_RECTS.get(tile, TILE_RECTS["."])
				sprite.centered = false
				sprite.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
				map_layer.add_child(sprite)
			else:
				var rect := ColorRect.new()
				rect.color = COLORS.get(tile, Color.MAGENTA)
				rect.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
				rect.size = Vector2(TILE_SIZE, TILE_SIZE)
				map_layer.add_child(rect)

func _draw_buildings() -> void:
	if not _quiet_buildings:
		return
	_add_building(Vector2i(3, 2), Rect2i(Vector2i(14, 16), Vector2i(118, 72)), 0.55)
	_add_building(Vector2i(15, 2), Rect2i(Vector2i(219, 16), Vector2i(172, 72)), 0.48)
	_add_building(Vector2i(28, 2), Rect2i(Vector2i(354, 466), Vector2i(129, 72)), 0.52)
	_add_building(Vector2i(3, 10), Rect2i(Vector2i(15, 573), Vector2i(117, 72)), 0.55)
	_add_building(Vector2i(26, 10), Rect2i(Vector2i(610, 2), Vector2i(193, 83)), 0.42)
	_add_building(Vector2i(7, 15), Rect2i(Vector2i(16, 681), Vector2i(116, 72)), 0.55)
	_add_building(Vector2i(30, 15), Rect2i(Vector2i(791, 609), Vector2i(84, 92)), 0.55)

func _add_building(grid: Vector2i, region: Rect2i, scale_amount: float) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = _quiet_buildings
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.centered = false
	sprite.position = Vector2(grid * TILE_SIZE)
	sprite.scale = Vector2(scale_amount, scale_amount)
	building_layer.add_child(sprite)

func _draw_props() -> void:
	if not _quiet_props:
		return
	_add_prop(Vector2i(21, 12), Rect2i(Vector2i(100, 39), Vector2i(36, 36)), 0.55)
	_add_prop(Vector2i(13, 8), Rect2i(Vector2i(65, 24), Vector2i(28, 17)), 0.7)
	_add_prop(Vector2i(23, 8), Rect2i(Vector2i(18, 41), Vector2i(26, 27)), 0.6)
	_add_prop(Vector2i(8, 20), Rect2i(Vector2i(0, 108), Vector2i(38, 10)), 0.8)

func _add_prop(grid: Vector2i, region: Rect2i, scale_amount: float) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = _quiet_props
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.centered = false
	sprite.position = Vector2(grid * TILE_SIZE)
	sprite.scale = Vector2(scale_amount, scale_amount)
	prop_layer.add_child(sprite)


func _build_npc_positions() -> void:
	npc_positions.clear()
	var phase: String = GameData.get_day_phase()
	for npc_id: String in NPC_IDS:
		var home: Vector2i = NPCDB.get_npc_position(npc_id, phase)
		if home.x >= 0:
			npc_positions[home] = npc_id
			_npc_wander_pos[npc_id] = home

func _draw_npcs() -> void:
	for npc_id: String in NPC_IDS:
		var marker := Sprite2D.new()
		if _town_atlas:
			marker.texture = _town_atlas
			marker.region_enabled = true
			marker.region_rect = NPC_RECTS.get(npc_id, NPC_RECTS["tavern_keeper"])
		else:
			marker.texture = _make_solid_texture(Color.WHITE)
			marker.modulate = NPCDB.get_npc_color(npc_id)
		var p: Vector2i = _npc_wander_pos.get(npc_id, Vector2i(-1, -1))
		if p.x >= 0:
			marker.position = Vector2(p * TILE_SIZE) + Vector2(TILE_SIZE / 2, TILE_SIZE / 2)
			marker.visible = true
		else:
			marker.visible = false
		map_layer.add_child(marker)
		_npc_markers[npc_id] = marker

func _make_solid_texture(color: Color) -> Texture2D:
	var image := Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)

func _find_npc_pos(npc_id: String) -> Vector2i:
	for p: Vector2i in npc_positions:
		if npc_positions[p] == npc_id:
			return p
	return Vector2i(-1, -1)

func _refresh_npcs() -> void:
	var old_phase: String = npc_positions.get("_phase", "")
	var phase: String = GameData.get_day_phase()
	if phase == old_phase:
		return
	for npc_id: String in NPC_IDS:
		var home: Vector2i = NPCDB.get_npc_position(npc_id, phase)
		_npc_wander_pos[npc_id] = home
	_build_npc_positions()
	npc_positions["_phase"] = phase
	for npc_id: String in NPC_IDS:
		if _npc_markers.has(npc_id):
			var marker: Sprite2D = _npc_markers[npc_id]
			var p: Vector2i = _npc_wander_pos.get(npc_id, Vector2i(-1, -1))
			if p.x >= 0:
				marker.position = Vector2(p * TILE_SIZE) + Vector2(TILE_SIZE / 2, TILE_SIZE / 2)
				marker.visible = true
			else:
				marker.visible = false


func _process(delta: float) -> void:
	_wander_timer += delta
	if _wander_timer >= WANDER_INTERVAL:
		_wander_timer -= WANDER_INTERVAL
		_wander_one_npc()

func _wander_one_npc() -> void:
	var phase: String = GameData.get_day_phase()
	var wander_chance := 0.4 if phase == "night" else 0.75
	if randf() > wander_chance:
		return
	var npcs: Array = _npc_wander_pos.keys()
	if npcs.is_empty():
		return
	var npc_id: String = npcs[randi() % npcs.size()]
	var home: Vector2i = NPCDB.get_npc_position(npc_id, phase)
	if home.x < 0:
		return
	var current: Vector2i = _npc_wander_pos.get(npc_id, home)
	var dirs := [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	dirs.shuffle()
	for d: Vector2i in dirs:
		var next := current + d
		if next.x < 0 or next.x >= MAP[0].length() or next.y < 0 or next.y >= MAP.size():
			continue
		if BLOCKED.has(MAP[next.y].substr(next.x, 1)):
			continue
		var max_radius := WANDER_RADIUS
		if GameData.beacon_lit:
			max_radius += 1
		if phase == "night":
			max_radius -= 1
		if abs(next.x - home.x) + abs(next.y - home.y) > max_radius:
			continue
		if next == pos:
			continue
		var occupied := false
		for other_id: String in _npc_wander_pos:
			if other_id != npc_id and _npc_wander_pos[other_id] == next:
				occupied = true
				break
		if occupied:
			continue
		_npc_wander_pos[npc_id] = next
		for p: Vector2i in npc_positions.keys():
			if npc_positions[p] == npc_id:
				npc_positions.erase(p)
				break
		npc_positions[next] = npc_id
		if _npc_markers.has(npc_id):
			_npc_markers[npc_id].position = Vector2(next * TILE_SIZE) + Vector2(TILE_SIZE / 2, TILE_SIZE / 2)
		break

func _update_player() -> void:
	_refresh_npcs()
	_apply_day_tint()
	player_sprite.position = Vector2(pos * TILE_SIZE) + Vector2(TILE_SIZE / 2, TILE_SIZE / 2)
	_update_camera()
	if _town_atlas and not player_sprite.has_node("Sprite"):
		var sprite := Sprite2D.new()
		sprite.name = "Sprite"
		sprite.texture = _town_atlas
		sprite.region_enabled = true
		sprite.region_rect = PLAYER_RECT
		player_sprite.add_child(sprite)
		if player_sprite.has_node("Body"):
			player_sprite.get_node("Body").visible = false

func _configure_camera() -> void:
	if not camera:
		return
	camera.anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	camera.limit_enabled = true
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = MAP[0].length() * TILE_SIZE
	camera.limit_bottom = MAP.size() * TILE_SIZE
	_update_camera()

func _update_camera() -> void:
	if camera:
		camera.global_position = player_sprite.global_position

func _apply_day_tint() -> void:
	var phase: String = GameData.get_day_phase()
	var tint: Color
	match phase:
		"night": tint = Color(0.6, 0.6, 0.75, 1.0)
		"dawn": tint = Color(1.0, 0.9, 0.75, 1.0)
		"dusk": tint = Color(1.0, 0.8, 0.65, 1.0)
		_: tint = Color.WHITE
	if GameData.beacon_lit:
		tint = tint.lerp(Color.WHITE, 0.15)
	map_layer.modulate = tint


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if walking:
		return

	# Dialogue input takes priority
	if talking_to != "":
		_handle_dialog_input(event.keycode)
		return

	# Roster browsing input
	if recruit_mode:
		_handle_roster_input(event.keycode)
		return

	# Cooking input
	if cooking_mode:
		_handle_cook_input(event.keycode)
		return

	# Alchemy crafting input
	if alchemy_mode:
		_handle_alchemy_input(event.keycode)
		return

	# Tinkering crafting input
	if tinkering_mode:
		_handle_tinker_input(event.keycode)
		return

	# Home browsing input
	if home_browse_mode:
		_handle_home_browse_input(event.keycode)
		return

	# Exchange browsing input
	if exchange_mode:
		_handle_exchange_input(event.keycode)
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

func _handle_dialog_input(keycode: int) -> void:
	# Lore display — any key returns to topic menu
	if lore_text != "":
		lore_text = ""
		_show_topics()
		return
	# Topic selection mode
	if topic_mode:
		match keycode:
			KEY_1, KEY_2, KEY_3, KEY_4:
				var topic_idx := keycode - KEY_1
				_select_topic(topic_idx)
			KEY_ESCAPE:
				topic_mode = false
				topic_npc = ""
				talking_to = ""
				_update_hud()
		return
	match keycode:
		KEY_1, KEY_ENTER, KEY_SPACE:
			_confirm_dialog()
		KEY_2:
			if talking_to == "realtor_owned":
				_show_home_details()
			elif talking_to == "tavern_keeper":
				talking_to = ""
				exchange_mode = true
				exchange_idx = 0
				_show_exchange()
		KEY_ESCAPE:
			if home_browse_mode:
				home_browse_mode = false
			talking_to = ""
			_update_hud()

func _confirm_dialog() -> void:
	match talking_to:
		"weapon_merchant":
			if GameData.boss_defeated:
				GameData.set_meta("visited_keepers_town", true)
				if GameData.get_meta("visited_compact_dock", false):
					GameData.set_meta("resolved_oil_dispute", true)
			GameData.set_meta("shop_type", "weapons")
			SceneTransition.change_scene("res://scenes/shop/shop.tscn")
		"armor_merchant":
			GameData.set_meta("shop_type", "armor")
			SceneTransition.change_scene("res://scenes/shop/shop.tscn")
		"elder_quest":
			_accept_next_quest()
		"innkeeper_cook":
			talking_to = ""
			cooking_mode = true
			cook_idx = 0
			_show_cook()
		"realtor_browse":
			home_browse_mode = true
			home_idx = 0
			talking_to = "home_browse"
			_show_home_browse()
		"realtor_owned":
			home_browse_mode = true
			home_idx = 0
			talking_to = "upgrade_browse"
			_show_upgrade_browse()
		"tavern_keeper":
			talking_to = ""
			recruit_mode = true
			roster_idx = 0
			_show_roster()

func _handle_roster_input(keycode: int) -> void:
	match keycode:
		KEY_UP:
			roster_idx = max(0, roster_idx - 1)
			_show_roster()
		KEY_DOWN:
			var available := _get_available_roster()
			roster_idx = min(available.size() - 1, roster_idx + 1)
			_show_roster()
		KEY_1, KEY_ENTER, KEY_SPACE:
			_try_recruit()
		KEY_ESCAPE:
			recruit_mode = false
			_update_hud()

func _try_move(dir: Vector2i) -> void:
	facing = dir
	if _is_exit_step(dir):
		_exit_to_overworld()
		return
	var next := pos + dir
	if _is_blocked(next):
		return
	pos = next
	_update_player()
	_check_exit()

func _is_blocked(grid: Vector2i) -> bool:
	if grid.x < 0 or grid.x >= MAP[0].length() or grid.y < 0 or grid.y >= MAP.size():
		return true
	return BLOCKED.has(MAP[grid.y].substr(grid.x, 1))

func _check_exit() -> void:
	if pos.y >= MAP.size() - 1:
		_exit_to_overworld()

func _is_exit_step(dir: Vector2i) -> bool:
	return dir == Vector2i.DOWN and pos.y >= MAP.size() - 2

func _exit_to_overworld() -> void:
	GameData.overworld_position = GameData.get_meta("overworld_return_position", GameData.overworld_position)
	GameData.overworld_facing = GameData.get_meta("overworld_return_facing", Vector2i.DOWN)
	SceneTransition.change_scene("res://scenes/overworld/overworld.tscn")

func _interact() -> void:
	var target := pos + facing
	var npc: String = npc_positions.get(target, "")
	talking_to = npc
	recruit_mode = false

	if npc == "":
		_say("Nothing here.")
		talking_to = ""
		return

	var context := "default"
	var npc_data: Dictionary = NPCDB.all_npcs().get(npc, {})
	var npc_faction: String = npc_data.get("faction", "none")
	var faction_enum: int = NPC_FACTION_MAP.get(npc_faction, -1)
	if faction_enum >= 0:
		var rep := GameData.get_faction_rep(faction_enum)
		if rep >= 20:
			context = "honored"
		elif rep <= -20:
			context = "distrusted"
	if GameData.boss_defeated:
		context = "boss_defeated"
	elif GameData.beacon_lit and context == "default":
		context = "beacon_lit"
	elif npc in ["weapon_merchant", "armor_merchant"] and GameData.gold < 100 and context == "default":
		context = "low_gold"
	var line: String = NPCDB.get_dialogue(npc, context)
	var npc_name: String = NPCDB.get_npc_name(npc)

	# Topic-based dialogue for NPCs with topics defined
	var topics: Array = NPCDB.get_topics(npc)
	if not topics.is_empty():
		topic_mode = true
		topic_npc = npc
		talking_to = npc
		_show_topics()
		return

	match npc:
		"weapon_merchant":
			_say("[color=#c0392b]%s[/color]: %s\n\n[1] Browse weapons  [Esc] Back" % [npc_name, line])
		"armor_merchant":
			_say("[color=#2980b9]%s[/color]: %s\n\n[1] Browse armor  [Esc] Back" % [npc_name, line])
		"innkeeper":
			GameData.full_heal()
			_say("[color=#27ae60]%s[/color]: %s\n\n[Restored all HP and magic!]\n\n[1] Cook fish  [Esc] Back" % [npc_name, line])
			talking_to = "innkeeper_cook"
		"tavern_keeper":
			_say("[color=#8b6914]%s[/color]: %s\n\n[1] Recruit companions  [2] Exchange currency  [Esc] Back" % [npc_name, line])
		"realtor":
			_show_realtor(npc_name, line)
		"healer":
			for m: Dictionary in GameData.party:
				for lvl: int in m["magic_levels"]:
					m["magic_levels"][lvl]["charges"] = m["magic_levels"][lvl]["max"]
			_say("[color=#ecf0f1]%s[/color]: %s\n\n[Restored all magic charges!]" % [npc_name, line])
			talking_to = ""
		_:
			_show_elder_dialogue(npc_name, line)
			talking_to = ""

var home_browse_mode: bool = false
var home_idx: int = 0
var cooking_mode: bool = false
var cook_idx: int = 0
var alchemy_mode: bool = false
var alchemy_idx: int = 0
var tinkering_mode: bool = false
var tinker_idx: int = 0
var topic_mode: bool = false
var topic_npc: String = ""
var lore_text: String = ""

const HOME_CATALOG := [
	{"id": "cottage", "name": "Seaside Cottage", "desc": "A small cottage on the shore. Cozy and affordable.", "base_price": 2000},
	{"id": "townhouse", "name": "Market Townhouse", "desc": "A townhouse near the market square. Room for upgrades.", "base_price": 8000},
	{"id": "manor", "name": "Cliffside Manor", "desc": "A grand manor overlooking the sound. Prestigious.", "base_price": 25000},
	{"id": "lighthouse_keeper", "name": "Keeper's Quarters", "desc": "The old keeper's quarters attached to the lighthouse.", "base_price": 5000},
]

const HOME_UPGRADES := [
	{"id": "bed", "name": "Quality Bed", "desc": "Full heal when resting at home", "price": 500},
	{"id": "chest", "name": "Storage Chest", "desc": "Store up to 10 extra items", "price": 300},
	{"id": "kitchen", "name": "Kitchen", "desc": "Cook fish into meals for party buffs", "price": 800},
	{"id": "garden", "name": "Herb Garden", "desc": "Grow herbs for alchemy", "price": 600},
	{"id": "guest_room", "name": "Guest Room", "desc": "Housing party members improves loyalty", "price": 1200},
	{"id": "beacon_map", "name": "Beacon Map", "desc": "Wall map showing all beacon tower states", "price": 200},
	{"id": "workbench", "name": "Workbench", "desc": "Craft tools and repair equipment", "price": 700},
]

func _show_topics() -> void:
	var npc_name: String = NPCDB.get_npc_name(topic_npc)
	var topics: Array = NPCDB.get_topics(topic_npc)
	var context := "default"
	var npc_data: Dictionary = NPCDB.all_npcs().get(topic_npc, {})
	var npc_faction: String = npc_data.get("faction", "none")
	var faction_enum: int = NPC_FACTION_MAP.get(npc_faction, -1)
	if faction_enum >= 0:
		var rep := GameData.get_faction_rep(faction_enum)
		if rep >= 20:
			context = "honored"
		elif rep <= -20:
			context = "distrusted"
	if GameData.boss_defeated:
		context = "boss_defeated"
	elif GameData.beacon_lit and context == "default":
		context = "beacon_lit"
	var line: String = NPCDB.get_dialogue(topic_npc, context)
	var color_map := {
		"weapon_merchant": "#c0392b", "armor_merchant": "#2980b9",
		"innkeeper": "#27ae60", "tavern_keeper": "#8b6914",
		"realtor": "#e67e22", "healer": "#ecf0f1",
		"elder": "#9b59b6", "tinkerer": "#7f8c8d",
	}
	var npc_color: String = color_map.get(topic_npc, "white")
	var msg := "[color=%s]%s[/color]: %s\n" % [npc_color, npc_name, line]
	msg += "\n"
	for i in range(topics.size()):
		var t: Dictionary = topics[i]
		msg += "[%d] %s\n" % [i + 1, t["label"]]
	msg += "\n[Esc] Back"
	_say(msg)

func _select_topic(idx: int) -> void:
	var topics: Array = NPCDB.get_topics(topic_npc)
	if idx >= topics.size():
		return
	var topic: Dictionary = topics[idx]
	var key: String = topic["key"]
	var npc_name: String = NPCDB.get_npc_name(topic_npc)
	match key:
		"shop":
			topic_mode = false
			if topic_npc == "weapon_merchant":
				GameData.set_meta("shop_type", "weapons")
			else:
				GameData.set_meta("shop_type", "armor")
			SceneTransition.change_scene("res://scenes/shop/shop.tscn")
		"heal":
			topic_mode = false
			GameData.full_heal()
			var color_map := {"innkeeper": "#27ae60", "healer": "#ecf0f1"}
			var npc_color: String = color_map.get(topic_npc, "white")
			_say("[color=%s]%s[/color]: %s\n\n[color=green][Restored all HP and magic!][/color]\n\n[Any key] Continue" % [npc_color, npc_name, NPCDB.get_dialogue(topic_npc, "default")])
			talking_to = ""
		"item_shop":
			topic_mode = false
			GameData.set_meta("shop_type", "items")
			SceneTransition.change_scene("res://scenes/shop/shop.tscn")
		"cook":
			topic_mode = false
			talking_to = ""
			cooking_mode = true
			cook_idx = 0
			_show_cook()
		"recruit":
			topic_mode = false
			talking_to = ""
			recruit_mode = true
			roster_idx = 0
			_show_roster()
		"exchange":
			topic_mode = false
			talking_to = ""
			exchange_mode = true
			exchange_idx = 0
			_show_exchange()
		"realtor":
			topic_mode = false
			talking_to = ""
			_show_realtor(npc_name, NPCDB.get_dialogue(topic_npc, "default"))
		"tinker":
			topic_mode = false
			talking_to = ""
			tinkering_mode = true
			tinker_idx = 0
			_show_tinkering()
		"quest":
			topic_mode = false
			talking_to = ""
			_show_elder_dialogue(npc_name, NPCDB.get_dialogue(topic_npc, "default"))
		_:
			# Lore topic — show flavor text
			var lore: String = NPCDB.get_topic_lore(topic_npc, key)
			if lore != "":
				var color_map := {
					"weapon_merchant": "#c0392b", "armor_merchant": "#2980b9",
					"innkeeper": "#27ae60", "tavern_keeper": "#8b6914",
					"realtor": "#e67e22", "healer": "#ecf0f1",
					"elder": "#9b59b6", "tinkerer": "#7f8c8d",
				}
				var npc_color: String = color_map.get(topic_npc, "white")
				lore_text = lore
				_say("[color=%s]%s[/color]: %s\n\n[Any key] Back" % [npc_color, npc_name, lore])
			else:
				lore_text = ""
				_show_topics()

func _show_realtor(npc_name: String, line: String) -> void:
	var msg := "[color=#e67e22]%s[/color]: %s" % [npc_name, line]
	if GameData.owns_home():
		var home_id: String = GameData.owned_home
		var home_name: String = "your home"
		for h in HOME_CATALOG:
			if h["id"] == home_id:
				home_name = h["name"]
				break
		msg += "\n\nCurrent home: [color=cyan]%s[/color]" % home_name
		# Show upgrades
		var upgrade_lines: Array = []
		for u in HOME_UPGRADES:
			if GameData.has_upgrade(u["id"]):
				upgrade_lines.append("[color=green]✓ %s[/color]" % u["name"])
			else:
				upgrade_lines.append("[color=yellow]★ %s[/color] — %s (%dc)" % [u["name"], u["desc"], u["price"]])
		if not upgrade_lines.is_empty():
			msg += "\n\n" + "\n".join(upgrade_lines)
		var rent: int = GameData.get_property_rent()
		var tax: int = GameData.get_property_tax()
		msg += "\n\n[color=green]Rent income: +%dc[/color] / cycle" % rent
		if tax > 0:
			msg += "\n[color=#e67e22]Property tax: -%dc[/color] / cycle" % tax
		var mod: float = GameData.property_market_mod
		var cond := "Hot" if mod > 1.2 else ("Cold" if mod < 0.9 else "Stable")
		var cond_color := "green" if mod > 1.2 else ("red" if mod < 0.9 else "yellow")
		msg += "\n[color=%s]Market: %s (x%.1f)[/color]" % [cond_color, cond, mod]
		msg += "\n"
		msg += "\n\n[1] Browse upgrades  [2] View home  [Esc] Back"
		talking_to = "realtor_owned"
	else:
		msg += "\n\n[1] Browse properties  [Esc] Back"
		talking_to = "realtor_browse"
	_say(msg)

func _handle_realtor_input(keycode: int) -> void:
	match keycode:
		KEY_1:
			if talking_to == "realtor_browse":
				talking_to = ""
				home_browse_mode = true
				home_idx = 0
				_show_home_browse()
			elif talking_to == "realtor_owned":
				talking_to = ""
				home_browse_mode = true
				home_idx = 0
				_show_upgrade_browse()
			else:
				talking_to = ""
				_update_hud()
		KEY_2:
			if talking_to == "realtor_owned":
				_show_home_details()
		KEY_ESCAPE:
			talking_to = ""
			home_browse_mode = false
			_update_hud()

func _show_home_browse() -> void:
	var lines: Array = []
	lines.append("[b]Properties For Sale[/b]    %s" % GameData.format_money_short())
	lines.append("")
	for i in range(HOME_CATALOG.size()):
		var h: Dictionary = HOME_CATALOG[i]
		var price: int = GameData.get_home_price(h["id"])
		var marker := "▶" if i == home_idx else " "
		var can_afford := GameData.gold >= price
		var color_start := "" if can_afford else "[color=#666]"
		var color_end := "" if can_afford else "[/color]"
		var price_text := "%dg %ds" % [price / 10000, (price % 10000) / 100] if price >= 10000 else ("%ds %dc" % [price / 100, price % 100] if price >= 100 else "%dc" % price)
		lines.append("%s%s %-20s %s%s" % [color_start, marker, h["name"], price_text, color_end])
		lines.append("    %s%s" % [color_start, h["desc"], color_end])
	lines.append("")
	lines.append("[1]/Enter to buy, arrows to browse, [Esc] back")
	_say("\n".join(lines))

func _show_upgrade_browse() -> void:
	var lines: Array = []
	lines.append("[b]Home Upgrades[/b]    %s" % GameData.format_money_short())
	lines.append("")
	for i in range(HOME_UPGRADES.size()):
		var u: Dictionary = HOME_UPGRADES[i]
		var marker := "▶" if i == home_idx else " "
		if GameData.has_upgrade(u["id"]):
			lines.append("[color=green]%s ✓ %s — Already installed[/color]" % [marker, u["name"]])
		else:
			var can_afford: bool = GameData.gold >= u["price"]
			var color_start := "" if can_afford else "[color=#666]"
			var color_end := "" if can_afford else "[/color]"
			lines.append("%s%s ★ %-18s %dc  %s%s" % [color_start, marker, u["name"], u["price"], u["desc"], color_end])
	lines.append("")
	lines.append("[1]/Enter to buy, arrows to browse, [Esc] back")
	_say("\n".join(lines))

func _handle_home_browse_input(keycode: int) -> void:
	match keycode:
		KEY_UP:
			home_idx = max(0, home_idx - 1)
			if talking_to == "home_browse":
				_show_home_browse()
			elif talking_to == "upgrade_browse":
				_show_upgrade_browse()
		KEY_DOWN:
			var max_idx := HOME_CATALOG.size() - 1 if talking_to == "home_browse" else HOME_UPGRADES.size() - 1
			home_idx = min(max_idx, home_idx + 1)
			if talking_to == "home_browse":
				_show_home_browse()
			elif talking_to == "upgrade_browse":
				_show_upgrade_browse()
		KEY_1, KEY_ENTER, KEY_SPACE:
			if talking_to == "home_browse":
				_try_buy_home()
			elif talking_to == "upgrade_browse":
				_try_buy_upgrade()
		KEY_ESCAPE:
			home_browse_mode = false
			talking_to = ""
			_update_hud()

func _try_buy_home() -> void:
	if home_idx >= HOME_CATALOG.size(): return
	var h: Dictionary = HOME_CATALOG[home_idx]
	if GameData.owns_home():
		_say("You already own a home!")
		home_browse_mode = false
		talking_to = ""
		return
	if GameData.buy_home(h["id"]):
		_say("[color=green]Congratulations! You now own %s![/color]" % h["name"])
		home_browse_mode = false
		talking_to = ""
	else:
		_say("You can't afford %s yet. Need %dc more." % [h["name"], GameData.get_home_price(h["id"]) - GameData.gold])

func _try_buy_upgrade() -> void:
	if home_idx >= HOME_UPGRADES.size(): return
	var u: Dictionary = HOME_UPGRADES[home_idx]
	if GameData.has_upgrade(u["id"]):
		_say("%s is already installed." % u["name"])
		return
	if GameData.buy_upgrade(u["id"], u["price"]):
		_say("[color=green]%s installed![/color] %s" % [u["name"], u["desc"]])
		_show_upgrade_browse()
	else:
		_say("Not enough copper. Need %dc." % u["price"])

func _show_home_details() -> void:
	var lines: Array = []
	var home_id: String = GameData.owned_home
	var home_name: String = home_id
	for h in HOME_CATALOG:
		if h["id"] == home_id:
			home_name = h["name"]
	lines.append("[b]%s[/b]" % home_name)
	lines.append("")
	for u in HOME_UPGRADES:
		if GameData.has_upgrade(u["id"]):
			lines.append("[color=green]✓ %s[/color] — %s" % [u["name"], u["desc"]])
		else:
			lines.append("[color=#666]✗ %s[/color]" % u["name"])
	lines.append("")
	lines.append("[Esc] Back")
	_say("\n".join(lines))
	talking_to = "realtor_details"



# ── Alchemy crafting ──────────────────────────────────────────────────────
func _show_alchemy() -> void:
	var lines: Array = []
	lines.append("[b]Alchemy Workshop[/b]    %s" % GameData.format_money_short())
	var skill: int = GameData.skill_uses.get("alchemy", 0)
	var level := _alchemy_level(skill)
	var tier: String = GameData.get_skill_tier("alchemy")
	lines.append("Skill: %s (%d crafts)" % [tier, skill])
	lines.append("")
	# Show herb inventory
	var herb_lines: Array = []
	for herb_id: String in GameData.herb_bag:
		var count: int = GameData.herb_bag[herb_id]
		if count > 0:
			herb_lines.append("%s x%d" % [herb_id.replace("_", " ").capitalize(), count])
	if not herb_lines.is_empty():
		lines.append("Herbs: %s" % ", ".join(herb_lines))
	else:
		lines.append("[color=#666]No herbs. Gather from overworld tiles![/color]")
	lines.append("")
	var recipes := AlchemyDB.available_recipes(level)
	if recipes.is_empty():
		lines.append("No recipes available. Gather herbs to unlock basic recipes.")
	else:
		for i in range(recipes.size()):
			var r: Dictionary = recipes[i]
			var marker := "▶" if i == alchemy_idx else " "
			var can_craft := _can_craft_alchemy(r)
			var color_start := "" if can_craft else "[color=#666]"
			var color_end := "" if can_craft else "[/color]"
			var herb_cost := _alchemy_cost_text(r)
			lines.append("%s%s %-18s %s (%s)%s" % [color_start, marker, r["name"], r["desc"], herb_cost, color_end])
	lines.append("")
	lines.append("[1]/Enter to craft, arrows to browse, [Esc] back")
	_say("\n".join(lines))

func _alchemy_level(uses: int) -> int:
	if uses >= 60: return 3
	if uses >= 30: return 2
	if uses >= 10: return 1
	return 0

func _can_craft_alchemy(recipe: Dictionary) -> bool:
	for herb_id: int in recipe["herbs"]:
		var herb_info: Dictionary = AlchemyDB.HERB_INFO[herb_id]
		var have: int = GameData.get_herb_count(herb_info["id"])
		if have < recipe["herbs"][herb_id]:
			return false
	return true

func _alchemy_cost_text(recipe: Dictionary) -> String:
	var parts: Array = []
	for herb_id: int in recipe["herbs"]:
		var herb_info: Dictionary = AlchemyDB.HERB_INFO[herb_id]
		parts.append("%s x%d" % [herb_info["name"], recipe["herbs"][herb_id]])
	return ", ".join(parts)

func _handle_alchemy_input(keycode: int) -> void:
	match keycode:
		KEY_UP:
			alchemy_idx = max(0, alchemy_idx - 1)
			_show_alchemy()
		KEY_DOWN:
			var skill: int = GameData.skill_uses.get("alchemy", 0)
			var level := _alchemy_level(skill)
			var recipes := AlchemyDB.available_recipes(level)
			alchemy_idx = min(max(recipes.size() - 1, 0), alchemy_idx + 1)
			_show_alchemy()
		KEY_1, KEY_ENTER, KEY_SPACE:
			_try_craft_alchemy()
		KEY_ESCAPE:
			alchemy_mode = false
			_update_hud()

func _try_craft_alchemy() -> void:
	var skill: int = GameData.skill_uses.get("alchemy", 0)
	var level := _alchemy_level(skill)
	var recipes := AlchemyDB.available_recipes(level)
	if recipes.is_empty() or alchemy_idx >= recipes.size():
		alchemy_mode = false
		return
	var recipe: Dictionary = recipes[alchemy_idx]
	if not _can_craft_alchemy(recipe):
		_say("Not enough herbs for %s." % recipe["name"])
		return
	# Consume herbs
	for herb_id: int in recipe["herbs"]:
		var herb_info: Dictionary = AlchemyDB.HERB_INFO[herb_id]
		GameData.remove_herb(herb_info["id"], recipe["herbs"][herb_id])
	# Add crafted item
	for _i in range(recipe.get("output_count", 1)):
		GameData.add_crafted_item({
			"id": recipe["id"],
			"name": recipe["name"],
			"effect": recipe["effect"],
			"type": "potion",
			"value": 0,
		})
	GameData.track_skill_use("alchemy", 1)
	# Apply immediate effect for healing/ether potions
	var effect: Dictionary = recipe["effect"]
	match effect["type"]:
		"heal":
			var hp: int = effect["hp"]
			var healed: Array = []
			for m: Dictionary in GameData.party:
				if m["alive"]:
					var actual := mini(hp, m["max_hp"] - m["hp"])
					m["hp"] += actual
					healed.append("%s +%d" % [m["name"], actual])
			_say("[color=green]Crafted %s![/color]\n%s" % [recipe["name"], ", ".join(healed)])
		"ether":
			var charges: int = effect["charges"]
			for m: Dictionary in GameData.party:
				if m["alive"]:
					for lvl: int in m["magic_levels"]:
						m["magic_levels"][lvl]["charges"] = mini(m["magic_levels"][lvl]["charges"] + charges, m["magic_levels"][lvl]["max"])
			_say("[color=green]Crafted %s![/color] Restored %d charges to all party members." % [recipe["name"], charges])
		"full_restore":
			GameData.full_heal()
			_say("[color=green]Crafted %s![/color] Party fully restored!" % recipe["name"])
		_:
			_say("[color=green]Crafted %s![/color] %s" % [recipe["name"], recipe["desc"]])
	alchemy_mode = false

# ── Tinkering crafting ────────────────────────────────────────────────────
func _show_tinkering() -> void:
	var lines: Array = []
	lines.append("[b]Tinker's Bench[/b]    %s" % GameData.format_money_short())
	var skill: int = GameData.skill_uses.get("tinkering", 0)
	var level := _tinker_level(skill)
	var tier: String = GameData.get_skill_tier("tinkering")
	lines.append("Skill: %s (%d crafts)" % [tier, skill])
	lines.append("")
	# Show material inventory
	var mat_lines: Array = []
	for mat_id: String in GameData.material_bag:
		var count: int = GameData.material_bag[mat_id]
		if count > 0:
			mat_lines.append("%s x%d" % [mat_id.replace("_", " ").capitalize(), count])
	if not mat_lines.is_empty():
		lines.append("Materials: %s" % ", ".join(mat_lines))
	else:
		lines.append("[color=#666]No materials. Scavenge from overworld tiles![/color]")
	lines.append("")
	var recipes := TinkerDB.available_recipes(level)
	if recipes.is_empty():
		lines.append("No recipes available yet.")
	else:
		for i in range(recipes.size()):
			var r: Dictionary = recipes[i]
			var marker := "▶" if i == tinker_idx else " "
			var can_craft := _can_craft_tinker(r)
			var color_start := "" if can_craft else "[color=#666]"
			var color_end := "" if can_craft else "[/color]"
			var mat_cost := _tinker_cost_text(r)
			lines.append("%s%s %-18s %s (%s)%s" % [color_start, marker, r["name"], r["desc"], mat_cost, color_end])
	lines.append("")
	lines.append("[1]/Enter to craft, arrows to browse, [Esc] back")
	_say("\n".join(lines))

func _tinker_level(uses: int) -> int:
	if uses >= 60: return 3
	if uses >= 30: return 2
	if uses >= 10: return 1
	return 0

func _can_craft_tinker(recipe: Dictionary) -> bool:
	for mat_id: int in recipe["materials"]:
		var mat_info: Dictionary = TinkerDB.MATERIAL_INFO[mat_id]
		var have: int = GameData.get_material_count(mat_info["id"])
		if have < recipe["materials"][mat_id]:
			return false
	return true

func _tinker_cost_text(recipe: Dictionary) -> String:
	var parts: Array = []
	for mat_id: int in recipe["materials"]:
		var mat_info: Dictionary = TinkerDB.MATERIAL_INFO[mat_id]
		parts.append("%s x%d" % [mat_info["name"], recipe["materials"][mat_id]])
	return ", ".join(parts)

func _handle_tinker_input(keycode: int) -> void:
	match keycode:
		KEY_UP:
			tinker_idx = max(0, tinker_idx - 1)
			_show_tinkering()
		KEY_DOWN:
			var skill: int = GameData.skill_uses.get("tinkering", 0)
			var level := _tinker_level(skill)
			var recipes := TinkerDB.available_recipes(level)
			tinker_idx = min(max(recipes.size() - 1, 0), tinker_idx + 1)
			_show_tinkering()
		KEY_1, KEY_ENTER, KEY_SPACE:
			_try_craft_tinker()
		KEY_ESCAPE:
			tinkering_mode = false
			_update_hud()

func _try_craft_tinker() -> void:
	var skill: int = GameData.skill_uses.get("tinkering", 0)
	var level := _tinker_level(skill)
	var recipes := TinkerDB.available_recipes(level)
	if recipes.is_empty() or tinker_idx >= recipes.size():
		tinkering_mode = false
		return
	var recipe: Dictionary = recipes[tinker_idx]
	if not _can_craft_tinker(recipe):
		_say("Not enough materials for %s." % recipe["name"])
		return
	# Consume materials
	for mat_id: int in recipe["materials"]:
		var mat_info: Dictionary = TinkerDB.MATERIAL_INFO[mat_id]
		GameData.remove_material(mat_info["id"], recipe["materials"][mat_id])
	# Add crafted item(s)
	for _i in range(recipe.get("output_count", 1)):
		GameData.add_crafted_item({
			"id": recipe["id"],
			"name": recipe["name"],
			"desc": recipe["desc"],
			"type": "tool",
			"value": recipe.get("value", 0),
		})
	GameData.track_skill_use("tinkering", 1)
	_say("[color=green]Crafted %s![/color] %s" % [recipe["name"], recipe["desc"]])
	tinkering_mode = false

func _get_cookable_fish() -> Array:
	var fish_items: Array = []
	for i in range(GameData.trade_goods.size()):
		var item: Dictionary = GameData.trade_goods[i]
		if item.get("cooking", {}).get("hp", 0) > 0:
			fish_items.append({"idx": i, "item": item})
	return fish_items

func _show_cook() -> void:
	var lines: Array = []
	lines.append("[b]Cook Fish[/b]    %s" % GameData.format_money_short())
	var cookable := _get_cookable_fish()
	if cookable.is_empty():
		lines.append("No fish to cook. Catch some at the shore!")
		cooking_mode = false
	else:
		for i in range(cookable.size()):
			var entry: Dictionary = cookable[i]
			var item: Dictionary = entry["item"]
			var marker := "▶" if i == cook_idx else " "
			var hp: int = item.get("cooking", {}).get("hp", 0)
			lines.append("%s %-18s Heals %d HP to party" % [marker, item["name"], hp])
		lines.append("")
		lines.append("[1]/Enter to cook, arrows to browse, [Esc] back")
	_say("\n".join(lines))

func _handle_cook_input(keycode: int) -> void:
	match keycode:
		KEY_UP:
			cook_idx = max(0, cook_idx - 1)
			_show_cook()
		KEY_DOWN:
			var cookable := _get_cookable_fish()
			cook_idx = min(max(cookable.size() - 1, 0), cook_idx + 1)
			_show_cook()
		KEY_1, KEY_ENTER, KEY_SPACE:
			_try_cook()
		KEY_ESCAPE:
			cooking_mode = false
			_update_hud()

func _try_cook() -> void:
	var cookable := _get_cookable_fish()
	if cookable.is_empty() or cook_idx >= cookable.size():
		cooking_mode = false
		return
	var entry: Dictionary = cookable[cook_idx]
	var item: Dictionary = entry["item"]
	var hp: int = item.get("cooking", {}).get("hp", 0)
	# Remove the fish from trade goods
	GameData.trade_goods.remove_at(entry["idx"])
	# Heal all alive party members
	var healed_names: Array = []
	for m: Dictionary in GameData.party:
		if m["alive"]:
			var actual := mini(hp, m["max_hp"] - m["hp"])
			m["hp"] += actual
			healed_names.append("%s +%d" % [m["name"], actual])
	GameData.track_skill_use("cooking", 1)
	_say("[color=green]Cooked %s![/color]\n%s" % [item["name"], ", ".join(healed_names)])
	cooking_mode = false

func _handle_exchange_input(keycode: int) -> void:
	match keycode:
		KEY_UP:
			exchange_idx = max(0, exchange_idx - 1)
			_show_exchange()
		KEY_DOWN:
			exchange_idx = min(_exchange_options().size() - 1, exchange_idx + 1)
			_show_exchange()
		KEY_1, KEY_ENTER, KEY_SPACE:
			_try_exchange()
		KEY_ESCAPE:
			exchange_mode = false
			_update_hud()

func _exchange_options() -> Array:
	var km_rate := GameData.get_currency_buy_rate("keeper_marks")
	var ht_rate := GameData.get_currency_buy_rate("harbor_tokens")
	var cs_rate := GameData.get_currency_buy_rate("chapel_script")
	var km_sell := GameData.get_currency_sell_rate("keeper_marks")
	var ht_sell := GameData.get_currency_sell_rate("harbor_tokens")
	var cs_sell := GameData.get_currency_sell_rate("chapel_script")
	return [
		{"label": "Buy Keeper Mark", "from": "copper", "to": "keeper_marks", "cost": km_rate, "gain": 1, "rate_text": "%dc → 1 Mark" % km_rate},
		{"label": "Buy Harbor Token", "from": "copper", "to": "harbor_tokens", "cost": ht_rate, "gain": 1, "rate_text": "%dc → 1 Token" % ht_rate},
		{"label": "Buy Chapel Script", "from": "copper", "to": "chapel_script", "cost": cs_rate, "gain": 1, "rate_text": "%dc → 1 Script" % cs_rate},
		{"label": "Sell Keeper Mark", "from": "keeper_marks", "to": "copper", "cost": 1, "gain": km_sell, "rate_text": "1 Mark → %dc" % km_sell},
		{"label": "Sell Harbor Token", "from": "harbor_tokens", "to": "copper", "cost": 1, "gain": ht_sell, "rate_text": "1 Token → %dc" % ht_sell},
		{"label": "Sell Chapel Script", "from": "chapel_script", "to": "copper", "cost": 1, "gain": cs_sell, "rate_text": "1 Script → %dc" % cs_sell},
	]

func _show_exchange() -> void:
	var lines: Array = []
	lines.append("[b]Currency Exchange[/b]")
	lines.append("%s | Marks: %d | Tokens: %d | Script: %d" % [
		GameData.format_money_short(), GameData.keeper_marks, GameData.harbor_tokens, GameData.chapel_script])
	lines.append("")
	var options := _exchange_options()
	for i in range(options.size()):
		var opt: Dictionary = options[i]
		var marker := "▶" if i == exchange_idx else " "
		var can_afford: bool = GameData.get_currency_balance(opt["from"]) >= opt["cost"]
		var color_start := "" if can_afford else "[color=#666]"
		var color_end := "" if can_afford else "[/color]"
		lines.append("%s%s %-18s %s%s" % [color_start, marker, opt["label"], opt["rate_text"], color_end])
	lines.append("")
	lines.append("[1]/Enter to trade, arrows to browse, [Esc] back")
	_say("\n".join(lines))

func _try_exchange() -> void:
	var options := _exchange_options()
	if exchange_idx >= options.size(): return
	var opt: Dictionary = options[exchange_idx]
	if not GameData.spend_currency(opt["from"], opt["cost"]):
		_say("Not enough funds for this trade.")
		return
	GameData.add_currency(opt["to"], opt["gain"])
	_show_exchange()

func _show_roster() -> void:
	var lines: Array = []
	lines.append("[b]Available Companions[/b]    %s\n" % GameData.format_money_short())
	var available := _get_available_roster()
	if available.is_empty():
		lines.append("No one is looking for work right now.")
		recruit_mode = false
	else:
		for i in range(available.size()):
			var r: Dictionary = available[i]
			var marker := "▶" if i == roster_idx else " "
			lines.append("%s %s  Lv%d %s  Wage: %dc/wk" % [marker, r["name"], r["level"], r["class"], r["wage"]])
			lines.append("    %s" % r["dialogue"])
		lines.append("\n[1] Recruit  [Esc] Back")
	_say("\n".join(lines))

func _try_recruit() -> void:
	var available := _get_available_roster()
	if available.is_empty():
		recruit_mode = false
		_update_hud()
		return
	if roster_idx >= available.size():
		roster_idx = available.size() - 1
	var r: Dictionary = available[roster_idx]
	if GameData.party.size() >= 4:
		_say("Your party is full! (Max 4 members)")
		recruit_mode = false
		return
	if not GameData.spend_copper(r["wage"]):
		_say("You can't afford %s's wage." % r["name"])
		return
	# Build party member from class template
	var tmpl: Dictionary = CharDB.get_template(r["class"]).duplicate(true)
	var member := {
		"name": r["name"],
		"class": r["class"],
		"hp": tmpl["hp"], "max_hp": tmpl["hp"],
		"str": tmpl["str"], "def": tmpl["def"], "agi": tmpl["agi"],
		"level": r["level"], "xp": 0, "next_xp": 18,
		"magic_levels": _copy_magic(tmpl.get("magic_levels", {})),
		"alive": true,
		"command": "",
		"command_label": "",
		"wage": r["wage"],
		"loyalty": r["loyalty"],
	}
	# Scale stats for level
	for _i in range(r["level"] - 1):
		var gains: Dictionary = CharDB.level_up_stats(r["class"], RandomNumberGenerator.new())
		member["max_hp"] += gains["hp"]
		member["str"] += gains["str"]
		member["def"] += gains["def"]
		member["agi"] += gains["agi"]
		member["hp"] = member["max_hp"]
		member["next_xp"] = int(round(member["next_xp"] * 1.4))
	GameData.party.append(member)
	GameData.equipped_weapon.append(-1)
	GameData.equipped_head.append(-1)
	GameData.equipped_body.append(-1)
	GameData.equipped_accessory.append(-1)
	# Mark as recruited
	var roster_pool = GameData.get_meta("roster_pool", _init_roster())
	for entry in roster_pool:
		if entry["name"] == r["name"]:
			entry["recruited"] = true
			break
	GameData.set_meta("roster_pool", roster_pool)
	_say("[color=#27ae60]%s joins your party![/color] Paid %dc wage." % [r["name"], r["wage"]])
	recruit_mode = false

func _get_available_roster() -> Array:
	var roster_pool = GameData.get_meta("roster_pool", null)
	if roster_pool == null:
		roster_pool = _init_roster()
		GameData.set_meta("roster_pool", roster_pool)
	var available: Array = []
	var party_names: Array = []
	for m: Dictionary in GameData.party:
		party_names.append(m["name"])
	for r: Dictionary in roster_pool:
		if r["available"] and not r["recruited"] and not r.get("departed", false) and not r["name"] in party_names:
			available.append(r)
	return available

func _init_roster() -> Array:
	var source: Array = NPCDB.recruitable_roster()
	var roster: Array = []
	for r: Dictionary in source:
		roster.append(r.duplicate(true))
	return roster

func _copy_magic(src: Dictionary) -> Dictionary:
	var out := {}
	for lvl: int in src:
		out[lvl] = {"charges": src[lvl], "max": src[lvl]}
	return out

func _show_elder_dialogue(npc_name: String, npc_line: String) -> void:
	# Check for quest completion first
	var completion_msg := _check_quest_completions()
	if completion_msg != "":
		_say(completion_msg)
		talking_to = ""
		return
	# Build dialogue
	var msg := "[color=#9b59b6]%s[/color]: " % npc_name
	# Find the next story quest to highlight
	var next_story := QuestDB.get_next_story_quest()
	if next_story != "":
		var quest: Dictionary = QuestDB.get_quest(next_story)
		msg += quest.get("dialogue_start", npc_line)
	else:
		msg += npc_line
	msg += "\n\n"
	# Show active quests
	var has_active := false
	for qid: String in GameData.active_quests.keys():
		var quest: Dictionary = QuestDB.get_quest(qid)
		if quest.is_empty(): continue
		var status: String = GameData.active_quests[qid]["status"]
		if status == "complete":
			msg += "[color=green]✓ %s[/color]\n" % quest["name"]
			has_active = true
		else:
			has_active = true
			var prog: int = GameData.get_quest_progress(qid)
			var needed: int = quest.get("target_count", 1)
			match quest["type"]:
				"kill":
					msg += "● %s (%d/%d)\n" % [quest["name"], prog, needed]
				"beacon":
					var bp: Vector2i = QuestDB.BEACON_POS.get(quest.get("target", ""), Vector2i(-1, -1))
					var lit: bool = GameData.beacon_states.get(str(bp), false)
					msg += "● %s %s\n" % [quest["name"], "[color=green](lit)[/color]" if lit else ""]
				_:
					msg += "● %s\n" % quest["name"]
	# Show available quests (prerequisites met)
	var available := QuestDB.get_available_quests()
	for qid: String in available:
		var quest: Dictionary = QuestDB.get_quest(qid)
		msg += "[color=yellow]★ %s[/color]\n" % quest["name"]
	if not available.is_empty():
		msg += "\n[1] Accept next quest  [Esc] Back"
		talking_to = "elder_quest"
	elif not has_active:
		msg += "\n[Esc] Back"
		talking_to = ""
	else:
		msg += "\n[Esc] Back"
		talking_to = "elder"
	_say(msg)

func _check_quest_completions() -> String:
	for qid: String in GameData.active_quests.keys():
		if GameData.active_quests[qid]["status"] != "active":
			continue
		var quest: Dictionary = QuestDB.get_quest(qid)
		if quest.is_empty(): continue
		var completed := false
		match quest["type"]:
			"beacon":
				var bp: Vector2i = QuestDB.BEACON_POS.get(quest.get("target", ""), Vector2i(-1, -1))
				completed = GameData.beacon_states.get(str(bp), false)
			"flag":
				var flag_target: String = quest.get("target", "")
				if GameData.get(flag_target) != null:
					completed = GameData.get(flag_target)
				else:
					completed = GameData.get_meta(flag_target, false)
			"kill":
				completed = GameData.get_quest_progress(qid) >= quest.get("target_count", 1)
			"gather":
				completed = GameData.get_quest_progress(qid) >= quest.get("target_count", 1)
			"faction":
				var faction_target: String = quest.get("target", "")
				var faction_key: int = NPC_FACTION_MAP.get(faction_target, -1)
				var faction_val: int = GameData.faction_reputation.get(faction_key, 0) if faction_key >= 0 else 0
				completed = faction_val >= quest.get("target_count", 20)
			"trade":
				var trade_profit: int = GameData.gather_counts.get("trade_profit", 0)
				GameData.active_quests[qid]["progress"] = mini(trade_profit, quest.get("target_count", 200))
				completed = trade_profit >= quest.get("target_count", 200)
			"upgrade":
				completed = GameData.home_upgrades.size() >= quest.get("target_count", 2) and GameData.owns_home()
			"all_beacons":
				var lit := 0
				for bname: String in QuestDB.BEACON_POS:
					if GameData.beacon_states.get(str(QuestDB.BEACON_POS[bname]), false):
						lit += 1
				completed = lit >= QuestDB.BEACON_POS.size()
			"explore_flag":
				completed = GameData.get_meta(quest.get("target", ""), false)
		if completed and not GameData.is_quest_complete(qid):
			GameData.complete_quest(qid)
			var reward_gold: int = quest.get("reward_gold", 0)
			var reward_copper: int = reward_gold * 100
			var reward_xp: int = quest.get("reward_xp", 0)
			GameData.add_copper(reward_copper)
			for m: Dictionary in GameData.party:
				if m["alive"]:
					m["xp"] += reward_xp
			var fac: String = quest.get("reward_faction", "")
			var rep: int = quest.get("reward_rep", 0)
			if fac != "" and rep > 0:
				var faction_key := _quest_reward_faction(fac)
				if faction_key >= 0:
					GameData.change_faction_rep(faction_key, rep)
			var complete_msg: String = quest.get("dialogue_complete", "Quest complete!")
			if quest.has("next_breadcrumb"):
				complete_msg += "\n\n[color=#f0d46a]%s[/color]" % quest["next_breadcrumb"]
			return "[color=cyan]✓ Quest Complete: %s[/color]\n%s\nReward: %s, %d XP" % [quest["name"], complete_msg, _format_reward(reward_copper), reward_xp]
	return ""

func _quest_reward_faction(faction_id: String) -> int:
	var faction_map := {
		"keepers": FactionDB.Faction.KEEPERS_GUILD,
		"keepers_guild": FactionDB.Faction.KEEPERS_GUILD,
		"harbor": FactionDB.Faction.HARBOR_COMPACT,
		"harbor_compact": FactionDB.Faction.HARBOR_COMPACT,
		"chapel": FactionDB.Faction.GREY_CHAPEL,
		"grey_chapel": FactionDB.Faction.GREY_CHAPEL,
		"unlit": FactionDB.Faction.THE_UNLIT,
		"the_unlit": FactionDB.Faction.THE_UNLIT,
	}
	return faction_map.get(faction_id, -1)

func _format_reward(copper: int) -> String:
	var g: int = copper / 10000
	var s: int = (copper % 10000) / 100
	var c: int = copper % 100
	if g > 0:
		return "%dg %ds %dc" % [g, s, c]
	if s > 0:
		return "%ds %dc" % [s, c]
	return "%dc" % c

func _accept_next_quest() -> void:
	var next := QuestDB.get_next_story_quest()
	if next != "":
		GameData.accept_quest(next)
		var quest: Dictionary = QuestDB.get_quest(next)
		_say(_quest_accepted_text(quest, quest.get("dialogue_start", quest["description"])))
		talking_to = ""
		return
	# Fall back to any available quest
	var available := QuestDB.get_available_quests()
	if not available.is_empty():
		var qid: String = available[0]
		GameData.accept_quest(qid)
		var quest: Dictionary = QuestDB.get_quest(qid)
		_say(_quest_accepted_text(quest, quest["description"]))
	else:
		_say("No more quests available right now.")
	talking_to = ""

func _quest_accepted_text(quest: Dictionary, intro: String) -> String:
	var lines := [
		"[color=cyan]Quest accepted: %s[/color]" % quest["name"],
		intro,
	]
	if quest.has("objective"):
		lines.append("\n[color=#f0d46a]Objective:[/color] %s" % quest["objective"])
	if quest.has("hint"):
		lines.append("[color=#9fc5ff]Hint:[/color] %s" % quest["hint"])
	lines.append("[color=#888]Press J on the overworld to review your journal.[/color]")
	return "\n".join(lines)

func _say(msg: String) -> void:
	dialog.text = "[b]Brindlewick[/b]    %s    Tonics: %d\n\n%s" % [GameData.format_money_short(), GameData.tonics, msg]

func _update_hud() -> void:
	var lines: Array = []
	for m: Dictionary in GameData.party:
		if m["alive"]:
			lines.append("Lv%d %s  %d/%d" % [m["level"], m["name"], m["hp"], m["max_hp"]])
		else:
			lines.append("Lv%d %s  [KO]" % [m["level"], m["name"]])
	dialog.text = "[b]Brindlewick[/b]    %s    Tonics: %d\n\n%s" % [GameData.format_money_short(), GameData.tonics, "\n".join(lines)]
