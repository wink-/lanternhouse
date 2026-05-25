# ItemDB — weapons and armor definitions
# Vanilla-WoW philosophy: small stat bumps, every upgrade matters
class_name ItemDB

# ── Weapons ───────────────────────────────────────────────────────────────
# Each tier is +2-3 ATK over the previous. Prices scale to require grinding.
static func weapon_list() -> Array:
	return [
		{"id":"wooden_sword",  "name":"Wooden Sword",  "atk":1,  "price":15},
		{"id":"short_sword",   "name":"Short Sword",   "atk":3,  "price":50},
		{"id":"long_sword",    "name":"Long Sword",    "atk":5,  "price":140},
		{"id":"broad_sword",   "name":"Broad Sword",   "atk":7,  "price":350},
		{"id":"battle_axe",    "name":"Battle Axe",    "atk":10, "price":700},
		{"id":"flame_blade",   "name":"Flame Blade",   "atk":13, "price":1400},
		{"id":"dragon_sword",  "name":"Dragon Sword",  "atk":17, "price":3200},
	]

# ── Armor ─────────────────────────────────────────────────────────────────
# Each tier is +2-4 DEF over the previous.
static func armor_list() -> Array:
	return [
		{"id":"cloth_armor",   "name":"Cloth Armor",   "def":1,  "price":10},
		{"id":"leather_armor", "name":"Leather Armor",  "def":3,  "price":40},
		{"id":"chain_mail",    "name":"Chain Mail",     "def":5,  "price":120},
		{"id":"iron_armor",    "name":"Iron Armor",     "def":8,  "price":300},
		{"id":"steel_armor",   "name":"Steel Armor",    "def":11, "price":650},
		{"id":"mythril_armor", "name":"Mythril Armor",  "def":15, "price":1300},
		{"id":"dragon_mail",   "name":"Dragon Mail",    "def":20, "price":3000},
	]

# ── Shop items ────────────────────────────────────────────────────────────
static func item_shop_list() -> Array:
	return [
		{"id":"tonic",   "name":"Tonic",    "price":8,  "desc":"Heals ~20 HP to one ally"},
		{"id":"ether",   "name":"Ether",    "price":60, "desc":"Restores 1 magic charge to all levels"},
	]
