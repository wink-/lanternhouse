# Inventory — full-screen item/equipment viewer with equip/use
#
# [CODING CONCEPT: Tab-Based UI]
# The inventory has 4 tabs (Consumables, Weapons, Armor, Trade) tracked by
# an integer: tab=0 means consumables, tab=1 means weapons, etc. Tab cycles
# with the Tab key. The _update() function reads the tab variable and calls
# the matching _draw_xxx() function. This is a common pattern for menus.
#
# [CODING CONCEPT: Deep Copy for Safety]
# When the shop adds a weapon to weapons_bag, it uses item.duplicate(true).
# The "true" means deep copy — if the item contains nested dictionaries or
# arrays, those get copied too. Without this, all weapons of the same type
# would share the same Dictionary object, and modifying one would change them all.
extends CanvasLayer

const ItemDB := preload("res://scripts/data/items.gd")

@onready var content: RichTextLabel = $Panel/Content
var active: bool = false
var tab: int = 0  # 0=consumables, 1=weapons, 2=armor, 3=tools, 4=trade
var selected_idx: int = 0
var last_message: String = ""

# Sub-states for equip/use flow
var equip_selecting: bool = false  # picking party member to equip
var use_confirm: bool = false      # confirming item use

const TAB_NAMES := ["Consumables", "Weapons", "Armor", "Tools", "Trade Goods"]

func _ready() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS

func open() -> void:
	active = true
	tab = 0
	selected_idx = 0
	equip_selecting = false
	use_confirm = false
	last_message = ""
	_update()
	show()

func close() -> void:
	active = false
	hide()

func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	if equip_selecting:
		_handle_equip_select(event.keycode)
		return

	match event.keycode:
		KEY_UP:
			selected_idx = maxi(0, selected_idx - 1)
			_update()
		KEY_DOWN:
			var count := _item_count()
			selected_idx = mini(max(count - 1, 0), selected_idx + 1)
			_update()
		KEY_TAB:
			tab = (tab + 1) % TAB_NAMES.size()
			selected_idx = 0
			_update()
		KEY_ESCAPE, KEY_I:
			close()
		KEY_1, KEY_ENTER, KEY_SPACE:
			_try_use_item()

func _item_count() -> int:
	match tab:
		0: return 2 + _crafted_consumables().size()
		1: return GameData.weapons_bag.size()
		2: return GameData.armor_bag.size()
		3: return _crafted_tools().size()
		4: return GameData.trade_goods.size() + _crafted_trade_goods().size()
	return 0

func _update() -> void:
	var lines: Array = []
	lines.append("[b][color=#f0d46a]════════════════════ INVENTORY ════════════════════[/color][/b]")

	var tab_bar := ""
	for i in range(TAB_NAMES.size()):
		if i == tab:
			tab_bar += "[b][color=cyan][%s][/color][/b]  " % TAB_NAMES[i]
		else:
			tab_bar += "[color=gray]%s[/color]  " % TAB_NAMES[i]
	lines.append(tab_bar)
	lines.append("%s" % GameData.format_money_short())
	if last_message != "":
		lines.append(last_message)
	lines.append("")

	match tab:
		0: _draw_consumables(lines)
		1: _draw_weapons(lines)
		2: _draw_armor(lines)
		3: _draw_tools(lines)
		4: _draw_trade_goods(lines)

	lines.append("")
	if equip_selecting:
		lines.append("[color=cyan]Select party member to equip  [Esc] Cancel[/color]")
	else:
		lines.append("[color=gray]↑↓ Browse   [Tab] Switch category   [Enter] Use/Equip   [Esc]/[I] Close[/color]")
	content.text = "\n".join(lines)

func _draw_consumables(lines: Array) -> void:
	var items := [
		{"name": "Tonic", "count": GameData.tonics, "desc": "Restores up to %d HP to the lowest-HP ally" % ItemDB.TONIC_HEAL},
		{"name": "Ether", "count": GameData.ethers, "desc": "Restores all magic charges to the ally missing the most"},
	]
	for crafted: Dictionary in _crafted_consumables():
		items.append({"name": crafted["name"], "count": _crafted_count(crafted["id"], "consumable"), "desc": crafted.get("desc", ""), "crafted_id": crafted["id"]})
	for i in range(items.size()):
		var item: Dictionary = items[i]
		var marker := "▶" if i == selected_idx else " "
		var color_start := "[color=#f0d46a]" if i == selected_idx else ""
		var color_end := "[/color]" if i == selected_idx else ""
		var dim := "" if item["count"] > 0 else "[color=#666]"
		var dim_end := "" if item["count"] > 0 else "[/color]"
		lines.append("%s%s%s %-16s x%d%s%s" % [dim, marker, color_start, item["name"], item["count"], color_end, dim_end])
		lines.append("    %s%s" % [dim, item["desc"]])

func _draw_weapons(lines: Array) -> void:
	if GameData.weapons_bag.is_empty():
		lines.append("No weapons in bag.")
		return
	for i in range(GameData.weapons_bag.size()):
		var w: Dictionary = GameData.weapons_bag[i]
		var marker := "▶" if i == selected_idx else " "
		var equipped_by := _equipped_by_weapon(i)
		var eq_str := "  [color=cyan]%s[/color]" % equipped_by if equipped_by != "" else ""
		var color_start := "[color=#f0d46a]" if i == selected_idx else ""
		var color_end := "[/color]" if i == selected_idx else ""
		lines.append("%s%s%s %-18s ATK+%d%s%s" % [marker, color_start, w["name"], w.get("atk", 0), eq_str, color_end])

func _draw_armor(lines: Array) -> void:
	if GameData.armor_bag.is_empty():
		lines.append("No armor in bag.")
		return
	for i in range(GameData.armor_bag.size()):
		var a: Dictionary = GameData.armor_bag[i]
		var marker := "▶" if i == selected_idx else " "
		var equipped_by := _equipped_by_armor(i)
		var eq_str := "  [color=cyan]%s[/color]" % equipped_by if equipped_by != "" else ""
		var color_start := "[color=#f0d46a]" if i == selected_idx else ""
		var color_end := "[/color]" if i == selected_idx else ""
		var slot_str := ""
		match a.get("slot", ""):
			"head": slot_str = " [Head]"
			"body": slot_str = " [Body]"
			"accessory": slot_str = " [Acc]"
		lines.append("%s%s%s %-18s DEF+%d%s%s%s" % [marker, color_start, a["name"], a.get("def", 0), slot_str, eq_str, color_end])

func _draw_trade_goods(lines: Array) -> void:
	if GameData.trade_goods.is_empty() and _crafted_trade_goods().is_empty():
		lines.append("No trade goods. Buy from the item shop and sell elsewhere for profit.")
		return
	for i in range(GameData.trade_goods.size()):
		var tg: Dictionary = GameData.trade_goods[i]
		var marker := "▶" if i == selected_idx else " "
		var color_start := "[color=#f0d46a]" if i == selected_idx else ""
		var color_end := "[/color]" if i == selected_idx else ""
		var sell_price: int = tg.get("sell_base", tg.get("price", 0))
		lines.append("%s%s%s %-18s Value: %dc%s" % [marker, color_start, tg["name"], sell_price, color_end])
	var offset := GameData.trade_goods.size()
	for i in range(_crafted_trade_goods().size()):
		var ctg: Dictionary = _crafted_trade_goods()[i]
		var idx := offset + i
		var marker := "▶" if idx == selected_idx else " "
		var color_start := "[color=#f0d46a]" if idx == selected_idx else ""
		var color_end := "[/color]" if idx == selected_idx else ""
		var count := _crafted_count(ctg["id"], "trade")
		if count > 0:
			lines.append("%s%s%s %-18s Value: %dc x%d%s" % [marker, color_start, ctg["name"], ctg.get("sell_base", 0), count, color_end])

func _draw_tools(lines: Array) -> void:
	var tools := _crafted_tools()
	if tools.is_empty():
		lines.append("No crafted tools. Make them at Fenn's workshop or a home workbench.")
		return
	for i in range(tools.size()):
		var tool: Dictionary = tools[i]
		var marker := "▶" if i == selected_idx else " "
		var color_start := "[color=#f0d46a]" if i == selected_idx else ""
		var color_end := "[/color]" if i == selected_idx else ""
		var count := _crafted_count(tool["id"], "tool")
		lines.append("%s%s%-18s x%d%s" % [marker, color_start, tool["name"], count, color_end])
		lines.append("    %s" % tool.get("desc", ""))

func _crafted_consumables() -> Array:
	return GameData.crafted_items.filter(func(c): return c.get("type") == "consumable")

func _crafted_trade_goods() -> Array:
	var seen: Dictionary = {}
	var result: Array = []
	for c: Dictionary in GameData.crafted_items:
		if c.get("type") == "trade" and not seen.has(c["id"]):
			seen[c["id"]] = true
			result.append(c)
	return result

func _crafted_tools() -> Array:
	var seen: Dictionary = {}
	var result: Array = []
	for c: Dictionary in GameData.crafted_items:
		if c.get("type") == "tool" and not seen.has(c["id"]):
			seen[c["id"]] = true
			result.append(c)
	return result

func _crafted_count(item_id: String, item_type: String) -> int:
	var count := 0
	for c: Dictionary in GameData.crafted_items:
		if c["id"] == item_id and c.get("type") == item_type:
			count += 1
	return count

func _equipped_by_weapon(bag_idx: int) -> String:
	var names: Array = []
	for pi in range(GameData.party.size()):
		if GameData.get_equipped_index(pi, "weapon") == bag_idx:
			names.append(GameData.party[pi]["name"])
	return "Equipped: %s" % ", ".join(names) if not names.is_empty() else ""

func _equipped_by_armor(bag_idx: int) -> String:
	var names: Array = []
	for pi in range(GameData.party.size()):
		if GameData.get_equipped_index(pi, "head") == bag_idx or GameData.get_equipped_index(pi, "body") == bag_idx or GameData.get_equipped_index(pi, "accessory") == bag_idx:
			names.append(GameData.party[pi]["name"])
	return "Equipped: %s" % ", ".join(names) if not names.is_empty() else ""

# ── Use / Equip logic ─────────────────────────────────────────────────────
func _try_use_item() -> void:
	match tab:
		0: _use_consumable()
		1: _start_equip_weapon()
		2: _start_equip_armor()
		3: _use_tool()
		4: _use_trade_good()

func _use_consumable() -> void:
	var crafted_count := _crafted_consumables().size()
	# Tonic
	if selected_idx == 0:
		if GameData.tonics <= 0:
			last_message = "[color=gray]No Tonics in the bag.[/color]"
			_update()
			return
		var tg: Variant = _lowest_hp_alive()
		if tg == null:
			last_message = "[color=gray]No one can use a Tonic right now.[/color]"
			_update()
			return
		if tg["hp"] >= tg["max_hp"]:
			last_message = "[color=gray]Everyone is already at full HP.[/color]"
			_update()
			return
		GameData.tonics -= 1
		var heal: int = mini(ItemDB.TONIC_HEAL, tg["max_hp"] - tg["hp"])
		tg["hp"] += heal
		last_message = "[color=green]Used Tonic on %s. Restored %d HP.[/color]" % [tg["name"], heal]
		_update()
		return
	# Ether
	if selected_idx == 1:
		if GameData.ethers <= 0:
			last_message = "[color=gray]No Ethers in the bag.[/color]"
			_update()
			return
		var tg: Variant = _lowest_mp_alive()
		if tg == null:
			last_message = "[color=gray]No one needs an Ether right now.[/color]"
			_update()
			return
		GameData.ethers -= 1
		for lvl: int in tg["magic_levels"]:
			tg["magic_levels"][lvl]["charges"] = tg["magic_levels"][lvl]["max"]
		last_message = "[color=green]Used Ether on %s. Magic charges restored.[/color]" % tg["name"]
		_update()
		return
	# Crafted consumable
	var crafted_list := _crafted_consumables()
	var crafted_idx := selected_idx - 2
	if crafted_idx < 0 or crafted_idx >= crafted_list.size():
		return
	var target_crafted: Dictionary = crafted_list[crafted_idx]
	# Find first matching item in crafted_items array
	for ci in range(GameData.crafted_items.size()):
		var c: Dictionary = GameData.crafted_items[ci]
		if c["id"] == target_crafted["id"] and c.get("type") == "consumable":
			var effect: Dictionary = c.get("effect", {})
			match effect.get("type", ""):
				"heal":
					var tg: Variant = _lowest_hp_alive()
					if tg != null and tg["hp"] < tg["max_hp"]:
						GameData.crafted_items.remove_at(ci)
						var heal: int = mini(effect.get("hp", 15), tg["max_hp"] - tg["hp"])
						tg["hp"] += heal
				"ether":
					var tg: Variant = _lowest_mp_alive()
					if tg != null:
						GameData.crafted_items.remove_at(ci)
						var charges: int = effect.get("charges", 2)
						for lvl: int in tg["magic_levels"]:
							tg["magic_levels"][lvl]["charges"] = mini(tg["magic_levels"][lvl]["charges"] + charges, tg["magic_levels"][lvl]["max"])
				"full_restore":
					var tg: Variant = _lowest_hp_alive()
					if tg != null:
						GameData.crafted_items.remove_at(ci)
						tg["hp"] = tg["max_hp"]
						for lvl: int in tg["magic_levels"]:
							tg["magic_levels"][lvl]["charges"] = tg["magic_levels"][lvl]["max"]
				_:
					return
			_update()
			return

func _lowest_hp_alive() -> Variant:
	var best = null
	for m: Dictionary in GameData.party:
		if m["alive"] and (best == null or m["hp"] < best["hp"]):
			best = m
	return best

func _lowest_mp_alive() -> Variant:
	var best = null
	var best_spent := 0
	for m: Dictionary in GameData.party:
		if not m["alive"]: continue
		var spent := 0
		for lvl: int in m["magic_levels"]:
			spent += m["magic_levels"][lvl]["max"] - m["magic_levels"][lvl]["charges"]
		if spent > best_spent:
			best_spent = spent
			best = m
	return best

func _start_equip_weapon() -> void:
	if GameData.weapons_bag.is_empty() or selected_idx >= GameData.weapons_bag.size():
		return
	equip_selecting = true
	_update()

func _start_equip_armor() -> void:
	if GameData.armor_bag.is_empty() or selected_idx >= GameData.armor_bag.size():
		return
	equip_selecting = true
	_update()

func _handle_equip_select(keycode: int) -> void:
	match keycode:
		KEY_1, KEY_2, KEY_3, KEY_4:
			var pi := keycode - KEY_1
			if pi < GameData.party.size():
				_do_equip(pi)
		KEY_ESCAPE:
			equip_selecting = false
			_update()

func _do_equip(pi: int) -> void:
	var m: Dictionary = GameData.party[pi]
	if not m["alive"]:
		return

	if tab == 1:
		# Equip weapon
		var old_idx: int = GameData.get_equipped_index(pi, "weapon")
		GameData.set_equipped_index(pi, "weapon", selected_idx)
		# If someone else had this weapon equipped, give them the old one
		if old_idx == selected_idx:
			pass  # same weapon, no change
		else:
			for other_pi in range(GameData.party.size()):
				if other_pi != pi and GameData.get_equipped_index(other_pi, "weapon") == selected_idx:
					GameData.set_equipped_index(other_pi, "weapon", old_idx)
	elif tab == 2:
		# Equip armor — determine slot
		var armor: Dictionary = GameData.armor_bag[selected_idx]
		var slot: String = armor.get("slot", "body")
		if not slot in ["head", "body", "accessory"]:
			slot = "body"
		var old_idx: int = GameData.get_equipped_index(pi, slot)
		GameData.set_equipped_index(pi, slot, selected_idx)
		# If someone else had this armor equipped, give them the old one
		if old_idx != selected_idx:
			for other_pi in range(GameData.party.size()):
				if other_pi != pi:
					for other_slot: String in ["head", "body", "accessory"]:
						if GameData.get_equipped_index(other_pi, other_slot) == selected_idx:
							GameData.set_equipped_index(other_pi, other_slot, old_idx)

	equip_selecting = false
	_update()

func _use_trade_good() -> void:
	if selected_idx >= GameData.trade_goods.size():
		return
	var tg: Dictionary = GameData.trade_goods[selected_idx]
	match tg.get("id", ""):
		"fog_in_a_bottle":
			GameData.trade_goods.erase(tg)
			GameData.set_meta("fog_active", true)
			GameData.set_meta("fog_timer", 60.0)
			_update()
		_:
			pass

func _use_tool() -> void:
	var tools := _crafted_tools()
	if selected_idx < 0 or selected_idx >= tools.size():
		return
	var target_tool: Dictionary = tools[selected_idx]
	for ci in range(GameData.crafted_items.size()):
		var tool: Dictionary = GameData.crafted_items[ci]
		if tool.get("type") != "tool" or tool.get("id", "") != target_tool.get("id", ""):
			continue
		var effect: Dictionary = tool.get("effect", {})
		match effect.get("type", ""):
			"heal":
				var tg: Variant = _lowest_hp_alive()
				if tg == null or tg["hp"] >= tg["max_hp"]:
					last_message = "[color=gray]No one needs that right now.[/color]"
					_update()
					return
				GameData.crafted_items.remove_at(ci)
				var heal: int = mini(effect.get("hp", 18), tg["max_hp"] - tg["hp"])
				tg["hp"] += heal
				last_message = "[color=green]Used %s on %s. Restored %d HP.[/color]" % [tool["name"], tg["name"], heal]
			"full_heal":
				GameData.crafted_items.remove_at(ci)
				GameData.full_heal()
				last_message = "[color=green]Used %s. Party fully restored.[/color]" % tool["name"]
			"fog_cover":
				GameData.crafted_items.remove_at(ci)
				GameData.set_meta("fog_active", true)
				GameData.set_meta("fog_timer", effect.get("timer", 180.0))
				last_message = "[color=green]%s burns steady. Heavy fog thins around the party.[/color]" % tool["name"]
			"beacon_lens":
				GameData.crafted_items.remove_at(ci)
				GameData.set_meta("beacon_lens_charges", GameData.get_meta("beacon_lens_charges", 0) + 1)
				last_message = "[color=green]Beacon Lens tuned. The next beacon will reveal farther.[/color]"
			"trap":
				GameData.crafted_items.remove_at(ci)
				GameData.set_meta("trap_kit_active", true)
				last_message = "[color=green]Trap Kit set. The next battle starts with an ambush trap.[/color]"
			"passive":
				last_message = "[color=gray]%s is carried automatically when needed.[/color]" % tool["name"]
			_:
				last_message = "[color=gray]That tool has no field use yet.[/color]"
		selected_idx = mini(selected_idx, max(_item_count() - 1, 0))
		_update()
		return
