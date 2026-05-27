class_name TinkerDB

enum Material {
	NONE = 0,
	SCRAP_METAL = 1,
	GLASS_SHARDS = 2,
	COPPER_WIRE = 3,
	LEATHER_SCRAP = 4,
	WOOD_CHIP = 5,
	OIL_RESIDUE = 6,
}

const MATERIAL_INFO := {
	Material.SCRAP_METAL: {"id": "scrap_metal", "name": "Scrap Metal", "color": "#95a5a6", "tiles": ["^", "#"]},
	Material.GLASS_SHARDS: {"id": "glass_shards", "name": "Glass Shards", "color": "#85c1e9", "tiles": [".", "~"]},
	Material.COPPER_WIRE: {"id": "copper_wire", "name": "Copper Wire", "color": "#e67e22", "tiles": ["h", "="]},
	Material.LEATHER_SCRAP: {"id": "leather_scrap", "name": "Leather Scrap", "color": "#8b6914", "tiles": [",", "T"]},
	Material.WOOD_CHIP: {"id": "wood_chip", "name": "Wood Chip", "color": "#a0522d", "tiles": ["T", "="]},
	Material.OIL_RESIDUE: {"id": "oil_residue", "name": "Oil Residue", "color": "#2c3e50", "tiles": ["B", "L"]},
}

const RECIPES := [
	{
		"id": "repair_kit",
		"name": "Repair Kit",
		"desc": "Restore 50% of equipment value",
		"materials": {Material.SCRAP_METAL: 2, Material.LEATHER_SCRAP: 1},
		"skill_level": 0,
		"output_count": 1,
		"value": 60,
	},
	{
		"id": "lantern_lens",
		"name": "Lantern Lens",
		"desc": "Trade good — sells well to keepers",
		"materials": {Material.GLASS_SHARDS: 3, Material.COPPER_WIRE: 1},
		"skill_level": 1,
		"output_count": 1,
		"value": 80,
	},
	{
		"id": "simple_lockpick",
		"name": "Simple Lockpick",
		"desc": "Open locked chests in dungeons",
		"materials": {Material.COPPER_WIRE: 2, Material.SCRAP_METAL: 1},
		"skill_level": 1,
		"output_count": 2,
		"value": 30,
	},
	{
		"id": "beacon_lens",
		"name": "Beacon Lens",
		"desc": "Increases beacon reveal radius",
		"materials": {Material.GLASS_SHARDS: 4, Material.OIL_RESIDUE: 2, Material.COPPER_WIRE: 2},
		"skill_level": 2,
		"output_count": 1,
		"value": 200,
	},
	{
		"id": "oil_lantern",
		"name": "Oil Lantern",
		"desc": "Permanent fog reduction in a small area",
		"materials": {Material.OIL_RESIDUE: 3, Material.GLASS_SHARDS: 2, Material.WOOD_CHIP: 2},
		"skill_level": 2,
		"output_count": 1,
		"value": 150,
	},
	{
		"id": "master_repair_kit",
		"name": "Master Repair Kit",
		"desc": "Fully restore equipment value",
		"materials": {Material.SCRAP_METAL: 4, Material.COPPER_WIRE: 2, Material.LEATHER_SCRAP: 2},
		"skill_level": 3,
		"output_count": 1,
		"value": 300,
	},
	{
		"id": "trap_kit",
		"name": "Trap Kit",
		"desc": "Set a trap for the next encounter",
		"materials": {Material.WOOD_CHIP: 3, Material.SCRAP_METAL: 1, Material.LEATHER_SCRAP: 1},
		"skill_level": 1,
		"output_count": 2,
		"value": 40,
	},
]

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

static func get_material_id_by_string(mat_str: String) -> int:
	for mat_id: int in MATERIAL_INFO:
		if MATERIAL_INFO[mat_id]["id"] == mat_str:
			return mat_id
	return Material.NONE
