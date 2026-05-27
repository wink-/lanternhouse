class_name AlchemyDB

enum Herb {
	NONE = 0,
	SEA_KELP = 1,
	FOREST_MOSS = 2,
	MOUNTAIN_ROOT = 3,
	FOG_PETALS = 4,
	SALT_CRYSTAL = 5,
	BEACON_ASH = 6,
	WILD_SAGE = 7,
	DARK_CAP = 8,
}

const HERB_INFO := {
	Herb.SEA_KELP: {"id": "sea_kelp", "name": "Sea Kelp", "color": "#2ecc71", "tiles": ["~", "."]},
	Herb.FOREST_MOSS: {"id": "forest_moss", "name": "Forest Moss", "color": "#27ae60", "tiles": ["T"]},
	Herb.MOUNTAIN_ROOT: {"id": "mountain_root", "name": "Mountain Root", "color": "#8b6914", "tiles": ["^", "M"]},
	Herb.FOG_PETALS: {"id": "fog_petals", "name": "Fog Petals", "color": "#bdc3c7", "tiles": [","]},
	Herb.SALT_CRYSTAL: {"id": "salt_crystal", "name": "Salt Crystal", "color": "#ecf0f1", "tiles": ["."]},
	Herb.BEACON_ASH: {"id": "beacon_ash", "name": "Beacon Ash", "color": "#f39c12", "tiles": ["B", "L"]},
	Herb.WILD_SAGE: {"id": "wild_sage", "name": "Wild Sage", "color": "#1abc9c", "tiles": [",", "T"]},
	Herb.DARK_CAP: {"id": "dark_cap", "name": "Dark Cap", "color": "#8e44ad", "tiles": ["T", "^"]},
}

const RECIPES := [
	{
		"id": "minor_tonic",
		"name": "Minor Tonic",
		"desc": "Heals 15 HP",
		"effect": {"type": "heal", "hp": 15},
		"herbs": {Herb.SEA_KELP: 2},
		"skill_level": 0,
		"output_count": 3,
	},
	{
		"id": "tonic",
		"name": "Tonic",
		"desc": "Heals 30 HP",
		"effect": {"type": "heal", "hp": 30},
		"herbs": {Herb.FOREST_MOSS: 2, Herb.SALT_CRYSTAL: 1},
		"skill_level": 1,
		"output_count": 2,
	},
	{
		"id": "greater_tonic",
		"name": "Greater Tonic",
		"desc": "Heals 60 HP",
		"effect": {"type": "heal", "hp": 60},
		"herbs": {Herb.WILD_SAGE: 2, Herb.MOUNTAIN_ROOT: 1, Herb.FOREST_MOSS: 1},
		"skill_level": 2,
		"output_count": 2,
	},
	{
		"id": "ether_brew",
		"name": "Ether Brew",
		"desc": "Restores 2 magic charges",
		"effect": {"type": "ether", "charges": 2},
		"herbs": {Herb.FOG_PETALS: 3, Herb.SEA_KELP: 1},
		"skill_level": 1,
		"output_count": 1,
	},
	{
		"id": "antidote",
		"name": "Antidote",
		"desc": "Cures poison",
		"effect": {"type": "cure_poison"},
		"herbs": {Herb.DARK_CAP: 1, Herb.WILD_SAGE: 1},
		"skill_level": 0,
		"output_count": 2,
	},
	{
		"id": "strength_elixir",
		"name": "Strength Elixir",
		"desc": "+3 STR for next battle",
		"effect": {"type": "buff", "stat": "str", "amount": 3, "duration": "battle"},
		"herbs": {Herb.MOUNTAIN_ROOT: 2, Herb.BEACON_ASH: 1},
		"skill_level": 2,
		"output_count": 1,
	},
	{
		"id": "defense_elixir",
		"name": "Defense Elixir",
		"desc": "+3 DEF for next battle",
		"effect": {"type": "buff", "stat": "def", "amount": 3, "duration": "battle"},
		"herbs": {Herb.SALT_CRYSTAL: 2, Herb.BEACON_ASH: 1},
		"skill_level": 2,
		"output_count": 1,
	},
	{
		"id": "panacea",
		"name": "Panacea",
		"desc": "Full heal + restore charges",
		"effect": {"type": "full_restore"},
		"herbs": {Herb.WILD_SAGE: 3, Herb.FOG_PETALS: 2, Herb.BEACON_ASH: 1},
		"skill_level": 3,
		"output_count": 1,
	},
]

static func available_recipes(skill_level: int) -> Array:
	return RECIPES.filter(func(r): return r["skill_level"] <= skill_level)

static func herbs_for_tile(tile: String) -> Array:
	var herbs: Array = []
	for herb_id: int in HERB_INFO:
		var info: Dictionary = HERB_INFO[herb_id]
		if tile in info["tiles"]:
			herbs.append(herb_id)
	return herbs

static func can_gather(tile: String) -> bool:
	return not herbs_for_tile(tile).is_empty()

static func get_herb_name(herb_id: int) -> String:
	if HERB_INFO.has(herb_id):
		return HERB_INFO[herb_id]["name"]
	return "Unknown Herb"

static func get_herb_id_by_string(herb_str: String) -> int:
	for herb_id: int in HERB_INFO:
		if HERB_INFO[herb_id]["id"] == herb_str:
			return herb_id
	return Herb.NONE
