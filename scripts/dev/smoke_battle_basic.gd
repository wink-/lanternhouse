extends Node

const BattleScene := preload("res://scenes/battle/battle.tscn")

func _ready() -> void:
	var ok := await _run_basic_battle()
	if ok:
		print("SMOKE_BATTLE_BASIC_OK")
		get_tree().quit(0)
	else:
		push_error("SMOKE_BATTLE_BASIC_FAILED")
		get_tree().quit(1)

func _run_basic_battle() -> bool:
	GameData.party.clear()
	GameData._init_party()
	GameData.full_heal()
	GameData.gold = 0
	GameData.tonics = 3
	GameData.ethers = 0
	GameData.overworld_position = Vector2i(14, 19)
	GameData.overworld_facing = Vector2i.DOWN
	GameData.set_meta("battle_zone", "grassland")
	GameData.set_meta("battle_weather", "clear")
	GameData.set_meta("battle_surprise", false)

	var battle := BattleScene.instantiate()
	add_child(battle)
	await get_tree().process_frame

	battle.enemies = [{
		"name": "Slime",
		"hp": 6,
		"max_hp": 6,
		"atk": 2,
		"def": 0,
		"agi": 1,
		"xp": 3,
		"gold": 1,
		"alive": true,
		"command": "",
	}]
	battle.round_phase = "command"

	for m: Dictionary in GameData.party:
		if m["alive"]:
			m["command"] = "fight:0"
			m["command_label"] = "Fight -> Slime"

	battle._start_resolution()
	while battle.round_phase == "resolution":
		await get_tree().process_frame

	return (
		battle.round_phase == "victory"
		and GameData.gold == 100
		and GameData.party[0]["xp"] >= 3
		and GameData.alive_count() == GameData.party.size()
	)
