extends Node

const OverworldScene := preload("res://scenes/overworld/overworld.tscn")

func _ready() -> void:
	var ok := await _run_command_menu_smoke()
	if ok:
		print("SMOKE_OVERWORLD_COMMAND_MENU_OK")
		get_tree().quit(0)
	else:
		push_error("SMOKE_OVERWORLD_COMMAND_MENU_FAILED")
		get_tree().quit(1)

func _run_command_menu_smoke() -> bool:
	_reset_state()

	var overworld := OverworldScene.instantiate()
	add_child(overworld)
	await get_tree().process_frame

	overworld._open_command_menu()
	if not overworld.command_menu_open:
		return false
	if not overworld.hud.text.contains("Command Menu"):
		return false

	overworld._activate_command_menu_option(1)
	if overworld.command_menu_open:
		return false
	if not overworld.quest_journal.active:
		return false
	overworld.quest_journal.close()

	overworld._open_command_menu()
	overworld._activate_command_menu_option(2)
	if not overworld.inventory_screen.active:
		return false
	overworld.inventory_screen.close()

	overworld._open_command_menu()
	overworld._activate_command_menu_option(3)
	if not overworld.settings_screen.active:
		return false
	overworld.settings_screen.close()

	overworld._open_command_menu()
	overworld._close_command_menu()
	if overworld.command_menu_open:
		return false
	if overworld.hud.text.contains("Command Menu"):
		return false

	return true

func _reset_state() -> void:
	GameData.party.clear()
	GameData._init_party()
	GameData.gold = 500
	GameData.tonics = 3
	GameData.ethers = 0
	GameData.overworld_position = Vector2i(14, 19)
	GameData.overworld_facing = Vector2i.DOWN
	GameData.active_quests.clear()
	GameData.beacon_lit = false
	GameData.beacon_states.clear()
	GameData.explored_tiles.clear()
	GameData.cleared_encounters.clear()
	GameData.kill_counts.clear()
	GameData.gather_counts.clear()
	GameData.faction_reputation.clear()
	GameData.skill_uses.clear()
	GameData.owned_home = ""
	GameData.home_upgrades.clear()
	GameData.home_storage.clear()
