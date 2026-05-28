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
	if town._town_buildings.size() != 7:
		return false
	if town._town_props.size() < 10:
		return false
	if town._cat_home != Vector2i(18, 18):
		return false

	var checks := {
		Vector2i(18, 5): "elder",
		Vector2i(6, 10): "weapon_merchant",
		Vector2i(31, 10): "armor_merchant",
		Vector2i(7, 17): "innkeeper",
		Vector2i(16, 17): "tavern_keeper",
		Vector2i(25, 17): "tinkerer",
		Vector2i(34, 17): "healer",
	}
	for door: Vector2i in checks:
		if town._building_door_at(door) != checks[door]:
			return false

	town.pos = Vector2i(6, 11)
	town.facing = Vector2i.UP
	var prompt: String = town._interaction_prompt()
	if not prompt.contains("Weapon Shop"):
		return false

	town._interact()
	if not town.topic_mode or town.topic_npc != "weapon_merchant":
		return false

	town.topic_mode = false
	town.talking_to = ""
	town.pos = Vector2i(34, 18)
	town.facing = Vector2i.UP
	prompt = town._interaction_prompt()
	if not prompt.contains("Chapel"):
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
