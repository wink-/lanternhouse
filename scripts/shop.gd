# Shop — buy weapons, armor, and items
#
# [CODING CONCEPT: Sub-Screens / Multi-Phase UI]
# The shop has two phases: browsing (selecting an item) and selecting_character
# (picking which party member gets the weapon/armor). A boolean (selecting_character)
# toggles between them, changing what keys do and what's displayed. This is a
# mini state machine — simpler than battle.gd's string-based one, but the same idea.
#
# [CODING CONCEPT: Price Modifiers]
# _get_price() doesn't just return the base price. It applies two modifiers:
# 1) beacon modifier (more beacons lit = higher prices) and 2) faction reputation
# (higher reputation with that faction = better prices). This creates an economy
# that responds to the player's progress through the world.
extends Node2D

const ItemDB := preload("res://scripts/data/items.gd")
const FactionDB := preload("res://scripts/data/factions.gd")

var shop_type: String = "weapons"   # "weapons", "armor", "items", "sell"
var shop_list: Array = []
var selected_idx: int = 0
var selecting_character: bool = false
var char_idx: int = 0
var sell_mode: bool = false
var sell_list: Array = []
var last_message: String = ""

@onready var text_display: RichTextLabel = $TextDisplay

func _ready() -> void:
	_layout_shop_panel()
	get_viewport().size_changed.connect(_layout_shop_panel)
	shop_type = GameData.get_meta("shop_type", "weapons")
	match shop_type:
		"weapons": shop_list = ItemDB.weapon_list()
		"armor":   shop_list = ItemDB.armor_list()
		"items":   shop_list = ItemDB.item_shop_list()
		"sell":    _build_sell_list()
		_:         shop_list = ItemDB.weapon_list()
	_update_display()

func _layout_shop_panel() -> void:
	var viewport_size := get_viewport_rect().size
	var preferred_size := Vector2(860, 580)
	var margin := Vector2(40, 40)
	var panel_size := Vector2(
		minf(preferred_size.x, maxf(320.0, viewport_size.x - margin.x * 2.0)),
		minf(preferred_size.y, maxf(240.0, viewport_size.y - margin.y * 2.0))
	)
	text_display.size = panel_size
	text_display.position = ((viewport_size - panel_size) * 0.5).floor()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	if selecting_character:
		match event.keycode:
			KEY_UP:    char_idx = max(0, char_idx - 1)
			KEY_DOWN:  char_idx = min(GameData.party.size() - 1, char_idx + 1)
			KEY_1, KEY_ENTER, KEY_SPACE:
				_buy_for_character(char_idx)
				return
			KEY_ESCAPE:
				selecting_character = false
		_update_display()
		return

	match event.keycode:
		KEY_UP:    selected_idx = max(0, selected_idx - 1)
		KEY_DOWN:  selected_idx = min(shop_list.size() - 1, selected_idx + 1)
		KEY_1, KEY_ENTER, KEY_SPACE:
			_try_buy()
		KEY_S:
			var prev_type: String = shop_type
			shop_type = "sell"
			_build_sell_list()
			if sell_list.is_empty():
				shop_type = prev_type
				last_message = "[color=gray]Nothing to sell right now.[/color]"
			_update_display()
		KEY_ESCAPE:
			if shop_type == "sell":
				shop_type = GameData.get_meta("shop_type", "weapons")
				match shop_type:
					"weapons": shop_list = ItemDB.weapon_list()
					"armor":   shop_list = ItemDB.armor_list()
					"items":   shop_list = ItemDB.item_shop_list()
				_update_display()
			else:
				SceneTransition.change_scene("res://scenes/town/town.tscn")
	_update_display()

func _try_buy() -> void:
	if shop_type == "sell":
		_do_sell(selected_idx)
		return
	if selected_idx < 0 or selected_idx >= shop_list.size():
		return
	var item: Dictionary = shop_list[selected_idx]
	var price: int = _get_price(item["price"])
	if price > GameData.gold:
		last_message = "[color=#c0392b]Not enough coin for %s. Need %s, you have %s.[/color]" % [item["name"], _format_price(price), _format_price(GameData.gold)]
		return

	if shop_type in ["weapons", "armor"]:
		selecting_character = true
		char_idx = 0
		_update_display()
		return

	if item.get("trade", false) and GameData.bag_full("trade"):
		last_message = "[color=#c0392b]Trade bag is full. Sell something before buying %s.[/color]" % item["name"]
		_update_display()
		return
	if GameData.spend_copper(price):
		if item.get("trade", false):
			GameData.trade_goods.append(item.duplicate(true))
			last_message = "[color=green]Bought %s.[/color]" % item["name"]
		else:
			match item["id"]:
				"tonic":
					GameData.tonics += 1
					last_message = "[color=green]Bought Tonic. Tonics: %d[/color]" % GameData.tonics
				"ether":
					GameData.ethers += 1
					_apply_ether()
					last_message = "[color=green]Bought Ether. Party magic charges restored. Ethers: %d[/color]" % GameData.ethers
	_update_display()

func _buy_for_character(ci: int) -> void:
	var item: Dictionary = shop_list[selected_idx]
	var price: int = _get_price(item["price"])
	if shop_type == "weapons" and _needs_new_weapon(item) and GameData.bag_full("weapons"):
		last_message = "[color=#c0392b]Weapon bag is full. Sell a spare weapon first.[/color]"
		selecting_character = false
		_update_display()
		return
	if shop_type == "armor" and _needs_new_armor(item) and GameData.bag_full("armor"):
		last_message = "[color=#c0392b]Armor bag is full. Sell spare armor first.[/color]"
		selecting_character = false
		_update_display()
		return
	if not GameData.spend_copper(price):
		last_message = "[color=#c0392b]Not enough coin for %s. Need %s, you have %s.[/color]" % [item["name"], _format_price(price), _format_price(GameData.gold)]
		selecting_character = false
		_update_display()
		return

	if shop_type == "weapons":
		# Check if already owned
		var existing: int = -1
		for i in range(GameData.weapons_bag.size()):
			if GameData.weapons_bag[i]["id"] == item["id"]:
				existing = i
				break
		if existing < 0:
			GameData.weapons_bag.append(item.duplicate(true))
			existing = GameData.weapons_bag.size() - 1
		GameData.set_equipped_index(ci, "weapon", existing)

	elif shop_type == "armor":
		var existing: int = -1
		for i in range(GameData.armor_bag.size()):
			if GameData.armor_bag[i]["id"] == item["id"]:
				existing = i
				break
		if existing < 0:
			GameData.armor_bag.append(item.duplicate(true))
			existing = GameData.armor_bag.size() - 1
		var slot: String = item.get("slot", "body")
		if not slot in ["head", "body", "accessory"]:
			slot = "body"
		GameData.set_equipped_index(ci, slot, existing)

	last_message = "[color=green]Equipped %s on %s.[/color]" % [item["name"], GameData.party[ci]["name"]]
	selecting_character = false
	_update_display()

func _needs_new_weapon(item: Dictionary) -> bool:
	for existing: Dictionary in GameData.weapons_bag:
		if existing["id"] == item["id"]:
			return false
	return true

func _needs_new_armor(item: Dictionary) -> bool:
	for existing: Dictionary in GameData.armor_bag:
		if existing["id"] == item["id"]:
			return false
	return true

func _apply_ether() -> void:
	for m: Dictionary in GameData.party:
		for lvl in m["magic_levels"]:
			var entry: Dictionary = m["magic_levels"][lvl]
			if entry["charges"] < entry["max"]:
				entry["charges"] = entry["max"]

func _build_sell_list() -> void:
	sell_list.clear()
	for i in range(GameData.weapons_bag.size()):
		var w: Dictionary = GameData.weapons_bag[i]
		if not GameData.is_weapon_equipped(i):
			sell_list.append({"type": "weapon", "idx": i, "id": w["id"], "name": w["name"], "sell_price": ItemDB.get_sell_price(w["id"])})
	for i in range(GameData.armor_bag.size()):
		var a: Dictionary = GameData.armor_bag[i]
		if not GameData.is_armor_equipped(i):
			sell_list.append({"type": "armor", "idx": i, "id": a["id"], "name": a["name"], "sell_price": ItemDB.get_sell_price(a["id"])})
	for i in range(GameData.trade_goods.size()):
		var tg: Dictionary = GameData.trade_goods[i]
		var base_sell: int = tg.get("sell_base", tg.get("price", 0))
		var sell_price: int = _get_sell_price_for_good(tg, base_sell)
		sell_list.append({"type": "trade", "idx": i, "id": tg["id"], "name": tg["name"], "sell_price": sell_price})
	shop_list = sell_list

func _do_sell(idx: int) -> void:
	if idx >= sell_list.size(): return
	var entry: Dictionary = sell_list[idx]
	var price: int = entry["sell_price"]
	GameData.add_copper(price)
	last_message = "[color=green]Sold %s for %s.[/color]" % [entry["name"], _format_price(price)]
	if entry["type"] == "weapon":
		GameData.weapons_bag.remove_at(entry["idx"])
		GameData.adjust_equipment_after_bag_remove("weapon", entry["idx"])
	elif entry["type"] == "armor":
		GameData.armor_bag.remove_at(entry["idx"])
		GameData.adjust_equipment_after_bag_remove("armor", entry["idx"])
	elif entry["type"] == "trade":
		var profit: int = price
		var buy_price: int = 0
		for item in ItemDB.trade_goods():
			if item["id"] == entry["id"]:
				buy_price = item["price"]
				break
		if price > buy_price:
			var gain: int = price - buy_price
			GameData.gather_counts["trade_profit"] = GameData.gather_counts.get("trade_profit", 0) + gain
		GameData.trade_goods.remove_at(entry["idx"])
	_build_sell_list()
	_update_display()

func _update_display() -> void:
	var lines: Array = []
	var title: String = "Sell Items" if shop_type == "sell" else ("Weapon Shop" if shop_type == "weapons" else ("Armor Shop" if shop_type == "armor" else "Item Shop"))
	var faction: int = SHOP_FACTION.get(shop_type, -1)
	var greeting: String = ""
	if faction >= 0:
		var rep: int = GameData.get_faction_rep(faction)
		if rep >= 20:
			greeting = " [color=green]Pleasure doing business, friend.[/color]"
		elif rep <= -20:
			greeting = " [color=red]Prices are firm. Take it or leave it.[/color]"
	lines.append("[b]%s[/b]    %s%s" % [title, GameData.format_money_short(), greeting])
	if last_message != "":
		lines.append(last_message)
	lines.append("")

	if selecting_character:
		lines.append("[b]Equip on whom?[/b]")
		for i in range(GameData.party.size()):
			var m: Dictionary = GameData.party[i]
			var marker: String = "▶" if i == char_idx else " "
			var wep: String = "(none)"
			var weapon_index := GameData.get_equipped_index(i, "weapon")
			if weapon_index >= 0:
				wep = GameData.weapons_bag[weapon_index]["name"]
			var head: String = ""
			var head_index := GameData.get_equipped_index(i, "head")
			if head_index >= 0:
				head = GameData.armor_bag[head_index]["name"]
			var body: String = ""
			var body_index := GameData.get_equipped_index(i, "body")
			if body_index >= 0:
				body = GameData.armor_bag[body_index]["name"]
			var acc: String = ""
			var accessory_index := GameData.get_equipped_index(i, "accessory")
			if accessory_index >= 0:
				acc = GameData.armor_bag[accessory_index]["name"]
			lines.append("%s Lv%d %s  W:%s H:%s B:%s A:%s" % [marker, m["level"], m["name"], wep, head, body, acc])
		lines.append("")
		lines.append("[1]/Enter to confirm, arrows to choose, [Esc] cancel")
	else:
		for i in range(shop_list.size()):
			var item: Dictionary = shop_list[i]
			var marker: String = "▶" if i == selected_idx else " "
			var can_afford: bool = true if shop_type == "sell" else _get_price(item["price"]) <= GameData.gold
			var color_start: String = "" if can_afford else "[color=#666]"
			var color_end: String = "" if can_afford else "[/color]"
			if shop_type == "sell":
				lines.append("%s %-18s Sell: %s" % [marker, item["name"], _format_price(item["sell_price"])])
			elif shop_type in ["weapons", "armor"]:
				var stat: int = item.get("atk", item.get("def", 0))
				var stat_name: String = "ATK" if shop_type == "weapons" else "DEF"
				var slot_tag: String = (" [%s]" % item["slot"]) if shop_type == "armor" else ""
				lines.append("%s%s %-16s %s+%d%s  %s%s" % [color_start, marker, item["name"], stat_name, stat, slot_tag, _format_price(_get_price(item["price"])), color_end])
			else:
				lines.append("%s%s %-16s %s  %s%s" % [color_start, marker, item["name"], _format_price(_get_price(item["price"])), item.get("desc",""), color_end])
		lines.append("")
		lines.append("[1]/Enter to %s, arrows to browse, [S] Sell, [Esc] leave" % ("sell" if shop_type == "sell" else "buy"))

	text_display.text = "\n".join(lines)

const SHOP_FACTION := {
	"weapons": FactionDB.Faction.KEEPERS_GUILD,
	"armor": FactionDB.Faction.HARBOR_COMPACT,
	"items": FactionDB.Faction.HARBOR_COMPACT,
}

func _get_price(base_price: int) -> int:
	var modified: int = GameData.get_price_with_beacon_modifier(base_price)
	var faction: int = SHOP_FACTION.get(shop_type, -1)
	if faction >= 0:
		modified = int(modified * GameData.get_faction_price_mod(faction))
	return maxi(modified, 1)

func _format_price(copper: int) -> String:
	var g: int = copper / 10000
	var s: int = (copper % 10000) / 100
	var c: int = copper % 100
	if g > 0:
		return "%dg%ds" % [g, s]
	elif s > 0:
		return "%ds%dc" % [s, c]
	return "%dc" % c

# Zone-based sell price modifier for trade goods
const ZONE_PRICE_MOD := {
	"oil_jar": {"docks": 1.5, "town": 1.0, "forest": 0.8, "beacon": 1.3, "default": 1.0},
	"salt_bag": {"docks": 1.4, "town": 1.0, "forest": 0.9, "beacon": 1.0, "default": 1.0},
	"herb_bun": {"docks": 0.8, "town": 1.2, "forest": 1.5, "beacon": 1.0, "default": 1.0},
	"shadow_oil": {"docks": 0.6, "town": 1.0, "forest": 1.2, "beacon": 0.5, "default": 1.0},
}

func _get_sell_price_for_good(good: Dictionary, base_sell: int) -> int:
	var good_id: String = good.get("id", "")
	var zone_prices: Dictionary = ZONE_PRICE_MOD.get(good_id, {})
	var mod: float = zone_prices.get("town", zone_prices.get("default", 1.0))
	# Beacon modifier: lit beacons boost sell prices
	var lit_count: int = GameData.beacon_states.values().filter(func(v): return v == true).size()
	mod *= 1.0 + lit_count * 0.03
	# Harbor Compact reputation helps sell prices
	var harbor_rep: int = GameData.get_faction_rep(FactionDB.Faction.HARBOR_COMPACT)
	mod *= 1.0 + harbor_rep * 0.005
	return maxi(int(base_sell * mod), 1)
