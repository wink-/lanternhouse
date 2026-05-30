extends Node

const PORT_FILE := "/tmp/lanternhouse_lan_smoke_port"
const READY_FILE := "/tmp/lanternhouse_lan_smoke_host_ready"
const CLIENT_OK_FILE := "/tmp/lanternhouse_lan_smoke_client_ok"
const TIMEOUT_SECONDS := 20.0

var _elapsed := 0.0
var _joined := false
var _attempted := false

func _ready() -> void:
	if not NetworkManager.connected_to_host.is_connected(_on_connected_to_host):
		NetworkManager.connected_to_host.connect(_on_connected_to_host)
	if not NetworkManager.network_error.is_connected(_on_network_error):
		NetworkManager.network_error.connect(_on_network_error)

func _process(delta: float) -> void:
	_elapsed += delta
	if _joined or _client_connected():
		_write_file(CLIENT_OK_FILE, "ok")
		print("SMOKE_LAN_CLIENT_OK")
		NetworkManager.stop_network()
		get_tree().quit(0)
		return
	if not _attempted and FileAccess.file_exists(READY_FILE) and FileAccess.file_exists(PORT_FILE):
		_attempted = true
		var port_text := FileAccess.get_file_as_string(PORT_FILE).strip_edges()
		var port := int(port_text) if port_text.is_valid_int() else NetworkManager.DEFAULT_PORT
		if not NetworkManager.join_game("127.0.0.1", port):
			push_error("SMOKE_LAN_CLIENT_FAILED: %s" % NetworkManager.last_error)
			get_tree().quit(1)
			return
	elif _elapsed > TIMEOUT_SECONDS:
		push_error("SMOKE_LAN_CLIENT_FAILED: timed out waiting for host/connection")
		NetworkManager.stop_network()
		get_tree().quit(1)

func _on_connected_to_host() -> void:
	_joined = true

func _write_file(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(text)

func _client_connected() -> bool:
	if not multiplayer.multiplayer_peer:
		return false
	return multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED

func _on_network_error(message: String) -> void:
	push_error("SMOKE_LAN_CLIENT_FAILED: %s" % message)
	get_tree().quit(1)
