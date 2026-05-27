# FishDB — fish types, zones, and rarity
class_name FishDB

enum Zone { COAST, FOREST_RIVER, MOUNTAIN_LAKE, DEEP_WATER }

static func all_fish() -> Array:
	return [
		# Common coast fish
		{"id":"sardine",       "name":"Sardine",        "zone": Zone.COAST,          "rarity": 0.40, "price": 5,  "cooking": {"hp": 10}, "skill": 0},
		{"id":"mackerel",      "name":"Mackerel",       "zone": Zone.COAST,          "rarity": 0.30, "price": 8,  "cooking": {"hp": 15}, "skill": 0},
		{"id":"perch",         "name":"Perch",           "zone": Zone.COAST,          "rarity": 0.20, "price": 12, "cooking": {"hp": 25}, "skill": 5},
		{"id":"bass",          "name":"Sea Bass",        "zone": Zone.COAST,          "rarity": 0.10, "price": 20, "cooking": {"hp": 40}, "skill": 15},
		# Forest river fish
		{"id":"trout",         "name":"Trout",           "zone": Zone.FOREST_RIVER,   "rarity": 0.35, "price": 10, "cooking": {"hp": 20}, "skill": 5},
		{"id":"salmon",        "name":"Salmon",          "zone": Zone.FOREST_RIVER,   "rarity": 0.25, "price": 18, "cooking": {"hp": 35}, "skill": 10},
		{"id":"catfish",       "name":"Catfish",         "zone": Zone.FOREST_RIVER,   "rarity": 0.20, "price": 25, "cooking": {"hp": 45}, "skill": 20},
		{"id":"golden_carp",   "name":"Golden Carp",     "zone": Zone.FOREST_RIVER,   "rarity": 0.05, "price": 80, "cooking": {"hp": 80}, "skill": 40},
		# Mountain lake fish
		{"id":"minnow",        "name":"Minnow",          "zone": Zone.MOUNTAIN_LAKE,  "rarity": 0.40, "price": 3,  "cooking": {"hp": 8},  "skill": 0},
		{"id":"char",          "name":"Arctic Char",     "zone": Zone.MOUNTAIN_LAKE,  "rarity": 0.25, "price": 22, "cooking": {"hp": 50}, "skill": 15},
		{"id":"pike",          "name":"Pike",            "zone": Zone.MOUNTAIN_LAKE,  "rarity": 0.15, "price": 35, "cooking": {"hp": 60}, "skill": 25},
		{"id":"frost_sturgeon","name":"Frost Sturgeon",  "zone": Zone.MOUNTAIN_LAKE,  "rarity": 0.05, "price": 120,"cooking": {"hp": 100},"skill": 50},
		# Deep water fish (rare, high value)
		{"id":"tuna",          "name":"Tuna",            "zone": Zone.DEEP_WATER,     "rarity": 0.25, "price": 30, "cooking": {"hp": 50}, "skill": 10},
		{"id":"swordfish",     "name":"Swordfish",       "zone": Zone.DEEP_WATER,     "rarity": 0.15, "price": 50, "cooking": {"hp": 70}, "skill": 25},
		{"id":"mournlight_eel","name":"Mournlight Eel",  "zone": Zone.DEEP_WATER,     "rarity": 0.05, "price": 150,"cooking": {"hp": 120},"skill": 60},
		{"id":"leviathan_fin", "name":"Leviathan Fin",   "zone": Zone.DEEP_WATER,     "rarity": 0.01, "price": 500,"cooking": {"hp": 200},"skill": 80},
	]

static func fish_for_zone(zone: int, skill_level: int) -> Array:
	var available: Array = []
	for fish in all_fish():
		if fish["zone"] == zone and skill_level >= fish["skill"]:
			available.append(fish)
	return available

static func zone_for_tile(tile: String) -> int:
	match tile:
		".": return Zone.COAST
		"~": return Zone.DEEP_WATER
		"T": return Zone.FOREST_RIVER
		"^", "#": return Zone.MOUNTAIN_LAKE
		_: return Zone.COAST

static func can_fish(tile: String) -> bool:
	return tile in [".", "~", "T", "^"]
