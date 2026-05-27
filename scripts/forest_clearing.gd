# Forest Clearing — hidden grove with herb garden and hermit NPC
extends Node2D

const FactionDB := preload("res://scripts/data/factions.gd")
const AlchemyDB := preload("res://scripts/data/alchemy.gd")
const TILE_SIZE := 16

const MAP := [
	"TTTTTTTTTTTTTTTT",
	"T,,,,,,TT,,,,,,T",
	"T,,,,,,,,,,,,,,T",
	"T,,,HHH,,,,,,,,T",
	"T,,,HHH,,,,BB,,T",
	"T,,,,,,,,,,,,,,T",
	"T,,,,,,,,,,,,,,T",
	"TTT,,,,,,,,,TTTT",
	"T,,,,,,,,,,,,,,T",
	"T,,,,GGGG,,,,,,T",
	"T,,,,GGGG,,,,,,T",
	"T,,,,,,,,,,,,,,T",
	"T,,,,,,,,,PP,,,T",
	"T,,,,,,,,,,,,,,T",
	"T,,,,,,,,,,,,,,T",
	"TTTTTTTTTTTTTTTT",
]

const COLORS := {
	"T": Color("2a4a2a"), ",": Color("4a6a3a"), "H": Color("3a8a3a"),
	"B": Color("8a6a3a"), "G": Color("5a8a5a"), "P": Color("6a4a6a"),
}

const BLOCKED := {"T": true}

const GARDEN_POSITIONS := [
	Vector2i(4, 9), Vector2i(5, 9), Vector2i(6, 9), Vector2i(7, 9),
	Vector2i(4, 10), Vector2i(5, 10), Vector2i(6, 10), Vector2i(7, 10),
]

const HERB_TYPES := ["forest_moss", "wild_sage", "dark_cap", "fog_petals"]
const NPC_POSITIONS := {
	Vector2i(10, 12): "hermit",
}

const NPC_DATA := {
	"hermit": {
		"name": "Wren Greenhand",
		"color": Color("5a7a3a"),
		"faction": FactionDB.Faction.KEEPERS_GUILD,
	},
}

var pos: Vector2i = Vector2i(7, 14)
var facing: Vector2i = Vector2i.UP
var walking: bool = false
var walk_timer: float = 0.0
var talking_to: String = ""
var gathered_today: Dictionary = {}
var rng := RandomNumberGenerator.new()

@onready var map_layer: Node2D = $MapLayer
@onready var player_sprite: Node2D = $PlayerSprite
@onready var dialog: RichTextLabel = $Dialog

func _ready() -> void:
	rng.seed = hash("clearing_%d" % Time.get_ticks_msec())
	_draw_map()
	_update_player()
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

func _tile(grid: Vector2i) -> String:
	if grid.x < 0 or grid.x >= MAP[0].length() or grid.y < 0 or grid.y >= MAP.size():
		return "T"
	return MAP[grid.y].substr(grid.x, 1)

func _interact() -> void:
	var target := pos + facing

	# Check NPC
	var npc_id: String = NPC_POSITIONS.get(target, "")
	if npc_id != "":
		talking_to = npc_id
		_interact_hermit()
		return

	var tile := _tile(target)

	# Garden tiles
	if tile == "G":
		_try_gather(target)
		return

	# Berry bush
	if tile == "B":
		_say("Wild berries grow here. They're tart but filling.")
		return

	# Herbs
	if tile == "H":
		_say("Rare herbs grow in the shade of the trees. The hermit tends these carefully.")
		return

	# Purple flowers
	if tile == "P":
		_say("Strange purple flowers pulse with a faint glow. The Unlit value these.")
		return

	_say("Sunlight filters through the canopy. Birds sing overhead.")

func _try_gather(target: Vector2i) -> void:
	var key := str(target)
	if gathered_today.get(key, false):
		_say("This patch has already been harvested. Come back later.")
		return
	gathered_today[key] = true
	var herb: String = HERB_TYPES[rng.randi() % HERB_TYPES.size()]
	var herb_id: int = AlchemyDB.get_herb_id_by_string(herb)
	var herb_name: String = AlchemyDB.get_herb_name(herb_id) if herb_id >= 0 else herb
	var count := rng.randi_range(1, 3)
	GameData.add_herb(herb, count)
	GameData.track_skill_use("herbalism")
	_say("[color=green]Gathered %s x%d from the garden![/color]" % [herb_name, count])

func _interact_hermit() -> void:
	var npc: Dictionary = NPC_DATA["hermit"]
	var rep := GameData.get_faction_rep(FactionDB.Faction.KEEPERS_GUILD)
	var msg := "[color=#%s]%s[/color]: " % [npc["color"].to_html(), npc["name"]]
	if rep <= -20:
		msg += "You're no friend of the Keepers. I have nothing to teach you."
	elif GameData.boss_defeated:
		msg += "The shade is gone! The herbs are growing stronger already. The clearing remembers your deeds."
		msg += "\n\nWait — I found something buried near the old oak. Pages from a journal. Mara's handwriting. She hid her full notes here.\n[color=cyan]You found Mara Venn's complete journal![/color]"
		GameData.set_meta("found_maras_journal", true)
	elif rep >= 20:
		msg += "A true Keeper! My garden is your garden. Gather what you need — the herbs grow back each day."
	else:
		msg += "Welcome to my clearing. I tend these herbs for the Keepers.\nThe garden regrows each visit. Gather freely — the forest provides."
	if rep > -20:
		var skill: int = GameData.skill_uses.get("herbalism", 0)
		var tier: String = GameData.get_skill_tier("herbalism")
		msg += "\n\nHerbalism: %s (%d gathers)" % [tier, skill]
	msg += "\n\n[Esc] Back"
	_say(msg)
	talking_to = ""

func _handle_dialog_input(keycode: int) -> void:
	match keycode:
		KEY_ESCAPE:
			talking_to = ""
			_update_hud()

func _say(msg: String) -> void:
	dialog.text = "[b]Forest Clearing[/b]    %s\n\n%s" % [GameData.format_money_short(), msg]

func _update_hud() -> void:
	var lines: Array = []
	for m: Dictionary in GameData.party:
		if m["alive"]:
			lines.append("Lv%d %s  %d/%d" % [m["level"], m["name"], m["hp"], m["max_hp"]])
		else:
			lines.append("Lv%d %s  [KO]" % [m["level"], m["name"]])
	dialog.text = "[b]Forest Clearing[/b]    %s\n\n%s" % [GameData.format_money_short(), "\n".join(lines)]
