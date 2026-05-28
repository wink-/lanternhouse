extends Node

const OverworldScene := preload("res://scenes/overworld/overworld.tscn")

func _ready() -> void:
	var ok := await _run_gather_site_rules()
	if ok:
		print("SMOKE_GATHER_SITES_OK")
		get_tree().quit(0)
	else:
		push_error("SMOKE_GATHER_SITES_FAILED")
		get_tree().quit(1)

func _run_gather_site_rules() -> bool:
	_reset_state()

	var overworld := OverworldScene.instantiate()
	add_child(overworld)
	await get_tree().process_frame
	overworld.rng.seed = 12345

	var herb_target := _find_target(overworld, "herb")
	var material_target := _find_target(overworld, "material")
	if herb_target == Vector2i(-1, -1) or material_target == Vector2i(-1, -1):
		return false

	if not _gather_until_site_created(overworld, "herb", herb_target):
		return false
	var herb_total := _sum_counts(GameData.herb_bag)
	overworld._try_gather_herbs(herb_target)
	if _sum_counts(GameData.herb_bag) != herb_total:
		return false

	GameData.play_time = 90.0 * GameData.DAY_CYCLE_SECONDS
	GameData.gather_sites.erase(overworld._gather_site_key("herb", herb_target))
	overworld._try_gather_herbs(herb_target)
	if _sum_counts(GameData.herb_bag) != herb_total:
		return false
	if GameData.gather_sites.has(overworld._gather_site_key("herb", herb_target)):
		return false

	GameData.play_time = 30.0 * GameData.DAY_CYCLE_SECONDS + 1.0
	if not _gather_until_site_created(overworld, "herb", herb_target):
		return false
	if _sum_counts(GameData.herb_bag) <= herb_total:
		return false

	if not _gather_until_site_created(overworld, "material", material_target):
		return false
	var material_total := _sum_counts(GameData.material_bag)
	for i in range(5):
		overworld._try_gather_materials(material_target)
	if _sum_counts(GameData.material_bag) != material_total:
		return false

	return true

func _find_target(overworld: Node, kind: String) -> Vector2i:
	for y in range(overworld.MAP_H):
		for x in range(overworld.MAP_W):
			var target := Vector2i(x, y)
			var tile: String = overworld._tile(target)
			if kind == "herb" and AlchemyDB.can_gather(tile):
				return target
			if kind == "material" and TinkerDB.can_gather(tile):
				return target
	return Vector2i(-1, -1)

func _gather_until_site_created(overworld: Node, kind: String, target: Vector2i) -> bool:
	var key: String = overworld._gather_site_key(kind, target)
	for i in range(60):
		if kind == "herb":
			overworld._try_gather_herbs(target)
		else:
			overworld._try_gather_materials(target)
		if GameData.gather_sites.has(key):
			return true
	return false

func _sum_counts(items: Dictionary) -> int:
	var total := 0
	for key in items:
		total += int(items[key])
	return total

func _reset_state() -> void:
	GameData.party.clear()
	GameData._init_party()
	GameData.herb_bag.clear()
	GameData.material_bag.clear()
	GameData.gather_counts.clear()
	GameData.gather_sites.clear()
	GameData.skill_uses = {"alchemy": 30, "tinkering": 30}
	GameData.play_time = 0.0
