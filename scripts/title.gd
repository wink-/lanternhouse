extends Control

const MENU_ITEMS := ["New Game", "Continue", "Settings"]
var selected := 0
var has_save := false
var settings_open := false

@onready var title_label: RichTextLabel = $TitleLabel
@onready var menu_label: RichTextLabel = $MenuLabel
@onready var version_label: Label = $VersionLabel

func _ready() -> void:
	has_save = SaveManager.has_save()
	if not has_save:
		selected = 0
	_update_display()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	if settings_open:
		match event.keycode:
			KEY_ESCAPE:
				settings_open = false
				_update_display()
			KEY_M:
				_toggle_music()
			KEY_S:
				_toggle_sfx()
		return

	match event.keycode:
		KEY_UP:
			selected = (selected - 1) % MENU_ITEMS.size()
			if selected < 0: selected = MENU_ITEMS.size() - 1
			if selected == 1 and not has_save:
				selected = (selected - 1) % MENU_ITEMS.size()
			_update_display()
		KEY_DOWN:
			selected = (selected + 1) % MENU_ITEMS.size()
			if selected == 1 and not has_save:
				selected = (selected + 1) % MENU_ITEMS.size()
			if selected == 2 and not has_save and MENU_ITEMS.size() > 2:
				selected = 0
			_update_display()
		KEY_ENTER, KEY_SPACE:
			_select()

func _select() -> void:
	match MENU_ITEMS[selected]:
		"New Game":
			GameData.party.clear()
			GameData.gold = 500
			GameData.tonics = 3
			GameData.ethers = 0
			GameData.keeper_marks = 0
			GameData.harbor_tokens = 0
			GameData.chapel_script = 0
			GameData.weapons_bag.clear()
			GameData.armor_bag.clear()
			GameData.trade_goods.clear()
			GameData.equipped_weapon = [-1, -1, -1, -1]
			GameData.equipped_head = [-1, -1, -1, -1]
			GameData.equipped_body = [-1, -1, -1, -1]
			GameData.equipped_accessory = [-1, -1, -1, -1]
			GameData.overworld_position = Vector2i(14, 19)
			GameData.overworld_facing = Vector2i.UP
			GameData.cleared_encounters.clear()
			GameData.visited_town = false
			GameData.boss_defeated = false
			GameData.beacon_lit = false
			GameData.beacon_states.clear()
			GameData.explored_tiles.clear()
			GameData.active_quests.clear()
			GameData.kill_counts.clear()
			GameData.gather_counts.clear()
			GameData.crafted_items.clear()
			GameData.herb_bag.clear()
			GameData.material_bag.clear()
			GameData.faction_reputation.clear()
			GameData.play_time = 0.0
			GameData.skill_uses.clear()
			GameData.owned_home = ""
			GameData.home_upgrades.clear()
			GameData.home_storage.clear()
			GameData.wage_timer = 0.0
			GameData.pending_departures.clear()
			GameData._init_party()
			SceneTransition.change_scene("res://scenes/overworld/overworld.tscn")
		"Continue":
			if SaveManager.load_game():
				SceneTransition.change_scene("res://scenes/overworld/overworld.tscn")
		"Settings":
			settings_open = true
			_update_display()

func _toggle_music() -> void:
	var vol := AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master"))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), -30.0 if vol > -20.0 else 0.0)
	_update_display()

func _toggle_sfx() -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(bus, not AudioServer.is_bus_mute(bus))
	_update_display()

func _update_display() -> void:
	if settings_open:
		var vol := AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master"))
		var muted := AudioServer.is_bus_mute(AudioServer.get_bus_index("Master"))
		title_label.text = "[center][b]Settings[/b][/center]"
		var lines := []
		lines.append("[M] Music: %s" % ("ON" if vol > -20.0 else "OFF"))
		lines.append("[S] SFX: %s" % ("ON" if not muted else "OFF"))
		lines.append("")
		lines.append("[Esc] Back")
		menu_label.text = "\n".join(lines)
		return

	title_label.text = (
		"[center]" +
		"[color=cyan][font_size=48]LANTERNHOUSE[/font_size][/color]\n" +
		"[font_size=18][color=#8a8a9a]Mournlight Sound[/color][/font_size]\n" +
		"[/center]"
	)

	var lines := []
	for i in range(MENU_ITEMS.size()):
		var item: String = MENU_ITEMS[i]
		var marker := "▶ " if i == selected else "  "
		if item == "Continue":
			if has_save:
				lines.append("%s[color=white]%s[/color]" % [marker, item])
			else:
				lines.append("%s[color=#444]%s[/color]" % [marker, item])
		else:
			lines.append("%s[color=white]%s[/color]" % [marker, item])
	lines.append("")
	lines.append("[color=#666]↑↓ to choose, Enter to select[/color]")
	menu_label.text = "\n".join(lines)

	version_label.text = "v0.1"
