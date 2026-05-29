extends Node

const TARGET_SCENES := {
	"overworld": "res://scenes/overworld/overworld.tscn",
	"town": "res://scenes/town/town.tscn",
	"battle": "res://scenes/battle/battle.tscn",
	"home": "res://scenes/home/home.tscn",
	"cave": "res://scenes/cave/cave.tscn",
	"dock": "res://scenes/dock/dock.tscn",
	"forest_clearing": "res://scenes/forest_clearing/forest_clearing.tscn",
}

func _ready() -> void:
	var options := _parse_options()
	var target: String = options.get("target", "town")
	var scene_path: String = options.get("scene", TARGET_SCENES.get(target, target))
	var output_path: String = options.get("output", "artifacts/screenshots/%s.png" % target)
	var frames: int = int(options.get("frames", "8"))

	var ok := await _capture_scene(scene_path, output_path, frames)
	if ok:
		print("VISUAL_SCENE_CAPTURE_OK %s" % output_path)
		get_tree().quit(0)
	else:
		push_error("VISUAL_SCENE_CAPTURE_FAILED")
		get_tree().quit(1)

func _capture_scene(scene_path: String, output_path: String, frames: int) -> bool:
	_reset_state()
	var packed: PackedScene = load(scene_path)
	if packed == null:
		push_error("Could not load scene: %s" % scene_path)
		return false

	var scene := packed.instantiate()
	add_child(scene)
	for _i in range(max(frames, 1)):
		await get_tree().process_frame

	var image := get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		push_error("Captured viewport image is empty")
		return false

	var absolute_output := _absolute_output_path(output_path)
	var directory := absolute_output.get_base_dir()
	var dir_result := DirAccess.make_dir_recursive_absolute(directory)
	if dir_result != OK:
		push_error("Could not create screenshot directory %s: %s" % [directory, error_string(dir_result)])
		return false

	var save_result := image.save_png(absolute_output)
	if save_result != OK:
		push_error("Could not save screenshot %s: %s" % [absolute_output, error_string(save_result)])
		return false
	return true

func _absolute_output_path(output_path: String) -> String:
	if output_path.begins_with("res://") or output_path.begins_with("user://"):
		return ProjectSettings.globalize_path(output_path)
	if output_path.is_absolute_path():
		return output_path
	return ProjectSettings.globalize_path("res://%s" % output_path)

func _parse_options() -> Dictionary:
	var result := {}
	var args := OS.get_cmdline_user_args()
	var index := 0
	while index < args.size():
		var arg: String = args[index]
		if arg.begins_with("--"):
			var key := arg.trim_prefix("--")
			var value := "true"
			if index + 1 < args.size() and not String(args[index + 1]).begins_with("--"):
				value = String(args[index + 1])
				index += 1
			result[key] = value
		index += 1
	return result

func _reset_state() -> void:
	GameData.party.clear()
	GameData._init_party()
	GameData.gold = 500
	GameData.tonics = 3
	GameData.ethers = 0
	GameData.overworld_position = Vector2i(14, 19)
	GameData.overworld_facing = Vector2i.DOWN
	GameData.visited_town = false
	GameData.active_quests.clear()
	GameData.beacon_lit = false
	GameData.beacon_states.clear()
	GameData.explored_tiles.clear()
	GameData.cleared_encounters.clear()
	GameData.kill_counts.clear()
	GameData.gather_counts.clear()
	GameData.gather_sites.clear()
	GameData.faction_reputation.clear()
	GameData.skill_uses.clear()
	GameData.owned_home = ""
	GameData.home_upgrades.clear()
	GameData.home_storage.clear()
	GameData.play_time = 0.0
