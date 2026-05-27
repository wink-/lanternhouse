extends Node

const TownScene := preload("res://scenes/town/town.tscn")
const QuestDB := preload("res://scripts/data/quests.gd")
const FactionDB := preload("res://scripts/data/factions.gd")

func _ready() -> void:
	var ok := await _run_dead_wick_roundtrip()
	if ok:
		print("SMOKE_DEAD_WICK_OK")
		get_tree().quit(0)
	else:
		push_error("SMOKE_DEAD_WICK_FAILED")
		get_tree().quit(1)

func _run_dead_wick_roundtrip() -> bool:
	_reset_state()

	var town := TownScene.instantiate()
	add_child(town)
	await get_tree().process_frame

	if GameData.is_quest_active("the_dead_wick") or GameData.is_quest_complete("the_dead_wick"):
		return false
	if QuestDB.get_next_story_quest() != "the_dead_wick":
		return false

	GameData.accept_quest("the_dead_wick")
	if not GameData.is_quest_active("the_dead_wick"):
		return false

	var lighthouse_pos: Vector2i = QuestDB.BEACON_POS["lighthouse"]
	GameData.beacon_states[str(lighthouse_pos)] = true
	var before_gold := GameData.gold
	var before_rep: int = GameData.get_faction_rep(FactionDB.Faction.KEEPERS_GUILD)
	var before_xp: int = GameData.party[0]["xp"]

	var msg: String = town._check_quest_completions()
	var reward_gold: int = QuestDB.get_quest("the_dead_wick").get("reward_gold", 0) * 100
	var reward_xp: int = QuestDB.get_quest("the_dead_wick").get("reward_xp", 0)

	return (
		msg.contains("Quest Complete")
		and GameData.is_quest_complete("the_dead_wick")
		and GameData.gold == before_gold + reward_gold
		and GameData.party[0]["xp"] == before_xp + reward_xp
		and GameData.get_faction_rep(FactionDB.Faction.KEEPERS_GUILD) == before_rep + 10
	)

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
	GameData.equipped_weapon = [-1, -1, -1, -1]
	GameData.equipped_head = [-1, -1, -1, -1]
	GameData.equipped_body = [-1, -1, -1, -1]
	GameData.equipped_accessory = [-1, -1, -1, -1]
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
