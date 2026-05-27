# Home — player's house interior with storage, rest, cooking, garden
extends Node2D

const TILE_SIZE := 16

const AlchemyDB := preload("res://scripts/data/alchemy.gd")
const TinkerDB := preload("res://scripts/data/tinkering.gd")

const MAP := [
	"################",
	"#..............#",
	"#..BB..KK..GGTT#",
	"#..BB..KK..GGTT#",
	"#..............#",
	"#.....@@.......#",
	"#.....@@.......#",
	"#..............#",
	"#..MM....WW....#",
	"#..MM....WW....#",
	"#....RR........#",
	"################",
]

const COLORS := {
	"#": Color("5a4a3a"), ".": Color("b08850"), "B": Color("4a6741"),
	"K": Color("8b6914"), "G": Color("27ae60"), "M": Color("7f8c8d"),
	"W": Color("6a4a3a"),
	"R": Color("9b59b6"),
		"T": Color("f0d46a"),
	"@" : Color("6a5a4a"),
}

const BLOCKED := {"#": true, "@": true}

const INTERACTABLES := {
	"B": "bed",
	"K": "kitchen",
	"G": "garden",
	"M": "beacon_map",
	"W": "workbench",
	"R": "guest_room",
		"T": "trophy",
}

const HOME_UPGRADES := [
	{"id": "bed", "name": "Quality Bed", "desc": "Full heal when resting at home", "price": 500},
	{"id": "chest", "name": "Storage Chest", "desc": "Store up to 10 extra items", "price": 300},
	{"id": "kitchen", "name": "Kitchen", "desc": "Cook fish into meals for party buffs", "price": 800},
	{"id": "garden", "name": "Herb Garden", "desc": "Grow herbs for alchemy", "price": 600},
	{"id": "guest_room", "name": "Guest Room", "desc": "Housing party members improves loyalty", "price": 1200},
	{"id": "beacon_map", "name": "Beacon Map", "desc": "Wall map showing all beacon tower states", "price": 200},
	{"id": "workbench", "name": "Workbench", "desc": "Craft tools and repair equipment", "price": 700},
]

var pos: Vector2i = Vector2i(8, 10)
var facing: Vector2i = Vector2i.UP
var walking: bool = false
var walk_timer: float = 0.0
var storage_mode: bool = false
var storage_idx: int = 0
var cooking_mode: bool = false
var cook_idx: int = 0
var garden_mode: bool = false
var garden_timer: float = 0.0
var alchemy_mode: bool = false
var alchemy_idx: int = 0
var kitchen_menu: bool = false
var tinkering_mode: bool = false
var tinker_idx: int = 0
var trophy_mode: bool = false

@onready var map_layer: Node2D = $MapLayer
@onready var player_sprite: Node2D = $PlayerSprite
@onready var dialog: RichTextLabel = $Dialog

func _ready() -> void:
	_draw_map()
	_update_player()
	_update_hud()
	garden_timer = GameData.get_meta("home_garden_timer", 0.0)

func _draw_map() -> void:
	for y in range(MAP.size()):
		for x in range(MAP[y].length()):
			var tile: String = MAP[y].substr(x, 1)
			var rect := ColorRect.new()
			rect.color = COLORS.get(tile, Color.MAGENTA)
			rect.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
			rect.size = Vector2(TILE_SIZE, TILE_SIZE)
			map_layer.add_child(rect)
	# Draw storage chest if installed
	if GameData.has_upgrade("chest"):
		var chest_pos := Vector2i(12, 5)
		var marker := ColorRect.new()
		marker.color = Color("8b6914")
		marker.position = Vector2(chest_pos * TILE_SIZE) + Vector2(2, 2)
		marker.size = Vector2(12, 12)
		map_layer.add_child(marker)

func _update_player() -> void:
	player_sprite.position = Vector2(pos * TILE_SIZE) + Vector2(TILE_SIZE / 2, TILE_SIZE / 2)

func _process(delta: float) -> void:
	if walking:
		walk_timer -= delta
		if walk_timer <= 0:
			walking = false
		_update_player()
	# Garden growth timer
	if GameData.has_upgrade("garden"):
		garden_timer += delta
		if garden_timer >= 60.0:
			garden_timer -= 60.0
			_grow_herbs()
		GameData.set_meta("home_garden_timer", garden_timer)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if walking:
		return

	if storage_mode:
		_handle_storage_input(event.keycode)
		return
	if cooking_mode:
		_handle_cook_input(event.keycode)
		return
	if garden_mode:
		_handle_garden_input(event.keycode)
		return
	if kitchen_menu:
		_handle_kitchen_menu(event.keycode)
		return
	if alchemy_mode:
		_handle_alchemy_input(event.keycode)
		return
	if tinkering_mode:
		_handle_tinkering_input(event.keycode)
		return
	if trophy_mode:
		trophy_mode = false
		_update_hud()
		return
	var dir := Vector2i.ZERO
	if Input.is_action_just_pressed("move_up"):    dir = Vector2i.UP
	elif Input.is_action_just_pressed("move_down"):  dir = Vector2i.DOWN
	elif Input.is_action_just_pressed("move_left"):  dir = Vector2i.LEFT
	elif Input.is_action_just_pressed("move_right"): dir = Vector2i.RIGHT
	elif Input.is_action_just_pressed("interact"):
		_interact()
		return
	elif event.keycode == KEY_ESCAPE:
		SceneTransition.change_scene("res://scenes/overworld/overworld.tscn")
		return

	if dir != Vector2i.ZERO:
		_try_move(dir)

func _try_move(dir: Vector2i) -> void:
	facing = dir
	if _is_exit_step(dir):
		SceneTransition.change_scene("res://scenes/overworld/overworld.tscn")
		return
	var next := pos + dir
	if _is_blocked(next):
		return
	pos = next
	walking = true
	walk_timer = 0.12
	_update_player()
	_check_exit()

func _is_blocked(grid: Vector2i) -> bool:
	if grid.x < 0 or grid.x >= MAP[0].length() or grid.y < 0 or grid.y >= MAP.size():
		return true
	return BLOCKED.has(MAP[grid.y].substr(grid.x, 1))

func _check_exit() -> void:
	if pos.y >= MAP.size() - 1:
		# Position is already saved from overworld transition
		SceneTransition.change_scene("res://scenes/overworld/overworld.tscn")

func _is_exit_step(dir: Vector2i) -> bool:
	return dir == Vector2i.DOWN and pos.y >= MAP.size() - 2

func _interact() -> void:
	var target := pos + facing
	var tile := _tile(target)

	match tile:
		"B":
			_interact_bed()
		"K":
			_interact_kitchen()
		"G":
			_interact_garden()
		"M":
			_interact_beacon_map()
		"W":
			_interact_workbench()
		"R":
			_interact_guest_room()
		"T":
			_interact_trophy()
		_:
			if _is_chest(target):
				_interact_chest()
			else:
				_say("Nothing here.")

func _tile(grid: Vector2i) -> String:
	if grid.x < 0 or grid.x >= MAP[0].length() or grid.y < 0 or grid.y >= MAP.size():
		return "#"
	return MAP[grid.y].substr(grid.x, 1)

func _is_chest(target: Vector2i) -> bool:
	return GameData.has_upgrade("chest") and target == Vector2i(12, 5)

# ── Bed ──────────────────────────────────────────────────────────────────
func _interact_bed() -> void:
	if GameData.has_upgrade("bed"):
		GameData.full_heal()
		_say("[color=green]You rest in your quality bed.[/color]\nParty fully healed! HP and magic restored.")
		if GameData.has_upgrade("guest_room"):
			for m: Dictionary in GameData.party:
				if m.get("wage", 0) > 0:
					m["loyalty"] = mini(m.get("loyalty", 50) + 3, 100)
	else:
		_say("A basic bed. Upgrade to a Quality Bed for full party healing.\n[current: Restores 20% HP]\n\n[1] Rest anyway")
		# Simple rest
		for m: Dictionary in GameData.party:
			if m["alive"]:
				m["hp"] = mini(m["hp"] + int(m["max_hp"] * 0.2), m["max_hp"])

# ── Kitchen ──────────────────────────────────────────────────────────────
func _interact_kitchen() -> void:
	if not GameData.has_upgrade("kitchen"):
		_say("An empty counter. Install a Kitchen upgrade to cook here.")
		return
	kitchen_menu = true
	_show_kitchen_menu()


func _get_cookable_fish() -> Array:
	var fish_items: Array = []
	for i in range(GameData.trade_goods.size()):
		var item: Dictionary = GameData.trade_goods[i]
		if item.get("cooking", {}).get("hp", 0) > 0:
			fish_items.append({"idx": i, "item": item})
	return fish_items

func _show_cook() -> void:
	var lines: Array = []
	lines.append("[b]Home Kitchen[/b]")
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
	GameData.trade_goods.remove_at(entry["idx"])
	var healed_names: Array = []
	for m: Dictionary in GameData.party:
		if m["alive"]:
			var actual := mini(hp, m["max_hp"] - m["hp"])
			m["hp"] += actual
			healed_names.append("%s +%d" % [m["name"], actual])
	GameData.track_skill_use("cooking", 1)
	_say("[color=green]Cooked %s![/color]\n%s" % [item["name"], ", ".join(healed_names)])
	cooking_mode = false

# ── Garden ───────────────────────────────────────────────────────────────
func _interact_garden() -> void:
	if not GameData.has_upgrade("garden"):
		_say("An empty patch of dirt. Install an Herb Garden to grow alchemy ingredients.")
		return
	garden_mode = true
	_show_garden()

func _show_garden() -> void:
	var lines: Array = []
	lines.append("[b]Herb Garden[/b]")
	lines.append("")
	# Show current herbs in bag
	var herb_lines: Array = []
	for herb_id: String in GameData.herb_bag:
		var count: int = GameData.herb_bag[herb_id]
		if count > 0:
			herb_lines.append("%s x%d" % [herb_id.replace("_", " ").capitalize(), count])
	if not herb_lines.is_empty():
		lines.append("Herbs: %s" % ", ".join(herb_lines))
	else:
		lines.append("No herbs in bag.")
	lines.append("")
	# Show growth timer
	var time_left := 60.0 - garden_timer
	lines.append("Next harvest in: %ds" % int(time_left))
	lines.append("")
	lines.append("[1] Harvest available herbs  [Esc] Back")
	_say("\n".join(lines))

func _handle_garden_input(keycode: int) -> void:
	match keycode:
		KEY_1, KEY_ENTER, KEY_SPACE:
			_harvest_garden()
		KEY_ESCAPE:
			garden_mode = false
			_update_hud()

func _harvest_garden() -> void:
	# Garden grows 1-2 random herbs per cycle
	var rng := RandomNumberGenerator.new()
	var harvested: Array = []
	var herbs := ["sea_kelp", "forest_moss", "wild_sage", "fog_petals"]
	var skill_bonus := GameData.get_skill_bonus("alchemy")
	var count := 1 + mini(skill_bonus, 2)
	for _i in range(count):
		var herb: String = herbs[rng.randi() % herbs.size()]
		GameData.add_herb(herb, 1)
		harvested.append(herb.replace("_", " ").capitalize())
	GameData.track_skill_use("alchemy", 1)
	_say("[color=green]Harvested: %s[/color]" % ", ".join(harvested))
	garden_mode = false

func _grow_herbs() -> void:
	# Passive growth — timer-based, auto-harvests to bag
	pass

# ── Storage Chest ────────────────────────────────────────────────────────
func _interact_chest() -> void:
	if not GameData.has_upgrade("chest"):
		_say("No storage chest installed.")
		return
	storage_mode = true
	storage_idx = 0
	_show_storage()

func _show_storage() -> void:
	var lines: Array = []
	lines.append("[b]Storage Chest[/b] (%d/%d items)" % [GameData.home_storage.size(), 10])
	lines.append("")
	if GameData.home_storage.is_empty():
		lines.append("Chest is empty.")
	else:
		for i in range(GameData.home_storage.size()):
			var item: Dictionary = GameData.home_storage[i]
			var marker := "▶" if i == storage_idx else " "
			lines.append("%s %s" % [marker, item.get("name", item.get("id", "???"))])
	lines.append("")
	lines.append("[1] Withdraw item  [2] Deposit tonics (have %d)  [Esc] Back" % GameData.tonics)
	_say("\n".join(lines))

func _handle_storage_input(keycode: int) -> void:
	match keycode:
		KEY_UP:
			storage_idx = max(0, storage_idx - 1)
			_show_storage()
		KEY_DOWN:
			storage_idx = min(max(GameData.home_storage.size() - 1, 0), storage_idx + 1)
			_show_storage()
		KEY_1, KEY_ENTER, KEY_SPACE:
			_withdraw_item()
		KEY_2:
			_deposit_tonic()
		KEY_ESCAPE:
			storage_mode = false
			_update_hud()

func _withdraw_item() -> void:
	if GameData.home_storage.is_empty() or storage_idx >= GameData.home_storage.size():
		return
	var item: Dictionary = GameData.home_storage[storage_idx]
	GameData.home_storage.remove_at(storage_idx)
	# Check bag capacity before adding
	var _bt: String = item.get("type", "")
	if _bt == "weapon" and GameData.bag_full("weapons"):
		GameData.home_storage.insert(storage_idx, item)
		_say("[color=red]Weapons bag full![/color]")
		return
	elif _bt == "armor" and GameData.bag_full("armor"):
		GameData.home_storage.insert(storage_idx, item)
		_say("[color=red]Armor bag full![/color]")
		return
	elif _bt == "trade" and GameData.bag_full("trade"):
		GameData.home_storage.insert(storage_idx, item)
		_say("[color=red]Trade goods bag full![/color]")
		return
	# Add back to appropriate bag
	match item.get("type", ""):
		"weapon":
			GameData.weapons_bag.append(item)
		"armor":
			GameData.armor_bag.append(item)
		"tonic":
			GameData.tonics += item.get("count", 1)
		"trade":
			GameData.trade_goods.append(item)
		_:
			GameData.trade_goods.append(item)
	_say("[color=green]Withdrew %s.[/color]" % item.get("name", "item"))
	storage_idx = mini(storage_idx, max(GameData.home_storage.size() - 1, 0))
	if GameData.home_storage.is_empty():
		storage_mode = false
		_update_hud()
	else:
		_show_storage()

func _deposit_tonic() -> void:
	if GameData.tonics <= 0:
		_say("No tonics to deposit.")
		return
	if GameData.home_storage.size() >= 10:
		_say("Storage chest is full!")
		return
	GameData.tonics -= 1
	GameData.home_storage.append({"id": "tonic", "name": "Tonic", "type": "tonic", "count": 1})
	_show_storage()

# ── Beacon Map ───────────────────────────────────────────────────────────
func _interact_beacon_map() -> void:
	if not GameData.has_upgrade("beacon_map"):
		_say("An empty wall. Install a Beacon Map to track tower states.")
		return
	var lines: Array = []
	lines.append("[b]Beacon Map[/b]")
	lines.append("")
	var beacons := {
	"lighthouse": "Lighthouse",
	"north_forest": "North Forest",
	"hill_overlook": "Hill Overlook",
	"south_shore": "South Shore",
	"west_point": "West Point",
	}
	# Use the same positions as overworld
	var beacon_positions := {
	"lighthouse": Vector2i(25, 13),
	"north_forest": Vector2i(17, 13),
	"hill_overlook": Vector2i(24, 19),
	"south_shore": Vector2i(24, 23),
	"west_point": Vector2i(10, 26),
	}
	for bname: String in beacons:
		var bp: Vector2i = beacon_positions.get(bname, Vector2i(-1, -1))
		var lit: bool = GameData.beacon_states.get(str(bp), false)
		var status := "[color=green]LIT[/color]" if lit else "[color=red]UNLIT[/color]"
		lines.append("%-16s %s" % [beacons[bname], status])
	var lit_count: int = 0
	for bname: String in beacon_positions:
		if GameData.beacon_states.get(str(beacon_positions[bname]), false):
			lit_count += 1
	lines.append("")
	lines.append("Beacons lit: %d/%d" % [lit_count, beacon_positions.size()])
	lines.append("")
	lines.append("[Esc] Back")
	_say("\n".join(lines))

func _show_kitchen_menu() -> void:
	_say("[b]Kitchen[/b]\n\n[1] Cook fish\n[2] Alchemy crafting\n[Esc] Back")

func _handle_kitchen_menu(keycode: int) -> void:
	match keycode:
		KEY_1:
			kitchen_menu = false
			cooking_mode = true
			cook_idx = 0
			_show_cook()
		KEY_2:
			kitchen_menu = false
			alchemy_mode = true
			alchemy_idx = 0
			_show_alchemy()
		KEY_ESCAPE:
			kitchen_menu = false
			_update_hud()

func _show_alchemy() -> void:
	var lines: Array = []
	lines.append("[b]Alchemy Crafting[/b]")
	lines.append("")
	var skill_level := GameData.get_skill_bonus("alchemy")
	var recipes := AlchemyDB.available_recipes(skill_level)
	if recipes.is_empty():
		lines.append("No recipes available. Gather herbs to increase your skill.")
		lines.append("")
		lines.append("[Esc] Back")
		_say("\n".join(lines))
		return
	for i_r in range(recipes.size()):
		var recipe: Dictionary = recipes[i_r]
		var marker := "▶" if i_r == alchemy_idx else " "
		var can_craft := true
		var herb_str: String = ""
		for herb_id: int in recipe["herbs"]:
			var needed: int = recipe["herbs"][herb_id]
			var have: int = GameData.get_herb_count(AlchemyDB.HERB_INFO[herb_id]["id"])
			if have < needed:
				can_craft = false
			herb_str += "%s %d/%d  " % [AlchemyDB.get_herb_name(herb_id), have, needed]
		var dim := "" if can_craft else "[color=#666]"
		var dim_e := "" if can_craft else "[/color]"
		var sel_s := "[color=#f0d46a]" if i_r == alchemy_idx else ""
		var sel_e := "[/color]" if i_r == alchemy_idx else ""
		lines.append("%s%s%s%s %s — %s(x%d)%s" % [dim, marker, sel_s, recipe["name"], herb_str, recipe.get("output_count", 1), sel_e + dim_e])
	lines.append("")
	var herb_names: Array = []
	for herb_id: String in GameData.herb_bag:
		var count: int = GameData.herb_bag[herb_id]
		if count > 0:
			herb_names.append("%s x%d" % [herb_id.replace("_", " ").capitalize(), count])
	lines.append("Herbs: %s" % (", ".join(herb_names) if not herb_names.is_empty() else "None"))
	lines.append("")
	lines.append("[1]/Enter to craft, arrows to browse, [Esc] back")
	_say("\n".join(lines))

func _handle_alchemy_input(keycode: int) -> void:
	match keycode:
		KEY_UP:
			alchemy_idx = max(0, alchemy_idx - 1)
			_show_alchemy()
		KEY_DOWN:
			var skill_level := GameData.get_skill_bonus("alchemy")
			var recipes := AlchemyDB.available_recipes(skill_level)
			alchemy_idx = min(max(recipes.size() - 1, 0), alchemy_idx + 1)
			_show_alchemy()
		KEY_1, KEY_ENTER, KEY_SPACE:
			_try_craft()
		KEY_ESCAPE:
			alchemy_mode = false
			_update_hud()

func _try_craft() -> void:
	var skill_level := GameData.get_skill_bonus("alchemy")
	var recipes := AlchemyDB.available_recipes(skill_level)
	if recipes.is_empty() or alchemy_idx >= recipes.size():
		alchemy_mode = false
		return
	var recipe: Dictionary = recipes[alchemy_idx]
	for herb_id: int in recipe["herbs"]:
		var needed: int = recipe["herbs"][herb_id]
		var herb_str: String = AlchemyDB.HERB_INFO[herb_id]["id"]
		if GameData.get_herb_count(herb_str) < needed:
			_say("Not enough %s!" % AlchemyDB.get_herb_name(herb_id))
			return
	for herb_id: int in recipe["herbs"]:
		var needed: int = recipe["herbs"][herb_id]
		var herb_str: String = AlchemyDB.HERB_INFO[herb_id]["id"]
		GameData.remove_herb(herb_str, needed)
	var count: int = recipe.get("output_count", 1)
	var effect: Dictionary = recipe.get("effect", {})
	for _i in range(count):
		GameData.crafted_items.append({"id": recipe["id"], "name": recipe["name"], "type": "consumable", "effect": effect})
	GameData.track_skill_use("alchemy", 1)
	_say("[color=green]Crafted %s x%d![/color] %s" % [recipe["name"], count, recipe["desc"]])
	alchemy_mode = false


# ── Workbench (Tinkering) ────────────────────────────────────────────────
func _interact_workbench() -> void:
	if not GameData.has_upgrade("workbench"):
		_say("An empty corner. Install a Workbench to craft tools and gear.")
		return
	tinkering_mode = true
	tinker_idx = 0
	_show_tinkering()

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
	for i_r in range(recipes.size()):
		var recipe: Dictionary = recipes[i_r]
		var marker := "\u25b6" if i_r == tinker_idx else " "
		var can_craft := true
		var mat_str: String = ""
		for mat_id: int in recipe["materials"]:
			var needed: int = recipe["materials"][mat_id]
			var have: int = GameData.get_material_count(TinkerDB.get_material_info(mat_id)["id"])
			if have < needed:
				can_craft = false
			mat_str += "%s %d/%d  " % [TinkerDB.get_material_name(mat_id), have, needed]
		var dim := "" if can_craft else "[color=#666]"
		var dim_e := "" if can_craft else "[/color]"
		var sel_s := "[color=#f0d46a]" if i_r == tinker_idx else ""
		var sel_e := "[/color]" if i_r == tinker_idx else ""
		lines.append("%s%s%s%s %s — %s(x%d)%s" % [dim, marker, sel_s, recipe["name"], mat_str, recipe.get("output_count", 1), sel_e + dim_e])
	lines.append("")
	var mat_names: Array = []
	for mat_id: String in GameData.material_bag:
		var count: int = GameData.material_bag[mat_id]
		if count > 0:
			mat_names.append("%s x%d" % [mat_id.replace("_", " ").capitalize(), count])
	lines.append("Materials: %s" % (", ".join(mat_names) if not mat_names.is_empty() else "None"))
	lines.append("")
	lines.append("[1]/Enter to craft, arrows to browse, [Esc] back")
	_say("\n".join(lines))

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
	var value: int = recipe.get("value", 0)
	for _i in range(count):
		GameData.crafted_items.append({"id": recipe["id"], "name": recipe["name"], "type": "trade", "sell_base": value})
	GameData.track_skill_use("tinkering", 1)
	_say("[color=green]Crafted %s x%d![/color] %s" % [recipe["name"], count, recipe["desc"]])
	tinkering_mode = false

# ── Guest Room ────────────────────────────────────────────────────────────
func _interact_guest_room() -> void:
	if not GameData.has_upgrade("guest_room"):
		_say("An empty room. Install a Guest Room to house party members and improve loyalty.")
		return
	var lines: Array = []
	lines.append("[b]Guest Room[/b]")
	lines.append("")
	var has_hired := false
	for m: Dictionary in GameData.party:
		if m.get("wage", 0) > 0:
			has_hired = true
			var loyalty: int = m.get("loyalty", 50)
			var loyalty_bar := ""
			for j in range(10):
				loyalty_bar += "\u2588" if loyalty >= (j + 1) * 10 else "\u2591"
			var tier := "Loyal" if loyalty >= 70 else ("Steady" if loyalty >= 40 else "Wavering")
			var tier_color := "green" if loyalty >= 70 else ("yellow" if loyalty >= 40 else "red")
			lines.append("%s  [color=%s]%s[/color] %s (%d)" % [m["name"], tier_color, tier, loyalty_bar, loyalty])
	if not has_hired:
		lines.append("No recruited party members. Hire companions in town or at the village.")
	else:
		lines.append("")
		lines.append("Resting here improves party member loyalty each night.")
	lines.append("")
	lines.append("[Esc] Back")
	_say("\n".join(lines))

# ── Trophy Case ───────────────────────────────────────────────────────────
func _interact_trophy() -> void:
	var lines: Array = []
	lines.append("[b][color=#f0d46a]Trophy Case[/color][/b]")
	lines.append("")
	if not GameData.kill_counts.is_empty():
		lines.append("[color=cyan]Bestiary[/color]")
		var total_kills: int = 0
		for enemy: String in GameData.kill_counts:
			total_kills += GameData.kill_counts[enemy]
		var sorted: Array = GameData.kill_counts.keys()
		sorted.sort_custom(func(a, b): return GameData.kill_counts[b] > GameData.kill_counts[a])
		for j in range(mini(sorted.size(), 6)):
			lines.append("  %-14s x%d" % [sorted[j], GameData.kill_counts[sorted[j]]])
		if sorted.size() > 6:
			lines.append("  ...and %d more" % (sorted.size() - 6))
		lines.append("  Total: %d" % total_kills)
		lines.append("")
	else:
		lines.append("[color=gray]No enemies defeated yet.[/color]")
		lines.append("")
	var gathers: Array = []
	for gtype: String in GameData.gather_counts:
		if GameData.gather_counts[gtype] > 0:
			gathers.append("%s: %d" % [gtype.replace("_", " ").capitalize(), GameData.gather_counts[gtype]])
	if not gathers.is_empty():
		lines.append("[color=cyan]Gathering[/color]")
		for g: String in gathers:
			lines.append("  %s" % g)
		lines.append("")
	if not GameData.explored_tiles.is_empty():
		var pct: int = GameData.explored_tiles.size() * 100 / 1600
		lines.append("[color=cyan]Explored[/color]  %d tiles (%d%%)" % [GameData.explored_tiles.size(), pct])
	else:
		lines.append("[color=gray]Exploration not started.[/color]")
	lines.append("")
	var lit: int = 0
	for key: String in GameData.beacon_states:
		if GameData.beacon_states[key]:
			lit += 1
	lines.append("[color=cyan]Beacons[/color]  %d/5 lit" % lit)
	if GameData.boss_defeated:
		lines.append("[color=green]Mountain Cave Shade: DEFEATED[/color]")
	else:
		lines.append("[color=gray]Mountain Cave Shade: ???[/color]")
	lines.append("")
	lines.append("[color=gray][Esc] Back[/color]")
	trophy_mode = true
	_say("\n".join(lines))

# ── HUD ──────────────────────────────────────────────────────────────────
func _say(msg: String) -> void:
	var _header := "[b]Your Home[/b]    %s" % GameData.format_money_short()
	if GameData.owns_home():
		var rent := GameData.get_property_rent()
		var tax := GameData.get_property_tax()
		_header += "  Rent:+%dc" % rent
		if tax > 0:
			_header += " Tax:-%dc" % tax
	dialog.text = "%s\n\n%s" % [_header, msg]

func _update_hud() -> void:
	var lines: Array = []
	for m: Dictionary in GameData.party:
		if m["alive"]:
			lines.append("Lv%d %s  %d/%d" % [m["level"], m["name"], m["hp"], m["max_hp"]])
		else:
			lines.append("Lv%d %s  [KO]" % [m["level"], m["name"]])
	dialog.text = "[b]Your Home[/b]    %s\n\n%s" % [GameData.format_money_short(), "\n".join(lines)]
