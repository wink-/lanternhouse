extends Node

const HomeScene := preload("res://scenes/home/home.tscn")

var _had_save: bool = false
var _original_save_text: String = ""

func _ready() -> void:
	_backup_existing_save()
	var ok: bool = await _run_home_base_roundtrip()
	_restore_existing_save()
	if ok:
		print("SMOKE_HOME_BASE_OK")
		get_tree().quit(0)
	else:
		push_error("SMOKE_HOME_BASE_FAILED")
		get_tree().quit(1)

func _run_home_base_roundtrip() -> bool:
	_reset_state()

	var home := HomeScene.instantiate()
	add_child(home)
	await get_tree().process_frame
	if not _interior_layout_ok(home):
		return false
	if not _player_sprite_ok(home):
		return false

	var fighter: Dictionary = GameData.party[0]
	fighter["hp"] = fighter["max_hp"] - 10
	home._interact_bed()
	if fighter["hp"] != fighter["max_hp"]:
		return false

	GameData.tonics = 2
	home._deposit_tonic()
	if GameData.tonics != 1 or GameData.home_storage.size() != 1:
		return false
	home.storage_idx = 0
	home._withdraw_item()
	if GameData.tonics != 2 or not GameData.home_storage.is_empty():
		return false

	GameData.trade_goods.append({"id": "sunfish", "name": "Sunfish", "type": "trade", "cooking": {"hp": 8}})
	fighter["hp"] = fighter["max_hp"] - 8
	home.cook_idx = 0
	home._try_cook()
	if fighter["hp"] != fighter["max_hp"] or not GameData.trade_goods.is_empty():
		return false

	home.garden_timer = home.GARDEN_GROW_SECONDS
	GameData.set_meta("home_garden_timer", home.garden_timer)
	var herbs_before: int = _herb_total()
	home._harvest_garden()
	var herbs_after: int = _herb_total()
	if herbs_after <= herbs_before:
		return false
	if not is_equal_approx(GameData.get_meta("home_garden_timer", -1.0), 0.0):
		return false
	home._harvest_garden()
	if _herb_total() != herbs_after:
		return false

	GameData.home_storage.append({"id": "tonic", "name": "Tonic", "type": "tonic", "count": 1})
	GameData.set_meta("home_garden_timer", 33.0)
	if not SaveManager.save_game():
		return false

	GameData.owned_home = ""
	GameData.home_upgrades = {}
	GameData.home_storage = []
	GameData.herb_bag = {}
	GameData.set_meta("home_garden_timer", 0.0)
	if not SaveManager.load_game():
		return false

	return (
		GameData.owned_home == "cottage"
		and GameData.home_upgrades.get("workbench", false)
		and GameData.home_storage.size() == 1
		and _herb_total() == herbs_after
		and is_equal_approx(GameData.get_meta("home_garden_timer", 0.0), 33.0)
	)

func _reset_state() -> void:
	GameData.party.clear()
	GameData._init_party()
	GameData.full_heal()
	GameData.gold = 500
	GameData.tonics = 3
	GameData.ethers = 0
	GameData.trade_goods.clear()
	GameData.home_storage.clear()
	GameData.herb_bag.clear()
	GameData.material_bag.clear()
	GameData.crafted_items.clear()
	GameData.owned_home = "cottage"
	GameData.home_upgrades = {
		"bed": true,
		"chest": true,
		"kitchen": true,
		"garden": true,
		"workbench": true,
	}
	GameData.set_meta("home_garden_timer", 0.0)

func _herb_total() -> int:
	var total := 0
	for herb_id: String in GameData.herb_bag:
		total += int(GameData.herb_bag[herb_id])
	return total

func _interior_layout_ok(interior: Node) -> bool:
	var map_size := Vector2(interior.MAP[0].length() * interior.TILE_SIZE, interior.MAP.size() * interior.TILE_SIZE)
	var expected_origin := ((get_viewport().get_visible_rect().size - map_size) * 0.5).floor()
	expected_origin.x = maxf(0.0, expected_origin.x)
	expected_origin.y = maxf(0.0, expected_origin.y)
	return interior.map_layer.position.is_equal_approx(expected_origin)

func _player_sprite_ok(interior: Node) -> bool:
	var sprite := interior.player_sprite.get_node_or_null("Sprite") as Sprite2D
	if not sprite or not sprite.texture:
		return false
	if interior.player_sprite.has_node("Body") and interior.player_sprite.get_node("Body").visible:
		return false
	if interior.player_sprite.has_node("Face") and interior.player_sprite.get_node("Face").visible:
		return false
	return true

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
