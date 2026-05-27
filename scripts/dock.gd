# Dock — Brindlewick harbor with NPCs, exchange, and fishing
extends Node2D

const FactionDB := preload("res://scripts/data/factions.gd")
const FishDB := preload("res://scripts/data/fish.gd")
const TILE_SIZE := 16

const MAP := [
	"~~~~~~~~~~~~~~~~",
	"~~~~~~~~~~~~~~~~",
	"~...~~~~~~~.....#",
	"~...~~~~~~~.....#",
	"~...............#",
	"~...............#",
	"~...##..........#",
	"~...##..........#",
	"~...............#",
	"~...............#",
	"~..RR.......SS..#",
	"~...............#",
	"~...............#",
	"################",
	"################",
	"################",
]

const COLORS := {
	"#": Color("6a5a3a"), "~": Color("2a5a8a"), ".": Color("8a7a5a"),
	"R": Color("8b6914"), "S": Color("5a3a1a"),
}

const BLOCKED := {"#": true, "~": true}

const NPC_POSITIONS := {
	Vector2i(3, 10): "harbor_master",
	Vector2i(13, 10): "sailor",
}

const NPC_DATA := {
	"harbor_master": {
		"name": "Captain Aldric",
		"color": Color("2980b9"),
		"faction": FactionDB.Faction.HARBOR_COMPACT,
	},
	"sailor": {
		"name": "Deckhand Mira",
		"color": Color("7f8c8d"),
		"faction": FactionDB.Faction.HARBOR_COMPACT,
	},
}

var pos: Vector2i = Vector2i(7, 11)
var facing: Vector2i = Vector2i.UP
var walking: bool = false
var walk_timer: float = 0.0
var talking_to: String = ""
var exchange_mode: bool = false
var exchange_idx: int = 0
var fishing_active: bool = false
var fish_timer: float = 0.0
var fish_state: String = "idle"
var fish_reel: int = 0
var fish_target: int = 5
var current_fish: Dictionary = {}
var rng := RandomNumberGenerator.new()

@onready var map_layer: Node2D = $MapLayer
@onready var player_sprite: Node2D = $PlayerSprite
@onready var dialog: RichTextLabel = $Dialog

func _ready() -> void:
	rng.seed = hash("dock_%d" % Time.get_ticks_msec())
	_draw_map()
	_update_player()
	if GameData.boss_defeated:
		GameData.set_meta("visited_compact_dock", true)
		if GameData.get_meta("visited_keepers_town", false):
			GameData.set_meta("resolved_oil_dispute", true)
	_update_hud()

func _draw_map() -> void:
	for y in range(MAP.size()):
		for x in range(MAP[y].length()):
			var tile: String = MAP[y].substr(x, 1)
			var rect := ColorRect.new()
			rect.color = COLORS.get(tile, Color.MAGENTA)
			rect.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
			rect.size = Vector2(TILE_SIZE, TILE_SIZE)
			map_layer.add_child(rect)
	for npc_pos in NPC_POSITIONS:
		var npc_id: String = NPC_POSITIONS[npc_pos]
		var npc: Dictionary = NPC_DATA[npc_id]
		var marker := ColorRect.new()
		marker.color = npc["color"]
		marker.position = Vector2(npc_pos * TILE_SIZE) + Vector2(2, 2)
		marker.size = Vector2(12, 12)
		map_layer.add_child(marker)

func _update_player() -> void:
	player_sprite.position = Vector2(pos * TILE_SIZE) + Vector2(TILE_SIZE / 2, TILE_SIZE / 2)

func _process(delta: float) -> void:
	if walking:
		walk_timer -= delta
		if walk_timer <= 0:
			walking = false
		_update_player()
	if fishing_active:
		_update_fishing(delta)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if walking:
		return

	if fishing_active:
		_handle_fishing_input(event.keycode)
		return

	if talking_to != "":
		_handle_dialog_input(event.keycode)
		return
	if exchange_mode:
		_handle_exchange_input(event.keycode)
		return

	var dir := Vector2i.ZERO
	if Input.is_action_just_pressed("move_up"):    dir = Vector2i.UP
	elif Input.is_action_just_pressed("move_down"):  dir = Vector2i.DOWN
	elif Input.is_action_just_pressed("move_left"):  dir = Vector2i.LEFT
	elif Input.is_action_just_pressed("move_right"): dir = Vector2i.RIGHT
	elif Input.is_action_just_pressed("interact"):
		_interact()
		return
	elif event.keycode == KEY_ESCAPE:
		SceneTransition.change_scene("res://scenes/overworld/overworld.tscn")
		return

	if dir != Vector2i.ZERO:
		_try_move(dir)

func _try_move(dir: Vector2i) -> void:
	facing = dir
	var next := pos + dir
	if _is_blocked(next):
		return
	pos = next
	walking = true
	walk_timer = 0.15
	_update_player()
	_check_exit()

func _is_blocked(grid: Vector2i) -> bool:
	if grid.x < 0 or grid.x >= MAP[0].length() or grid.y < 0 or grid.y >= MAP.size():
		return true
	return BLOCKED.has(MAP[grid.y].substr(grid.x, 1))

func _check_exit() -> void:
	if pos.y >= MAP.size() - 1:
		SceneTransition.change_scene("res://scenes/overworld/overworld.tscn")

func _tile(grid: Vector2i) -> String:
	if grid.x < 0 or grid.x >= MAP[0].length() or grid.y < 0 or grid.y >= MAP.size():
		return "#"
	return MAP[grid.y].substr(grid.x, 1)

func _interact() -> void:
	var target := pos + facing
	var tile := _tile(target)

	# Check NPCs first
	var npc_id: String = NPC_POSITIONS.get(target, "")
	if npc_id != "":
		talking_to = npc_id
		_interact_npc(npc_id)
		return

	# Water tiles = fishing
	if tile == "~":
		_start_fishing(FishDB.Zone.DEEP_WATER)
		return

	# Rope/ship interaction
	if tile == "S":
		_say("A weathered fishing boat. The harbor master might know if there's passage available.")
		return
	if tile == "R":
		_say("Coiled rope and cargo crates. The Harbor Compact keeps this dock running.")
		return

	_say("Nothing interesting here.")

func _interact_npc(npc_id: String) -> void:
	var npc: Dictionary = NPC_DATA[npc_id]
	var rep := GameData.get_faction_rep(npc["faction"])
	match npc_id:
		"harbor_master":
			var msg := "[color=#%s]%s[/color]: " % [npc["color"].to_html(), npc["name"]]
			if rep <= -20:
				msg += "The Compact doesn't do business with your kind. Come back when you've made amends."
				msg += "\n\n[Esc] Back"
			else:
				msg += "Welcome to Brindlewick Harbor. The Harbor Compact runs these docks.\n"
				if rep >= 20:
					msg += "A friend of the Compact! Good to see you.\n"
				else:
					msg += "Trade's been steady. Ships from the mainland keep the cargo flowing.\n"
				msg += "\n[1] Exchange currency  [2] Deep water fishing  [Esc] Back"
			_say(msg)
		"sailor":
			var msg := "[color=#%s]%s[/color]: " % [npc["color"].to_html(), npc["name"]]
			if GameData.boss_defeated:
				msg += "The fog's gone! I've never seen the horizon this clear. Whatever you did, it worked."
			elif GameData.beacon_lit:
				msg += "I work the ships. Seen fog swallow whole vessels. Keep those beacons lit.\n"
				msg += "I heard a beacon's been lit. That's good news for all of us."
			else:
				msg += "I work the ships. Seen fog swallow whole vessels. Keep those beacons lit.\n"
				msg += "The fog's been getting thicker. Something's wrong out there."
			msg += "\n\n[Esc] Back"
			_say(msg)
			talking_to = ""

func _handle_dialog_input(keycode: int) -> void:
	match keycode:
		KEY_1:
			if talking_to == "harbor_master":
				talking_to = ""
				exchange_mode = true
				exchange_idx = 0
				_show_exchange()
		KEY_2:
			if talking_to == "harbor_master":
				talking_to = ""
				_start_fishing(FishDB.Zone.DEEP_WATER)
		KEY_ESCAPE:
			talking_to = ""
			exchange_mode = false
			_update_hud()

func _start_fishing(zone: int) -> void:
	fishing_active = true
	fish_state = "idle"
	fish_timer = 0.0
	fish_reel = 0
	current_fish = {}
	GameData.set_meta("dock_fishing_zone", zone)
	_update_fishing_display()

func _update_fishing(delta: float) -> void:
	match fish_state:
		"casting":
			fish_timer -= delta
			if fish_timer <= 0:
				fish_state = "waiting"
				fish_timer = randf_range(2.0, 6.0)
		"waiting":
			fish_timer -= delta
			if fish_timer <= 0:
				_try_bite()
		"bite":
			fish_timer -= delta
			if fish_timer <= 0:
				fish_state = "lost"
	_update_fishing_display()

func _try_bite() -> void:
	var zone: int = GameData.get_meta("dock_fishing_zone", FishDB.Zone.DEEP_WATER)
	var skill: int = GameData.skill_uses.get("fishing", 0)
	var level := _skill_level(skill)
	var available := FishDB.fish_for_zone(zone, level)
	if available.is_empty():
		fish_state = "idle"
		return
	var weights: Array = available.map(func(f): return f["rarity"])
	var total := 0.0
	for w in weights:
		total += w
	var roll := rng.randf() * total
	var cumulative := 0.0
	for i in range(available.size()):
		cumulative += weights[i]
		if roll <= cumulative:
			current_fish = available[i]
			break
	if current_fish.is_empty():
		current_fish = available[0]
	fish_state = "bite"
	fish_timer = 2.5
	fish_reel = 0
	fish_target = mini(3 + int(current_fish["rarity"] * 20), 12)

func _handle_fishing_input(keycode: int) -> void:
	match keycode:
		KEY_SPACE, KEY_ENTER, KEY_E:
			match fish_state:
				"idle":
					fish_state = "casting"
					fish_timer = 1.0
				"bite":
					fish_reel += 1
					if fish_reel >= fish_target:
						_catch_fish()
				"caught", "lost":
					fish_state = "idle"
					current_fish = {}
		KEY_ESCAPE:
			fishing_active = false
			_update_hud()

func _catch_fish() -> void:
	fish_state = "caught"
	GameData.track_skill_use("fishing", 1)
	GameData.track_gather("fish")
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

func _skill_level(uses: int) -> int:
	if uses >= 80: return 4
	if uses >= 40: return 3
	if uses >= 15: return 2
	if uses >= 5: return 1
	return 0

func _update_fishing_display() -> void:
	var lines: Array = []
	lines.append("[b][color=#3498db]Deep Water Fishing[/color][/b]")
	var skill: int = GameData.skill_uses.get("fishing", 0)
	var tier: String = GameData.get_skill_tier("fishing")
	lines.append("Skill: %s (%d casts)" % [tier, skill])
	lines.append("")
	match fish_state:
		"idle":
			lines.append("The deep water churns beneath the dock.")
			lines.append("[Space/E] Cast line")
		"casting":
			var dots := ".".repeat(int(fish_timer * 3) % 4)
			lines.append("Casting%s" % dots)
		"waiting":
			var dots := ".".repeat(int(fish_timer * 2) % 4)
			lines.append("Waiting for a bite%s" % dots)
		"bite":
			lines.append("[color=yellow][b]SOMETHING'S BITING![/b][/color]")
			var bar := ""
			for i in range(fish_target):
				if i < fish_reel:
					bar += "[color=green]█[/color]"
				else:
					bar += "[color=#555]░[/color]"
			lines.append("Reel: %s" % bar)
			lines.append("[Space/E] Reel in!")
		"caught":
			if not current_fish.is_empty():
				lines.append("[color=green][b]Caught: %s![/b][/color]" % current_fish["name"])
				lines.append("Value: %dc" % current_fish["price"])
			else:
				lines.append("[color=green]Got something![/color]")
			lines.append("[Space/E] Continue")
		"lost":
			lines.append("[color=red]The fish got away...[/color]")
			lines.append("[Space/E] Try again")
	lines.append("")
	lines.append("[Esc] Stop fishing")
	_say("\n".join(lines))

func _exchange_options() -> Array:
	var km_rate := GameData.get_currency_buy_rate("keeper_marks")
	var ht_rate := GameData.get_currency_buy_rate("harbor_tokens")
	var cs_rate := GameData.get_currency_buy_rate("chapel_script")
	var km_sell := GameData.get_currency_sell_rate("keeper_marks")
	var cs_sell := GameData.get_currency_sell_rate("chapel_script")
	return [
		{"label": "Buy Harbor Token", "from": "copper", "to": "harbor_tokens", "cost": ht_rate, "gain": 1, "rate_text": "%dc → 1 Token" % ht_rate},
		{"label": "Sell Harbor Token", "from": "harbor_tokens", "to": "copper", "cost": 1, "gain": GameData.get_currency_sell_rate("harbor_tokens"), "rate_text": "1 Token → %dc" % GameData.get_currency_sell_rate("harbor_tokens")},
		{"label": "Buy Keeper Mark", "from": "copper", "to": "keeper_marks", "cost": km_rate, "gain": 1, "rate_text": "%dc → 1 Mark" % km_rate},
		{"label": "Sell Keeper Mark", "from": "keeper_marks", "to": "copper", "cost": 1, "gain": km_sell, "rate_text": "1 Mark → %dc" % km_sell},
		{"label": "Buy Chapel Script", "from": "copper", "to": "chapel_script", "cost": cs_rate, "gain": 1, "rate_text": "%dc → 1 Script" % cs_rate},
		{"label": "Sell Chapel Script", "from": "chapel_script", "to": "copper", "cost": 1, "gain": cs_sell, "rate_text": "1 Script → %dc" % cs_sell},
	]

func _show_exchange() -> void:
	var lines: Array = []
	lines.append("[b]Currency Exchange[/b]")
	lines.append("%s | Marks: %d | Tokens: %d | Script: %d" % [
		GameData.format_money_short(), GameData.keeper_marks, GameData.harbor_tokens, GameData.chapel_script])
	lines.append("")
	var options := _exchange_options()
	for i in range(options.size()):
		var opt: Dictionary = options[i]
		var marker := "▶" if i == exchange_idx else " "
		var can_afford := GameData.get_currency_balance(opt["from"]) >= opt["cost"]
		var color_start := "" if can_afford else "[color=#666]"
		var color_end := "" if can_afford else "[/color]"
		lines.append("%s%s %-18s %s%s" % [color_start, marker, opt["label"], opt["rate_text"], color_end])
	lines.append("")
	lines.append("[1]/Enter to trade, arrows to browse, [Esc] back")
	_say("\n".join(lines))

func _handle_exchange_input(keycode: int) -> void:
	match keycode:
		KEY_UP:
			exchange_idx = max(0, exchange_idx - 1)
			_show_exchange()
		KEY_DOWN:
			exchange_idx = min(_exchange_options().size() - 1, exchange_idx + 1)
			_show_exchange()
		KEY_1, KEY_ENTER, KEY_SPACE:
			_try_exchange()
		KEY_ESCAPE:
			exchange_mode = false
			_update_hud()

func _try_exchange() -> void:
	var options := _exchange_options()
	if exchange_idx >= options.size(): return
	var opt: Dictionary = options[exchange_idx]
	if not GameData.spend_currency(opt["from"], opt["cost"]):
		_say("Not enough funds for this trade.")
		return
	GameData.add_currency(opt["to"], opt["gain"])
	_show_exchange()

func _say(msg: String) -> void:
	dialog.text = "[b]Brindlewick Docks[/b]    %s\n\n%s" % [GameData.format_money_short(), msg]

func _update_hud() -> void:
	var lines: Array = []
	for m: Dictionary in GameData.party:
		if m["alive"]:
			lines.append("Lv%d %s  %d/%d" % [m["level"], m["name"], m["hp"], m["max_hp"]])
		else:
			lines.append("Lv%d %s  [KO]" % [m["level"], m["name"]])
	dialog.text = "[b]Brindlewick Docks[/b]    %s\n\n%s" % [GameData.format_money_short(), "\n".join(lines)]
