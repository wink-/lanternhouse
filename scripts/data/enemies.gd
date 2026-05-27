# EnemyDB — enemy templates, AI behaviors, and formations
# Tight numbers: small gold/xp drops, meaningful grind required
#
# [CODING CONCEPT: Data-Driven Design]
# Instead of hard-coding each enemy's behavior inside the battle logic,
# we store AI types ("smart", "pack", "boss") in a dictionary.
# The battle script looks up the AI type and acts accordingly.
# This means adding a new enemy behavior is just adding a string here
# + handling it in battle.gd's match statement. No spaghetti code.
#
# [CODING CONCEPT: Scaling / Multiplier]
# scaled_template() takes a base enemy and multiplies stats by a factor
# based on the player's level. This is how RPGs keep enemies relevant
# as you get stronger — the same Slime that was easy at level 1 is
# tougher when you meet it at level 10. The formula: scale = 1.0 + (level-1) * 0.12
class_name EnemyDB

# AI behavior types:
# "attack"   — random target (default)
# "smart"    — targets lowest-HP party member
# "pack"     — same target as first pack member
# "support"  — buffs/heals allies if any are wounded, else attacks
# "boss"     — cycles through special abilities
# "cunning"  — targets party member with lowest defense
const AI_BEHAVIORS := {
	"Slime": "attack",
	"Imp": "attack",
	"Wolf": "pack",
	"Ghoul": "smart",
	"Skeleton": "attack",
	"Ogre": "smart",
	"Wraith": "cunning",
	"Drake": "smart",
	"Golem": "attack",
	"ShadowWisp": "cunning",
	"Mournlight Shade": "boss",
	"AncientGrief": "boss",
}

# Status effects enemies can inflict:
# "poison"    — 2-3 dmg per round for 3 rounds
# "blind"     — 30% miss chance for 2 rounds
# "silence"   — cannot cast magic for 2 rounds
const ENEMY_SPECIALS := {
	"Ghoul": {"effect": "poison", "chance": 0.20},
	"Wraith": {"effect": "blind", "chance": 0.25},
	"ShadowWisp": {"effect": "silence", "chance": 0.20},
	"Mournlight Shade": {"specials": ["shadow_bolt", "life_drain", "summon_shadows"]},
	"AncientGrief": {"specials": ["sorrow_wave", "entomb", "wail"]},
}

static func template(enemy_name: String) -> Dictionary:
	match enemy_name:
		"Slime":    return {"hp":6,  "atk":2,  "def":0,  "agi":1,  "xp":3,  "gold":1}
		"Imp":      return {"hp":8,  "atk":3,  "def":1,  "agi":2,  "xp":5,  "gold":2}
		"Wolf":     return {"hp":10, "atk":5,  "def":1,  "agi":5,  "xp":7,  "gold":3}
		"Ghoul":    return {"hp":15, "atk":6,  "def":3,  "agi":3,  "xp":12, "gold":5}
		"Skeleton": return {"hp":13, "atk":7,  "def":2,  "agi":3,  "xp":10, "gold":4}
		"Ogre":     return {"hp":20, "atk":9,  "def":4,  "agi":2,  "xp":20, "gold":10}
		"Wraith":   return {"hp":17, "atk":8,  "def":5,  "agi":6,  "xp":16, "gold":8}
		"Drake":    return {"hp":30, "atk":12, "def":7,  "agi":4,  "xp":35, "gold":20}
		"Golem":    return {"hp":40, "atk":14, "def":10, "agi":1,  "xp":50, "gold":30}
		"ShadowWisp": return {"hp":14, "atk":9,  "def":4,  "agi":7,  "xp":18, "gold":8}
		"Mournlight Shade": return {"hp":120, "atk":18, "def":8,  "agi":6,  "xp":200, "gold":50}
		"AncientGrief": return {"hp":200, "atk":22, "def":12, "agi":5,  "xp":300, "gold":100}
		"DarkShade": return {"hp":8,  "atk":7,  "def":2,  "agi":4,  "xp":10, "gold":3}
	return {"hp":5, "atk":2, "def":0, "agi":2, "xp":3, "gold":1}

static func scaled_template(enemy_name: String, party_level: int) -> Dictionary:
	var base := template(enemy_name).duplicate(true)
	var scale := 1.0 + (party_level - 1) * 0.12
	if scale < 1.0:
		scale = 1.0
	base["hp"] = int(base["hp"] * scale)
	base["atk"] = int(base["atk"] * scale)
	base["def"] = int(base["def"] * scale)
	base["agi"] = int(base["agi"] * scale)
	base["xp"] = int(base["xp"] * scale)
	base["gold"] = int(base["gold"] * scale)
	base["name"] = enemy_name
	return base

static func get_formation(zone: String, party_level: int) -> Array:
	var formations: Array
	match zone:
		"grassland": formations = grassland_formations()
		"forest": formations = forest_formations()
		"mountain": formations = mountain_formations()
		"cave": formations = cave_formations()
		"beach": formations = beach_formations()
		"post_seal": formations = post_seal_formations()
		"cave_boss": formations = cave_boss_formation()
		"cave_deep": formations = cave_deep_formation()
		_: formations = grassland_formations()
	var formation := formations[randi() % formations.size()]
	var enemies: Array = []
	for group: Dictionary in formation:
		for _i in range(group["count"]):
			enemies.append(scaled_template(group["name"], party_level))
	return enemies

static func get_ai(enemy_name: String) -> String:
	return AI_BEHAVIORS.get(enemy_name, "attack")

static func get_special(enemy_name: String) -> Dictionary:
	return ENEMY_SPECIALS.get(enemy_name, {})

# ── Formations ───────────────────────────────────────────────────────────────
static func grassland_formations() -> Array:
	return [
		[{"name":"Slime","count":1}],
		[{"name":"Slime","count":2}],
		[{"name":"Imp","count":1}],
		[{"name":"Imp","count":1}, {"name":"Slime","count":1}],
		[{"name":"Imp","count":2}],
		[{"name":"Wolf","count":1}],
	]

static func forest_formations() -> Array:
	return [
		[{"name":"Wolf","count":1}],
		[{"name":"Wolf","count":2}],
		[{"name":"Imp","count":2}],
		[{"name":"Ghoul","count":1}],
		[{"name":"Wolf","count":1}, {"name":"Imp","count":1}],
		[{"name":"Skeleton","count":1}],
		[{"name":"Wolf","count":1}, {"name":"Ghoul","count":1}],
	]

static func mountain_formations() -> Array:
	return [
		[{"name":"Ghoul","count":1}],
		[{"name":"Skeleton","count":1}],
		[{"name":"Skeleton","count":2}],
		[{"name":"Ogre","count":1}],
		[{"name":"Wraith","count":1}],
		[{"name":"Ghoul","count":1}, {"name":"Skeleton","count":1}],
		[{"name":"Wolf","count":2}, {"name":"Ghoul","count":1}],
	]

static func cave_formations() -> Array:
	return [
		[{"name":"Skeleton","count":2}],
		[{"name":"Ghoul","count":2}],
		[{"name":"Wraith","count":1}],
		[{"name":"Ogre","count":1}, {"name":"Skeleton","count":1}],
		[{"name":"Drake","count":1}],
		[{"name":"Golem","count":1}],
		[{"name":"Wraith","count":2}],
	]

static func beach_formations() -> Array:
	return [
		[{"name":"Slime","count":2}],
		[{"name":"Slime","count":3}],
		[{"name":"Imp","count":1}, {"name":"Slime","count":1}],
		[{"name":"Wolf","count":1}],
		[{"name":"Imp","count":2}],
	]

static func post_seal_formations() -> Array:
	return [
		[{"name":"ShadowWisp","count":1}],
		[{"name":"ShadowWisp","count":2}],
		[{"name":"Wraith","count":1}, {"name":"ShadowWisp","count":1}],
		[{"name":"Ghoul","count":1}, {"name":"ShadowWisp","count":1}],
		[{"name":"ShadowWisp","count":1}, {"name":"Imp","count":2}],
		[{"name":"Wraith","count":2}],
	]

static func cave_boss_formation() -> Array:
	return [[{"name":"Mournlight Shade","count":1}]]

static func cave_deep_formation() -> Array:
	return [[{"name":"AncientGrief","count":1}]]
