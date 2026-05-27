extends Node

var _sfx_players: Array = []
var _sfx_index: int = 0
const SFX_POOL_SIZE := 8

var _music_player: AudioStreamPlayer
var _current_music: String = ""

var _sounds: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_buses()
	_setup_sfx_pool()
	_setup_music_player()

func _setup_buses() -> void:
	if not AudioServer.get_bus_index("Master") >= 0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(0, "Master")
	if AudioServer.get_bus_index("SFX") < 0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "SFX")
		AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	if AudioServer.get_bus_index("Music") < 0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "Music")
		AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")

func _setup_sfx_pool() -> void:
	for i in range(SFX_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_sfx_players.append(player)

func _setup_music_player() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	add_child(_music_player)

func play_sfx(path: String, volume_db: float = 0.0) -> void:
	if _sounds.has(path):
		_play_stream(_sounds[path], volume_db)
		return
	if not ResourceLoader.exists(path):
		return
	var stream := load(path)
	if stream:
		_sounds[path] = stream
		_play_stream(stream, volume_db)

func _play_stream(stream: AudioStream, volume_db: float) -> void:
	var player: AudioStreamPlayer = _sfx_players[_sfx_index]
	player.stream = stream
	player.volume_db = volume_db
	player.play()
	_sfx_index = (_sfx_index + 1) % SFX_POOL_SIZE

func play_music(path: String, fade_time: float = 1.0) -> void:
	if path == _current_music:
		return
	_current_music = path
	if not ResourceLoader.exists(path):
		_music_player.stop()
		return
	var stream := load(path)
	if not stream:
		return
	if _music_player.playing:
		var tween := create_tween()
		tween.tween_property(_music_player, "volume_db", -40.0, fade_time)
		tween.tween_callback(func():
			_music_player.stream = stream
			_music_player.volume_db = 0.0
			_music_player.play()
		)
	else:
		_music_player.stream = stream
		_music_player.volume_db = 0.0
		_music_player.play()

func stop_music(fade_time: float = 1.0) -> void:
	_current_music = ""
	if _music_player.playing:
		var tween := create_tween()
		tween.tween_property(_music_player, "volume_db", -40.0, fade_time)
		tween.tween_callback(_music_player.stop)

# Procedural sound generators (no audio files needed)
func play_footstep_grass() -> void:
	_play_tone(220.0 + randf() * 80.0, 0.04, -18.0)

func play_footstep_dirt() -> void:
	_play_tone(120.0 + randf() * 40.0, 0.05, -15.0)

func play_footstep_stone() -> void:
	_play_tone(400.0 + randf() * 100.0, 0.03, -20.0)

func play_footstep_sand() -> void:
	_play_tone(100.0 + randf() * 30.0, 0.06, -22.0)

func play_beacon_light() -> void:
	_play_chime(523.25, 0.15, 0.0)
	await get_tree().create_timer(0.1).timeout
	_play_chime(659.25, 0.15, 0.0)
	await get_tree().create_timer(0.1).timeout
	_play_chime(783.99, 0.3, 0.0)

func play_menu_confirm() -> void:
	_play_chime(440.0, 0.06, -10.0)

func play_menu_cancel() -> void:
	_play_chime(330.0, 0.06, -10.0)

func play_hurt() -> void:
	_play_tone(150.0, 0.08, -8.0)

func play_attack() -> void:
	_play_tone(300.0 + randf() * 100.0, 0.05, -10.0)

func play_coin() -> void:
	_play_chime(880.0, 0.06, -5.0)

func _play_tone(freq: float, duration: float, volume_db: float) -> void:
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = 22050
	var player: AudioStreamPlayer = _sfx_players[_sfx_index]
	player.stream = stream
	player.volume_db = volume_db
	player.play()
	# Push a short buffer
	var frames := int(duration * 22050)
	var data := PackedVector2Array()
	data.resize(frames)
	var phase := 0.0
	var phase_inc := freq / 22050.0
	for i in range(frames):
		var env := clampf(float(frames - i) / frames, 0.0, 1.0)
		data[i] = Vector2(sin(phase) * env, sin(phase) * env)
		phase += phase_inc
	# Use playback to push buffer
	var pb: AudioStreamGeneratorPlayback = player.get_stream_playback()
	if pb:
		pb.push_buffer(data)
	_sfx_index = (_sfx_index + 1) % SFX_POOL_SIZE

func _play_chime(freq: float, duration: float, volume_db: float) -> void:
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = 22050
	var player: AudioStreamPlayer = _sfx_players[_sfx_index]
	player.stream = stream
	player.volume_db = volume_db
	player.play()
	var frames := int(duration * 22050)
	var data := PackedVector2Array()
	data.resize(frames)
	var phase := 0.0
	var phase_inc := freq / 22050.0
	for i in range(frames):
		var env := clampf(float(frames - i) / (frames * 0.3), 0.0, 1.0)
		data[i] = Vector2(sin(phase) * env, sin(phase) * env)
		phase += phase_inc
	var pb: AudioStreamGeneratorPlayback = player.get_stream_playback()
	if pb:
		pb.push_buffer(data)
	_sfx_index = (_sfx_index + 1) % SFX_POOL_SIZE
