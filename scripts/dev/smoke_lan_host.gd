extends Node

const PORT_FILE := "/tmp/lanternhouse_lan_smoke_port"
const READY_FILE := "/tmp/lanternhouse_lan_smoke_host_ready"
const CLIENT_OK_FILE := "/tmp/lanternhouse_lan_smoke_client_ok"
const PORT := 45455
const TIMEOUT_SECONDS := 20.0

var _elapsed := 0.0
var _peer_seen := false

func _ready() -> void:
	_delete_file(PORT_FILE)
	_delete_file(READY_FILE)
	_delete_file(CLIENT_OK_FILE)
	if not NetworkManager.peer_joined.is_connected(_on_peer_joined):
		NetworkManager.peer_joined.connect(_on_peer_joined)
	if not NetworkManager.host_game(PORT):
		push_error("SMOKE_LAN_HOST_FAILED: %s" % NetworkManager.last_error)
		get_tree().quit(1)
		return
	_write_file(PORT_FILE, str(PORT))
	_write_file(READY_FILE, "ready")
	print("SMOKE_LAN_HOST_READY port=%d" % PORT)

func _process(delta: float) -> void:
	_elapsed += delta
	if _peer_seen or NetworkManager.connected_peer_count() > 0 or FileAccess.file_exists(CLIENT_OK_FILE):
		print("SMOKE_LAN_HOST_OK")
		NetworkManager.stop_network()
		_delete_file(PORT_FILE)
		_delete_file(READY_FILE)
		_delete_file(CLIENT_OK_FILE)
		get_tree().quit(0)
	elif _elapsed > TIMEOUT_SECONDS:
		push_error("SMOKE_LAN_HOST_FAILED: no client peer connected")
		NetworkManager.stop_network()
		_delete_file(PORT_FILE)
		_delete_file(READY_FILE)
		_delete_file(CLIENT_OK_FILE)
		get_tree().quit(1)

func _on_peer_joined(_peer_id: int) -> void:
	_peer_seen = true

func _write_file(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(text)

func _delete_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
