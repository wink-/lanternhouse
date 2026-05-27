# Fishing — coast/river/lake fishing minigame
extends CanvasLayer

const FishDB := preload("res://scripts/data/fish.gd")

@onready var content: RichTextLabel = $Panel/Content
var active: bool = false
var state: String = "idle"  # idle, casting, waiting, bite, reeling, caught, lost
var cast_timer: float = 0.0
var reel_progress: int = 0
var reel_target: int = 5
var current_fish: Dictionary = {}
var zone: int = FishDB.Zone.COAST

signal fish_caught(fish_id: String)

func _ready() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS

func open(fishing_zone: int) -> void:
	active = true
	zone = fishing_zone
	state = "idle"
	_update()
	show()

func close() -> void:
	active = false
	state = "idle"
	hide()

func _process(delta: float) -> void:
	if not active:
		return
	match state:
		"casting":
			cast_timer -= delta
			if cast_timer <= 0:
				state = "waiting"
				cast_timer = randf_range(2.0, 6.0)
				_update()
		"waiting":
			cast_timer -= delta
			if cast_timer <= 0:
				_try_bite()
				_update()
		"bite":
			cast_timer -= delta
			if cast_timer <= 0:
				state = "lost"
				_update()

func _try_bite() -> void:
	var skill: int = GameData.skill_uses.get("fishing", 0)
	var level := _skill_level(skill)
	var available := FishDB.fish_for_zone(zone, level)
	if available.is_empty():
		state = "idle"
		return
	var weights: Array = available.map(func(f): return f["rarity"])
	var total := 0.0
	for w in weights:
		total += w
	var roll := randf() * total
	var cumulative := 0.0
	for i in range(available.size()):
		cumulative += weights[i]
		if roll <= cumulative:
			current_fish = available[i]
			break
	if current_fish.is_empty():
		current_fish = available[0]
	state = "bite"
	cast_timer = 2.5
	reel_progress = 0
	reel_target = 3 + int(current_fish["rarity"] * 20)
	reel_target = mini(reel_target, 12)

func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_ESCAPE:
			close()
		KEY_SPACE, KEY_ENTER, KEY_E:
			match state:
				"idle":
					_start_cast()
				"bite":
					_reel()
				"caught", "lost":
					state = "idle"
					current_fish = {}
					_update()

func _start_cast() -> void:
	state = "casting"
	cast_timer = 1.0
	_update()

func _reel() -> void:
	reel_progress += 1
	if reel_progress >= reel_target:
		_catch_fish()
	else:
		_update()

func _catch_fish() -> void:
	state = "caught"
	GameData.track_skill_use("fishing", 1)
	if not current_fish.is_empty():
		if GameData.bag_full("trade"):
			return
		GameData.trade_goods.append({
			"id": current_fish["id"],
			"name": current_fish["name"],
			"price": current_fish["price"],
			"sell_base": current_fish["price"],
			"cooking": current_fish.get("cooking", {}),
		})
	fish_caught.emit(current_fish.get("id", ""))
	_update()

func _skill_level(uses: int) -> int:
	if uses >= 80: return 4
	if uses >= 40: return 3
	if uses >= 15: return 2
	if uses >= 5: return 1
	return 0

func _update() -> void:
	var lines: Array = []
	lines.append("[b][color=#3498db]╔══════════════════════════════════════════════════════╗[/color][/b]")
	lines.append("[b][color=#3498db]║              F I S H I N G                       ║[/color][/b]")
	lines.append("[b][color=#3498db]╚══════════════════════════════════════════════════════╝[/color][/b]")

	var skill: int = GameData.skill_uses.get("fishing", 0)
	var level := _skill_level(skill)
	var tier: String = GameData.get_skill_tier("fishing")
	lines.append("Skill: %s (%d casts)" % [tier, skill])
	lines.append("")

	match state:
		"idle":
			lines.append("You stand at the water's edge.")
			lines.append("")
			lines.append("[Space/E] Cast line")
		"casting":
			var dots := ".".repeat(int(cast_timer * 3) % 4)
			lines.append("Casting%s" % dots)
		"waiting":
			var dots := ".".repeat(int(cast_timer * 2) % 4)
			lines.append("Waiting for a bite%s" % dots)
		"bite":
			lines.append("[color=yellow][b]SOMETHING'S BITING![/b][/color]")
			var bar := ""
			for i in range(reel_target):
				if i < reel_progress:
					bar += "[color=green]█[/color]"
				else:
					bar += "[color=#555]░[/color]"
			lines.append("Reel: %s" % bar)
			lines.append("[Space/E] Reel in!")
		"caught":
			if not current_fish.is_empty():
				lines.append("[color=green][b]Caught: %s![/b][/color]" % current_fish["name"])
				lines.append("Value: %dc" % current_fish["price"])
				if current_fish.get("cooking", {}).get("hp", 0) > 0:
					lines.append("Cooking: +%d HP" % current_fish["cooking"]["hp"])
			else:
				lines.append("[color=green]Got something![/color]")
			lines.append("")
			lines.append("[Space/E] Continue")
		"lost":
			lines.append("[color=red]The fish got away...[/color]")
			lines.append("")
			lines.append("[Space/E] Try again")

	lines.append("")
	lines.append("[color=gray][Esc] Stop fishing[/color]")
	content.text = "\n".join(lines)
