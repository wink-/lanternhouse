# SaveManager — saves and loads all game state to a JSON file
#
# [CODING CONCEPT: Serialization]
# "Serialization" means converting live game data into a format that can be
# saved to disk (here, JSON text). The save_game() function copies every
# important variable from GameData into one big Dictionary, then writes it
# as a JSON file. load_game() does the reverse: reads the JSON and copies
# values back into GameData. This works because GDScript's dictionaries,
# arrays, and basic types (int, String, bool) convert to JSON natively.
#
# [CODING CONCEPT: Why Vector2i Can't Be Saved Directly]
# Godot's Vector2i is a special engine type, not a plain dictionary. JSON
# doesn't know what a Vector2i is. So we convert it to {"x": 6, "y": 11}
# before saving, and reconstruct it when loading. Any custom type needs
# this kind of conversion.
extends Node

const SAVE_DIR := "user://saves/"
const SAVE_FILE := "save_slot1.json"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_DIR + SAVE_FILE)

func save_game() -> bool:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR.get_base_dir())
	var file := FileAccess.open(SAVE_DIR + SAVE_FILE, FileAccess.WRITE)
	if not file:
		push_error("Save failed: cannot open file")
		return false

	var data := {
		"version": 1,
		"party": GameData.party,
		"gold": GameData.gold,
		"keeper_marks": GameData.keeper_marks,
		"harbor_tokens": GameData.harbor_tokens,
		"chapel_script": GameData.chapel_script,
		"tonics": GameData.tonics,
			"ethers": GameData.ethers,
		"weapons_bag": GameData.weapons_bag,
		"armor_bag": GameData.armor_bag,
		"equipped_weapon": GameData.equipped_weapon,
		"equipped_head": GameData.equipped_head,
			"equipped_body": GameData.equipped_body,
			"equipped_accessory": GameData.equipped_accessory,
		"overworld_position": {"x": GameData.overworld_position.x, "y": GameData.overworld_position.y},
		"overworld_facing": {"x": GameData.overworld_facing.x, "y": GameData.overworld_facing.y},
		"cleared_encounters": GameData.cleared_encounters,
		"visited_town": GameData.visited_town,
		"boss_defeated": GameData.boss_defeated,
		"beacon_states": GameData.beacon_states,
		"explored_tiles": GameData.explored_tiles,
		"active_quests": GameData.active_quests,
		"kill_counts": GameData.kill_counts,
		"wage_timer": GameData.wage_timer,
		"beacon_lit": GameData.beacon_lit,
		"pending_departures": GameData.pending_departures,
		"faction_reputation": GameData.faction_reputation,
			"trade_goods": GameData.trade_goods,
		"play_time": GameData.play_time,
		"skill_uses": GameData.skill_uses,
			"owned_home": GameData.owned_home,
			"home_upgrades": GameData.home_upgrades,
			"home_storage": GameData.home_storage,
		"quest_flags": {
			"cave_opened": GameData.get_meta("cave_opened", false),
			"victory_shown": GameData.get_meta("victory_shown", false),
			"all_beacons_triggered": GameData.get_meta("all_beacons_triggered", false),
			"overworld_victory_msg": GameData.get_meta("overworld_victory_msg", false),
			"visited_unlit_post_seal": GameData.get_meta("visited_unlit_post_seal", false),
			"found_maras_journal": GameData.get_meta("found_maras_journal", false),
			"resolved_oil_dispute": GameData.get_meta("resolved_oil_dispute", false),
			"visited_compact_dock": GameData.get_meta("visited_compact_dock", false),
			"visited_keepers_town": GameData.get_meta("visited_keepers_town", false),
			"endgame_choice_made": GameData.get_meta("endgame_choice_made", false),
			"kaels_ledger_found": GameData.get_meta("kaels_ledger_found", false),
			"broks_banner_found": GameData.get_meta("broks_banner_found", false),
			"offensive_casts": GameData.get_meta("offensive_casts", 0),
			"heal_casts": GameData.get_meta("heal_casts", 0),
			"roster_pool": GameData.get_meta("roster_pool", []),
		},
		"timestamp": Time.get_datetime_string_from_system(),
	}

	var json := JSON.stringify(data, "\t")
	file.store_string(json)
	file.close()
	print("Game saved: ", SAVE_DIR + SAVE_FILE)
	return true

func load_game() -> bool:
	if not has_save():
		return false

	var file := FileAccess.open(SAVE_DIR + SAVE_FILE, FileAccess.READ)
	if not file:
		push_error("Load failed: cannot open file")
		return false

	var json_text := file.get_as_text()
	file.close()

	var result := JSON.parse_string(json_text)
	if result == null or not result is Dictionary:
		push_error("Load failed: invalid JSON")
		return false

	var data: Dictionary = result

	GameData.party = data.get("party", [])
	GameData.gold = data.get("gold", 0)
	GameData.keeper_marks = data.get("keeper_marks", 0)
	GameData.harbor_tokens = data.get("harbor_tokens", 0)
	GameData.chapel_script = data.get("chapel_script", 0)
	GameData.tonics = data.get("tonics", 3)
	GameData.ethers = data.get("ethers", 0)
	GameData.weapons_bag = data.get("weapons_bag", [])
	GameData.armor_bag = data.get("armor_bag", [])
	GameData.equipped_weapon = data.get("equipped_weapon", [-1, -1, -1, -1])
	if data.has("equipped_body"):
		GameData.equipped_head = data.get("equipped_head", [-1, -1, -1, -1])
		GameData.equipped_body = data.get("equipped_body", [-1, -1, -1, -1])
		GameData.equipped_accessory = data.get("equipped_accessory", [-1, -1, -1, -1])
	elif data.has("equipped_armor"):
		var old_armor = data["equipped_armor"]
		GameData.equipped_body = old_armor
		GameData.equipped_head = [-1, -1, -1, -1]
		GameData.equipped_accessory = [-1, -1, -1, -1]
		# Migrate old armor items to body slot
		for item in GameData.armor_bag:
			if not item.has("slot"):
				item["slot"] = "body"
	else:
		GameData.equipped_head = [-1, -1, -1, -1]
		GameData.equipped_body = [-1, -1, -1, -1]
		GameData.equipped_accessory = [-1, -1, -1, -1]

	var pos: Dictionary = data.get("overworld_position", {"x": 6, "y": 11})
	GameData.overworld_position = Vector2i(pos["x"], pos["y"])
	var fac: Dictionary = data.get("overworld_facing", {"x": 0, "y": 1})
	GameData.overworld_facing = Vector2i(fac["x"], fac["y"])

	GameData.cleared_encounters = data.get("cleared_encounters", {})
	GameData.visited_town = data.get("visited_town", false)
	GameData.boss_defeated = data.get("boss_defeated", false)
	GameData.beacon_states = data.get("beacon_states", {})
	GameData.explored_tiles = data.get("explored_tiles", {})
	GameData.active_quests = data.get("active_quests", {})
	GameData.kill_counts = data.get("kill_counts", {})
	GameData.wage_timer = data.get("wage_timer", 0.0)
	GameData.beacon_lit = data.get("beacon_lit", false)
	GameData.pending_departures = data.get("pending_departures", [])
	GameData.faction_reputation = data.get("faction_reputation", {})
	GameData.play_time = data.get("play_time", 0.0)
	GameData.skill_uses = data.get("skill_uses", {})
	GameData.owned_home = data.get("owned_home", "")
	GameData.home_upgrades = data.get("home_upgrades", {})
	GameData.home_storage = data.get("home_storage", [])
	GameData.trade_goods = data.get("trade_goods", [])
	GameData.herb_bag = data.get("herb_bag", {})
	GameData.material_bag = data.get("material_bag", {})
	GameData.crafted_items = data.get("crafted_items", [])
	GameData.gather_counts = data.get("gather_counts", {})
	GameData.property_market_mod = data.get("property_market_mod", 1.0)
	GameData.market_cycle = data.get("market_cycle", 0)

	var quest_flags: Dictionary = data.get("quest_flags", {})
	GameData.set_meta("cave_opened", quest_flags.get("cave_opened", false))
	GameData.set_meta("victory_shown", quest_flags.get("victory_shown", false))
	GameData.set_meta("all_beacons_triggered", quest_flags.get("all_beacons_triggered", false))
	GameData.set_meta("overworld_victory_msg", quest_flags.get("overworld_victory_msg", false))
	GameData.set_meta("visited_unlit_post_seal", quest_flags.get("visited_unlit_post_seal", false))
	GameData.set_meta("found_maras_journal", quest_flags.get("found_maras_journal", false))
	GameData.set_meta("resolved_oil_dispute", quest_flags.get("resolved_oil_dispute", false))
	GameData.set_meta("visited_compact_dock", quest_flags.get("visited_compact_dock", false))
	GameData.set_meta("visited_keepers_town", quest_flags.get("visited_keepers_town", false))
	GameData.set_meta("endgame_choice_made", quest_flags.get("endgame_choice_made", false))
	GameData.set_meta("kaels_ledger_found", quest_flags.get("kaels_ledger_found", false))
	GameData.set_meta("broks_banner_found", quest_flags.get("broks_banner_found", false))
	GameData.set_meta("offensive_casts", quest_flags.get("offensive_casts", 0))
	GameData.set_meta("heal_casts", quest_flags.get("heal_casts", 0))
	GameData.set_meta("roster_pool", quest_flags.get("roster_pool", []))

	print("Game loaded: ", SAVE_DIR + SAVE_FILE)
	return true

func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_DIR + SAVE_FILE)
		print("Save deleted")
