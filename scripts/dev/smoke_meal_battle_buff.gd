extends Node

const BattleScene := preload("res://scenes/battle/battle.tscn")

func _ready() -> void:
	var ok := await _run_checks()
	print("SMOKE_MEAL_BATTLE_BUFF_OK" if ok else "SMOKE_MEAL_BATTLE_BUFF_FAILED")
	get_tree().quit(0 if ok else 1)

func _run_checks() -> bool:
	GameData.party.clear()
	GameData._init_party()
	GameData.full_heal()
	GameData.set_meta("battle_zone", "grassland")
	GameData.set_meta("battle_weather", "clear")
	GameData.set_meta("battle_surprise", false)
	GameData.skill_uses["cooking"] = 10
	var original_def: int = GameData.party[0]["def"]
	var buff := GameData.apply_meal_buff("Sea Bass", 40)
	if buff.get("def", 0) < 2:
		return false
	var battle := BattleScene.instantiate()
	add_child(battle)
	await get_tree().process_frame
	var applied: bool = GameData.party[0]["def"] == original_def + buff["def"]
	var decremented: bool = GameData.get_meta("meal_buff_battles", -1) == 2
	var logged := false
	for line: String in battle.combat_log:
		if line.contains("well fed"):
			logged = true
			break
	battle.queue_free()
	await get_tree().process_frame
	return applied and decremented and logged
