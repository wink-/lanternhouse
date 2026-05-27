# Settings — audio, display, and text options
extends CanvasLayer

@onready var content: RichTextLabel = $Panel/Content
var active: bool = false
var selected_idx: int = 0

const OPTIONS := [
	{"key": "music_vol", "label": "Music Volume", "type": "slider", "min": 0, "max": 100},
	{"key": "sfx_vol", "label": "SFX Volume", "type": "slider", "min": 0, "max": 100},
	{"key": "text_speed", "label": "Text Speed", "type": "choice", "values": ["Slow", "Normal", "Fast"]},
	{"key": "window_mode", "label": "Window Mode", "type": "choice", "values": ["Windowed", "Fullscreen", "Borderless"]},
]

var _values: Dictionary = {}

func _ready() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_defaults()

func _load_defaults() -> void:
	_values["music_vol"] = 80
	_values["sfx_vol"] = 100
	_values["text_speed"] = 1  # index into ["Slow", "Normal", "Fast"]
	_values["window_mode"] = 0

func open() -> void:
	active = true
	selected_idx = 0
	_update()
	show()

func close() -> void:
	active = false
	hide()

func _input(event: InputEvent) -> void:
	if not active:
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_UP:
			selected_idx = maxi(0, selected_idx - 1)
			_update()
			get_viewport().set_input_as_handled()
		KEY_DOWN:
			selected_idx = mini(OPTIONS.size() - 1, selected_idx + 1)
			_update()
			get_viewport().set_input_as_handled()
		KEY_LEFT:
			_adjust(-1)
			get_viewport().set_input_as_handled()
		KEY_RIGHT:
			_adjust(1)
			get_viewport().set_input_as_handled()
		KEY_ESCAPE:
			close()
			get_viewport().set_input_as_handled()

func _adjust(dir: int) -> void:
	var opt: Dictionary = OPTIONS[selected_idx]
	var key: String = opt["key"]
	match opt["type"]:
		"slider":
			_values[key] = clampi(_values[key] + dir * 10, opt["min"], opt["max"])
			_apply(key)
		"choice":
			var vals: Array = opt["values"]
			_values[key] = (_values[key] + dir) % vals.size()
			if _values[key] < 0:
				_values[key] = vals.size() - 1
			_apply(key)
	_update()

func _apply(key: String) -> void:
	match key:
		"music_vol":
			var bus := AudioServer.get_bus_index("Master")
			var db := linear_to_db(float(_values["music_vol"]) / 100.0)
			AudioServer.set_bus_volume_db(bus, db)
		"sfx_vol":
			pass
		"text_speed":
			pass
		"window_mode":
			match _values["window_mode"]:
				0: get_viewport().mode = Window.MODE_WINDOWED
				1: get_viewport().mode = Window.MODE_FULLSCREEN
				2: get_viewport().mode = Window.MODE_EXCLUSIVE_FULLSCREEN

func _update() -> void:
	var lines: Array = []
	lines.append("[b][color=#f0d46a]╔══════════════════════════════════════════════════════╗[/color][/b]")
	lines.append("[b][color=#f0d46a]║              S E T T I N G S                      ║[/color][/b]")
	lines.append("[b][color=#f0d46a]╚══════════════════════════════════════════════════════╝[/color][/b]")
	lines.append("")

	for i in range(OPTIONS.size()):
		var opt: Dictionary = OPTIONS[i]
		var marker := "▶" if i == selected_idx else " "
		var color_start := "[color=#f0d46a]" if i == selected_idx else ""
		var color_end := "[/color]" if i == selected_idx else ""
		var val_str := _format_value(opt)
		lines.append("%s%s %-16s %s%s" % [color_start, marker, opt["label"], val_str, color_end])

	lines.append("")
	lines.append("[color=gray]←→ Adjust   ↑↓ Navigate   [Esc] Close[/color]")
	content.text = "\n".join(lines)

func _format_value(opt: Dictionary) -> String:
	var key: String = opt["key"]
	match opt["type"]:
		"slider":
			var val: int = _values[key]
			var filled := int(float(val) / float(opt["max"]) * 16)
			var bar := ""
			for _i in range(filled):
				bar += "█"
			for _i in range(16 - filled):
				bar += "░"
			return "%s %d%%" % [bar, val]
		"choice":
			var vals: Array = opt["values"]
			var idx: int = _values[key]
			var val: String = vals[idx]
			var left := "[color=gray]◄[/color] " if idx > 0 else "  "
			var right := " [color=gray]►[/color]" if idx < vals.size() - 1 else "  "
			return "%s%s%s" % [left, val, right]
	return ""
