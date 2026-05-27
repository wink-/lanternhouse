# ItemDB — weapons and armor definitions
# Vanilla-WoW philosophy: small stat bumps, every upgrade matters
#
# [CODING CONCEPT: Tiered Data / Power Curves]
# Weapons go from ATK 1 (Wooden Sword) to ATK 17 (Dragon Sword).
# Each tier is ~+2-3 ATK, and prices roughly double. This creates a
# "power curve" — the game gets harder to match your growing strength,
# and each new sword feels like a real upgrade, not an afterthought.
#
# [CODING CONCEPT: Filtering with Lambda Functions]
# trade_goods() uses .filter(func(i): return i.get("trade", false))
# That "func(i):" is an inline/anonymous function (lambda). It runs
# on every item in the list and keeps only the ones where trade=true.
# It's a concise way to pull a subset from a larger dataset.
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
# Each tier is +2-4 DEF over the previous. Slot: head, body, accessory.
static func armor_list() -> Array:
	return [
		# Body armor
		{"id":"cloth_armor",   "name":"Cloth Armor",   "def":2,  "price":10,  "slot":"body"},
		{"id":"leather_armor", "name":"Leather Armor",  "def":4,  "price":40,  "slot":"body"},
		{"id":"chain_mail",    "name":"Chain Mail",     "def":6,  "price":120, "slot":"body"},
		{"id":"iron_armor",    "name":"Iron Armor",     "def":9,  "price":300, "slot":"body"},
		{"id":"steel_armor",   "name":"Steel Armor",    "def":12, "price":650, "slot":"body"},
		{"id":"mythril_armor", "name":"Mythril Armor",  "def":16, "price":1300,"slot":"body"},
		{"id":"dragon_mail",   "name":"Dragon Mail",    "def":21, "price":3000,"slot":"body"},
		# Head armor
		{"id":"leather_cap",   "name":"Leather Cap",    "def":1,  "price":8,   "slot":"head"},
		{"id":"iron_helm",     "name":"Iron Helm",      "def":3,  "price":80,  "slot":"head"},
		{"id":"steel_helm",    "name":"Steel Helm",     "def":5,  "price":250, "slot":"head"},
		{"id":"mythril_helm",  "name":"Mythril Helm",   "def":7,  "price":800, "slot":"head"},
		{"id":"dragon_crown",  "name":"Dragon Crown",   "def":10, "price":2200,"slot":"head"},
		# Accessories
		{"id":"copper_ring",   "name":"Copper Ring",    "def":1,  "price":15,  "slot":"accessory"},
		{"id":"silver_ring",   "name":"Silver Ring",    "def":2,  "price":60,  "slot":"accessory"},
		{"id":"guard_amulet",  "name":"Guard Amulet",   "def":3,  "price":180, "slot":"accessory"},
		{"id":"ward_pendant",  "name":"Ward Pendant",   "def":5,  "price":500, "slot":"accessory"},
		{"id":"dragon_heart",  "name":"Dragon Heart",   "def":8,  "price":1800,"slot":"accessory"},
	]

# ── Shop items ────────────────────────────────────────────────────────────
static func item_shop_list() -> Array:
	return [
		{"id":"tonic",   "name":"Tonic",    "price":8,  "desc":"Heals ~20 HP to one ally"},
		{"id":"ether",   "name":"Ether",    "price":60, "desc":"Restores 1 magic charge to all levels"},
		{"id":"oil_jar", "name":"Beacon Oil",  "price":15, "desc":"Trade good — sells for more near beacons", "trade":true, "sell_base":20},
		{"id":"salt_bag","name":"Salt Pouch",   "price":25, "desc":"Trade good — Harbor Compact values these", "trade":true, "sell_base":35},
		{"id":"herb_bun","name":"Chapel Herb",   "price":30, "desc":"Trade good — healers pay well for fresh herbs", "trade":true, "sell_base":45},
	]

static func trade_goods() -> Array:
	return item_shop_list().filter(func(i): return i.get("trade", false))

static func get_sell_price(item_id: String) -> int:
	var all_items := weapon_list() + armor_list() + item_shop_list()
	for item in all_items:
		if item["id"] == item_id:
			if item.get("trade", false):
				return item.get("sell_base", item["price"])
			return int(item["price"] * 0.5)
	return 0
