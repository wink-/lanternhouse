extends Node

const TownScene := preload("res://scenes/town/town.tscn")
const OverworldScene := preload("res://scenes/overworld/overworld.tscn")
const QuestDB := preload("res://scripts/data/quests.gd")

func _ready() -> void:
	var ok := await _run_first_route_guidance()
	if ok:
		print("SMOKE_FIRST_ROUTE_GUIDANCE_OK")
		get_tree().quit(0)
	else:
		push_error("SMOKE_FIRST_ROUTE_GUIDANCE_FAILED")
		get_tree().quit(1)

func _run_first_route_guidance() -> bool:
	_reset_state()

	var town := TownScene.instantiate()
	add_child(town)
	await get_tree().process_frame

	if not town.dialog.text.contains("First stop"):
		return false
	if not town.dialog.text.contains("Elder Hall"):
		return false

	town.facing = Vector2i.DOWN
	town._interact()
	if not town.dialog.text.contains("south road"):
		return false

	town._accept_next_quest()
	if not town.dialog.text.contains("Walk south out of town"):
		return false
	if not GameData.is_quest_active("the_dead_wick"):
		return false

	var quest: Dictionary = QuestDB.get_quest("the_dead_wick")
	if not quest.get("hint", "").contains("Lighthouse marker"):
		return false

	var overworld := OverworldScene.instantiate()
	add_child(overworld)
	await get_tree().process_frame

	var lighthouse_pos: Vector2i = QuestDB.BEACON_POS["lighthouse"]
	overworld._interact_beacon("lighthouse", lighthouse_pos)
	if not overworld.hud.text.contains("Route back"):
		return false
	if not overworld.hud.text.contains("path west"):
		return false

	return true

func _reset_state() -> void:
	GameData.party.clear()
	GameData._init_party()
	GameData.gold = 500
	GameData.tonics = 3
	GameData.ethers = 0
	GameData.keeper_marks = 0
	GameData.harbor_tokens = 0
	GameData.chapel_script = 0
	GameData.weapons_bag.clear()
	GameData.armor_bag.clear()
	GameData.trade_goods.clear()
	GameData.overworld_position = Vector2i(14, 19)
	GameData.overworld_facing = Vector2i.DOWN
	GameData.cleared_encounters.clear()
	GameData.visited_town = false
	GameData.boss_defeated = false
	GameData.beacon_lit = false
	GameData.beacon_states.clear()
	GameData.explored_tiles.clear()
	GameData.active_quests.clear()
	GameData.kill_counts.clear()
	GameData.gather_counts.clear()
	GameData.gather_sites.clear()
	GameData.crafted_items.clear()
	GameData.herb_bag.clear()
	GameData.material_bag.clear()
	GameData.faction_reputation.clear()
	GameData.play_time = 0.0
	GameData.skill_uses.clear()
	GameData.owned_home = ""
	GameData.home_upgrades.clear()
	GameData.home_storage.clear()
	GameData.wage_timer = 0.0
	GameData.pending_departures.clear()
