extends CanvasLayer

var _overlay: ColorRect
var _tween: Tween
var _transitioning: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100

	_overlay = ColorRect.new()
	_overlay.color = Color.BLACK
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.z_index = 100
	add_child(_overlay)
	_overlay.visible = false

func change_scene(scene_path: String, fade_duration: float = 0.3) -> void:
	if _transitioning:
		return
	_transitioning = true
	_overlay.visible = true
	_overlay.color.a = 0.0

	# Fade out
	_tween = create_tween()
	_tween.tween_property(_overlay, "color:a", 1.0, fade_duration)
	await _tween.finished

	# Change scene
	get_tree().change_scene_to_file(scene_path)

	# Wait one frame for scene to load
	await get_tree().process_frame

	# Fade in
	_tween = create_tween()
	_tween.tween_property(_overlay, "color:a", 0.0, fade_duration)
	await _tween.finished

	_overlay.visible = false
	_transitioning = false
