extends Node

signal hosting_started(port: int)
signal join_started(address: String, port: int)
signal peer_joined(peer_id: int)
signal peer_left(peer_id: int)
signal connected_to_host()
signal network_error(message: String)

const DEFAULT_PORT := 45455
const MAX_CLIENTS := 8

var current_port: int = DEFAULT_PORT
var current_address: String = "127.0.0.1"
var is_hosting := false
var is_joining := false
var last_error := ""

func _ready() -> void:
	_connect_multiplayer_signals()

func host_game(port: int = DEFAULT_PORT) -> bool:
	stop_network()
	_connect_multiplayer_signals()
	var enet := ENetMultiplayerPeer.new()
	var err := enet.create_server(port, MAX_CLIENTS)
	if err != OK:
		last_error = "Could not host LAN game on port %d (error %d)." % [port, err]
		network_error.emit(last_error)
		return false
	multiplayer.multiplayer_peer = enet
	current_port = port
	current_address = "0.0.0.0"
	is_hosting = true
	is_joining = false
	hosting_started.emit(port)
	return true

func join_game(address: String = "127.0.0.1", port: int = DEFAULT_PORT) -> bool:
	stop_network()
	_connect_multiplayer_signals()
	var enet := ENetMultiplayerPeer.new()
	var err := enet.create_client(address, port)
	if err != OK:
		last_error = "Could not join LAN game at %s:%d (error %d)." % [address, port, err]
		network_error.emit(last_error)
		return false
	multiplayer.multiplayer_peer = enet
	current_address = address
	current_port = port
	is_hosting = false
	is_joining = true
	join_started.emit(address, port)
	return true

func stop_network() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	is_hosting = false
	is_joining = false

func connected_peer_count() -> int:
	if not multiplayer.multiplayer_peer:
		return 0
	return multiplayer.get_peers().size()

func is_network_active() -> bool:
	return multiplayer.multiplayer_peer != null

func _connect_multiplayer_signals() -> void:
	if not multiplayer.peer_connected.is_connected(_on_peer_connected):
		multiplayer.peer_connected.connect(_on_peer_connected)
	if not multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	if not multiplayer.connected_to_server.is_connected(_on_connected_to_server):
		multiplayer.connected_to_server.connect(_on_connected_to_server)
	if not multiplayer.connection_failed.is_connected(_on_connection_failed):
		multiplayer.connection_failed.connect(_on_connection_failed)
	if not multiplayer.server_disconnected.is_connected(_on_server_disconnected):
		multiplayer.server_disconnected.connect(_on_server_disconnected)

func _on_peer_connected(peer_id: int) -> void:
	peer_joined.emit(peer_id)

func _on_peer_disconnected(peer_id: int) -> void:
	peer_left.emit(peer_id)

func _on_connected_to_server() -> void:
	connected_to_host.emit()

func _on_connection_failed() -> void:
	last_error = "LAN connection failed."
	network_error.emit(last_error)
	stop_network()

func _on_server_disconnected() -> void:
	last_error = "LAN host disconnected."
	network_error.emit(last_error)
	stop_network()
