extends Node

const OverworldScene := preload("res://scenes/overworld/overworld.tscn")
const TownScene := preload("res://scenes/town/town.tscn")
const ShopScene := preload("res://scenes/shop/shop.tscn")
const BattleScene := preload("res://scenes/battle/battle.tscn")

func _ready() -> void:
	var ok := await _run_demo_flow()
	if ok:
		print("SMOKE_PLAYABLE_DEMO_FLOW_OK")
		get_tree().quit(0)
	else:
		push_error("SMOKE_PLAYABLE_DEMO_FLOW_FAILED")
		get_tree().quit(1)

func _run_demo_flow() -> bool:
	_reset_state()
	if not await _instantiate_and_check(OverworldScene, "Overworld"):
		return false
	if not await _instantiate_and_check(TownScene, "Town"):
		return false
	GameData.set_meta("shop_type", "weapons")
	if not await _instantiate_and_check(ShopScene, "Shop"):
		return false
	GameData.set_meta("battle_zone", "grassland")
	if not await _instantiate_and_check(BattleScene, "Battle"):
		return false
	return true

func _instantiate_and_check(scene: PackedScene, node_name: String) -> bool:
	var inst := scene.instantiate()
	add_child(inst)
	await get_tree().process_frame
	var ok := inst != null and inst.name == node_name
	inst.queue_free()
	await get_tree().process_frame
	return ok

func _reset_state() -> void:
	GameData.party.clear()
	GameData._init_party()
	GameData.gold = 500
	GameData.tonics = 3
	GameData.ethers = 0
	GameData.keeper_marks = 0
	GameData.harbor_tokens = 0
	GameData.chapel_script = 0
	GameData.overworld_position = Vector2i(15, 21)
	GameData.overworld_facing = Vector2i.DOWN
	GameData.visited_town = false
	GameData.boss_defeated = false
	GameData.beacon_lit = false
	GameData.beacon_states.clear()
	GameData.explored_tiles.clear()
	GameData.cleared_encounters.clear()
	GameData.active_quests.clear()
	GameData.kill_counts.clear()
	GameData.gather_counts.clear()
	GameData.gather_sites.clear()
	GameData.faction_reputation.clear()
	GameData.skill_uses.clear()
	GameData.owned_home = ""
	GameData.home_upgrades.clear()
	GameData.home_storage.clear()
