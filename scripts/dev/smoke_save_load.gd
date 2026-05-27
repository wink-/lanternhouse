extends Node

var _had_save: bool = false
var _original_save_text: String = ""

func _ready() -> void:
	_backup_existing_save()

	var ok := _run_save_load_roundtrip()
	_restore_existing_save()

	if ok:
		print("SMOKE_SAVE_LOAD_OK")
		get_tree().quit(0)
	else:
		push_error("SMOKE_SAVE_LOAD_FAILED")
		get_tree().quit(1)

func _run_save_load_roundtrip() -> bool:
	GameData.party.clear()
	GameData._init_party()
	GameData.gold = 1234
	GameData.tonics = 7
	GameData.ethers = 2
	GameData.overworld_position = Vector2i(14, 19)
	GameData.overworld_facing = Vector2i.DOWN
	GameData.faction_reputation = {1: 15}
	GameData.herb_bag = {"mournmint": 2}
	GameData.material_bag = {"driftwood": 3}
	GameData.crafted_items = [{"id": "test_lantern_oil", "name": "Test Lantern Oil"}]
	GameData.gather_counts = {"herb": 2}
	GameData.set_meta("fog_active", true)
	GameData.set_meta("fog_timer", 42.0)

	if GameData.party.size() > 0:
		GameData.party[0]["magic_levels"] = {1: {"charges": 1, "max": 2}}

	if not SaveManager.save_game():
		return false

	GameData.gold = 0
	GameData.tonics = 0
	GameData.ethers = 0
	GameData.overworld_position = Vector2i.ZERO
	GameData.overworld_facing = Vector2i.LEFT
	GameData.faction_reputation = {}
	GameData.herb_bag = {}
	GameData.material_bag = {}
	GameData.crafted_items = []
	GameData.gather_counts = {}
	GameData.set_meta("fog_active", false)
	GameData.set_meta("fog_timer", 0.0)
	if GameData.party.size() > 0:
		GameData.party[0]["magic_levels"] = {}

	if not SaveManager.load_game():
		return false

	return (
		GameData.gold == 1234
		and GameData.tonics == 7
		and GameData.ethers == 2
		and GameData.overworld_position == Vector2i(14, 19)
		and GameData.overworld_facing == Vector2i.DOWN
		and GameData.faction_reputation.get(1, 0) == 15
		and GameData.herb_bag.get("mournmint", 0) == 2
		and GameData.material_bag.get("driftwood", 0) == 3
		and GameData.crafted_items.size() == 1
		and GameData.gather_counts.get("herb", 0) == 2
		and GameData.get_meta("fog_active", false)
		and is_equal_approx(GameData.get_meta("fog_timer", 0.0), 42.0)
		and GameData.party[0]["magic_levels"].has(1)
	)

func _backup_existing_save() -> void:
	var save_path := SaveManager.SAVE_DIR + SaveManager.SAVE_FILE
	_had_save = FileAccess.file_exists(save_path)
	if _had_save:
		var file := FileAccess.open(save_path, FileAccess.READ)
		if file:
			_original_save_text = file.get_as_text()
			file.close()

func _restore_existing_save() -> void:
	var save_path := SaveManager.SAVE_DIR + SaveManager.SAVE_FILE
	if _had_save:
		DirAccess.make_dir_recursive_absolute(SaveManager.SAVE_DIR.get_base_dir())
		var file := FileAccess.open(save_path, FileAccess.WRITE)
		if file:
			file.store_string(_original_save_text)
			file.close()
	elif FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
