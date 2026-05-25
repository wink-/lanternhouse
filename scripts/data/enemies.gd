# EnemyDB — enemy templates and formations
# Tight numbers: small gold/xp drops, meaningful grind required
class_name EnemyDB

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
	return {"hp":5, "atk":2, "def":0, "agi":2, "xp":3, "gold":1}

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
