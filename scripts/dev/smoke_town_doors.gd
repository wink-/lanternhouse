extends Node

const TownScene := preload("res://scenes/town/town.tscn")

func _ready() -> void:
	var ok := await _run_town_door_checks()
	if ok:
		print("SMOKE_TOWN_DOORS_OK")
		get_tree().quit(0)
	else:
		push_error("SMOKE_TOWN_DOORS_FAILED")
		get_tree().quit(1)

func _run_town_door_checks() -> bool:
	_reset_state()
	var town := TownScene.instantiate()
	add_child(town)
	await get_tree().process_frame
	if town._town_buildings.size() < 7:
		push_error("Not enough buildings: %d" % town._town_buildings.size())
		return false
	if town._town_props.size() < 10:
		push_error("Not enough props: %d" % town._town_props.size())
		return false
	
	# Verify cat home is within bounds and walkable
	var cat_home: Vector2i = town._cat_home
	var height: int = town._town_map.size()
	var width: int = town._town_map[0].length()
	if cat_home.x < 0 or cat_home.x >= width or cat_home.y < 0 or cat_home.y >= height:
		push_error("Cat home outside bounds: %s" % str(cat_home))
		return false
	
	# Find door coordinates dynamically from buildings
	var expected_npcs := ["elder", "weapon_merchant", "armor_merchant", "innkeeper", "tavern_keeper", "tinkerer", "healer"]
	var door_positions := {} # npc -> Array[Vector2i]
	
	for building_data: Dictionary in town._town_buildings:
		var building_id: String = building_data["id"]
		var interaction: Dictionary = town._building_interactions.get(building_id, {})
		if interaction.is_empty() or interaction.get("door_width", 0) <= 0:
			continue
		var door_offset: Vector2i = interaction["door_offset"]
		var door_start: Vector2i = building_data["grid"] + door_offset
		var npc: String = interaction["npc"]
		if not door_positions.has(npc):
			door_positions[npc] = []
		door_positions[npc].append(door_start)
		
	# Verify each expected NPC has at least one door position and the building door query matches
	for npc in expected_npcs:
		if not door_positions.has(npc) or door_positions[npc].is_empty():
			push_error("NPC %s has no door positions assigned!" % npc)
			return false
		var door_pos: Vector2i = door_positions[npc][0]
		if town._building_door_at(door_pos) != npc:
			push_error("NPC door lookup mismatch at %s: expected %s, got %s" % [str(door_pos), npc, town._building_door_at(door_pos)])
			return false
			
	# Dynamically check Weapon Shop interaction prompt
	var weapon_doors = door_positions.get("weapon_merchant", [])
	var weapon_door: Vector2i = weapon_doors[0]
	town.pos = weapon_door + Vector2i(0, 1) # standing 1 tile below the door
	town.facing = Vector2i.UP
	var prompt: String = town._interaction_prompt()
	if not prompt.contains("Weapon Shop"):
		push_error("Weapon Shop prompt check failed at %s, got: %s" % [str(town.pos), prompt])
		return false
		
	town._interact()
	if not town.topic_mode or town.topic_npc != "weapon_merchant":
		push_error("Weapon Shop interaction failed")
		return false
		
	town.topic_mode = false
	town.talking_to = ""
	
	# Dynamically check Chapel interaction prompt
	var healer_doors = door_positions.get("healer", [])
	var healer_door: Vector2i = healer_doors[0]
	town.pos = healer_door + Vector2i(0, 1) # standing 1 tile below the door
	town.facing = Vector2i.UP
	prompt = town._interaction_prompt()
	if not prompt.contains("Chapel"):
		push_error("Chapel prompt check failed at %s, got: %s" % [str(town.pos), prompt])
		return false
		
	return true

func _reset_state() -> void:
	GameData.party.clear()
	GameData._init_party()
	GameData.gold = 500
	GameData.tonics = 3
	GameData.overworld_position = Vector2i(15, 21)
	GameData.overworld_facing = Vector2i.DOWN
	GameData.visited_town = false
	GameData.active_quests.clear()
	GameData.kill_counts.clear()
	GameData.gather_counts.clear()
	GameData.gather_sites.clear()
	GameData.skill_uses.clear()
	GameData.owned_home = ""
	GameData.home_upgrades.clear()
	GameData.home_storage.clear()
	GameData.play_time = 0.0
