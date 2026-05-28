extends Node

const CaveScene := preload("res://scenes/cave/cave.tscn")

func _ready() -> void:
	var ok := await _run_checks()
	print("SMOKE_CAVE_LOCKPICK_CHESTS_OK" if ok else "SMOKE_CAVE_LOCKPICK_CHESTS_FAILED")
	get_tree().quit(0 if ok else 1)

func _run_checks() -> bool:
	_reset_state()
	var cave := CaveScene.instantiate()
	add_child(cave)
	await get_tree().process_frame

	var locked_pos := Vector2i(14, 12)
	cave._open_chest(locked_pos)
	if GameData.weapons_bag.size() != 0:
		cave.queue_free()
		return false
	if not GameData.get_meta("cave_claimed_chests", []).is_empty():
		cave.queue_free()
		return false

	GameData.add_crafted_item({"id": "simple_lockpick", "name": "Simple Lockpick", "type": "tool", "effect": {"type": "passive"}})
	cave._open_chest(locked_pos)
	var claimed: Array = GameData.get_meta("cave_claimed_chests", [])
	var opened: bool = GameData.weapons_bag.size() == 1 and str(locked_pos) in claimed and _crafted_count("simple_lockpick", "tool") == 0
	if not opened:
		cave.queue_free()
		return false

	cave._open_chest(locked_pos)
	var stayed_empty: bool = GameData.weapons_bag.size() == 1 and GameData.get_meta("cave_claimed_chests", []).size() == 1
	cave.queue_free()
	await get_tree().process_frame
	return stayed_empty

func _reset_state() -> void:
	GameData.party.clear()
	GameData._init_party()
	GameData.weapons_bag.clear()
	GameData.crafted_items.clear()
	GameData.set_meta("cave_opened", true)
	GameData.set_meta("cave_deep", false)
	GameData.set_meta("cave_claimed_chests", [])

func _crafted_count(item_id: String, item_type: String) -> int:
	var count := 0
	for item: Dictionary in GameData.crafted_items:
		if item.get("id", "") == item_id and item.get("type", "") == item_type:
			count += 1
	return count
