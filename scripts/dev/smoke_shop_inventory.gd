extends Node

const ShopScene := preload("res://scenes/shop/shop.tscn")
const InventoryScene := preload("res://scenes/inventory/inventory.tscn")

var _had_save: bool = false
var _original_save_text: String = ""

func _ready() -> void:
	_backup_existing_save()
	var ok := await _run_shop_inventory_roundtrip()
	_restore_existing_save()
	if ok:
		print("SMOKE_SHOP_INVENTORY_OK")
		get_tree().quit(0)
	else:
		push_error("SMOKE_SHOP_INVENTORY_FAILED")
		get_tree().quit(1)

func _run_shop_inventory_roundtrip() -> bool:
	_reset_state()

	GameData.set_meta("shop_type", "items")
	var shop := ShopScene.instantiate()
	add_child(shop)
	await get_tree().process_frame
	if not _shop_layout_ok(shop):
		return false
	shop.selected_idx = 0
	var before_gold: int = GameData.gold
	var before_tonics: int = GameData.tonics
	shop._try_buy()
	var tonic_price: int = shop._get_price(shop.shop_list[0]["price"])
	if GameData.gold != before_gold - tonic_price:
		return false
	if GameData.tonics != before_tonics + 1:
		return false

	if not SaveManager.save_game():
		return false
	GameData.gold = 0
	GameData.tonics = 0
	if not SaveManager.load_game():
		return false
	if GameData.gold != before_gold - tonic_price or GameData.tonics != before_tonics + 1:
		return false

	var inventory := InventoryScene.instantiate()
	add_child(inventory)
	var fighter: Dictionary = GameData.party[0]
	fighter["hp"] = fighter["max_hp"] - 12
	inventory.open()
	inventory.selected_idx = 0
	inventory._use_consumable()
	if GameData.tonics != before_tonics:
		return false
	if fighter["hp"] != fighter["max_hp"]:
		return false

	inventory._use_consumable()
	return GameData.tonics == before_tonics

func _shop_layout_ok(shop: Node) -> bool:
	var text_display := shop.text_display as RichTextLabel
	var expected_position := ((get_viewport().get_visible_rect().size - text_display.size) * 0.5).floor()
	return text_display.position.is_equal_approx(expected_position)

func _reset_state() -> void:
	GameData.party.clear()
	GameData._init_party()
	GameData.full_heal()
	GameData.gold = 500
	GameData.tonics = 3
	GameData.ethers = 0
	GameData.weapons_bag.clear()
	GameData.armor_bag.clear()
	GameData.trade_goods.clear()

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
