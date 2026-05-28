# CharacterSheet — full-screen party status display
extends CanvasLayer

const CharDB := preload("res://scripts/data/classes.gd")
const FactionDB := preload("res://scripts/data/factions.gd")

@onready var content: RichTextLabel = $Panel/Content
var selected_idx: int = 0
var active: bool = false

func _ready() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS

func open() -> void:
	active = true
	selected_idx = 0
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
	match event.keycode:
		KEY_UP:
			selected_idx = maxi(0, selected_idx - 1)
			_update()
		KEY_DOWN:
			selected_idx = mini(GameData.party.size() - 1, selected_idx + 1)
			_update()
		KEY_ESCAPE:
			close()
		KEY_M:
			close()

func _update() -> void:
	var lines: Array = []
	lines.append("[b][color=#f0d46a]╔══════════════════════════════════════════════════════╗[/color][/b]")
	lines.append("[b][color=#f0d46a]║              P A R T Y   R O S T E R              ║[/color][/b]")
	lines.append("[b][color=#f0d46a]╚══════════════════════════════════════════════════════╝[/color][/b]")
	lines.append("")

	# Party members
	for i in range(GameData.party.size()):
		var m: Dictionary = GameData.party[i]
		var marker := "▶" if i == selected_idx else " "
		var name_color := "[color=#f0d46a]" if i == selected_idx else ""
		var end_color := "[/color]" if i == selected_idx else ""

		var status := ""
		if not m["alive"]:
			status = "[color=red]KO[/color] "
		elif m.get("departed", false):
			status = "[color=red]DEPARTING[/color] "

		lines.append("%s %s%s%s  Lv%d %s  %s" % [marker, name_color, m["name"], end_color, m["level"], m["class"], status])

	# Selected member detail
	if GameData.party.size() > 0:
		var m: Dictionary = GameData.party[selected_idx]
		lines.append("")
		lines.append("[color=#f0d46a]──────────────────────────────────────────────────────[/color]")
		lines.append("[b]%s[/b] — %s  Lv%d" % [m["name"], m["class"], m["level"]])
		lines.append("")

		# HP bar
		var hp_bar := _bar(m["hp"], m["max_hp"], 20)
		lines.append("HP  %s  %d/%d" % [hp_bar, m["hp"], m["max_hp"]])

		# Stats
		var eff_str := GameData.get_effective_str(selected_idx)
		var eff_def := GameData.get_effective_def(selected_idx)
		var loyalty_str := ""
		if m.get("wage", 0) > 0:
			var loy: int = m.get("loyalty", 50)
			var loy_color := "green" if loy >= 60 else "yellow" if loy >= 40 else "red"
			loyalty_str = "  [color=%s]Loyalty: %d[/color]" % [loy_color, loy]
			if m.get("departed", false):
				loyalty_str += " [color=red][LEAVING][/color]"
			var wage_str: String = "  Wage: %dc/wk" % m["wage"]
			lines.append("STR: %d (%d)  DEF: %d (%d)  AGI: %d%s%s" % [m["str"], eff_str, m["def"], eff_def, m["agi"], loyalty_str, wage_str])
		else:
			lines.append("STR: %d (%d)  DEF: %d (%d)  AGI: %d" % [m["str"], eff_str, m["def"], eff_def, m["agi"]])

		# XP progress
		var xp_pct := int(float(m["xp"]) / m["next_xp"] * 100) if m["next_xp"] > 0 else 0
		lines.append("XP: %d/%d (%d%%)" % [m["xp"], m["next_xp"], xp_pct])

		# Equipment
		var wep_str := "None"
		var wi := GameData.get_equipped_index(selected_idx, "weapon")
		if wi >= 0:
			if wi < GameData.weapons_bag.size():
				wep_str = "%s (+%d)" % [GameData.weapons_bag[wi]["name"], GameData.weapons_bag[wi].get("atk", 0)]
		lines.append("Weapon: %s" % wep_str)
		var head_str := "None"
		var ai := GameData.get_equipped_index(selected_idx, "head")
		if ai >= 0:
			if ai < GameData.armor_bag.size():
				head_str = "%s (+%d)" % [GameData.armor_bag[ai]["name"], GameData.armor_bag[ai].get("def", 0)]
		var body_str := "None"
		ai = GameData.get_equipped_index(selected_idx, "body")
		if ai >= 0 and ai < GameData.armor_bag.size():
			body_str = "%s (+%d)" % [GameData.armor_bag[ai]["name"], GameData.armor_bag[ai].get("def", 0)]
		var acc_str := "None"
		ai = GameData.get_equipped_index(selected_idx, "accessory")
		if ai >= 0 and ai < GameData.armor_bag.size():
			acc_str = "%s (+%d)" % [GameData.armor_bag[ai]["name"], GameData.armor_bag[ai].get("def", 0)]
		lines.append("Head: %s    Body: %s    Acc: %s" % [head_str, body_str, acc_str])

		# Magic
		if m["magic_levels"].size() > 0:
			var magic_parts: Array = []
			for lvl: int in m["magic_levels"]:
				var charges: int = m["magic_levels"][lvl]["charges"]
				var max_charges: int = m["magic_levels"][lvl]["max"]
				var spells: Array = CharDB.spells_for_level(lvl)
				var spell_names := ", ".join(spells.map(func(s): return s["name"]))
				magic_parts.append("Lv%d %s [%d/%d]" % [lvl, spell_names, charges, max_charges])
			if not magic_parts.is_empty():
				lines.append("Magic: %s" % "  ".join(magic_parts))

		# Skills
		var combat_skills := ["weapon", "magic", "healing"]
		var trade_skills := ["alchemy", "tinkering", "cooking", "fishing", "herbalism", "exploration", "trading"]
		var skill_parts: Array = []
		for sk: String in combat_skills:
			if GameData.skill_uses.has(sk):
				skill_parts.append("%s %s (%d)" % [sk.capitalize(), GameData.get_skill_tier(sk), GameData.skill_uses[sk]])
		lines.append("Combat: %s" % ("  ".join(skill_parts) if skill_parts else "None trained"))
		skill_parts.clear()
		for sk: String in trade_skills:
			if GameData.skill_uses.has(sk):
				skill_parts.append("%s %s (%d)" % [sk.capitalize(), GameData.get_skill_tier(sk), GameData.skill_uses[sk]])
		lines.append("Trade:  %s" % ("  ".join(skill_parts) if skill_parts else "None trained"))

	# Kill statistics
	if not GameData.kill_counts.is_empty():
		lines.append("")
		lines.append("[color=#f0d46a]──────────────────────────────────────────────────────[/color]")
		lines.append("[b]Bestiary[/b]")
		var total_kills := 0
		for enemy in GameData.kill_counts:
			total_kills += GameData.kill_counts[enemy]
		lines.append("  Total kills: %d" % total_kills)
		var sorted_kills: Array = GameData.kill_counts.keys()
		sorted_kills.sort()
		for enemy in sorted_kills:
			lines.append("    %s: %d" % [enemy, GameData.kill_counts[enemy]])

	# Faction reputation
	for f: int in FactionDB.all_factions():
		var rep: int = GameData.get_faction_rep(f)
		var tier: String = GameData.get_faction_tier_name(f)
		var name: String = FactionDB.NAMES[f]
		var rep_color := "green" if rep > 0 else "red" if rep < 0 else "gray"
		lines.append("  %-20s [color=%s]%s (%d)[/color]" % [name, rep_color, tier, rep])

	# Currency
	lines.append("")
	lines.append("[b]Wealth:[/b] %s  |  Marks: %d  Tokens: %d  Script: %d" % [
		GameData.format_money(), GameData.keeper_marks, GameData.harbor_tokens, GameData.chapel_script
	])

	# Controls
	lines.append("")
	lines.append("[color=gray]↑↓ Select   [Esc]/[M] Close[/color]")

	content.text = "\n".join(lines)

func _bar(current: int, maximum: int, width: int) -> String:
	var n := clampi(int(ceil(float(current) / maximum * width)), 0, width)
	var s := "[color=#4c9040]"
	for _i in range(n): s += "█"
	s += "[/color][color=#555]"
	for _i in range(width - n): s += "░"
	s += "[/color]"
	return s
