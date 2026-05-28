extends Node

const BattleScene := preload("res://scenes/battle/battle.tscn")
const InventoryScene := preload("res://scenes/inventory/inventory.tscn")
const WorkshopScene := preload("res://scenes/workshop/workshop.tscn")
const TinkerDB := preload("res://scripts/data/tinkering.gd")

func _ready() -> void:
	var ok := await _run_checks()
	print("SMOKE_TRADESKILL_TOOLS_OK" if ok else "SMOKE_TRADESKILL_TOOLS_FAILED")
	get_tree().quit(0 if ok else 1)

func _run_checks() -> bool:
	_reset_state()
	print("TRADESKILL_SMOKE craft")
	if not await _craft_trap_kit_at_workshop():
		return false
	print("TRADESKILL_SMOKE use trap")
	if not await _use_trap_kit_from_inventory():
		return false
	print("TRADESKILL_SMOKE battle trap")
	if not await _trap_applies_to_next_battle():
		return false
	print("TRADESKILL_SMOKE oil lantern")
	if not await _oil_lantern_sets_fog_cover():
		return false
	return true

func _reset_state() -> void:
	GameData.party.clear()
	GameData._init_party()
	GameData.full_heal()
	GameData.crafted_items.clear()
	GameData.material_bag.clear()
	GameData.skill_uses.clear()
	GameData.trade_goods.clear()
	GameData.set_meta("trap_kit_active", false)
	GameData.set_meta("fog_active", false)
	GameData.set_meta("fog_timer", 0.0)
	GameData.set_meta("beacon_lens_charges", 0)
	GameData.set_meta("battle_zone", "grassland")
	GameData.set_meta("battle_weather", "clear")
	GameData.set_meta("battle_surprise", false)

func _craft_trap_kit_at_workshop() -> bool:
	GameData.skill_uses["tinkering"] = 10
	GameData.material_bag = {
		"wood_chip": 3,
		"scrap_metal": 1,
		"leather_scrap": 1,
	}
	var workshop := WorkshopScene.instantiate()
	add_child(workshop)
	await get_tree().process_frame
	var recipes := TinkerDB.available_recipes(GameData.get_skill_bonus("tinkering"))
	var trap_idx := _recipe_index(recipes, "trap_kit")
	if trap_idx < 0:
		workshop.queue_free()
		return false
	workshop.tinker_idx = trap_idx
	workshop._try_tinker()
	var crafted_count := _crafted_count("trap_kit", "tool")
	var materials_spent := GameData.get_material_count("wood_chip") == 0 and GameData.get_material_count("scrap_metal") == 0 and GameData.get_material_count("leather_scrap") == 0
	workshop.queue_free()
	await get_tree().process_frame
	return crafted_count == 2 and materials_spent

func _use_trap_kit_from_inventory() -> bool:
	var inventory := InventoryScene.instantiate()
	add_child(inventory)
	await get_tree().process_frame
	inventory.tab = 3
	inventory.selected_idx = 0
	inventory._use_tool()
	var ok: bool = GameData.get_meta("trap_kit_active", false) and _crafted_count("trap_kit", "tool") == 1
	inventory.queue_free()
	await get_tree().process_frame
	return ok

func _trap_applies_to_next_battle() -> bool:
	var battle := BattleScene.instantiate()
	add_child(battle)
	await get_tree().process_frame
	var saw_log := false
	for line: String in battle.combat_log:
		if line.contains("Trap Kit"):
			saw_log = true
			break
	var trap_cleared: bool = not GameData.get_meta("trap_kit_active", true)
	var enemy_hurt := false
	for enemy: Dictionary in battle.enemies:
		if enemy.get("hp", 0) < enemy.get("max_hp", 0):
			enemy_hurt = true
			break
	battle.queue_free()
	await get_tree().process_frame
	return saw_log and trap_cleared and enemy_hurt

func _oil_lantern_sets_fog_cover() -> bool:
	var oil_recipe := _recipe_by_id("oil_lantern")
	if oil_recipe.is_empty():
		return false
	GameData.add_crafted_item(TinkerDB.create_crafted_item(oil_recipe))
	var inventory := InventoryScene.instantiate()
	add_child(inventory)
	await get_tree().process_frame
	inventory.tab = 3
	inventory.selected_idx = _tool_index(inventory, "oil_lantern")
	if inventory.selected_idx < 0:
		inventory.queue_free()
		return false
	inventory._use_tool()
	var ok: bool = GameData.get_meta("fog_active", false) and is_equal_approx(GameData.get_meta("fog_timer", 0.0), 180.0)
	inventory.queue_free()
	await get_tree().process_frame
	return ok

func _recipe_index(recipes: Array, recipe_id: String) -> int:
	for i in range(recipes.size()):
		if recipes[i].get("id", "") == recipe_id:
			return i
	return -1

func _recipe_by_id(recipe_id: String) -> Dictionary:
	for recipe: Dictionary in TinkerDB.RECIPES:
		if recipe.get("id", "") == recipe_id:
			return recipe
	return {}

func _tool_index(inventory: CanvasLayer, tool_id: String) -> int:
	var tools: Array = inventory._crafted_tools()
	for i in range(tools.size()):
		if tools[i].get("id", "") == tool_id:
			return i
	return -1

func _crafted_count(item_id: String, item_type: String) -> int:
	var count := 0
	for item: Dictionary in GameData.crafted_items:
		if item.get("id", "") == item_id and item.get("type", "") == item_type:
			count += 1
	return count
