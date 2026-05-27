# Cave — sealed sea cave dungeon, final boss chamber
extends Node2D

const TILE_SIZE := 16
const EnemyDB := preload("res://scripts/data/enemies.gd")
const ItemDB := preload("res://scripts/data/items.gd")

const MAP := [
	"################",
	"#..............#",
	"#..##....##....#",
	"#..##....##....#",
	"#..............#",
	"#....####......#",
	"#....####......#",
	"#..............#",
	"####..........##",
	"#..............#",
	"#..##..........#",
	"#..##....####..#",
	"#............BB#",
	"#............BB#",
	"#..............#",
	"################",
]

const COLORS := {
	"#": Color("3a3a4a"), ".": Color("5a5a6a"), "B": Color("8b0000"),
}

const BLOCKED := {"#": true}

const CHESTS := {
	Vector2i(14, 12): {"type": "weapon", "id": "mythril_blade", "name": "Mythril Blade", "atk": 18, "price": 3000, "claimed": false},
	Vector2i(5, 2): {"type": "item", "id": "ether", "name": "Ether", "count": 3, "claimed": false},
}

const BOSS_POS := Vector2i(13, 13)
const BOSS := {
	"name": "Mournlight Shade",
	"hp": 120, "atk": 18, "def": 8, "agi": 6,
	"xp": 200, "gold": 5000,
	"color": Color("4a0080"),
}

var pos: Vector2i = Vector2i(7, 15)
var facing: Vector2i = Vector2i.UP
var walking: bool = false
var walk_timer: float = 0.0
var steps: int = 0
var encounter_cooldown: float = 0.0
var victory_phase: int = -1

@onready var map_layer: Node2D = $MapLayer
@onready var player_sprite: Node2D = $PlayerSprite
@onready var dialog: RichTextLabel = $Dialog

func _ready() -> void:
	var deep: bool = GameData.get_meta("cave_deep", false)
	if not GameData.get_meta("cave_opened", false) and not deep:
		SceneTransition.change_scene("res://scenes/overworld/overworld.tscn")
		return
	_draw_map()
	_update_player()
	if deep:
		if GameData.get_meta("endgame_choice_made", false):
			_say("[color=cyan]The deep chamber is quiet now. Ancient grief has been laid to rest.[/color]")
		else:
			_say("[color=yellow]The cave descends deeper than before. Something ancient stirs in the darkness below...[/color]\n\n[Move toward the glowing seal to descend]")
		_update_hud()
	elif GameData.boss_defeated and not GameData.get_meta("victory_shown", false):
		victory_phase = 0
		_show_victory_text()
		GameData.set_meta("victory_shown", true)
	else:
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
	# Draw chest markers
	for cpos in CHESTS:
		var chest: Dictionary = CHESTS[cpos]
		if not chest.get("claimed", false):
			var marker := ColorRect.new()
			marker.color = Color("daa520")
			marker.position = Vector2(cpos * TILE_SIZE) + Vector2(2, 2)
			marker.size = Vector2(12, 12)
			map_layer.add_child(marker)
	# Draw boss marker
	var deep: bool = GameData.get_meta("cave_deep", false)
	if deep and not GameData.get_meta("endgame_choice_made", false):
		var deep_marker := ColorRect.new()
		deep_marker.color = Color("2a1a4a")
		deep_marker.position = Vector2(BOSS_POS * TILE_SIZE) + Vector2(0, 0)
		deep_marker.size = Vector2(TILE_SIZE, TILE_SIZE)
		map_layer.add_child(deep_marker)
	elif not GameData.boss_defeated and not deep:
		var boss_marker := ColorRect.new()
		boss_marker.color = BOSS["color"]
		boss_marker.position = Vector2(BOSS_POS * TILE_SIZE) + Vector2(0, 0)
		boss_marker.size = Vector2(TILE_SIZE, TILE_SIZE)
		map_layer.add_child(boss_marker)

func _update_player() -> void:
	player_sprite.position = Vector2(pos * TILE_SIZE) + Vector2(TILE_SIZE / 2, TILE_SIZE / 2)

func _process(delta: float) -> void:
	if walking:
		walk_timer -= delta
		if walk_timer <= 0:
			walking = false
		_update_player()
	if encounter_cooldown > 0:
		encounter_cooldown -= delta

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if walking:
		return

	if victory_phase >= 0:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			victory_phase += 1
			if victory_phase >= VICTORY_TEXT.size():
				victory_phase = -1
				_update_hud()
			else:
				_show_victory_text()
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
	steps += 1
	_update_player()
	_check_tile()
	_check_exit()

func _is_blocked(grid: Vector2i) -> bool:
	if grid.x < 0 or grid.x >= MAP[0].length() or grid.y < 0 or grid.y >= MAP.size():
		return true
	return BLOCKED.has(MAP[grid.y].substr(grid.x, 1))

func _tile(grid: Vector2i) -> String:
	if grid.x < 0 or grid.x >= MAP[0].length() or grid.y < 0 or grid.y >= MAP.size():
		return "#"
	return MAP[grid.y].substr(grid.x, 1)

func _check_exit() -> void:
	if pos.y >= MAP.size() - 1:
		var deep: bool = GameData.get_meta("cave_deep", false)
		GameData.set_meta("cave_deep", false)
		SceneTransition.change_scene("res://scenes/overworld/overworld.tscn")

func _check_tile() -> void:
	var deep: bool = GameData.get_meta("cave_deep", false)
	# Deep cave boss encounter
	if deep and pos == BOSS_POS and not GameData.get_meta("endgame_choice_made", false):
		_start_deep_boss()
		return
	# Boss tile (Act 1)
	if pos == BOSS_POS and not GameData.boss_defeated:
		_start_boss_fight()
		return

	# Chest tiles
	for cpos in CHESTS:
		if pos == cpos:
			_open_chest(cpos)
			return

	# Random encounters (every 4-8 steps on floor tiles)
	if _tile(pos) == "." and encounter_cooldown <= 0 and steps >= 4:
		if randf() < 0.25:
			steps = 0
			encounter_cooldown = 2.0
			_start_encounter()

func _interact() -> void:
	var target := pos + facing
	var deep: bool = GameData.get_meta("cave_deep", false)
	# Check chests adjacent
	for cpos in CHESTS:
		if target == cpos:
			_open_chest(cpos)
			return
	# Check deep boss adjacent
	if deep and target == BOSS_POS and not GameData.get_meta("endgame_choice_made", false):
		_start_deep_boss()
		return
	# Check boss adjacent (Act 1)
	if target == BOSS_POS and not GameData.boss_defeated:
		_start_boss_fight()
		return
	_say("Damp stone walls. Water drips from somewhere above.")

func _open_chest(cpos: Vector2i) -> void:
	var chest: Dictionary = CHESTS[cpos]
	if chest.get("claimed", false):
		_say("An empty chest.")
		return
	chest["claimed"] = true
	match chest["type"]:
		"weapon":
			GameData.weapons_bag.append({
				"id": chest["id"],
				"name": chest["name"],
				"atk": chest["atk"],
				"price": chest["price"],
			})
			_say("[color=green]Found %s! (ATK +%d)[/color]" % [chest["name"], chest["atk"]])
		"item":
			var count: int = chest.get("count", 1)
			match chest["id"]:
				"ether":
					GameData.ethers += count
			_say("[color=green]Found %s x%d![/color]" % [chest["name"], count])
		_:
			_say("[color=green]Found %s![/color]" % chest["name"])

const VICTORY_TEXT := [
	"[color=cyan]The Mournlight Shade dissolves into wisps of fading shadow...[/color]",
	"[color=yellow]The Lantern Line blazes brighter than ever. The fog begins to recede from the coast.[/color]",
	"The ancient seal is broken. The cave trembles one last time, then falls still.\n\n[color=green]You feel the beacons across the land pulse in unison. The darkness has been pushed back — for now.[/color]",
	"[b]The Lantern Line holds. Brindlewick is safe.[/b]\n\nThe Elder will want to hear of this. The factions will take notice.\n\n[i]Perhaps this is only the beginning...[/i]\n\n[Esc] Return to the overworld",
]

func _show_victory_text() -> void:
	if victory_phase < 0 or victory_phase >= VICTORY_TEXT.size():
		victory_phase = -1
		_update_hud()
		return
	_say(VICTORY_TEXT[victory_phase])

func _start_encounter() -> void:
	GameData.overworld_position = Vector2i(2, 24)  # Cave overworld position
	GameData.overworld_facing = Vector2i.UP
	GameData.set_meta("battle_zone", "cave")
	GameData.set_meta("battle_surprise", false)
	SceneTransition.change_scene("res://scenes/battle/battle.tscn")

func _start_boss_fight() -> void:
	GameData.overworld_position = Vector2i(2, 24)
	GameData.overworld_facing = Vector2i.UP
	GameData.set_meta("battle_zone", "cave_boss")
	GameData.set_meta("battle_surprise", false)
	SceneTransition.change_scene("res://scenes/battle/battle.tscn")

func _start_deep_boss() -> void:
	_say("[color=yellow]The darkness coalesces before you. Ancient grief given form — a monument of sorrow older than the island itself.[/color]")
	await get_tree().create_timer(1.5).timeout
	GameData.overworld_position = Vector2i(2, 24)
	GameData.overworld_facing = Vector2i.UP
	GameData.set_meta("battle_zone", "cave_deep")
	GameData.set_meta("battle_surprise", false)
	GameData.set_meta("deep_boss_active", true)
	SceneTransition.change_scene("res://scenes/battle/battle.tscn")

func _say(msg: String) -> void:
	dialog.text = "[b]Sealed Cave[/b]\n\n%s" % msg

func _update_hud() -> void:
	var lines: Array = []
	for m: Dictionary in GameData.party:
		if m["alive"]:
			lines.append("Lv%d %s  %d/%d" % [m["level"], m["name"], m["hp"], m["max_hp"]])
		else:
			lines.append("Lv%d %s  [KO]" % [m["level"], m["name"]])
	dialog.text = "[b]Sealed Cave[/b]\n\n%s" % "\n".join(lines)
