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

	if not _check_fishing_rules(overworld):
		return false

	return true

func _check_fishing_rules(overworld: Node) -> bool:
	GameData.weapons_bag.append({"id": "fishing_pole", "name": "Fishing Pole", "atk": 0, "fishing_bonus": 2})
	GameData.set_equipped_index(0, "weapon", GameData.weapons_bag.size() - 1)
	if GameData.get_equipped_fishing_bonus() < 2:
		return false

	var water_edge := _find_water_edge(overworld)
	if water_edge.is_empty():
		return false
	if not overworld._can_fish_from(water_edge["standing"], water_edge["target"]):
		return false

	var dry_spot := _find_dry_fishable_spot(overworld)
	if dry_spot.is_empty():
		return false
	return not overworld._can_fish_from(dry_spot["standing"], dry_spot["target"])

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

func _find_water_edge(overworld: Node) -> Dictionary:
	var directions := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
	for y in range(overworld.MAP_H):
		for x in range(overworld.MAP_W):
			var standing := Vector2i(x, y)
			if overworld._tile(standing) == "~":
				continue
			for direction in directions:
				var target: Vector2i = standing + direction
				if overworld._tile(target) == "~":
					return {"standing": standing, "target": target}
	return {}

func _find_dry_fishable_spot(overworld: Node) -> Dictionary:
	var directions := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
	for y in range(overworld.MAP_H):
		for x in range(overworld.MAP_W):
			var target := Vector2i(x, y)
			if not FishDB.can_fish(overworld._tile(target)):
				continue
			if overworld._water_neighbor_mask(target) > 0:
				continue
			for direction in directions:
				var standing: Vector2i = target - direction
				if overworld._tile(standing) != "~" and overworld._water_neighbor_mask(standing) == 0:
					return {"standing": standing, "target": target}
	return {}

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
	GameData.weapons_bag.clear()
	GameData.gather_counts.clear()
	GameData.gather_sites.clear()
	GameData.skill_uses = {"alchemy": 30, "tinkering": 30}
	GameData.play_time = 0.0
