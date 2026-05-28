# Abandoned Village — The Unlit hideout with faction NPCs
extends Node2D

const FactionDB := preload("res://scripts/data/factions.gd")
const CharDB := preload("res://scripts/data/classes.gd")
const TILE_SIZE := 16

const MAP := [
	"################",
	"#......##......#",
	"#......##......#",
	"#..NN..##..HH..#",
	"#......##......#",
	"#..............#",
	"#..............#",
	"#####....#######",
	"#..............#",
	"#..TT..........#",
	"#..............#",
	"#..DD......CC..#",
	"#..............#",
	"#..............#",
	"#..............#",
	"################",
]

const COLORS := {
	"#": Color("4a4040"), ".": Color("5a5550"),
	"N": Color("3a3a3a"), "H": Color("2a2a3a"),
	"T": Color("3a2a2a"), "D": Color("2a3a2a"),
	"C": Color("4a4a3a"),
}

const BLOCKED := {"#": true}

const NPC_POSITIONS := {
	Vector2i(3, 3): "unlit_elder",
	Vector2i(13, 3): "unlit_healer",
	Vector2i(3, 9): "unlit_trader",
	Vector2i(3, 11): "unlit_recruit",
	Vector2i(13, 11): "unlit_scout",
}

const NPC_DATA := {
	"unlit_elder": {
		"name": "Vash the Dim",
		"color": Color("6a4a6a"),
		"faction": FactionDB.Faction.THE_UNLIT,
		"lines": {
			"welcome": "You walk in the light, yet you come here. Interesting.\nThe Unlit chose shadow over flame — and we survive still.",
			"hostile": "Leave this place. You've done enough harm to our people already.",
			"friendly": "You have shown kindness to those in shadow. Perhaps not all who carry light are blind.",
			"quest": "The sealed cave... we've felt something stirring within. If the Line breaks, both light and shadow may fall.",
			"boss_done": "The shade is gone. The seal holds no longer. What comes next... even the dark does not know.",
		},
	},
	"unlit_healer": {
		"name": "Mist Weaver Ash",
		"color": Color("5a7a5a"),
		"faction": FactionDB.Faction.THE_UNLIT,
		"lines": {
			"default": "The mist heals what light burns. Let me tend to your wounds — for a price.",
			"hostile": "I don't heal those who hurt us.",
			"friendly": "A friend of the shadow deserves our care. I'll charge you less.",
		},
	},
	"unlit_trader": {
		"name": "Rook Blackmarket",
		"color": Color("8a6a3a"),
		"faction": FactionDB.Faction.THE_UNLIT,
		"lines": {
			"default": "No questions asked, no records kept. What do you need?\nI trade in things the factions don't want people to have.",
			"hostile": "I don't trade with enemies. Get out.",
			"friendly": "For a friend of the shadow, I have special stock. Prices are... favorable.",
		},
	},
	"unlit_recruit": {
		"name": "Kira Shadowstep",
		"color": Color("5a5a8a"),
		"faction": FactionDB.Faction.THE_UNLIT,
		"lines": {
			"default": "Looking for someone who knows how to move unseen? I'm your person.\nI work for wages, but I'm loyal to those who treat the Unlit fairly.",
			"hostile": "You think I'd work for someone like you? Dream on.",
			"friendly": "You've been good to my people. I'll join you — wage negotiable.",
		},
	},
	"unlit_scout": {
		"name": "Dusk",
		"color": Color("7a5a5a"),
		"faction": FactionDB.Faction.THE_UNLIT,
		"lines": {
			"default": "I watch the roads. Nothing enters or leaves this village without my knowing.\nThe beacons... when they light up, it burns our eyes. But we endure.",
			"hostile": "I see you. And I don't like what I see. Leave.",
			"friendly": "You've earned some trust. I can tell you what I've seen on the roads.",
		},
	},
}

var pos: Vector2i = Vector2i(7, 15)
var facing: Vector2i = Vector2i.UP
var walking: bool = false
var walk_timer: float = 0.0
var talking_to: String = ""
var recruit_mode: bool = false
var trade_mode: bool = false
var trade_idx: int = 0

@onready var map_layer: Node2D = $MapLayer
@onready var player_sprite: Node2D = $PlayerSprite
@onready var dialog: RichTextLabel = $Dialog

func _ready() -> void:
	_draw_map()
	_update_player()
	if GameData.boss_defeated:
		GameData.set_meta("visited_unlit_post_seal", true)
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

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if walking:
		return

	if talking_to != "":
		_handle_dialog_input(event.keycode)
		return
	if recruit_mode:
		_handle_recruit_input(event.keycode)
		return
	if trade_mode:
		_handle_trade_input(event.keycode)
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
	if _is_exit_step(dir):
		SceneTransition.change_scene("res://scenes/overworld/overworld.tscn")
		return
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

func _is_exit_step(dir: Vector2i) -> bool:
	return dir == Vector2i.DOWN and pos.y >= MAP.size() - 2

func _interact() -> void:
	var target := pos + facing
	var npc_id: String = NPC_POSITIONS.get(target, "")
	if npc_id == "":
		_say("Crumbling walls. Dust and shadows.")
		return
	talking_to = npc_id
	var npc: Dictionary = NPC_DATA[npc_id]
	var rep := GameData.get_faction_rep(FactionDB.Faction.THE_UNLIT)
	var context := "default"
	if rep <= -20:
		context = "hostile"
	elif rep >= 20:
		context = "friendly"
	var line: String = npc["lines"].get(context, npc["lines"].get("default", "..."))
	match npc_id:
		"unlit_elder":
			_interact_elder(npc, line, rep)
		"unlit_healer":
			_interact_healer(npc, line, rep)
		"unlit_trader":
			_interact_trader(npc, line)
		"unlit_recruit":
			_interact_recruit(npc, line, rep)
		"unlit_scout":
			_say("[color=#%s]%s[/color]: %s\n\n[Esc] Back" % [npc["color"].to_html(), npc["name"], line])
			talking_to = ""

func _get_context_line(npc: Dictionary, context: String) -> String:
	return npc["lines"].get(context, npc["lines"].get("default", "..."))

func _interact_elder(npc: Dictionary, line: String, rep: int) -> void:
	if rep <= -20:
		_say("[color=#%s]%s[/color]: %s\n\n[Esc] Back" % [npc["color"].to_html(), npc["name"], line])
		talking_to = ""
		return
	var msg := "[color=#%s]%s[/color]: " % [npc["color"].to_html(), npc["name"]]
	if GameData.boss_defeated:
		msg += npc["lines"].get("boss_done", line)
	elif GameData.get_meta("cave_opened", false):
		msg += npc["lines"].get("quest", line)
	elif rep >= 20:
		msg += npc["lines"].get("friendly", line)
	else:
		msg += npc["lines"].get("welcome", line)
	GameData.change_faction_rep(FactionDB.Faction.THE_UNLIT, 2)
	msg += "\n\n[Esc] Back"
	_say(msg)
	talking_to = ""

func _interact_healer(npc: Dictionary, line: String, rep: int) -> void:
	if rep <= -20:
		_say("[color=#%s]%s[/color]: %s\n\n[Esc] Back" % [npc["color"].to_html(), npc["name"], line])
		talking_to = ""
		return
	var cost: int = 100 if rep < 20 else 50
	var msg: String = "[color=#%s]%s[/color]: %s\n\n[Restores all HP and magic!]\nCost: %dc\n\n[1] Heal party (%dc)  [Esc] Back" % [npc["color"].to_html(), npc["name"], line, cost, cost]
	talking_to = "healer_confirm"
	# Store cost in meta for confirmation
	GameData.set_meta("unlit_heal_cost", cost)
	_say(msg)

func _interact_trader(npc: Dictionary, line: String) -> void:
	var msg: String = "[color=#%s]%s[/color]: %s\n\n[1] Browse goods  [Esc] Back" % [npc["color"].to_html(), npc["name"], line]
	talking_to = "trader_confirm"
	_say(msg)

func _interact_recruit(npc: Dictionary, line: String, rep: int) -> void:
	if rep <= -20:
		_say("[color=#%s]%s[/color]: %s\n\n[Esc] Back" % [npc["color"].to_html(), npc["name"], line])
		talking_to = ""
		return
	if GameData.party.size() >= 4:
		_say("[color=#%s]%s[/color]: Your party's full. Come back when there's room." % npc["color"].to_html())
		talking_to = ""
		return
	var wage: int = 60 if rep >= 20 else 80
	var msg: String = "[color=#%s]%s[/color]: %s\n\nWage: %dc/wk  Class: Thief\n\n[1] Recruit (%dc)  [Esc] Back" % [
		npc["color"].to_html(), npc["name"], line, wage, wage]
	GameData.set_meta("unlit_recruit_wage", wage)
	talking_to = "recruit_confirm"
	_say(msg)

func _handle_dialog_input(keycode: int) -> void:
	match keycode:
		KEY_1, KEY_ENTER, KEY_SPACE:
			_confirm_dialog()
		KEY_ESCAPE:
			talking_to = ""
			recruit_mode = false
			trade_mode = false
			_update_hud()

func _handle_recruit_input(keycode: int) -> void:
	_handle_dialog_input(keycode)

func _confirm_dialog() -> void:
	match talking_to:
		"healer_confirm":
			var cost: int = GameData.get_meta("unlit_heal_cost", 100)
			if GameData.spend_copper(cost):
				GameData.full_heal()
				_say("[color=green]The mist envelops your party. All wounds mended![/color]")
			else:
				_say("Not enough copper. You need %dc." % cost)
			talking_to = ""
		"trader_confirm":
			talking_to = ""
			trade_mode = true
			trade_idx = 0
			_show_trade()
		"recruit_confirm":
			_try_recruit_kira()
		_:
			talking_to = ""
			_update_hud()

func _try_recruit_kira() -> void:
	var wage: int = GameData.get_meta("unlit_recruit_wage", 80)
	if GameData.party.size() >= 4:
		_say("Your party is full!")
		talking_to = ""
		return
	if not GameData.spend_copper(wage):
		_say("Not enough copper. You need %dc." % wage)
		talking_to = ""
		return
	var tmpl: Dictionary = CharDB.get_template("Thief").duplicate(true)
	var member := {
		"name": "Kira",
		"class": "Thief",
		"hp": tmpl["hp"], "max_hp": tmpl["hp"],
		"str": tmpl["str"], "def": tmpl["def"], "agi": tmpl["agi"],
		"level": 3, "xp": 0, "next_xp": 18,
		"magic_levels": _copy_magic(tmpl.get("magic_levels", {})),
		"alive": true, "command": "", "command_label": "",
		"wage": wage, "loyalty": 60,
		"equipment": GameData.create_empty_equipment(),
	}
	GameData.party.append(member)
	GameData.ensure_party_equipment()
	GameData.change_faction_rep(FactionDB.Faction.THE_UNLIT, 5)
	_say("[color=green]Kira Shadowstep joins your party![/color] Paid %dc wage." % wage)
	talking_to = ""

const TRADE_GOODS := [
	{"id": "shadow_oil", "name": "Shadow Oil", "type": "trade", "price": 200, "sell_base": 150, "desc": "Dark lantern fuel — reduces beacon detection"},
	{"id": "smoke_bomb", "name": "Smoke Bomb", "type": "consumable", "price": 150, "desc": "Guaranteed escape from one battle"},
	{"id": "dark_lens", "name": "Dark Lens", "type": "trade", "price": 300, "sell_base": 200, "desc": "Unlit-made lens — opposite of beacon lenses"},
	{"id": "fog_in_a_bottle", "name": "Fog in a Bottle", "type": "consumable", "price": 100, "desc": "Creates fog cover on the overworld"},
]

func _show_trade() -> void:
	var lines: Array = []
	var rep: int = GameData.get_faction_rep(FactionDB.Faction.THE_UNLIT)
	var price_mod: float = 1.0 if rep >= 20 else (1.5 if rep <= -20 else 1.0)
	lines.append("[b]Black Market[/b]    %s" % GameData.format_money_short())
	lines.append("")
	for i in range(TRADE_GOODS.size()):
		var item: Dictionary = TRADE_GOODS[i]
		var price: int = int(item["price"] * price_mod)
		var marker: String = "▶" if i == trade_idx else " "
		var can_afford: bool = GameData.gold >= price
		var color_start: String = "" if can_afford else "[color=#666]"
		var color_end: String = "" if can_afford else "[/color]"
		lines.append("%s%s %-18s %dc  %s%s" % [color_start, marker, item["name"], price, item["desc"], color_end])
	lines.append("")
	lines.append("[1]/Enter to buy, arrows to browse, [Esc] back")
	_say("\n".join(lines))

func _handle_trade_input(keycode: int) -> void:
	match keycode:
		KEY_UP:
			trade_idx = max(0, trade_idx - 1)
			_show_trade()
		KEY_DOWN:
			trade_idx = min(TRADE_GOODS.size() - 1, trade_idx + 1)
			_show_trade()
		KEY_1, KEY_ENTER, KEY_SPACE:
			_try_buy_trade()
		KEY_ESCAPE:
			trade_mode = false
			_update_hud()

func _try_buy_trade() -> void:
	if trade_idx >= TRADE_GOODS.size():
		return
	var item: Dictionary = TRADE_GOODS[trade_idx]
	var rep: int = GameData.get_faction_rep(FactionDB.Faction.THE_UNLIT)
	var price_mod: float = 1.0 if rep >= 20 else (1.5 if rep <= -20 else 1.0)
	var price: int = int(item["price"] * price_mod)
	if not GameData.spend_copper(price):
		_say("Not enough copper. Need %dc." % price)
		return
	if GameData.bag_full("trade"):
		return
	GameData.trade_goods.append({
		"id": item["id"],
		"name": item["name"],
		"price": price,
		"sell_base": item.get("sell_base", int(price * 0.6)),
	})
	GameData.change_faction_rep(FactionDB.Faction.THE_UNLIT, 1)
	_say("[color=green]Bought %s for %dc![/color]" % [item["name"], price])
	trade_mode = false

func _copy_magic(src: Dictionary) -> Dictionary:
	var out := {}
	for lvl: int in src:
		out[lvl] = {"charges": src[lvl], "max": src[lvl]}
	return out

func _say(msg: String) -> void:
	dialog.text = "[b]The Abandoned Village[/b]    %s\n\n%s" % [GameData.format_money_short(), msg]

func _update_hud() -> void:
	var lines: Array = []
	for m: Dictionary in GameData.party:
		if m["alive"]:
			lines.append("Lv%d %s  %d/%d" % [m["level"], m["name"], m["hp"], m["max_hp"]])
		else:
			lines.append("Lv%d %s  [KO]" % [m["level"], m["name"]])
	dialog.text = "[b]The Abandoned Village[/b]    %s\n\n%s" % [GameData.format_money_short(), "\n".join(lines)]
