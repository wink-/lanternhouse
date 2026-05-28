# GameData — autoload singleton holding all persistent game state
# Survives scene transitions. Party, inventory, gold, flags, map position.
#
# [CODING CONCEPT: Singleton Pattern]
# This script is registered as an "autoload" in project.godot. Godot creates
# exactly one instance of it when the game starts and keeps it alive forever.
# Any script can access it as GameData.party, GameData.gold, etc. — no imports,
# no passing references around. It's the game's shared memory.
#
# [CODING CONCEPT: Dictionaries as Game Objects]
# A party member is just a Dictionary: {"name": "Fighter", "hp": 38, ...}
# There's no Character class. This is common in small GDScript projects because
# dictionaries are easy to serialize (save to file) and flexible (add new keys
# without changing a class definition). The tradeoff: no autocomplete for keys,
# and typos in key names cause silent bugs.
#
# [CODING CONCEPT: Character Equipment Records]
# Each party member owns an "equipment" dictionary with weapon/head/body/accessory
# slots. This keeps join/leave/reorder behavior local to the character record.

extends Node

const CharDB := preload("res://scripts/data/classes.gd")
const FactionDB := preload("res://scripts/data/factions.gd")

# ── Party ─────────────────────────────────────────────────────────────────
var party: Array = []            # Array[Dictionary] — 4 characters
var gold: int = 500              # total value in copper (100 copper = 1 silver, 100 silver = 1 gold)
var tonics: int = 3
var ethers: int = 0

# ── Currency ──────────────────────────────────────────────────────────────
var keeper_marks: int = 0        # Keeper Guild faction currency
var harbor_tokens: int = 0       # Harbor Compact faction currency
var chapel_script: int = 0       # Grey Chapel faction currency

# ── Faction reputation ────────────────────────────────────────────────────
var faction_reputation: Dictionary = {}   # FactionDB.Faction enum → int (-100 to +100)

# ── Equipment inventory (what's in the bag, not equipped) ─────────────────
var weapons_bag: Array = []      # Array[Dictionary] — weapon entries {id, name, atk, price}
var armor_bag: Array = []        # Array[Dictionary] — armor entries {id, name, def, price}
var trade_goods: Array = []      # Array[Dictionary] — trade goods in inventory {id, name, price, sell_base}

# ── Overworld state ───────────────────────────────────────────────────────
var overworld_position: Vector2i = Vector2i(15, 21)
var overworld_facing: Vector2i = Vector2i.DOWN

# ── Flags ─────────────────────────────────────────────────────────────────
var cleared_encounters: Dictionary = {}   # str(Vector2i) → true
var visited_town: bool = false
var boss_defeated: bool = false
var beacon_lit: bool = false
var beacon_states: Dictionary = {}  # str(Vector2i) → true/false for each beacon

# ── Home ownership ──────────────────────────────────────────────────────────
var owned_home: String = ""  # id of owned property, "" = none
var home_upgrades: Dictionary = {}  # upgrade_id → true
var home_storage: Array = []  # items stored in home chest

# ── Alchemy & Tinkering inventory ──────────────────────────────────────────
var herb_bag: Dictionary = {}   # herb_id_string -> int count
var material_bag: Dictionary = {}  # material_id_string -> int count
var crafted_items: Array = []  # potions/tools crafted

var explored_tiles: Dictionary = {}  # str(Vector2i) → true
var active_quests: Dictionary = {}   # quest_id → {"status": "active"/"complete", "progress": int}
var kill_counts: Dictionary = {}     # enemy_name → int
var gather_counts: Dictionary = {}  # gather_type → int (herb, fish, etc.)
var gather_sites: Dictionary = {}  # "type:Vector2i" -> site state
# ── Play time tracking ────────────────────────────────────────────────────
var play_time: float = 0.0

# ── Wage tracking ─────────────────────────────────────────────────────────
var wage_timer: float = 0.0
var pending_departures: Array = []   # names of members departing after battle
const WAGE_INTERVAL := 120.0  # seconds between wage cycles (~2 min)
signal wage_paid(name: String, amount: int)
signal wage_failed(name: String)
signal member_departed(name: String)

# ── Property income & tax ──────────────────────────────────────────────
const PROPERTY_RENT := {
	"cottage": 15, "townhouse": 50, "manor": 150, "lighthouse_keeper": 30,
}
const PROPERTY_TAX_RATE := 0.10
var property_market_mod: float = 1.0
var market_cycle: int = 0
signal rent_collected(amount: int)
signal tax_paid(amount: int)

# ── Skill tracking (use-based progression) ──────────────────────────────────
var skill_uses: Dictionary = {}   # "skill_name" → int (total uses across party)
const SKILL_TIERS := {
	0: "Novice", 10: "Adept", 30: "Expert", 60: "Master",
}

# ── Inventory limits ────────────────────────────────────────────────────
const WEAPONS_BAG_LIMIT := 12
const ARMOR_BAG_LIMIT := 12
const TRADE_GOODS_LIMIT := 8

func bag_full(bag_type: String) -> bool:
	match bag_type:
		"weapons": return weapons_bag.size() >= WEAPONS_BAG_LIMIT
		"armor": return armor_bag.size() >= ARMOR_BAG_LIMIT
		"trade": return trade_goods.size() >= TRADE_GOODS_LIMIT
	return false

# ── Initialization ────────────────────────────────────────────────────────
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if party.is_empty():
		_init_party()
	ensure_party_equipment()

func _process(delta: float) -> void:
	play_time += delta
	wage_timer += delta
	if wage_timer >= WAGE_INTERVAL:
		wage_timer -= WAGE_INTERVAL
		_process_wages()

func _process_wages() -> void:
	for m: Dictionary in party:
		if m.get("wage", 0) > 0 and m["alive"]:
			var wage: int = m["wage"]
			if spend_copper(wage):
				m["loyalty"] = mini(m.get("loyalty", 50) + 2, 100)
				wage_paid.emit(m["name"], wage)
			else:
				m["loyalty"] = maxi(m.get("loyalty", 50) - 10, 0)
				wage_failed.emit(m["name"])
	_process_property_income()

func _process_property_income() -> void:
	_update_property_market()
	if owned_home == "":
		return
	var rent_base: int = PROPERTY_RENT.get(owned_home, 0)
	var lit_count: int = beacon_states.values().filter(func(v): return v == true).size()
	var rent: int = rent_base + (rent_base * lit_count / 5)
	add_copper(rent)
	rent_collected.emit(rent)
	var tax: int = int(get_home_price(owned_home) * PROPERTY_TAX_RATE * maxi(lit_count - 1, 0))
	if tax > 0:
		spend_copper(tax)
		tax_paid.emit(tax)

func get_property_rent() -> int:
	if owned_home == "":
		return 0
	var rent_base: int = PROPERTY_RENT.get(owned_home, 0)
	var lit_count: int = beacon_states.values().filter(func(v): return v == true).size()
	return rent_base + (rent_base * lit_count / 5)

func get_property_tax() -> int:
	if owned_home == "":
		return 0
	var lit_count: int = beacon_states.values().filter(func(v): return v == true).size()
	return int(get_home_price(owned_home) * PROPERTY_TAX_RATE * maxi(lit_count - 1, 0))

const DAY_CYCLE_SECONDS := 300.0
const SEASON_LENGTH_DAYS := 30
const YEAR_LENGTH_DAYS := SEASON_LENGTH_DAYS * 4

func get_day_phase() -> String:
	var t := fmod(play_time, DAY_CYCLE_SECONDS) / DAY_CYCLE_SECONDS
	if t < 0.15:
		return "night"
	elif t < 0.3:
		return "dawn"
	elif t < 0.7:
		return "day"
	elif t < 0.85:
		return "dusk"
	else:
		return "night"

func get_current_day() -> int:
	return int(floor(play_time / DAY_CYCLE_SECONDS))

func get_season_name() -> String:
	var season_idx := int(floor(float(get_current_day() % YEAR_LENGTH_DAYS) / SEASON_LENGTH_DAYS))
	match season_idx:
		0: return "spring"
		1: return "summer"
		2: return "autumn"
		_: return "winter"

func is_growing_season() -> bool:
	var season := get_season_name()
	return season == "spring" or season == "summer"

# Called once when the game first starts and party is empty.
# Creates 4 starter characters from class templates.
# .duplicate(true) makes a deep copy so leveling one character
# doesn't affect the template for future new games.
func _init_party() -> void:
	for cls_name in ["Fighter", "Thief", "BlackBelt", "RedMage"]:
		var tmpl: Dictionary = CharDB.get_template(cls_name).duplicate(true)
		party.append({
			"name": cls_name,
			"class": cls_name,
			"hp": tmpl["hp"],  "max_hp": tmpl["hp"],
			"str": tmpl["str"], "def": tmpl["def"], "agi": tmpl["agi"],
			"level": 1, "xp": 0, "next_xp": 18,
			"magic_levels": _copy_magic(tmpl.get("magic_levels", {})),
			"alive": true,
			"command": "",
			"command_label": "",
			"equipment": create_empty_equipment(),
		})

func _copy_magic(src: Dictionary) -> Dictionary:
	var out := {}
	for lvl: int in src:
		out[lvl] = {"charges": src[lvl], "max": src[lvl]}
	return out

func create_empty_equipment() -> Dictionary:
	return {
		"weapon": -1,
		"head": -1,
		"body": -1,
		"accessory": -1,
	}

func ensure_party_equipment() -> void:
	for member: Dictionary in party:
		var equipment: Dictionary = member.get("equipment", {})
		if equipment.is_empty():
			equipment = create_empty_equipment()
		else:
			for slot: String in ["weapon", "head", "body", "accessory"]:
				if not equipment.has(slot):
					equipment[slot] = -1
		member["equipment"] = equipment

func get_equipped_index(char_index: int, slot: String) -> int:
	if char_index < 0 or char_index >= party.size():
		return -1
	ensure_party_equipment()
	return int(party[char_index].get("equipment", {}).get(slot, -1))

func set_equipped_index(char_index: int, slot: String, bag_index: int) -> void:
	if char_index < 0 or char_index >= party.size():
		return
	ensure_party_equipment()
	var equipment: Dictionary = party[char_index]["equipment"]
	equipment[slot] = bag_index
	party[char_index]["equipment"] = equipment

func is_weapon_equipped(bag_index: int) -> bool:
	ensure_party_equipment()
	for member: Dictionary in party:
		if int(member.get("equipment", {}).get("weapon", -1)) == bag_index:
			return true
	return false

func is_armor_equipped(bag_index: int) -> bool:
	ensure_party_equipment()
	for member: Dictionary in party:
		var equipment: Dictionary = member.get("equipment", {})
		if int(equipment.get("head", -1)) == bag_index:
			return true
		if int(equipment.get("body", -1)) == bag_index:
			return true
		if int(equipment.get("accessory", -1)) == bag_index:
			return true
	return false

func adjust_equipment_after_bag_remove(bag_type: String, removed_index: int) -> void:
	ensure_party_equipment()
	for pi in range(party.size()):
		var slots := ["weapon"] if bag_type == "weapon" else ["head", "body", "accessory"]
		for slot: String in slots:
			var current := get_equipped_index(pi, slot)
			if current == removed_index:
				set_equipped_index(pi, slot, -1)
			elif current > removed_index:
				set_equipped_index(pi, slot, current - 1)

# ── Stat helpers ──────────────────────────────────────────────────────────
# [CODING CONCEPT: Computed Properties]
# Characters have a base STR, but equipment adds more. get_effective_str()
# combines base + weapon bonus + loyalty bonus into the "real" number used
# in combat. This is cleaner than modifying the base stat every time you
# equip/unequip — the base stays pure, and the effective value is always
# recalculated from current state.
func get_effective_str(char_index: int) -> int:
	var m: Dictionary = party[char_index]
	var base: int = m["str"]
	var wi: int = get_equipped_index(char_index, "weapon")
	if wi >= 0 and wi < weapons_bag.size():
		base += weapons_bag[wi].get("atk", 0)
	if m.get("wage", 0) > 0 and m.get("loyalty", 50) >= 80:
		base = int(base * 1.1)
	return base

func get_effective_def(char_index: int) -> int:
	var m: Dictionary = party[char_index]
	var base: int = m["def"]
	for slot: String in ["head", "body", "accessory"]:
		var ai: int = get_equipped_index(char_index, slot)
		if ai >= 0 and ai < armor_bag.size():
			base += armor_bag[ai].get("def", 0)
	if m.get("wage", 0) > 0 and m.get("loyalty", 50) >= 80:
		base = int(base * 1.1)
	return base

func get_equipped_fishing_bonus() -> int:
	var bonus := 0
	for pi in range(party.size()):
		var wi := get_equipped_index(pi, "weapon")
		if wi >= 0 and wi < weapons_bag.size():
			var weapon: Dictionary = weapons_bag[wi]
			if weapon.has("fishing_bonus"):
				bonus += weapon.get("fishing_bonus", 0)
			elif "pole" in str(weapon.get("id", "")).to_lower() or "pole" in str(weapon.get("name", "")).to_lower():
				bonus += 1
	return bonus

func full_heal() -> void:
	for m in party:
		m["hp"] = m["max_hp"]
		m["alive"] = true
		for lvl: int in m["magic_levels"]:
			m["magic_levels"][lvl]["charges"] = m["magic_levels"][lvl]["max"]
	tonics = 3

func anyone_alive() -> bool:
	for m in party:
		if m["alive"]:
			return true
	return false

func alive_count() -> int:
	var c := 0
	for m in party:
		if m["alive"]:
			c += 1
	return c

# ── Currency helpers ─────────────────────────────────────────────────────
# [CODING CONCEPT: Unit Conversion]
# Gold is stored as one integer in copper pieces (the smallest unit).
# 100 copper = 1 silver, 100 silver = 1 gold piece. These helper functions
# break the single number into display parts. Storing one value is simpler
# than tracking three separate variables and keeps arithmetic clean.
func gold_pieces() -> int:
	return gold / 10000

func silver_pieces() -> int:
	return (gold % 10000) / 100

func copper_pieces() -> int:
	return gold % 100

func format_money() -> String:
	return "%dg %ds %dc" % [gold_pieces(), silver_pieces(), copper_pieces()]

func format_money_short() -> String:
	var g := gold_pieces()
	var s := silver_pieces()
	var c := copper_pieces()
	if g > 0:
		return "%dg %ds" % [g, s]
	elif s > 0:
		return "%ds %dc" % [s, c]
	return "%dc" % c

func add_copper(amount: int) -> void:
	gold = maxi(gold + amount, 0)

func spend_copper(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		return true
	return false

func get_price_with_beacon_modifier(base_price: int) -> int:
	var lit_count := beacon_states.values().filter(func(v): return v == true).size()
	var modifier := 1.0 + lit_count * 0.05
	return int(base_price * modifier)

# ── Currency exchange helpers ─────────────────────────────────────────────
func get_currency_balance(currency: String) -> int:
	match currency:
		"copper": return gold
		"keeper_marks": return keeper_marks
		"harbor_tokens": return harbor_tokens
		"chapel_script": return chapel_script
	return 0

func add_currency(currency: String, amount: int) -> void:
	match currency:
		"copper": gold = maxi(gold + amount, 0)
		"keeper_marks": keeper_marks = maxi(keeper_marks + amount, 0)
		"harbor_tokens": harbor_tokens = maxi(harbor_tokens + amount, 0)
		"chapel_script": chapel_script = maxi(chapel_script + amount, 0)

func spend_currency(currency: String, amount: int) -> bool:
	if get_currency_balance(currency) >= amount:
		match currency:
			"copper": gold -= amount
			"keeper_marks": keeper_marks -= amount
			"harbor_tokens": harbor_tokens -= amount
			"chapel_script": chapel_script -= amount
		return true
	return false

func get_currency_buy_rate(currency: String) -> int:
	var base_rates := {"keeper_marks": 150, "harbor_tokens": 120, "chapel_script": 130}
	var rate: int = base_rates.get(currency, 100)
	var lit_count: int = beacon_states.values().filter(func(v): return v == true).size()
	if currency == "keeper_marks":
		rate = int(rate * (1.0 + lit_count * 0.08))
	elif currency == "harbor_tokens":
		rate = int(rate * (1.0 - lit_count * 0.02))
	return maxi(rate, 50)

func get_currency_sell_rate(currency: String) -> int:
	var base_rates := {"keeper_marks": 120, "harbor_tokens": 95, "chapel_script": 105}
	var rate: int = base_rates.get(currency, 80)
	var lit_count: int = beacon_states.values().filter(func(v): return v == true).size()
	if currency == "keeper_marks":
		rate = int(rate * (1.0 + lit_count * 0.08))
	elif currency == "harbor_tokens":
		rate = int(rate * (1.0 - lit_count * 0.02))
	return maxi(rate, 30)

# ── Skill helpers ────────────────────────────────────────────────────────
func track_skill_use(skill_name: String, count: int = 1) -> void:
	skill_uses[skill_name] = skill_uses.get(skill_name, 0) + count

func get_skill_tier(skill_name: String) -> String:
	var uses: int = skill_uses.get(skill_name, 0)
	var tier: String = "Novice"
	for threshold: int in SKILL_TIERS:
		if uses >= threshold:
			tier = SKILL_TIERS[threshold]
	return tier

func get_skill_bonus(skill_name: String) -> int:
	var uses: int = skill_uses.get(skill_name, 0)
	if uses >= 60: return 3
	if uses >= 30: return 2
	if uses >= 10: return 1
	return 0

func apply_meal_buff(meal_name: String, heal_value: int) -> Dictionary:
	var def_bonus: int = clampi(1 + int(heal_value / 40) + get_skill_bonus("cooking"), 1, 6)
	var battles := 3
	set_meta("meal_buff_name", meal_name)
	set_meta("meal_buff_def", def_bonus)
	set_meta("meal_buff_battles", battles)
	return {"name": meal_name, "def": def_bonus, "battles": battles}

# ── Faction helpers ─────────────────────────────────────────────────────────
func get_faction_rep(faction: int) -> int:
	return faction_reputation.get(faction, 0)

func change_faction_rep(faction: int, amount: int) -> void:
	var current: int = faction_reputation.get(faction, 0)
	faction_reputation[faction] = clampi(current + amount, -100, 100)

func get_faction_tier_name(faction: int) -> String:
	return FactionDB.reputation_tier(get_faction_rep(faction))

func get_faction_price_mod(faction: int) -> float:
	return FactionDB.price_modifier(get_faction_rep(faction))

# ── Loyalty departure ──────────────────────────────────────────────────────
func check_loyalty_departures() -> void:
	var i := party.size() - 1
	while i >= 0:
		var m: Dictionary = party[i]
		if m.get("wage", 0) > 0 and m.get("loyalty", 50) <= 0 and not m.get("departed", false):
			m["departed"] = true
			member_departed.emit(m["name"])
			# Mark in roster pool
			var roster_pool = get_meta("roster_pool", [])
			for entry in roster_pool:
				if entry["name"] == m["name"]:
					entry["departed"] = true
					break
			set_meta("roster_pool", roster_pool)
		i -= 1

func remove_departed_members() -> void:
	ensure_party_equipment()
	var i := party.size() - 1
	while i >= 0:
		if party[i].get("departed", false):
			pending_departures.erase(party[i]["name"])
			party.remove_at(i)
		i -= 1

# ── Home helpers ────────────────────────────────────────────────────────────
func get_home_price(home_id: String) -> int:
	var base_prices := {"cottage": 2000, "townhouse": 8000, "manor": 25000, "lighthouse_keeper": 5000}
	var base: int = base_prices.get(home_id, 5000)
	var lit_count: int = beacon_states.values().filter(func(v): return v == true).size()
	base = int(base * (1.0 + lit_count * 0.1) * property_market_mod)
	return base

func get_home_value(home_id: String) -> int:
	return get_home_price(home_id)

func _update_property_market() -> void:
	market_cycle += 1
	var baseline := 1.0
	var lit_count: int = beacon_states.values().filter(func(v): return v == true).size()
	baseline += lit_count * 0.05
	if gather_counts.get("trade_profit", 0) > 500:
		baseline += 0.1
	# Faction reputation affects property market
	var harbor_rep: int = faction_reputation.get(FactionDB.Faction.HARBOR_COMPACT, 0)
	baseline += harbor_rep * 0.001
	# Smooth drift toward baseline with noise
	var drift := (baseline - property_market_mod) * 0.1
	var noise := (randf() - 0.5) * 0.15
	property_market_mod = clampf(property_market_mod + drift + noise, 0.6, 1.6)
	# Rare market events
	if randf() < 0.05:
		if randf() < 0.5:
			property_market_mod += 0.15
		else:
			property_market_mod -= 0.15
	property_market_mod = clampf(property_market_mod, 0.6, 1.6)

func owns_home() -> bool:
	return owned_home != ""

func buy_home(home_id: String) -> bool:
	var price := get_home_price(home_id)
	if not spend_copper(price):
		return false
	owned_home = home_id
	return true

func has_upgrade(upgrade_id: String) -> bool:
	return home_upgrades.get(upgrade_id, false)

func buy_upgrade(upgrade_id: String, price: int) -> bool:
	if not spend_copper(price):
		return false
	home_upgrades[upgrade_id] = true
	return true

# ── Quest helpers ────────────────────────────────────────────────────────────
func accept_quest(qid: String) -> void:
	if not active_quests.has(qid):
		active_quests[qid] = {"status": "active", "progress": 0}

func complete_quest(qid: String) -> void:
	if active_quests.has(qid):
		active_quests[qid]["status"] = "complete"

func is_quest_active(qid: String) -> bool:
	return active_quests.has(qid) and active_quests[qid]["status"] == "active"

func is_quest_complete(qid: String) -> bool:
	return active_quests.has(qid) and active_quests[qid]["status"] == "complete"

func get_quest_progress(qid: String) -> int:
	if active_quests.has(qid):
		return active_quests[qid].get("progress", 0)
	return 0

func track_kill(enemy_name: String) -> void:
	kill_counts[enemy_name] = kill_counts.get(enemy_name, 0) + 1

# ── Herb helpers ─────────────────────────────────────────────────────────────
func add_herb(herb_id: String, count: int = 1) -> void:
	herb_bag[herb_id] = herb_bag.get(herb_id, 0) + count

func remove_herb(herb_id: String, count: int = 1) -> bool:
	if herb_bag.get(herb_id, 0) < count:
		return false
	herb_bag[herb_id] -= count
	if herb_bag[herb_id] <= 0:
		herb_bag.erase(herb_id)
	return true

func get_herb_count(herb_id: String) -> int:
	return herb_bag.get(herb_id, 0)

# ── Material helpers ──────────────────────────────────────────────────────
func add_material(material_id: String, count: int = 1) -> void:
	material_bag[material_id] = material_bag.get(material_id, 0) + count

func remove_material(material_id: String, count: int = 1) -> bool:
	if material_bag.get(material_id, 0) < count:
		return false
	material_bag[material_id] -= count
	if material_bag[material_id] <= 0:
		material_bag.erase(material_id)
	return true

func get_material_count(material_id: String) -> int:
	return material_bag.get(material_id, 0)

# ── Crafted items ─────────────────────────────────────────────────────────
func add_crafted_item(item: Dictionary) -> void:
	crafted_items.append(item)
