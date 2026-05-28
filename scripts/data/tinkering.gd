class_name TinkerDB

enum TinkerMaterial {
	NONE = 0,
	SCRAP_METAL = 1,
	GLASS_SHARDS = 2,
	COPPER_WIRE = 3,
	LEATHER_SCRAP = 4,
	WOOD_CHIP = 5,
	OIL_RESIDUE = 6,
}

const MATERIAL_INFO := {
	TinkerMaterial.SCRAP_METAL: {"id": "scrap_metal", "name": "Scrap Metal", "color": "#95a5a6", "tiles": ["^", "#", "r"]},
	TinkerMaterial.GLASS_SHARDS: {"id": "glass_shards", "name": "Glass Shards", "color": "#85c1e9", "tiles": [".", "~", "d"]},
	TinkerMaterial.COPPER_WIRE: {"id": "copper_wire", "name": "Copper Wire", "color": "#e67e22", "tiles": ["h", "="]},
	TinkerMaterial.LEATHER_SCRAP: {"id": "leather_scrap", "name": "Leather Scrap", "color": "#8b6914", "tiles": [",", ";", "T"]},
	TinkerMaterial.WOOD_CHIP: {"id": "wood_chip", "name": "Wood Chip", "color": "#a0522d", "tiles": ["T", "=", "p"]},
	TinkerMaterial.OIL_RESIDUE: {"id": "oil_residue", "name": "Oil Residue", "color": "#2c3e50", "tiles": ["B", "L"]},
}

const RECIPES := [
	{
		"id": "repair_kit",
		"name": "Repair Kit",
		"desc": "Restore 18 HP to the most wounded ally",
		"materials": {TinkerMaterial.SCRAP_METAL: 2, TinkerMaterial.LEATHER_SCRAP: 1},
		"skill_level": 0,
		"output_count": 1,
		"value": 60,
		"tool_effect": {"type": "heal", "hp": 18},
	},
	{
		"id": "lantern_lens",
		"name": "Lantern Lens",
		"desc": "Keeper trade good that sells well",
		"materials": {TinkerMaterial.GLASS_SHARDS: 3, TinkerMaterial.COPPER_WIRE: 1},
		"skill_level": 1,
		"output_count": 1,
		"value": 80,
		"item_type": "trade",
	},
	{
		"id": "simple_lockpick",
		"name": "Simple Lockpick",
		"desc": "Carry for locked chests and future dungeon shortcuts",
		"materials": {TinkerMaterial.COPPER_WIRE: 2, TinkerMaterial.SCRAP_METAL: 1},
		"skill_level": 1,
		"output_count": 2,
		"value": 30,
		"tool_effect": {"type": "passive"},
	},
	{
		"id": "beacon_lens",
		"name": "Beacon Lens",
		"desc": "Tune the Lantern Line for wider fog reveal",
		"materials": {TinkerMaterial.GLASS_SHARDS: 4, TinkerMaterial.OIL_RESIDUE: 2, TinkerMaterial.COPPER_WIRE: 2},
		"skill_level": 2,
		"output_count": 1,
		"value": 200,
		"tool_effect": {"type": "beacon_lens"},
	},
	{
		"id": "oil_lantern",
		"name": "Oil Lantern",
		"desc": "Burns away heavy fog cover for a short expedition",
		"materials": {TinkerMaterial.OIL_RESIDUE: 3, TinkerMaterial.GLASS_SHARDS: 2, TinkerMaterial.WOOD_CHIP: 2},
		"skill_level": 2,
		"output_count": 1,
		"value": 150,
		"tool_effect": {"type": "fog_cover", "timer": 180.0},
	},
	{
		"id": "master_repair_kit",
		"name": "Master Repair Kit",
		"desc": "Fully restore the party's HP",
		"materials": {TinkerMaterial.SCRAP_METAL: 4, TinkerMaterial.COPPER_WIRE: 2, TinkerMaterial.LEATHER_SCRAP: 2},
		"skill_level": 3,
		"output_count": 1,
		"value": 300,
		"tool_effect": {"type": "full_heal"},
	},
	{
		"id": "trap_kit",
		"name": "Trap Kit",
		"desc": "Set a trap for the next encounter",
		"materials": {TinkerMaterial.WOOD_CHIP: 3, TinkerMaterial.SCRAP_METAL: 1, TinkerMaterial.LEATHER_SCRAP: 1},
		"skill_level": 1,
		"output_count": 2,
		"value": 40,
		"tool_effect": {"type": "trap"},
	},
]

static func create_crafted_item(recipe: Dictionary) -> Dictionary:
	var item_type: String = recipe.get("item_type", "tool")
	var item := {
		"id": recipe["id"],
		"name": recipe["name"],
		"desc": recipe.get("desc", ""),
		"type": item_type,
		"value": recipe.get("value", 0),
		"sell_base": recipe.get("value", 0),
	}
	if recipe.has("tool_effect"):
		item["effect"] = recipe["tool_effect"].duplicate(true)
	return item

static func available_recipes(skill_level: int) -> Array:
	return RECIPES.filter(func(r): return r["skill_level"] <= skill_level)

static func materials_for_tile(tile: String) -> Array:
	var materials: Array = []
	for mat_id: int in MATERIAL_INFO:
		var info: Dictionary = MATERIAL_INFO[mat_id]
		if tile in info["tiles"]:
			materials.append(mat_id)
	return materials

static func can_gather(tile: String) -> bool:
	return not materials_for_tile(tile).is_empty()

static func get_material_name(mat_id: int) -> String:
	if MATERIAL_INFO.has(mat_id):
		return MATERIAL_INFO[mat_id]["name"]
	return "Unknown Material"

static func get_material_info(mat_id: int) -> Dictionary:
	return MATERIAL_INFO.get(mat_id, {})

static func get_material_id_by_string(mat_str: String) -> int:
	for mat_id: int in MATERIAL_INFO:
		if MATERIAL_INFO[mat_id]["id"] == mat_str:
			return mat_id
	return TinkerMaterial.NONE
