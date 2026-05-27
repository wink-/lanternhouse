# CharDB — static class templates, spell definitions, level-up tables
#
# [CODING CONCEPT: Static / Lookup Tables]
# This file uses "static func" — functions you call on the class itself,
# not on an instance. Think of it like a dictionary that also has functions.
# No "new" needed: you just write CharDB.get_template("Fighter").
#
# The match statement (lines 8-15) is GDScript's version of switch/case.
# Each class gets a Dictionary with base stats. These are *templates* —
# the actual party members get copies (.duplicate(true)) so they can
# change independently (gain HP, level up, etc.)
#
# [CODING CONCEPT: Dictionaries as Records]
# {"str":12, "def":9, "hp":38} is a dictionary — a bag of named values.
# In other languages you'd use a class or struct for this. In GDScript,
# plain dictionaries are the common pattern for simple data like game stats.
class_name CharDB

static func get_classes() -> Array:
	return ["Fighter", "Thief", "BlackBelt", "RedMage", "WhiteMage", "BlackMage"]

static func get_template(cls_name: String) -> Dictionary:
	match cls_name:
		"Fighter":   return {"str":12, "def":9,  "agi":5,  "hp":38, "magic_levels":{}}
		"Thief":     return {"str":8,  "def":5,  "agi":10, "hp":28, "magic_levels":{}}
		"BlackBelt": return {"str":10, "def":4,  "agi":8,  "hp":32, "magic_levels":{}}
		"RedMage":   return {"str":7,  "def":6,  "agi":7,  "hp":26, "magic_levels":{1:3}}
		"WhiteMage": return {"str":5,  "def":4,  "agi":6,  "hp":24, "magic_levels":{1:4}}
		"BlackMage": return {"str":5,  "def":4,  "agi":6,  "hp":22, "magic_levels":{1:3}}
	return {}

static func spells_for_level(lvl: int) -> Array:
	match lvl:
		1: return [
			{"name":"Cure",  "heal":18, "target":"ally"},
			{"name":"Fire",  "dmg":18,  "target":"enemy"},
			{"name":"Blind", "dmg":10,  "target":"enemy"},
		]
		2: return [
			{"name":"Cura",   "heal":36, "target":"ally"},
			{"name":"Fira",   "dmg":36,  "target":"enemy"},
			{"name":"Thunder","dmg":28,  "target":"enemy"},
		]
		3: return [
			{"name":"Curaga", "heal":72, "target":"ally"},
			{"name":"Firaga", "dmg":72,  "target":"enemy"},
		]
	return []

static func level_up_stats(cls_name: String, rng: RandomNumberGenerator) -> Dictionary:
	# Returns {hp_gain, str_gain, def_gain, agi_gain}
	# Small gains — sometimes nothing. Makes gear feel more impactful.
	match cls_name:
		"Fighter":   return {"hp":rng.randi_range(3,6),  "str":rng.randi_range(0,1), "def":rng.randi_range(0,1), "agi":rng.randi_range(0,0)}
		"Thief":     return {"hp":rng.randi_range(2,5),  "str":rng.randi_range(0,1), "def":rng.randi_range(0,0), "agi":rng.randi_range(0,1)}
		"BlackBelt": return {"hp":rng.randi_range(3,5),  "str":rng.randi_range(0,1), "def":rng.randi_range(0,0), "agi":rng.randi_range(0,1)}
		"RedMage":   return {"hp":rng.randi_range(2,4),  "str":rng.randi_range(0,0), "def":rng.randi_range(0,0), "agi":rng.randi_range(0,0)}
		_:           return {"hp":rng.randi_range(2,4),  "str":rng.randi_range(0,0), "def":rng.randi_range(0,0), "agi":rng.randi_range(0,0)}
