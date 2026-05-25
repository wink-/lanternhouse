# GameData — autoload singleton holding all persistent game state
# Survives scene transitions. Party, inventory, gold, flags, map position.

extends Node

const CharDB := preload("res://scripts/data/classes.gd")

# ── Party ─────────────────────────────────────────────────────────────────
var party: Array = []            # Array[Dictionary] — 4 characters
var gold: int = 0
var tonics: int = 3

# ── Equipment inventory (what's in the bag, not equipped) ─────────────────
var weapons_bag: Array = []      # Array[Dictionary] — weapon entries {id, name, atk, price}
var armor_bag: Array = []        # Array[Dictionary] — armor entries {id, name, def, price}

# ── Equipment slots per character index ───────────────────────────────────
var equipped_weapon: Array = [-1, -1, -1, -1]   # index into weapons_bag, -1 = none
var equipped_armor: Array = [-1, -1, -1, -1]     # index into armor_bag

# ── Overworld state ───────────────────────────────────────────────────────
var overworld_position: Vector2i = Vector2i(6, 11)
var overworld_facing: Vector2i = Vector2i.DOWN

# ── Flags ─────────────────────────────────────────────────────────────────
var cleared_encounters: Dictionary = {}   # str(Vector2i) → true
var visited_town: bool = false
var boss_defeated: bool = false

# ── Initialization ────────────────────────────────────────────────────────
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if party.is_empty():
		_init_party()

func _init_party() -> void:
	for cls_name in ["Fighter", "Thief", "BlackBelt", "RedMage"]:
		var tmpl: Dictionary = CharDB.get_template(cls_name).duplicate(true)
		party.append({
			"name": cls_name,
			"class": cls_name,
			"hp": tmpl["hp"],  "max_hp": tmpl["hp"],
			"str": tmpl["str"], "def": tmpl["def"], "agi": tmpl["agi"],
			"level": 1, "xp": 0, "next_xp": 18,
			"magic_levels": _copy_magic(tmpl.get("magic_levels", {})),
			"alive": true,
			"command": "",
			"command_label": "",
		})

func _copy_magic(src: Dictionary) -> Dictionary:
	var out := {}
	for lvl: int in src:
		out[lvl] = {"charges": src[lvl], "max": src[lvl]}
	return out

# ── Stat helpers ──────────────────────────────────────────────────────────
func get_effective_str(char_index: int) -> int:
	var m: Dictionary = party[char_index]
	var base: int = m["str"]
	var wi: int = equipped_weapon[char_index]
	if wi >= 0 and wi < weapons_bag.size():
		base += weapons_bag[wi].get("atk", 0)
	return base

func get_effective_def(char_index: int) -> int:
	var m: Dictionary = party[char_index]
	var base: int = m["def"]
	var ai: int = equipped_armor[char_index]
	if ai >= 0 and ai < armor_bag.size():
		base += armor_bag[ai].get("def", 0)
	return base

func full_heal() -> void:
	for m in party:
		m["hp"] = m["max_hp"]
		m["alive"] = true
		for lvl: int in m["magic_levels"]:
			m["magic_levels"][lvl]["charges"] = m["magic_levels"][lvl]["max"]
	tonics = 3

func anyone_alive() -> bool:
	for m in party:
		if m["alive"]:
			return true
	return false

func alive_count() -> int:
	var c := 0
	for m in party:
		if m["alive"]:
			c += 1
	return c
