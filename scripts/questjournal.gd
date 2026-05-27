# QuestJournal — full-screen quest status display
extends CanvasLayer

const QuestDB := preload("res://scripts/data/quests.gd")

@onready var content: RichTextLabel = $Panel/Content
var active: bool = false

func _ready() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS

func open() -> void:
	active = true
	_update()
	show()

func close() -> void:
	active = false
	hide()

func _input(event: InputEvent) -> void:
	if not active:
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_ESCAPE, KEY_J:
			close()
			get_viewport().set_input_as_handled()

func _update() -> void:
	var lines: Array = []
	lines.append("[b][color=#f0d46a]Q U E S T   J O U R N A L[/color][/b]")
	lines.append("[color=#f0d46a]──────────────────────────────────────────────────────[/color]")
	lines.append("")

	# Active quests
	var active_quests: Array = []
	var complete_quests: Array = []
	for qid: String in GameData.active_quests:
		if GameData.active_quests[qid]["status"] == "active":
			active_quests.append(qid)
		else:
			complete_quests.append(qid)

	if not active_quests.is_empty():
		lines.append("[b][color=#f0d46a]Active Quests[/color][/b]")
		lines.append("[color=#f0d46a]──────────────────────────────────────────────────────[/color]")
		for qid in active_quests:
			var quest: Dictionary = QuestDB.get_quest(qid)
			if quest.is_empty(): continue
			lines.append("")
			lines.append("[b]%s[/b]" % quest["name"])
			lines.append("  %s" % quest["description"])
			if quest.has("objective"):
				lines.append("  [color=#f0d46a]Objective:[/color] %s" % quest["objective"])
			if quest.has("hint"):
				lines.append("  [color=#9fc5ff]Hint:[/color] %s" % quest["hint"])
			match quest["type"]:
				"kill":
					var current: int = GameData.get_quest_progress(qid)
					var needed: int = quest.get("target_count", 1)
					var bar := _progress_bar(current, needed, 20)
					lines.append("  Progress: %s %d/%d %s" % [bar, current, needed, quest["target"]])
				"beacon":
					var beacon_pos: Vector2i = QuestDB.BEACON_POS.get(quest.get("target", ""), Vector2i(-1, -1))
					var lit: bool = GameData.beacon_states.get(str(beacon_pos), false)
					var status: String = "[color=green]Lit[/color]" if lit else "[color=red]Unlit[/color]"
					lines.append("  Status: %s" % status)
					if lit and quest.has("objective_done"):
						lines.append("  [color=#9fc5ff]%s[/color]" % quest["objective_done"])
					if lit and quest.has("turn_in"):
						lines.append("  [color=#f0d46a]Next:[/color] %s" % quest["turn_in"])
				"flag":
					var flag_val: Variant = GameData.get(quest.get("target", ""))
					var status: String = "[color=green]Complete[/color]" if flag_val else "[color=yellow]Incomplete[/color]"
					lines.append("  Status: %s" % status)
				"all_beacons":
					var lit_count := 0
					for bname: String in QuestDB.BEACON_POS:
						if GameData.beacon_states.get(str(QuestDB.BEACON_POS[bname]), false):
							lit_count += 1
					var total := QuestDB.BEACON_POS.size()
					var bar := _progress_bar(lit_count, total, 20)
					lines.append("  Beacons: %s %d/%d" % [bar, lit_count, total])
				"gather":
					var current: int = GameData.get_quest_progress(qid)
					var needed: int = quest.get("target_count", 1)
					var bar := _progress_bar(current, needed, 20)
					lines.append("  Gathered: %s %d/%d %s" % [bar, current, needed, quest["target"]])
				"faction":
					var rep: int = GameData.faction_reputation.get(quest.get("target", ""), 0)
					var needed_f: int = quest.get("target_count", 20)
					var bar_f := _progress_bar(rep, needed_f, 20)
					lines.append("  Reputation: %s %d/%d" % [bar_f, rep, needed_f])
				"trade":
					var current_t: int = GameData.get_quest_progress(qid)
					var needed_t: int = quest.get("target_count", 200)
					var bar_t := _progress_bar(current_t, needed_t, 20)
					lines.append("  Profit: %s %d/%dc" % [bar_t, current_t, needed_t])
				"upgrade":
					var count: int = GameData.home_upgrades.size()
					var needed_u: int = quest.get("target_count", 2)
					var bar_u := _progress_bar(count, needed_u, 20)
					lines.append("  Upgrades: %s %d/%d" % [bar_u, count, needed_u])
				"member_quest":
					var member_name: String = quest.get("member", "?")
					var sub: String = quest.get("sub_type", "flag")
					match sub:
						"flag":
							var done: bool = GameData.get_meta(quest.get("target", ""), false)
							var status: String = "[color=green]Complete[/color]" if done else "[color=yellow]Incomplete[/color]"
							lines.append("  %s's quest: %s" % [member_name, status])
						"skill":
							var val: int = GameData.get_meta(quest.get("target", ""), 0)
							var needed_mq: int = quest.get("target_count", 1)
							var bar_mq := _progress_bar(val, needed_mq, 20)
							lines.append("  %s: %s %d/%d" % [member_name, bar_mq, val, needed_mq])
				"explore_flag":
					var done_ef: bool = GameData.get_meta(quest.get("target", ""), false)
					var status_ef: String = "[color=green]Complete[/color]" if done_ef else "[color=yellow]Incomplete[/color]"
					lines.append("  Status: %s" % status_ef)
			var reward_gold: int = quest.get("reward_gold", 0)
			lines.append("  Reward: %s" % _format_reward(reward_gold * 100))
		lines.append("")

	# Complete quests
	if not complete_quests.is_empty():
		lines.append("[b][color=green]Completed[/color][/b]")
		lines.append("[color=#f0d46a]──────────────────────────────────────────────────────[/color]")
		for qid in complete_quests:
			var quest: Dictionary = QuestDB.get_quest(qid)
			if quest.is_empty(): continue
			lines.append("  [color=green]✓[/color] %s" % quest["name"])
		lines.append("")

	# Available quests
	var available: Array = QuestDB.get_available_quests()
	if not available.is_empty():
		lines.append("[b][color=yellow]Available[/color][/b] (speak with the Elder)")
		lines.append("[color=#f0d46a]──────────────────────────────────────────────────────[/color]")
		for qid in available:
			var quest: Dictionary = QuestDB.get_quest(qid)
			if quest.is_empty(): continue
			lines.append("  [color=yellow]★[/color] %s" % quest["name"])
		lines.append("")

	if active_quests.is_empty() and complete_quests.is_empty() and available.is_empty():
		lines.append("[i]No quests yet. Explore the island and speak with the Elder in Brindlewick.[/i]")

	# Kill statistics
	if not GameData.kill_counts.is_empty():
		lines.append("[color=#f0d46a]──────────────────────────────────────────────────────[/color]")
		lines.append("[b]Kill Statistics[/b]")
		var kills: Array = GameData.kill_counts.keys()
		kills.sort()
		for enemy in kills:
			lines.append("  %s: %d" % [enemy, GameData.kill_counts[enemy]])

	lines.append("")
	lines.append("[color=gray][Esc]/[J] Close[/color]")
	content.text = "\n".join(lines)

func _progress_bar(current: int, maximum: int, width: int) -> String:
	var n := clampi(int(ceil(float(current) / max(maximum, 1) * width)), 0, width)
	var s := "[color=#4c9040]"
	for _i in range(n): s += "█"
	s += "[/color][color=#555]"
	for _i in range(width - n): s += "░"
	s += "[/color]"
	return s

func _format_reward(copper: int) -> String:
	var g := copper / 10000
	var s := (copper % 10000) / 100
	var c := copper % 100
	if g > 0:
		return "%dg %ds" % [g, s]
	if s > 0:
		return "%ds %dc" % [s, c]
	return "%dc" % c
