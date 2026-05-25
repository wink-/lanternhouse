# Shop — buy weapons, armor, and items
extends Node2D

const ItemDB := preload("res://scripts/data/items.gd")

var shop_type: String = "weapons"   # "weapons", "armor", "items"
var shop_list: Array = []
var selected_idx: int = 0
var selecting_character: bool = false
var char_idx: int = 0

@onready var text_display: RichTextLabel = $TextDisplay

func _ready() -> void:
	shop_type = GameData.get_meta("shop_type", "weapons")
	match shop_type:
		"weapons": shop_list = ItemDB.weapon_list()
		"armor":   shop_list = ItemDB.armor_list()
		"items":   shop_list = ItemDB.item_shop_list()
		_:         shop_list = ItemDB.weapon_list()
	_update_display()

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
		KEY_ESCAPE:
			get_tree().change_scene_to_file("res://scenes/town/town.tscn")
	_update_display()

func _try_buy() -> void:
	var item: Dictionary = shop_list[selected_idx]
	if item["price"] > GameData.gold:
		return  # can't afford, silently ignored (shown in display)

	# For weapons/armor, ask which character to equip
	if shop_type in ["weapons", "armor"]:
		selecting_character = true
		char_idx = 0
		_update_display()
		return

	# For items, buy directly
	GameData.gold -= item["price"]
	match item["id"]:
		"tonic":   GameData.tonics += 1
		"ether":   _apply_ether()
	_update_display()

func _buy_for_character(ci: int) -> void:
	var item: Dictionary = shop_list[selected_idx]
	GameData.gold -= item["price"]

	if shop_type == "weapons":
		# Check if already owned
		var existing := -1
		for i in range(GameData.weapons_bag.size()):
			if GameData.weapons_bag[i]["id"] == item["id"]:
				existing = i
				break
		if existing < 0:
			GameData.weapons_bag.append(item.duplicate(true))
			existing = GameData.weapons_bag.size() - 1
		GameData.equipped_weapon[ci] = existing

	elif shop_type == "armor":
		var existing := -1
		for i in range(GameData.armor_bag.size()):
			if GameData.armor_bag[i]["id"] == item["id"]:
				existing = i
				break
		if existing < 0:
			GameData.armor_bag.append(item.duplicate(true))
			existing = GameData.armor_bag.size() - 1
		GameData.equipped_armor[ci] = existing

	selecting_character = false
	_update_display()

func _apply_ether() -> void:
	for m: Dictionary in GameData.party:
		for lvl in m["magic_levels"]:
			var entry: Dictionary = m["magic_levels"][lvl]
			if entry["charges"] < entry["max"]:
				entry["charges"] = entry["max"]

func _update_display() -> void:
	var lines: Array = []
	var title := "Weapon Shop" if shop_type == "weapons" else ("Armor Shop" if shop_type == "armor" else "Item Shop")
	lines.append("[b]%s[/b]    Gold: %d" % [title, GameData.gold])
	lines.append("")

	if selecting_character:
		lines.append("[b]Equip on whom?[/b]")
		for i in range(GameData.party.size()):
			var m: Dictionary = GameData.party[i]
			var marker := "▶" if i == char_idx else " "
			var wep := "(none)"
			var arm := "(none)"
			if GameData.equipped_weapon[i] >= 0:
				wep = GameData.weapons_bag[GameData.equipped_weapon[i]]["name"]
			if GameData.equipped_armor[i] >= 0:
				arm = GameData.armor_bag[GameData.equipped_armor[i]]["name"]
			lines.append("%s Lv%d %s  [%s / %s]" % [marker, m["level"], m["name"], wep, arm])
		lines.append("")
		lines.append("[1]/Enter to confirm, arrows to choose, [Esc] cancel")
	else:
		for i in range(shop_list.size()):
			var item: Dictionary = shop_list[i]
			var marker := "▶" if i == selected_idx else " "
			var can_afford := item["price"] <= GameData.gold
			var color_start := "" if can_afford else "[color=#666]"
			var color_end := "" if can_afford else "[/color]"
			if shop_type in ["weapons", "armor"]:
				var stat := item.get("atk", item.get("def", 0))
				var stat_name := "ATK" if shop_type == "weapons" else "DEF"
				lines.append("%s%s %-16s %s+%d  %dg%s" % [color_start, marker, item["name"], stat_name, stat, item["price"], color_end])
			else:
				lines.append("%s%s %-16s %dg  %s%s" % [color_start, marker, item["name"], item["price"], item.get("desc",""), color_end])
		lines.append("")
		lines.append("[1]/Enter to buy, arrows to browse, [Esc] leave")

	text_display.text = "\n".join(lines)
