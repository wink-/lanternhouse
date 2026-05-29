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
	var options: Dictionary = _parse_options()
	var target: String = options.get("target", "town")
	var scene_path: String = options.get("scene", "")
	var output_path: String = options.get("output", "artifacts/screenshots/%s.png" % target)
	var manifest_path: String = options.get("manifest", output_path.get_basename() + ".json")
	var frames: int = int(options.get("frames", "8"))

	if scene_path.is_empty():
		if not TARGET_SCENES.has(target):
			push_error("Unknown visual QA target '%s'. Known targets: %s. Use --scene for a direct scene path." % [target, ", ".join(TARGET_SCENES.keys())])
			get_tree().quit(2)
			return
		scene_path = TARGET_SCENES[target]

	print("VISUAL_SCENE_CAPTURE_START target=%s scene=%s output=%s frames=%d" % [target, scene_path, output_path, frames])
	var result: Dictionary = await _capture_scene(target, scene_path, output_path, manifest_path, frames)
	if bool(result.get("ok", false)):
		print("VISUAL_SCENE_CAPTURE_OK target=%s scene=%s output=%s manifest=%s size=%sx%s" % [target, scene_path, output_path, manifest_path, result.get("width", 0), result.get("height", 0)])
		get_tree().quit(0)
	else:
		push_error("VISUAL_SCENE_CAPTURE_FAILED target=%s reason=%s" % [target, result.get("error", "unknown")])
		get_tree().quit(1)

func _capture_scene(target: String, scene_path: String, output_path: String, manifest_path: String, frames: int) -> Dictionary:
	_reset_state()
	var packed: PackedScene = load(scene_path)
	if packed == null:
		return {"ok": false, "error": "Could not load scene: %s" % scene_path}

	var scene: Node = packed.instantiate()
	add_child(scene)
	for _i: int in range(max(frames, 1)):
		await get_tree().process_frame

	var image: Image = get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		return {"ok": false, "error": "Captured viewport image is empty"}

	var absolute_output: String = _absolute_output_path(output_path)
	var directory: String = absolute_output.get_base_dir()
	var dir_result: Error = DirAccess.make_dir_recursive_absolute(directory)
	if dir_result != OK:
		return {"ok": false, "error": "Could not create screenshot directory %s: %s" % [directory, error_string(dir_result)]}

	var save_result: Error = image.save_png(absolute_output)
	if save_result != OK:
		return {"ok": false, "error": "Could not save screenshot %s: %s" % [absolute_output, error_string(save_result)]}

	var manifest: Dictionary = {
		"ok": true,
		"target": target,
		"scene": scene_path,
		"output": output_path,
		"absolute_output": absolute_output,
		"frames_waited": max(frames, 1),
		"width": image.get_width(),
		"height": image.get_height(),
		"main_scene": ProjectSettings.get_setting("application/run/main_scene", ""),
	}
	var manifest_result: Error = _write_manifest(manifest_path, manifest)
	if manifest_result != OK:
		return {"ok": false, "error": "Could not write manifest %s: %s" % [manifest_path, error_string(manifest_result)]}
	return manifest

func _write_manifest(manifest_path: String, manifest: Dictionary) -> Error:
	var absolute_manifest: String = _absolute_output_path(manifest_path)
	var directory: String = absolute_manifest.get_base_dir()
	var dir_result: Error = DirAccess.make_dir_recursive_absolute(directory)
	if dir_result != OK:
		return dir_result
	var file: FileAccess = FileAccess.open(absolute_manifest, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(manifest, "  "))
	file.store_string("\n")
	file.close()
	return OK

func _absolute_output_path(output_path: String) -> String:
	if output_path.begins_with("res://") or output_path.begins_with("user://"):
		return ProjectSettings.globalize_path(output_path)
	if output_path.is_absolute_path():
		return output_path
	return ProjectSettings.globalize_path("res://%s" % output_path)

func _parse_options() -> Dictionary:
	var result: Dictionary = {}
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var index: int = 0
	while index < args.size():
		var arg: String = args[index]
		if arg.begins_with("--"):
			var key: String = arg.trim_prefix("--")
			var value: String = "true"
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
