# Town — interior map with NPCs, weapon shop, armor shop, inn
#
# [CODING CONCEPT: Scene Transitions]
# When the player walks to the bottom of this map, the game switches to the
# overworld scene via SceneTransition.change_scene(). When they talk to a
# merchant, it switches to the shop scene. Each scene is independent — this
# script doesn't know how the shop works, and the shop doesn't know how the
# town map is drawn. They communicate through GameData (shared state) and
# GameData.set_meta()/get_meta() (one-time messages like "shop_type=weapons").
@tool
extends Node2D

const TownLayout := preload("res://scripts/town_layout.gd")
const FactionDB := preload("res://scripts/data/factions.gd")
const QuestDB := preload("res://scripts/data/quests.gd")
const NPCDB := preload("res://scripts/data/npcs.gd")
const AlchemyDB := preload("res://scripts/data/alchemy.gd")
const TinkerDB := preload("res://scripts/data/tinkering.gd")
const CharDB := preload("res://scripts/data/classes.gd")
const NPC_FACTION_MAP := {
	"keepers": FactionDB.Faction.KEEPERS_GUILD,
	"harbor": FactionDB.Faction.HARBOR_COMPACT,
	"chapel": FactionDB.Faction.GREY_CHAPEL,
	"unlit": FactionDB.Faction.THE_UNLIT,
}

const TOWN_LAYOUT_PATH := "res://assets/world/towns/brindlewick.layout.json"
const TILE_SIZE := 16
const CAT_HOME := Vector2i(18, 18)
const CAT_WANDER_RADIUS := 5
const CAT_FRAME_TIME := 0.12
const GROUND_TILE_RECTS := {
	".": Rect2i(Vector2i(0, 0), Vector2i(TILE_SIZE, TILE_SIZE)),
	"=": Rect2i(Vector2i(16, 0), Vector2i(TILE_SIZE, TILE_SIZE)),
	"@": Rect2i(Vector2i(32, 0), Vector2i(TILE_SIZE, TILE_SIZE)),
	",": Rect2i(Vector2i(48, 0), Vector2i(TILE_SIZE, TILE_SIZE)),
	";": Rect2i(Vector2i(64, 0), Vector2i(TILE_SIZE, TILE_SIZE)),
	"w": Rect2i(Vector2i(80, 0), Vector2i(TILE_SIZE, TILE_SIZE)),
	"+": Rect2i(Vector2i(96, 0), Vector2i(TILE_SIZE, TILE_SIZE)),
	"g": Rect2i(Vector2i(112, 0), Vector2i(TILE_SIZE, TILE_SIZE)),
	"s": Rect2i(Vector2i(0, 16), Vector2i(TILE_SIZE, TILE_SIZE)),
	"m": Rect2i(Vector2i(16, 16), Vector2i(TILE_SIZE, TILE_SIZE)),
	"b": Rect2i(Vector2i(32, 16), Vector2i(TILE_SIZE, TILE_SIZE)),
	"l": Rect2i(Vector2i(48, 16), Vector2i(TILE_SIZE, TILE_SIZE)),
	"H": Rect2i(Vector2i(0, 0), Vector2i(TILE_SIZE, TILE_SIZE)),
}
const WANG_NW := 1
const WANG_NE := 2
const WANG_SW := 4
const WANG_SE := 8
const DETAIL_GRASS_COLORS := [
	Color("3f8c36"),
	Color("5eaa48"),
	Color("6fb858"),
	Color("386f32"),
]
const DETAIL_FLOWER_COLORS := [
	Color("f0d46a"),
	Color("d98880"),
	Color("c58cf0"),
]
const DETAIL_STONE_COLORS := [
	Color("7b7969"),
	Color("9a8f74"),
]
const SHADOW_COLOR := Color(0.05, 0.04, 0.03, 0.48)
const BUILDING_CONTACT_SHADOW_COLOR := Color(0.05, 0.04, 0.03, 0.22)
const UI_PANEL_COLOR := Color(0.035, 0.032, 0.045, 0.82)
const UI_PANEL_BORDER := Color(0.82, 0.72, 0.46, 0.86)
const GRASS_DIRT_WANG_RECTS := {
	0: Rect2i(Vector2i(32, 16), Vector2i(TILE_SIZE, TILE_SIZE)),
	1: Rect2i(Vector2i(16, 16), Vector2i(TILE_SIZE, TILE_SIZE)),
	2: Rect2i(Vector2i(32, 0), Vector2i(TILE_SIZE, TILE_SIZE)),
	3: Rect2i(Vector2i(48, 0), Vector2i(TILE_SIZE, TILE_SIZE)),
	4: Rect2i(Vector2i(32, 32), Vector2i(TILE_SIZE, TILE_SIZE)),
	5: Rect2i(Vector2i(16, 0), Vector2i(TILE_SIZE, TILE_SIZE)),
	6: Rect2i(Vector2i(0, 16), Vector2i(TILE_SIZE, TILE_SIZE)),
	7: Rect2i(Vector2i(16, 48), Vector2i(TILE_SIZE, TILE_SIZE)),
	8: Rect2i(Vector2i(48, 16), Vector2i(TILE_SIZE, TILE_SIZE)),
	9: Rect2i(Vector2i(32, 48), Vector2i(TILE_SIZE, TILE_SIZE)),
	10: Rect2i(Vector2i(48, 32), Vector2i(TILE_SIZE, TILE_SIZE)),
	11: Rect2i(Vector2i(0, 0), Vector2i(TILE_SIZE, TILE_SIZE)),
	12: Rect2i(Vector2i(16, 32), Vector2i(TILE_SIZE, TILE_SIZE)),
	13: Rect2i(Vector2i(0, 32), Vector2i(TILE_SIZE, TILE_SIZE)),
	14: Rect2i(Vector2i(48, 48), Vector2i(TILE_SIZE, TILE_SIZE)),
	15: Rect2i(Vector2i(0, 48), Vector2i(TILE_SIZE, TILE_SIZE)),
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
const MODULAR_BUILDING_TILE_RECTS := {
	"roof_left": Rect2i(Vector2i(0, 0), Vector2i(TILE_SIZE, TILE_SIZE)),
	"roof_mid": Rect2i(Vector2i(16, 0), Vector2i(TILE_SIZE, TILE_SIZE)),
	"roof_right": Rect2i(Vector2i(32, 0), Vector2i(TILE_SIZE, TILE_SIZE)),
	"roof_ridge": Rect2i(Vector2i(48, 0), Vector2i(TILE_SIZE, TILE_SIZE)),
	"roof_eave": Rect2i(Vector2i(64, 0), Vector2i(TILE_SIZE, TILE_SIZE)),
	"roof_moss": Rect2i(Vector2i(80, 0), Vector2i(TILE_SIZE, TILE_SIZE)),
	"chimney": Rect2i(Vector2i(96, 0), Vector2i(TILE_SIZE, TILE_SIZE)),
	"wall": Rect2i(Vector2i(0, 16), Vector2i(TILE_SIZE, TILE_SIZE)),
	"wall_timber": Rect2i(Vector2i(16, 16), Vector2i(TILE_SIZE, TILE_SIZE)),
	"wall_brace": Rect2i(Vector2i(32, 16), Vector2i(TILE_SIZE, TILE_SIZE)),
	"wall_shadow": Rect2i(Vector2i(48, 16), Vector2i(TILE_SIZE, TILE_SIZE)),
	"foundation": Rect2i(Vector2i(64, 16), Vector2i(TILE_SIZE, TILE_SIZE)),
	"foundation_moss": Rect2i(Vector2i(80, 16), Vector2i(TILE_SIZE, TILE_SIZE)),
	"foundation_shadow": Rect2i(Vector2i(96, 16), Vector2i(TILE_SIZE, TILE_SIZE)),
	"threshold": Rect2i(Vector2i(112, 16), Vector2i(TILE_SIZE, TILE_SIZE)),
	"door": Rect2i(Vector2i(0, 32), Vector2i(TILE_SIZE, TILE_SIZE)),
	"door_open": Rect2i(Vector2i(16, 32), Vector2i(TILE_SIZE, TILE_SIZE)),
	"window": Rect2i(Vector2i(32, 32), Vector2i(TILE_SIZE, TILE_SIZE)),
	"window_arch": Rect2i(Vector2i(48, 32), Vector2i(TILE_SIZE, TILE_SIZE)),
	"window_flower": Rect2i(Vector2i(64, 32), Vector2i(TILE_SIZE, TILE_SIZE)),
	"plaque_blank": Rect2i(Vector2i(80, 32), Vector2i(TILE_SIZE, TILE_SIZE)),
	"lantern": Rect2i(Vector2i(96, 32), Vector2i(TILE_SIZE, TILE_SIZE)),
	"flower_box": Rect2i(Vector2i(112, 32), Vector2i(TILE_SIZE, TILE_SIZE)),
	"plaque_sword": Rect2i(Vector2i(0, 48), Vector2i(TILE_SIZE, TILE_SIZE)),
	"plaque_shield": Rect2i(Vector2i(16, 48), Vector2i(TILE_SIZE, TILE_SIZE)),
	"plaque_tankard": Rect2i(Vector2i(32, 48), Vector2i(TILE_SIZE, TILE_SIZE)),
	"plaque_gear": Rect2i(Vector2i(48, 48), Vector2i(TILE_SIZE, TILE_SIZE)),
	"plaque_bed": Rect2i(Vector2i(64, 48), Vector2i(TILE_SIZE, TILE_SIZE)),
	"plaque_candle": Rect2i(Vector2i(80, 48), Vector2i(TILE_SIZE, TILE_SIZE)),
}

const MAP := [
	",,,,,,,,,,,,,,,lllllll,,,,,,,,,,,,,,,,,,",
	",,,,,,,,,,,,,,,..+++..,,,,,,,,,,,,,,,,,,",
	",,,,,,,,,,,,,,,HHHHHHH,,,,,,,,,,,,,,,,,,",
	",,,,,,,,,,,,,,,HHHHHHH,,,,,,,,,,,,,,,,,,",
	",,,,,,,,,,,,,,,HHHHHHH,,,,,,,,,,,,,,,,,,",
	",,,,,,,,,,,,,,,,ss==ss,,,,,,,,,,,,,,,,,,",
	",,,,,,,,,,,,,,,,ss==ss,,,,,,,,,,,,,,,,,,",
	",,,..gg..,,,,,,,,,==,,,,,,,,,..gg..,,,,,",
	",,,HHHHHH,,,,,,,,,==,,,,,,,,,HHHHHH,,,,,",
	",,,HHHHHH========++====++====HHHHHH,,,,,",
	",,,HHHHHH,,,,,,,,,,====,,,,,,HHHHHH,,,,,",
	",,,,,,,,,,,,,,,,,,,====,,,,,,,,,,,,,,,,,",
	",,,,,,,,,,,,,,,,,,,====,,,,,,,,,,,,,,,,,",
	",,,,,,;;;;,,,,,,,======,,,,,,,,;;;;,,,,,",
	",,,,HHHHHH,,,HHHHHH,wwwHHHHHH,,,HHHHHH,",
	",,,,HHHHHH,,,HHHHHH,,,HHHHHH,,,HHHHHH,",
	",,,,HHHHHH,,,HHHHHH,,,HHHHHH,,,HHHHHH,",
	",,,,,++==++,,,,++==++,,,,++==++,,++==+,",
	",,,,,,,================================,",
	",,,,,,,,,,,,,,,,,,,==,,,,,,,,,,,,,,,,,,",
	",,,,,,,,,,,,,,,,,,,==,,,,,,,,,,,,,,,,,,",
	",,,,,,,,,,,,,,,,,,ss==ss,,,,,,,,,,,,,,,,",
	",,,,,,,,,,,,,,,,,,ss==ss,,,,,,,,,,,,,,,,",
	",,,,,,,,,,,,,,,,,,ss==ss,,,,,,,,,,,,,,,,",
]

const COLORS := {
	"#": Color("8b7355"), ".": Color("c49b56"), "@": Color("a08050"),
	"W": Color("27ae60"), "A": Color("27ae60"), "I": Color("3498db"),
	"S": Color("9b59b6"), "E": Color("e67e22"), "R": Color("e67e22"),
	",": Color("4f9e43"), "=": Color("ad7e48"), "H": Color("4d9e43"),
	";": Color("65563c"), "w": Color("8f5b34"), "+": Color("807e6e"),
	"g": Color("754c31"), "s": Color("c2a665"), "m": Color("8b8169"),
	"b": Color("804e3c"), "l": Color("4a8f3e"),
}
const BLOCKED := {"#": true, "H": true}
const NPC_IDS := ["weapon_merchant", "armor_merchant", "innkeeper", "elder", "tavern_keeper", "healer", "tinkerer", "realtor"]
const BUILDING_DOORS := {
	Vector2i(17, 5): "elder",
	Vector2i(18, 5): "elder",
	Vector2i(19, 5): "elder",
	Vector2i(5, 10): "weapon_merchant",
	Vector2i(6, 10): "weapon_merchant",
	Vector2i(7, 10): "weapon_merchant",
	Vector2i(30, 10): "armor_merchant",
	Vector2i(31, 10): "armor_merchant",
	Vector2i(32, 10): "armor_merchant",
	Vector2i(6, 17): "innkeeper",
	Vector2i(7, 17): "innkeeper",
	Vector2i(8, 17): "innkeeper",
	Vector2i(15, 17): "tavern_keeper",
	Vector2i(16, 17): "tavern_keeper",
	Vector2i(17, 17): "tavern_keeper",
	Vector2i(24, 17): "tinkerer",
	Vector2i(25, 17): "tinkerer",
	Vector2i(26, 17): "tinkerer",
	Vector2i(33, 17): "healer",
	Vector2i(34, 17): "healer",
	Vector2i(35, 17): "healer",
}
const BUILDING_INTERACTIONS := {
	"elder_hall": {"npc": "elder", "name": "Elder Hall", "door_offset": Vector2i(3, 4), "door_width": 3},
	"weapon_shop": {"npc": "weapon_merchant", "name": "Weapon Shop", "door_offset": Vector2i(2, 3), "door_width": 3},
	"armor_shop": {"npc": "armor_merchant", "name": "Armor Shop", "door_offset": Vector2i(2, 3), "door_width": 3},
	"inn": {"npc": "innkeeper", "name": "Inn", "door_offset": Vector2i(2, 3), "door_width": 3},
	"tavern": {"npc": "tavern_keeper", "name": "Tavern", "door_offset": Vector2i(2, 3), "door_width": 3},
	"workshop": {"npc": "tinkerer", "name": "Workshop", "door_offset": Vector2i(2, 3), "door_width": 3},
	"chapel": {"npc": "healer", "name": "Chapel", "door_offset": Vector2i(2, 3), "door_width": 3},
}
const SOUTH_FACING_BUILDING_OVERRIDES := {
	"weapon_shop": true,
	"armor_shop": true,
	"inn": true,
	"chapel": true,
}
const BUILDING_LABELS := []
const TOWN_BUILDINGS := [
	{"id": "elder_hall", "grid": Vector2i(14, 1), "size": Vector2i(7, 5), "plaque": "plaque_blank", "public": true, "fallback_region": Rect2i(Vector2i(219, 16), Vector2i(172, 72)), "fallback_scale": 0.5},
	{"id": "weapon_shop", "grid": Vector2i(3, 7), "size": Vector2i(6, 4), "plaque": "plaque_sword", "fallback_region": Rect2i(Vector2i(15, 573), Vector2i(117, 72)), "fallback_scale": 0.55},
	{"id": "armor_shop", "grid": Vector2i(28, 7), "size": Vector2i(6, 4), "plaque": "plaque_shield", "fallback_region": Rect2i(Vector2i(16, 466), Vector2i(116, 72)), "fallback_scale": 0.55},
	{"id": "inn", "grid": Vector2i(4, 14), "size": Vector2i(6, 4), "plaque": "plaque_bed", "fallback_region": Rect2i(Vector2i(16, 681), Vector2i(116, 72)), "fallback_scale": 0.55},
	{"id": "tavern", "grid": Vector2i(13, 14), "size": Vector2i(6, 4), "plaque": "plaque_tankard", "fallback_region": Rect2i(Vector2i(14, 16), Vector2i(118, 72)), "fallback_scale": 0.55},
	{"id": "workshop", "grid": Vector2i(22, 14), "size": Vector2i(6, 4), "plaque": "plaque_gear", "fallback_region": Rect2i(Vector2i(354, 466), Vector2i(129, 72)), "fallback_scale": 0.5},
	{"id": "chapel", "grid": Vector2i(31, 14), "size": Vector2i(6, 4), "plaque": "plaque_candle", "fallback_region": Rect2i(Vector2i(14, 16), Vector2i(118, 72)), "fallback_scale": 0.55},
]
const SHOP_SIGNS := [
	{"id": "weapon_shop", "grid": Vector2i(5, 7), "offset": Vector2(8, -5)},
	{"id": "armor_shop", "grid": Vector2i(30, 7), "offset": Vector2(8, -5)},
	{"id": "inn", "grid": Vector2i(6, 14), "offset": Vector2(8, -5)},
	{"id": "tavern", "grid": Vector2i(15, 14), "offset": Vector2(8, -5)},
	{"id": "workshop", "grid": Vector2i(24, 14), "offset": Vector2(8, -5)},
	{"id": "chapel", "grid": Vector2i(33, 14), "offset": Vector2(8, -5)},
]
const SHOP_AWNINGS := [
	{"id": "weapon_shop", "grid": Vector2i(4, 8), "offset": Vector2(0, 0)},
	{"id": "armor_shop", "grid": Vector2i(29, 8), "offset": Vector2(0, 0)},
	{"id": "inn", "grid": Vector2i(5, 15), "offset": Vector2(0, 0)},
	{"id": "tavern", "grid": Vector2i(14, 15), "offset": Vector2(0, 0)},
	{"id": "workshop", "grid": Vector2i(23, 15), "offset": Vector2(0, 0)},
	{"id": "chapel", "grid": Vector2i(32, 15), "offset": Vector2(0, 0)},
]
const TOWN_PROPS := [
	{"id": "well", "grid": Vector2i(20, 11), "offset": Vector2(8, 8), "scale": 0.62},
	{"id": "notice_board", "grid": Vector2i(12, 10), "offset": Vector2(8, 4), "scale": 0.62},
	{"id": "signpost", "grid": Vector2i(15, 6), "offset": Vector2(8, 8), "scale": 0.62},
	{"id": "lantern_post", "grid": Vector2i(17, 6), "offset": Vector2(8, -2), "scale": 0.58},
	{"id": "lantern_post", "grid": Vector2i(22, 12), "offset": Vector2(8, -2), "scale": 0.58},
	{"id": "lantern_post", "grid": Vector2i(19, 16), "offset": Vector2(8, -2), "scale": 0.54},
	{"id": "bench", "grid": Vector2i(18, 13), "offset": Vector2(8, 8), "scale": 0.58},
	{"id": "bench", "grid": Vector2i(21, 13), "offset": Vector2(8, 8), "scale": 0.55},
	{"id": "herb_planter", "grid": Vector2i(17, 20), "offset": Vector2(8, 8), "scale": 0.54},
	{"id": "herb_planter", "grid": Vector2i(21, 20), "offset": Vector2(8, 8), "scale": 0.54},
	{"id": "crate_stack", "grid": Vector2i(24, 13), "offset": Vector2(8, 8), "scale": 0.58},
	{"id": "barrel_pair", "grid": Vector2i(14, 13), "offset": Vector2(8, 8), "scale": 0.6},
	{"id": "crate_stack", "grid": Vector2i(8, 19), "offset": Vector2(8, 8), "scale": 0.55},
	{"id": "barrel_pair", "grid": Vector2i(10, 19), "offset": Vector2(8, 8), "scale": 0.58},
]

@export var load_layout: bool = false:
	set(val):
		if val:
			_load_layout_from_json()
		load_layout = false

@export var save_layout: bool = false:
	set(val):
		if val:
			_save_layout_to_json()
		save_layout = false

@export var clear_preview: bool = false:
	set(val):
		if val:
			_clear_editor_nodes()
		clear_preview = false

var npc_positions: Dictionary = {}
var _npc_markers: Dictionary = {}  # npc_id -> Sprite2D
var _npc_positions_phase: String = ""

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
var _grass_dirt_wang: Texture2D
var _quiet_buildings: Texture2D
var _quiet_props: Texture2D
var _modular_building_atlas: Texture2D
var _town_map: Array = MAP.duplicate()
var _town_buildings: Array = TOWN_BUILDINGS.duplicate(true)
var _shop_signs: Array = SHOP_SIGNS.duplicate(true)
var _shop_awnings: Array = SHOP_AWNINGS.duplicate(true)
var _town_props: Array = TOWN_PROPS.duplicate(true)
var _building_doors: Dictionary = BUILDING_DOORS.duplicate(true)
var _building_interactions: Dictionary = BUILDING_INTERACTIONS.duplicate(true)
var _cat_wander_radius: int = CAT_WANDER_RADIUS
var _shop_sign_textures: Dictionary = {}
var _shop_awning_textures: Dictionary = {}
var _shop_building_textures: Dictionary = {}
var _town_prop_textures: Dictionary = {}
var _player_idle_textures: Dictionary = {}
var _npc_idle_textures: Dictionary = {}
var _cat_marker: Sprite2D
var _cat_pos: Vector2i = CAT_HOME
var _cat_home: Vector2i = CAT_HOME
var _cat_facing: Vector2i = Vector2i.DOWN
var _cat_walk_frames: Dictionary = {}
var _cat_idle_textures: Dictionary = {}
var _cat_anim_timer: float = 0.0
var _cat_frame: int = 0
const WANDER_INTERVAL := 2.5
const WANDER_RADIUS := 3

@onready var map_layer: Node2D = $MapLayer
@onready var building_layer: Node2D = $BuildingLayer
@onready var prop_layer: Node2D = $PropLayer
@onready var building_upper_layer: Node2D = $BuildingUpperLayer
@onready var camera: Camera2D = $Camera2D
@onready var player_sprite: Node2D = $PlayerSprite
@onready var dialog: RichTextLabel = $UILayer/Dialog

func _ready() -> void:
	if Engine.is_editor_hint():
		return
		
	_clear_editor_nodes()
	_load_town_atlas()
	_load_quiet_village_assets()
	_load_town_layout()
	_configure_dialog_panel()
	_apply_return_spawn()
	_draw_map()
	_draw_ground_details()
	_draw_buildings()
	_draw_props()
	_build_npc_positions()
	_draw_npcs()
	_draw_cat()
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
	_show_arrival_hint()

func _load_town_atlas() -> void:
	_town_atlas = SpriteCache.get_asset("town.atlas")
	if not _town_atlas:
		push_warning("Town atlas could not be loaded from asset registry.")

func _configure_dialog_panel() -> void:
	if not dialog:
		return
	var ui_layer := dialog.get_parent()
	if not ui_layer or ui_layer.has_node("DialogPanel"):
		return
	var border := ColorRect.new()
	border.name = "DialogPanel"
	border.color = UI_PANEL_BORDER
	border.position = dialog.position - Vector2(3, 3)
	border.size = dialog.size + Vector2(6, 6)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	border.z_index = -2
	ui_layer.add_child(border)
	ui_layer.move_child(border, 0)
	var panel := ColorRect.new()
	panel.name = "DialogPanelFill"
	panel.color = UI_PANEL_COLOR
	panel.position = dialog.position - Vector2(1, 1)
	panel.size = dialog.size + Vector2(2, 2)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.z_index = -1
	ui_layer.add_child(panel)
	ui_layer.move_child(panel, 1)
	dialog.add_theme_color_override("default_color", Color("f5efd6"))
	dialog.add_theme_color_override("font_shadow_color", Color("100d0b"))
	dialog.add_theme_constant_override("shadow_offset_x", 1)
	dialog.add_theme_constant_override("shadow_offset_y", 1)

func _load_quiet_village_assets() -> void:
	_town_ground = SpriteCache.get_asset("town.ground")
	_grass_dirt_wang = SpriteCache.get_asset("town.grass_dirt_wang")
	_quiet_buildings = SpriteCache.get_asset("town.vendor.buildings")
	_quiet_props = SpriteCache.get_asset("town.vendor.props")
	_modular_building_atlas = SpriteCache.get_asset("town.modular_building_atlas")

func _load_town_layout() -> void:
	var layout := TownLayout.load_from_file(TOWN_LAYOUT_PATH, _default_town_layout())
	if layout.is_empty():
		return
	_town_map = layout["map"]
	_town_buildings = layout["buildings"]
	_shop_signs = layout["shop_signs"]
	_shop_awnings = layout["shop_awnings"]
	_town_props = layout["props"]
	_building_doors = layout["doors"]
	_building_interactions = layout["building_interactions"]
	_cat_home = layout["cat_home"]
	_cat_pos = _cat_home
	_cat_wander_radius = layout["cat_wander_radius"]

func _default_town_layout() -> Dictionary:
	return {
		"map": MAP,
		"buildings": TOWN_BUILDINGS,
		"shop_signs": SHOP_SIGNS,
		"shop_awnings": SHOP_AWNINGS,
		"props": TOWN_PROPS,
		"doors": BUILDING_DOORS,
		"building_interactions": BUILDING_INTERACTIONS,
		"cat": {
			"home": CAT_HOME,
			"wander_radius": CAT_WANDER_RADIUS,
		},
	}

func _load_png_texture(path: String) -> Texture2D:
	if not FileAccess.file_exists(path):
		push_warning("Image missing: %s" % path)
		return null
	if ResourceLoader.exists(path):
		var texture: Texture2D = load(path)
		if texture:
			return texture
	var image := Image.new()
	if image.load(path) != OK:
		push_warning("Image could not be loaded: %s" % path)
		return null
	return ImageTexture.create_from_image(image)

func _draw_map() -> void:
	for y in range(_town_map.size()):
		for x in range(_town_map[y].length()):
			var tile: String = _town_map[y].substr(x, 1)
			var wang_mask := _grass_dirt_wang_mask(x, y) if _is_grass_dirt_terrain_tile(tile) else 0
			if _grass_dirt_wang and wang_mask != 0:
				var sprite := Sprite2D.new()
				sprite.texture = _grass_dirt_wang
				sprite.region_enabled = true
				sprite.region_rect = GRASS_DIRT_WANG_RECTS.get(wang_mask, GRASS_DIRT_WANG_RECTS[0])
				sprite.centered = false
				sprite.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
				map_layer.add_child(sprite)
			elif _town_ground and GROUND_TILE_RECTS.has(tile):
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

func _draw_ground_details() -> void:
	for y in range(_town_map.size()):
		for x in range(_town_map[y].length()):
			var tile: String = _town_map[y].substr(x, 1)
			if tile != "." and tile != ",":
				continue
			var h := int(abs((x * 928371 + y * 364479 + x * y * 1013) % 97))
			if h > 32:
				continue
			var base := Vector2(x * TILE_SIZE, y * TILE_SIZE)
			if h % 11 == 0:
				_add_ground_pixel_cluster(base + Vector2(3 + h % 8, 5 + int(h / 3) % 7), DETAIL_FLOWER_COLORS[h % DETAIL_FLOWER_COLORS.size()], 1, 1)
			elif h % 7 == 0:
				_add_ground_pixel_cluster(base + Vector2(4 + h % 6, 7 + int(h / 5) % 5), DETAIL_STONE_COLORS[h % DETAIL_STONE_COLORS.size()], 3, 2)
			else:
				_add_ground_pixel_cluster(base + Vector2(2 + h % 9, 4 + int(h / 4) % 7), DETAIL_GRASS_COLORS[h % DETAIL_GRASS_COLORS.size()], 4, 1)

func _add_ground_pixel_cluster(position: Vector2, color: Color, width: int, height: int) -> void:
	var detail := ColorRect.new()
	detail.color = color
	detail.position = position
	detail.size = Vector2(width, height)
	detail.z_index = 1
	map_layer.add_child(detail)

func _is_grass_dirt_terrain_tile(tile: String) -> bool:
	return tile == "." or tile == "," or tile == "=" or tile == "+" or tile == "H"

func _terrain_tile_at(x: int, y: int) -> String:
	if y < 0 or y >= _town_map.size():
		return ""
	if x < 0 or x >= _town_map[y].length():
		return ""
	return _town_map[y].substr(x, 1)

func _is_dirt_terrain_tile_at(x: int, y: int) -> bool:
	var tile: String = _terrain_tile_at(x, y)
	return tile == "=" or tile == "+"

func _grass_dirt_corner_is_dirt(tile_x: int, tile_y: int, vertex_x: int, vertex_y: int) -> bool:
	var x := tile_x + vertex_x
	var y := tile_y + vertex_y
	return (
		_is_dirt_terrain_tile_at(x - 1, y - 1)
		or _is_dirt_terrain_tile_at(x, y - 1)
		or _is_dirt_terrain_tile_at(x - 1, y)
		or _is_dirt_terrain_tile_at(x, y)
	)

func _grass_dirt_wang_mask(x: int, y: int) -> int:
	var mask := 0
	if _grass_dirt_corner_is_dirt(x, y, 0, 0):
		mask |= WANG_NW
	if _grass_dirt_corner_is_dirt(x, y, 1, 0):
		mask |= WANG_NE
	if _grass_dirt_corner_is_dirt(x, y, 0, 1):
		mask |= WANG_SW
	if _grass_dirt_corner_is_dirt(x, y, 1, 1):
		mask |= WANG_SE
	return mask

func _draw_buildings() -> void:
	for building_data: Dictionary in _town_buildings:
		_draw_town_building(building_data)
	_draw_building_labels()

const USE_MODULAR_BUILDINGS := false

func _draw_town_building(building_data: Dictionary) -> void:
	if USE_MODULAR_BUILDINGS and _modular_building_atlas:
		_draw_modular_town_building(building_data)
		return
	var texture: Texture2D = _load_shop_building(building_data["id"])
	if texture:
		_add_soft_shadow(
			building_layer,
			Vector2(building_data["grid"] * TILE_SIZE) + Vector2(2, max(4, texture.get_height() - 1)),
			Vector2(max(24, texture.get_width() - 4), 2),
			1,
			BUILDING_CONTACT_SHADOW_COLOR
		)
		_add_split_texture_building(building_data["id"], texture, Vector2(building_data["grid"] * TILE_SIZE))
	elif _quiet_buildings:
		var fallback_size: Vector2 = Vector2(building_data["fallback_region"].size) * building_data["fallback_scale"]
		_add_soft_shadow(
			building_layer,
			Vector2(building_data["grid"] * TILE_SIZE) + Vector2(2, max(4, fallback_size.y - 1)),
			Vector2(max(24, fallback_size.x - 4), 2),
			1,
			BUILDING_CONTACT_SHADOW_COLOR
		)
		_add_building(building_data["grid"], building_data["fallback_region"], building_data["fallback_scale"])

func _add_soft_shadow(parent: Node, position: Vector2, size: Vector2, z: int, color: Color = SHADOW_COLOR) -> void:
	var shadow := ColorRect.new()
	shadow.name = "SoftShadow"
	shadow.color = color
	shadow.position = position
	shadow.size = size
	shadow.z_index = z
	parent.add_child(shadow)

func _draw_modular_town_building(building_data: Dictionary) -> void:
	var root := Node2D.new()
	root.name = "ModularTownBuilding_%s" % building_data["id"]
	root.position = Vector2(building_data["grid"] * TILE_SIZE)
	root.z_index = 2
	building_layer.add_child(root)

	var upper_root := Node2D.new()
	upper_root.name = "ModularTownBuildingUpper_%s" % building_data["id"]
	upper_root.position = root.position
	upper_root.z_index = 2
	building_upper_layer.add_child(upper_root)

	var size: Vector2i = building_data.get("size", Vector2i(6, 4))
	var door_col: int = int(size.x / 2)
	var wall_start: int = 1
	var foundation_row: int = size.y - 1
	var plaque_id: String = building_data.get("plaque", "plaque_blank")

	for x in range(size.x):
		var roof_tile := "roof_mid"
		if x == 0:
			roof_tile = "roof_left"
		elif x == size.x - 1:
			roof_tile = "roof_right"
		_add_modular_building_tile(upper_root, roof_tile, Vector2i(x, 0))

	for x in range(size.x):
		var eave_tile := "roof_eave"
		if building_data.get("public", false) and x == door_col:
			eave_tile = "roof_ridge"
		_add_modular_building_tile(upper_root, eave_tile, Vector2i(x, wall_start))

	for y in range(wall_start + 1, foundation_row):
		for x in range(size.x):
			var wall_tile := "wall"
			if x == 0 or x == size.x - 1:
				wall_tile = "wall_timber"
			elif (x + y) % 4 == 0:
				wall_tile = "wall_brace"
			_add_modular_building_tile(root, wall_tile, Vector2i(x, y))

	for x in range(size.x):
		var foundation_tile := "foundation_moss" if x == 0 or x == size.x - 1 else "foundation"
		_add_modular_building_tile(root, foundation_tile, Vector2i(x, foundation_row))

	_add_modular_building_tile(root, "door", Vector2i(door_col, foundation_row - 1))
	_add_modular_building_tile(root, "threshold", Vector2i(door_col, foundation_row))
	_add_modular_building_tile(root, plaque_id, Vector2i(door_col, max(wall_start, foundation_row - 2)))
	_add_modular_building_tile(root, "lantern", Vector2i(max(0, door_col - 1), foundation_row - 1))

	for x in _building_window_columns(size.x, door_col):
		var window_tile := "window_arch" if building_data.get("public", false) else "window"
		_add_modular_building_tile(root, window_tile, Vector2i(x, foundation_row - 1))

	if size.x >= 7:
		_add_modular_building_tile(upper_root, "chimney", Vector2i(size.x - 2, 0))
	elif building_data["id"] in ["tavern", "workshop", "inn"]:
		_add_modular_building_tile(upper_root, "chimney", Vector2i(size.x - 2, 0))

func _building_window_columns(width: int, door_col: int) -> Array:
	var cols: Array = []
	for x in range(1, width - 1):
		if abs(x - door_col) >= 2:
			cols.append(x)
	if cols.is_empty() and width >= 5:
		cols.append(1)
		cols.append(width - 2)
	return cols

func _add_modular_building_tile(parent: Node2D, tile_id: String, local_grid: Vector2i) -> void:
	if not MODULAR_BUILDING_TILE_RECTS.has(tile_id):
		return
	var sprite := Sprite2D.new()
	sprite.texture = _modular_building_atlas
	sprite.region_enabled = true
	sprite.region_rect = MODULAR_BUILDING_TILE_RECTS[tile_id]
	sprite.centered = false
	sprite.position = Vector2(local_grid * TILE_SIZE)
	parent.add_child(sprite)

func _load_shop_building(building_id: String) -> Texture2D:
	if _shop_building_textures.has(building_id):
		return _shop_building_textures[building_id]
	var texture: Texture2D
	if SOUTH_FACING_BUILDING_OVERRIDES.has(building_id):
		texture = SpriteCache.get_sprite("town/shops/buildings/%s.png" % building_id)
	else:
		texture = SpriteCache.town_building(building_id)
	_shop_building_textures[building_id] = texture
	return texture

func _add_building(grid: Vector2i, region: Rect2i, scale_amount: float) -> void:
	var upper_height := _building_upper_height(region.size.y)
	var lower_height := region.size.y - upper_height
	var upper_region := Rect2i(region.position, Vector2i(region.size.x, upper_height))
	var lower_region := Rect2i(region.position + Vector2i(0, upper_height), Vector2i(region.size.x, lower_height))
	if lower_height > 0:
		var lower_sprite := Sprite2D.new()
		lower_sprite.name = "BuildingLower"
		lower_sprite.texture = _quiet_buildings
		lower_sprite.region_enabled = true
		lower_sprite.region_rect = lower_region
		lower_sprite.centered = false
		lower_sprite.position = Vector2(grid * TILE_SIZE) + Vector2(0, float(upper_height) * scale_amount)
		lower_sprite.scale = Vector2(scale_amount, scale_amount)
		lower_sprite.z_index = 2
		building_layer.add_child(lower_sprite)
	var upper_sprite := Sprite2D.new()
	upper_sprite.name = "BuildingUpper"
	upper_sprite.texture = _quiet_buildings
	upper_sprite.region_enabled = true
	upper_sprite.region_rect = upper_region
	upper_sprite.centered = false
	upper_sprite.position = Vector2(grid * TILE_SIZE)
	upper_sprite.scale = Vector2(scale_amount, scale_amount)
	upper_sprite.z_index = 2
	building_upper_layer.add_child(upper_sprite)

func _add_split_texture_building(building_id: String, texture: Texture2D, position: Vector2) -> void:
	var texture_size := texture.get_size()
	var upper_height := _building_upper_height(int(texture_size.y))
	var lower_height := int(texture_size.y) - upper_height
	if lower_height > 0:
		var lower_sprite := Sprite2D.new()
		lower_sprite.name = "TownBuildingLower_%s" % building_id
		lower_sprite.texture = texture
		lower_sprite.region_enabled = true
		lower_sprite.region_rect = Rect2(Vector2(0, upper_height), Vector2(texture_size.x, lower_height))
		lower_sprite.centered = false
		lower_sprite.position = position + Vector2(0, upper_height)
		lower_sprite.z_index = 2
		building_layer.add_child(lower_sprite)
	var upper_sprite := Sprite2D.new()
	upper_sprite.name = "TownBuildingUpper_%s" % building_id
	upper_sprite.texture = texture
	upper_sprite.region_enabled = true
	upper_sprite.region_rect = Rect2(Vector2.ZERO, Vector2(texture_size.x, upper_height))
	upper_sprite.centered = false
	upper_sprite.position = position
	upper_sprite.z_index = 2
	building_upper_layer.add_child(upper_sprite)

func _building_upper_height(texture_height: int) -> int:
	var max_upper: int = max(1, texture_height - 1)
	var minimum_upper: int = min(TILE_SIZE, max_upper)
	var upper_height := int(round(float(texture_height) * 0.45))
	return clampi(upper_height, minimum_upper, max_upper)

func _draw_building_labels() -> void:
	for label_data: Dictionary in BUILDING_LABELS:
		var label := Label.new()
		label.text = label_data["text"]
		label.position = Vector2(label_data["grid"] * TILE_SIZE) + Vector2(0, -14)
		label.add_theme_color_override("font_color", Color("f6df79"))
		label.add_theme_color_override("font_shadow_color", Color("1a1612"))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
		label.z_index = 5
		building_layer.add_child(label)

func _draw_shop_awnings() -> void:
	for awning_data: Dictionary in _shop_awnings:
		var awning_id: String = awning_data["id"]
		var texture: Texture2D = _load_shop_awning(awning_id)
		if not texture:
			continue
		var sprite := Sprite2D.new()
		sprite.name = "ShopAwning_%s" % awning_id
		sprite.texture = texture
		sprite.centered = false
		sprite.position = Vector2(awning_data["grid"] * TILE_SIZE) + awning_data["offset"]
		sprite.z_index = 2
		building_upper_layer.add_child(sprite)

func _load_shop_awning(awning_id: String) -> Texture2D:
	if _shop_awning_textures.has(awning_id):
		return _shop_awning_textures[awning_id]
	var texture := SpriteCache.town_awning(awning_id)
	_shop_awning_textures[awning_id] = texture
	return texture

func _draw_props() -> void:
	if not _quiet_props:
		_draw_town_props()
		_draw_shop_signs()
		return
	_draw_town_props()
	_draw_shop_signs()

func _add_prop(grid: Vector2i, region: Rect2i, scale_amount: float) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = _quiet_props
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.centered = false
	sprite.position = Vector2(grid * TILE_SIZE)
	sprite.scale = Vector2(scale_amount, scale_amount)
	prop_layer.add_child(sprite)

func _draw_shop_signs() -> void:
	for sign_data: Dictionary in _shop_signs:
		var sign_id: String = sign_data["id"]
		var texture: Texture2D = _load_shop_sign(sign_id)
		if not texture:
			continue
		var sprite := Sprite2D.new()
		sprite.name = "ShopSign_%s" % sign_id
		sprite.texture = texture
		sprite.centered = true
		sprite.position = Vector2(sign_data["grid"] * TILE_SIZE) + sign_data["offset"]
		sprite.scale = Vector2(0.68, 0.68)
		sprite.z_index = 5
		prop_layer.add_child(sprite)

func _load_shop_sign(sign_id: String) -> Texture2D:
	if _shop_sign_textures.has(sign_id):
		return _shop_sign_textures[sign_id]
	var texture := SpriteCache.town_sign(sign_id)
	_shop_sign_textures[sign_id] = texture
	return texture

func _draw_town_props() -> void:
	for prop_data: Dictionary in _town_props:
		var prop_id: String = prop_data["id"]
		var texture: Texture2D = _load_town_prop(prop_id)
		if not texture:
			continue
		var sprite := Sprite2D.new()
		sprite.name = "TownProp_%s" % prop_id
		sprite.texture = texture
		sprite.centered = true
		sprite.position = Vector2(prop_data["grid"] * TILE_SIZE) + prop_data["offset"]
		sprite.scale = Vector2(prop_data.get("scale", 0.6), prop_data.get("scale", 0.6))
		sprite.rotation = deg_to_rad(prop_data.get("rotation", 0.0))
		sprite.z_index = 3
		var prop_scale: float = prop_data.get("scale", 0.6)
		var shadow_width := clampf(sprite.texture.get_width() * prop_scale * 0.7, 10.0, 34.0)
		_add_soft_shadow(prop_layer, sprite.position + Vector2(-shadow_width / 2.0, 5), Vector2(shadow_width, 5), 2)
		prop_layer.add_child(sprite)

func _load_town_prop(prop_id: String) -> Texture2D:
	if _town_prop_textures.has(prop_id):
		return _town_prop_textures[prop_id]
	var texture := SpriteCache.town_prop(prop_id)
	_town_prop_textures[prop_id] = texture
	return texture


func _build_npc_positions() -> void:
	npc_positions.clear()
	var phase: String = GameData.get_day_phase()
	_npc_positions_phase = phase
	for npc_id: String in NPC_IDS:
		var home: Vector2i = NPCDB.get_npc_position(npc_id, phase)
		if home.x >= 0:
			npc_positions[home] = npc_id
			_npc_wander_pos[npc_id] = home

func _draw_npcs() -> void:
	_load_npc_textures()
	for npc_id: String in NPC_IDS:
		var marker := Sprite2D.new()
		var pixel_art_texture: Texture2D = _npc_idle_textures.get(npc_id, null)
		if pixel_art_texture:
			marker.texture = pixel_art_texture
			marker.centered = true
			marker.scale = Vector2(0.42, 0.42)
			marker.z_index = 4
		elif _town_atlas:
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

func _load_npc_textures() -> void:
	for npc_id: String in NPC_IDS:
		if _npc_idle_textures.has(npc_id):
			continue
		_npc_idle_textures[npc_id] = SpriteCache.character_rotation("town_npcs/%s" % npc_id, "south")

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
	var phase: String = GameData.get_day_phase()
	if phase == _npc_positions_phase:
		return
	for npc_id: String in NPC_IDS:
		var home: Vector2i = NPCDB.get_npc_position(npc_id, phase)
		_npc_wander_pos[npc_id] = home
	_build_npc_positions()
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
	_update_cat_animation(delta)
	_wander_timer += delta
	if _wander_timer >= WANDER_INTERVAL:
		_wander_timer -= WANDER_INTERVAL
		_wander_one_npc()
		_wander_cat()

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
		if next.x < 0 or next.x >= _town_map[0].length() or next.y < 0 or next.y >= _town_map.size():
			continue
		if BLOCKED.has(_town_map[next.y].substr(next.x, 1)):
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
		if next == _cat_pos:
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

func _draw_cat() -> void:
	_load_cat_textures()
	_cat_marker = Sprite2D.new()
	_cat_marker.name = "PixelLabCat"
	_cat_marker.centered = true
	_cat_marker.scale = Vector2(0.32, 0.32)
	_cat_marker.z_index = 4
	_cat_marker.texture = _cat_idle_textures.get("south", null)
	_cat_marker.position = _grid_center(_cat_pos) + Vector2(0, -6)
	map_layer.add_child(_cat_marker)

func _load_cat_textures() -> void:
	for dir_name in ["south", "east", "north", "west"]:
		_cat_idle_textures[dir_name] = SpriteCache.character_rotation("cat", dir_name)
		var frames: Array = []
		for i in range(6):
			var frame_tex := SpriteCache.character_walk_frame("cat", dir_name, i)
			if frame_tex:
				frames.append(frame_tex)
		_cat_walk_frames[dir_name] = frames

func _wander_cat() -> void:
	if not _cat_marker:
		return
	if randf() > 0.85:
		return
	var dirs := [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	dirs.shuffle()
	for dir: Vector2i in dirs:
		var next := _cat_pos + dir
		if _is_blocked(next):
			continue
		if next == pos:
			continue
		if abs(next.x - _cat_home.x) + abs(next.y - _cat_home.y) > _cat_wander_radius:
			continue
		var occupied := false
		for npc_id: String in _npc_wander_pos:
			if _npc_wander_pos[npc_id] == next:
				occupied = true
				break
		if occupied:
			continue
		_cat_pos = next
		_cat_facing = dir
		_cat_frame = 0
		_cat_marker.position = _grid_center(_cat_pos) + Vector2(0, -6)
		_set_cat_texture()
		return

func _update_cat_animation(delta: float) -> void:
	if not _cat_marker:
		return
	_cat_anim_timer += delta
	if _cat_anim_timer < CAT_FRAME_TIME:
		return
	_cat_anim_timer = 0.0
	var dir_name := _cat_direction_name(_cat_facing)
	var frames: Array = _cat_walk_frames.get(dir_name, [])
	if frames.is_empty():
		return
	_cat_frame = (_cat_frame + 1) % frames.size()
	_cat_marker.texture = frames[_cat_frame]

func _set_cat_texture() -> void:
	var dir_name := _cat_direction_name(_cat_facing)
	var frames: Array = _cat_walk_frames.get(dir_name, [])
	if not frames.is_empty():
		_cat_marker.texture = frames[_cat_frame]
	else:
		_cat_marker.texture = _cat_idle_textures.get(dir_name, _cat_idle_textures.get("south", null))

func _cat_direction_name(dir: Vector2i) -> String:
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

func _grid_center(grid: Vector2i) -> Vector2:
	return Vector2(grid * TILE_SIZE) + Vector2(TILE_SIZE / 2, TILE_SIZE / 2)

func _update_player() -> void:
	_refresh_npcs()
	_apply_day_tint()
	player_sprite.position = Vector2(pos * TILE_SIZE) + Vector2(TILE_SIZE / 2, TILE_SIZE / 2)
	_update_camera()
	_update_player_texture()
	if _town_atlas and not player_sprite.has_node("Sprite"):
		var sprite := Sprite2D.new()
		sprite.name = "Sprite"
		sprite.texture = _town_atlas
		sprite.region_enabled = true
		sprite.region_rect = PLAYER_RECT
		player_sprite.add_child(sprite)
		if player_sprite.has_node("Body"):
			player_sprite.get_node("Body").visible = false
	_update_player_texture()

func _update_player_texture() -> void:
	if player_sprite.has_node("Sprite"):
		var sprite: Sprite2D = player_sprite.get_node("Sprite")
		var dir_name := _cat_direction_name(facing)
		if _player_idle_textures.is_empty():
			_load_player_textures()
		var texture: Texture2D = _player_idle_textures.get(dir_name, _player_idle_textures.get("south", null))
		if texture:
			sprite.texture = texture
			sprite.region_enabled = false
			sprite.centered = true
			sprite.scale = Vector2(0.42, 0.42)
			sprite.z_index = 4
			if player_sprite.has_node("Body"):
				player_sprite.get_node("Body").visible = false

func _load_player_textures() -> void:
	for dir_name in ["south", "east", "north", "west"]:
		_player_idle_textures[dir_name] = SpriteCache.character_rotation("player", dir_name)

func _configure_camera() -> void:
	if not camera:
		return
	camera.anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	camera.limit_enabled = true
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = _town_map[0].length() * TILE_SIZE
	camera.limit_bottom = _town_map.size() * TILE_SIZE
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
		_update_hud()
		return
	pos = next
	_update_player()
	_check_exit()
	_update_hud()

func _is_blocked(grid: Vector2i) -> bool:
	if grid.x < 0 or grid.x >= _town_map[0].length() or grid.y < 0 or grid.y >= _town_map.size():
		return true
	if grid == _cat_pos:
		return true
	return BLOCKED.has(_town_map[grid.y].substr(grid.x, 1))

func _check_exit() -> void:
	if pos.y >= _town_map.size() - 1:
		_exit_to_overworld()

func _is_exit_step(dir: Vector2i) -> bool:
	return dir == Vector2i.DOWN and pos.y >= _town_map.size() - 2

func _exit_to_overworld() -> void:
	GameData.overworld_position = GameData.get_meta("overworld_return_position", GameData.overworld_position)
	GameData.overworld_facing = GameData.get_meta("overworld_return_facing", Vector2i.DOWN)
	SceneTransition.change_scene("res://scenes/overworld/overworld.tscn")

func _interact() -> void:
	var target := pos + facing
	if target == _cat_pos:
		_say("[color=#f0a46a]Tabby[/color]: Mrrp.\n\nThe little cat winds around your boots, then pads back toward the tavern.")
		return
	var npc: String = npc_positions.get(target, "")

	if npc == "":
		npc = _building_door_at(target)
	if npc == "":
		npc = _building_door_at(pos)
	if npc == "":
		_say(_nothing_here_text(target))
		return
	if npc == "tinkerer" and (_building_door_at(target) == "tinkerer" or _building_door_at(pos) == "tinkerer"):
		SceneTransition.change_scene("res://scenes/workshop/workshop.tscn")
		return
	if npc == "realtor" and (_building_door_at(target) == "realtor" or _building_door_at(pos) == "realtor"):
		var door_grid := target if _building_door_at(target) == "realtor" else pos
		var house_id := _house_id_at_door(door_grid)
		GameData.set_meta("house_id", house_id)
		GameData.set_meta("house_door_pos", Vector2i(door_grid.x, door_grid.y + 1))
		SceneTransition.change_scene("res://scenes/house_interior/house_interior.tscn")
		return

	_start_npc_interaction(npc)

func _apply_return_spawn() -> void:
	if GameData.has_meta("town_spawn_pos"):
		pos = GameData.get_meta("town_spawn_pos", pos)
		GameData.remove_meta("town_spawn_pos")
	if GameData.has_meta("town_spawn_facing"):
		facing = GameData.get_meta("town_spawn_facing", facing)
		GameData.remove_meta("town_spawn_facing")

func _building_door_at(grid: Vector2i) -> String:
	var exact: String = _building_doors.get(grid, "")
	if exact != "":
		return exact
	for building_data: Dictionary in _town_buildings:
		var building_id: String = building_data["id"]
		var interaction: Dictionary = _building_interactions.get(building_id, {})
		if interaction.is_empty():
			continue
		var door_offset: Vector2i = interaction["door_offset"]
		var door_width: int = interaction.get("door_width", 1)
		var door_start: Vector2i = building_data["grid"] + door_offset
		for dx in range(door_width):
			if grid == door_start + Vector2i(dx, 0):
				return interaction["npc"]
	return ""

func _house_id_at_door(grid: Vector2i) -> String:
	## Returns the building id of the residential house whose door matches grid.
	for building_data: Dictionary in _town_buildings:
		var building_id: String = building_data["id"]
		var interaction: Dictionary = _building_interactions.get(building_id, {})
		if interaction.get("npc", "") != "realtor":
			continue
		var door_offset: Vector2i = interaction["door_offset"]
		var door_width: int = interaction.get("door_width", 1)
		var door_start: Vector2i = building_data["grid"] + door_offset
		for dx in range(door_width):
			if grid == door_start + Vector2i(dx, 0):
				return building_id
	return "small_house"  # fallback

func _door_label_at(grid: Vector2i) -> String:
	for building_data: Dictionary in _town_buildings:
		var building_id: String = building_data["id"]
		var interaction: Dictionary = _building_interactions.get(building_id, {})
		if interaction.is_empty():
			continue
		var door_offset: Vector2i = interaction["door_offset"]
		var door_width: int = interaction.get("door_width", 1)
		var door_start: Vector2i = building_data["grid"] + door_offset
		for dx in range(door_width):
			if grid == door_start + Vector2i(dx, 0):
				return interaction["name"]
	return ""

func _nothing_here_text(target: Vector2i) -> String:
	if target.y < pos.y:
		return "Nothing responds here.\n\nFace a villager or a labeled doorway, then press Interact. Elder Hall is at the north end of town."
	if target.y > pos.y:
		return "The south road leads back to the overworld. Walk down past the last path tile to leave Brindlewick."
	return "Nothing here.\n\nFace a villager or a building door, then press Interact."

func _show_arrival_hint() -> void:
	if GameData.is_quest_complete("the_dead_wick") and QuestDB.get_next_story_quest() == "the_missing_keeper":
		_say("[color=#f0d46a]The lighthouse burns again.[/color]\n\nReturn to Elder Hall at the north end of town and speak with Old Thatch.")
	elif GameData.is_quest_active("the_dead_wick"):
		_say("[color=#f0d46a]Current objective:[/color] Relight the lighthouse wick east of Brindlewick.\n\nLeave by walking south out of town, then follow the overworld path east.")
	elif QuestDB.get_next_story_quest() == "the_dead_wick":
		_say("[color=#f0d46a]First stop:[/color] Elder Hall at the north end of town.\n\nFace Old Thatch or the Elder Hall door and press Interact.")

func _start_npc_interaction(npc: String) -> void:
	talking_to = npc
	recruit_mode = false

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
		GameData.add_crafted_item(TinkerDB.create_crafted_item(recipe))
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
	var buff := GameData.apply_meal_buff(item["name"], hp)
	_say("[color=green]Cooked %s![/color]\n%s\n[color=#9fc5ff]Well fed: DEF +%d for the next %d battles.[/color]" % [item["name"], ", ".join(healed_names), buff["def"], buff["battles"]])
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
		"equipment": GameData.create_empty_equipment(),
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
	GameData.ensure_party_equipment()
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
	lines.append("[color=#888]Walk south out of town to return to the overworld. Press J on the overworld to review your journal.[/color]")
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
	var prompt := _interaction_prompt()
	if prompt != "":
		lines.append("")
		lines.append(prompt)
	dialog.text = "[b]Brindlewick[/b]    %s    Tonics: %d\n\n%s" % [GameData.format_money_short(), GameData.tonics, "\n".join(lines)]

func _interaction_prompt() -> String:
	var target := pos + facing
	if target == _cat_pos:
		return "[color=#f0d46a]Interact:[/color] Pet Tabby"
	var door_npc := _building_door_at(target)
	var door_label := _door_label_at(target)
	if door_npc == "":
		door_npc = _building_door_at(pos)
		door_label = _door_label_at(pos)
	if door_npc != "":
		if door_label == "":
			door_label = NPCDB.get_npc_name(door_npc)
		return "[color=#f0d46a]Interact:[/color] Enter %s" % door_label
	var npc: String = npc_positions.get(target, "")
	if npc != "":
		return "[color=#f0d46a]Interact:[/color] Talk to %s" % NPCDB.get_npc_name(npc)
	if target.y >= _town_map.size() - 1 or pos.y >= _town_map.size() - 2:
		return "[color=#f0d46a]Move south:[/color] Leave town"
	return ""

func _clear_editor_nodes() -> void:
	for layer in [map_layer, building_layer, prop_layer, building_upper_layer]:
		if not layer:
			continue
		for child in layer.get_children():
			child.queue_free()

func _load_layout_from_json() -> void:
	_clear_editor_nodes()
	
	var layout := TownLayout.load_from_file(TOWN_LAYOUT_PATH, _default_town_layout())
	if layout.is_empty():
		push_error("Could not load town layout to editor.")
		return
	
	_town_map = layout["map"]
	_town_buildings = layout["buildings"]
	_shop_signs = layout["shop_signs"]
	_shop_awnings = layout["shop_awnings"]
	_town_props = layout["props"]
	_building_doors = layout["doors"]
	_building_interactions = layout["building_interactions"]
	
	_load_town_atlas()
	_load_quiet_village_assets()
	_draw_map()
	
	for building_data: Dictionary in _town_buildings:
		var building_id: String = building_data["id"]
		var container := Node2D.new()
		container.name = "Building_%s" % building_id
		container.position = Vector2(building_data["grid"] * TILE_SIZE)
		building_layer.add_child(container)
		container.owner = get_tree().edited_scene_root
		
		var texture: Texture2D = _load_shop_building(building_id)
		if texture:
			var sprite := Sprite2D.new()
			sprite.name = "Sprite"
			sprite.texture = texture
			sprite.centered = false
			sprite.z_index = 2
			container.add_child(sprite)
			sprite.owner = get_tree().edited_scene_root
		elif _quiet_buildings:
			var sprite := Sprite2D.new()
			sprite.name = "Sprite"
			sprite.texture = _quiet_buildings
			sprite.region_enabled = true
			sprite.region_rect = building_data["fallback_region"]
			sprite.centered = false
			sprite.scale = Vector2(building_data["fallback_scale"], building_data["fallback_scale"])
			sprite.z_index = 2
			container.add_child(sprite)
			sprite.owner = get_tree().edited_scene_root
			
		for sign_data: Dictionary in _shop_signs:
			if sign_data["id"] == building_id:
				var sign_texture: Texture2D = _load_shop_sign(building_id)
				if sign_texture:
					var sign_sprite := Sprite2D.new()
					sign_sprite.name = "Sign"
					sign_sprite.texture = sign_texture
					sign_sprite.centered = true
					var rel_grid := Vector2(sign_data["grid"] - building_data["grid"])
					sign_sprite.position = rel_grid * TILE_SIZE + sign_data["offset"]
					sign_sprite.scale = Vector2(0.68, 0.68)
					sign_sprite.z_index = 5
					container.add_child(sign_sprite)
					sign_sprite.owner = get_tree().edited_scene_root
					
		for awning_data: Dictionary in _shop_awnings:
			if awning_data["id"] == building_id:
				var awning_texture: Texture2D = _load_shop_awning(building_id)
				if awning_texture:
					var awning_sprite := Sprite2D.new()
					awning_sprite.name = "Awning"
					awning_sprite.texture = awning_texture
					awning_sprite.centered = false
					var rel_grid := Vector2(awning_data["grid"] - building_data["grid"])
					awning_sprite.position = rel_grid * TILE_SIZE + awning_data["offset"]
					awning_sprite.z_index = 4
					container.add_child(awning_sprite)
					awning_sprite.owner = get_tree().edited_scene_root
					
	for prop_data: Dictionary in _town_props:
		var prop_id: String = prop_data["id"]
		var texture: Texture2D = _load_town_prop(prop_id)
		if texture:
			var sprite := Sprite2D.new()
			sprite.name = "Prop_%s" % prop_id
			sprite.texture = texture
			sprite.centered = true
			sprite.position = Vector2(prop_data["grid"] * TILE_SIZE) + prop_data["offset"]
			sprite.scale = Vector2(prop_data.get("scale", 0.6), prop_data.get("scale", 0.6))
			sprite.rotation = deg_to_rad(prop_data.get("rotation", 0.0))
			sprite.z_index = 3
			prop_layer.add_child(sprite)
			sprite.owner = get_tree().edited_scene_root

func _save_layout_to_json() -> void:
	var file_content := ""
	if FileAccess.file_exists(TOWN_LAYOUT_PATH):
		var file := FileAccess.open(TOWN_LAYOUT_PATH, FileAccess.READ)
		if file:
			file_content = file.get_as_text()
			
	var layout: Dictionary = {}
	if file_content != "":
		var parsed = JSON.parse_string(file_content)
		if parsed is Dictionary:
			layout = parsed
			
	if layout.is_empty():
		push_error("Could not load original layout file to update it.")
		return
		
	var orig_buildings: Array = layout.get("buildings", [])
	var new_buildings: Array = []
	var new_signs: Array = []
	var new_awnings: Array = []
	
	var orig_build_map := {}
	for b: Dictionary in orig_buildings:
		orig_build_map[b["id"]] = b
		
	for child in building_layer.get_children():
		if child is Node2D and child.name.begins_with("Building_"):
			var building_id: String = child.name.replace("Building_", "")
			var b_pos: Vector2 = child.position
			var grid_x: int = int(round(b_pos.x / TILE_SIZE))
			var grid_y: int = int(round(b_pos.y / TILE_SIZE))
			
			var orig: Dictionary = orig_build_map.get(building_id, {
				"id": building_id,
				"size": [6, 4],
				"plaque": "plaque_blank",
				"fallback_region": [14, 16, 118, 72],
				"fallback_scale": 0.55
			})
			
			var entry: Dictionary = orig.duplicate(true)
			entry["grid"] = [grid_x, grid_y]
			new_buildings.append(entry)
			
			var sign_node = child.get_node_or_null("Sign")
			if sign_node:
				var sign_pos: Vector2 = sign_node.position
				var global_sign_pos: Vector2 = child.position + sign_pos
				var s_grid_x: int = int(round(global_sign_pos.x / TILE_SIZE))
				var s_grid_y: int = int(round(global_sign_pos.y / TILE_SIZE))
				var offset_x = global_sign_pos.x - s_grid_x * TILE_SIZE
				var offset_y = global_sign_pos.y - s_grid_y * TILE_SIZE
				new_signs.append({
					"id": building_id,
					"grid": [s_grid_x, s_grid_y],
					"offset": [offset_x, offset_y]
				})
				
			var awning_node = child.get_node_or_null("Awning")
			if awning_node:
				var awning_pos: Vector2 = awning_node.position
				var global_awning_pos: Vector2 = child.position + awning_pos
				var a_grid_x: int = int(round(global_awning_pos.x / TILE_SIZE))
				var a_grid_y: int = int(round(global_awning_pos.y / TILE_SIZE))
				var offset_x = global_awning_pos.x - a_grid_x * TILE_SIZE
				var offset_y = global_awning_pos.y - a_grid_y * TILE_SIZE
				new_awnings.append({
					"id": building_id,
					"grid": [a_grid_x, a_grid_y],
					"offset": [offset_x, offset_y]
				})
				
	layout["buildings"] = new_buildings
	layout["shop_signs"] = new_signs
	layout["shop_awnings"] = new_awnings
	
	var new_props: Array = []
	for child in prop_layer.get_children():
		if child is Sprite2D and child.name.begins_with("Prop_"):
			var prop_id: String = child.name.replace("Prop_", "")
			var parts: PackedStringArray = prop_id.split("@")
			prop_id = parts[0].strip_edges()
			
			var regex: RegEx = RegEx.new()
			regex.compile("^([A-Za-z_]+)\\d*$")
			var match_res = regex.search(prop_id)
			if match_res:
				prop_id = match_res.get_string(1)
				
			var p_pos: Vector2 = child.position
			var grid_x: int = int(round(p_pos.x / TILE_SIZE))
			var grid_y: int = int(round(p_pos.y / TILE_SIZE))
			var offset_x = p_pos.x - grid_x * TILE_SIZE
			var offset_y = p_pos.y - grid_y * TILE_SIZE
			
			var prop_entry = {
				"id": prop_id,
				"grid": [grid_x, grid_y],
				"offset": [offset_x, offset_y],
				"scale": child.scale.x
			}
			if abs(child.rotation) > 0.001:
				prop_entry["rotation"] = round(rad_to_deg(child.rotation))
				
			new_props.append(prop_entry)
			
	layout["props"] = new_props
	
	var new_doors: Array = []
	var interactions: Dictionary = layout.get("building_interactions", {})
	
	for b in new_buildings:
		var building_id: String = b["id"]
		var inter: Dictionary = interactions.get(building_id, {})
		if not inter.is_empty():
			var npc = inter.get("npc", "")
			var door_offset = inter.get("door_offset", [0, 0])
			var door_width = inter.get("door_width", 1)
			
			var b_grid = b["grid"]
			for dx in range(door_width):
				var d_grid = [b_grid[0] + door_offset[0] + dx, b_grid[1] + door_offset[1]]
				new_doors.append({
					"grid": d_grid,
					"npc": npc
				})
				
	layout["doors"] = new_doors
	
	var current_map: Array = layout.get("map", [])
	if not current_map.is_empty():
		var mutable_map := []
		for row in current_map:
			var chars := []
			for i in range(row.length()):
				chars.append(row.substr(i, 1))
			mutable_map.append(chars)
			
		for y in range(mutable_map.size()):
			for x in range(mutable_map[y].size()):
				if mutable_map[y][x] == "H":
					mutable_map[y][x] = ","
					
		for b in new_buildings:
			var bg = b["grid"]
			var bs = b["size"]
			for dy in range(bs[1]):
				var y = bg[1] + dy
				if y >= 0 and y < mutable_map.size():
					for dx in range(bs[0]):
						var x = bg[0] + dx
						if x >= 0 and x < mutable_map[y].size():
							mutable_map[y][x] = "H"
							
		var string_map := []
		for row_chars in mutable_map:
			string_map.append("".join(row_chars))
			
		layout["map"] = string_map
		
	var file := FileAccess.open(TOWN_LAYOUT_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(layout, "  ") + "\n")
		print("Successfully saved town layout to JSON!")
	else:
		push_error("Could not write updated layout back to path.")
