extends Node

const TownScene := preload("res://scenes/town/town.tscn")
const OverworldScene := preload("res://scenes/overworld/overworld.tscn")
const QuestDB := preload("res://scripts/data/quests.gd")
const FactionDB := preload("res://scripts/data/factions.gd")

func _ready() -> void:
	var ok := await _run_missing_keeper_roundtrip()
	if ok:
		print("SMOKE_MISSING_KEEPER_OK")
		get_tree().quit(0)
	else:
		push_error("SMOKE_MISSING_KEEPER_FAILED")
		get_tree().quit(1)

func _run_missing_keeper_roundtrip() -> bool:
	_reset_state()

	var town := TownScene.instantiate()
	add_child(town)
	var overworld := OverworldScene.instantiate()
	add_child(overworld)
	await get_tree().process_frame

	GameData.accept_quest("the_dead_wick")
	overworld._interact_beacon("lighthouse", QuestDB.BEACON_POS["lighthouse"])
	town._check_quest_completions()
	if QuestDB.get_next_story_quest() != "the_missing_keeper":
		return false

	var north_pos: Vector2i = QuestDB.BEACON_POS["north_forest"]
	overworld._interact_beacon("north_forest", north_pos)
	if GameData.beacon_states.get(str(north_pos), false):
		return false

	GameData.accept_quest("the_missing_keeper")
	if not GameData.is_quest_active("the_missing_keeper"):
		return false
	var missing_quest: Dictionary = QuestDB.get_quest("the_missing_keeper")
	if not missing_quest.has("objective") or not missing_quest.has("hint"):
		return false

	var before_gold: int = GameData.gold
	var before_xp: int = GameData.party[0]["xp"]
	var before_rep: int = GameData.get_faction_rep(FactionDB.Faction.KEEPERS_GUILD)
	overworld._interact_beacon("north_forest", north_pos)
	if not GameData.beacon_states.get(str(north_pos), false):
		return false
	if GameData.gold != before_gold or GameData.party[0]["xp"] != before_xp:
		return false
	if GameData.active_quests["the_missing_keeper"].get("progress", 0) != 1:
		return false
	if not overworld.hud.text.contains("Mara") or not overworld.hud.text.contains("Return to Old Thatch"):
		return false
	var after_light_rep: int = GameData.get_faction_rep(FactionDB.Faction.KEEPERS_GUILD)
	overworld._interact_beacon("north_forest", north_pos)
	if GameData.get_faction_rep(FactionDB.Faction.KEEPERS_GUILD) != after_light_rep:
		return false

	var msg: String = town._check_quest_completions()
	var reward_gold: int = missing_quest.get("reward_gold", 0) * 100
	var reward_xp: int = missing_quest.get("reward_xp", 0)
	return (
		msg.contains("Quest Complete")
		and msg.contains("beacon oil")
		and GameData.is_quest_complete("the_missing_keeper")
		and QuestDB.get_next_story_quest() == "oil_for_the_line"
		and GameData.gold == before_gold + reward_gold
		and GameData.party[0]["xp"] == before_xp + reward_xp
		and GameData.get_faction_rep(FactionDB.Faction.KEEPERS_GUILD) == before_rep + 20
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
