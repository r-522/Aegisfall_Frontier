extends Node
## ENetMultiplayerPeerによるホスト/参加管理
## Server Authoritative方式: 30Hz tick、60fps補間

signal server_connected()
signal server_disconnected()
signal player_joined(peer_id: int)
signal player_left(peer_id: int)
signal connection_failed()

const DEFAULT_PORT: int = GameConfig.DEFAULT_SERVER_PORT
const MAX_CLIENTS: int = GameConfig.MAX_PLAYERS

var _peer: ENetMultiplayerPeer = null
var _is_server: bool = false
var _connected_peers: Array[int] = []

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func host_game(port: int = DEFAULT_PORT) -> Error:
	_peer = ENetMultiplayerPeer.new()
	var err := _peer.create_server(port, MAX_CLIENTS)
	if err != OK:
		push_error("NetworkManager: サーバー作成失敗 — error %d" % err)
		_peer = null
		return err

	multiplayer.multiplayer_peer = _peer
	_is_server = true
	EventBus.connected_to_server.emit()
	print("NetworkManager: サーバー開始 port=%d" % port)
	return OK

func join_game(address: String, port: int = DEFAULT_PORT) -> Error:
	_peer = ENetMultiplayerPeer.new()
	var err := _peer.create_client(address, port)
	if err != OK:
		push_error("NetworkManager: 接続失敗 — %s:%d error %d" % [address, port, err])
		_peer = null
		return err

	multiplayer.multiplayer_peer = _peer
	_is_server = false
	print("NetworkManager: %s:%d に接続中..." % [address, port])
	return OK

func disconnect_from_session() -> void:
	if _peer != null:
		_peer.close()
		_peer = null
	multiplayer.multiplayer_peer = null
	_connected_peers.clear()
	_is_server = false
	EventBus.disconnected_from_server.emit()

func is_server() -> bool:
	return _is_server

func is_connected_to_session() -> bool:
	return _peer != null and _peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED

func get_connected_peers() -> Array[int]:
	return _connected_peers.duplicate()

func get_player_count() -> int:
	return _connected_peers.size() + (1 if _is_server else 0)

func kick_player(peer_id: int) -> void:
	if not _is_server:
		return
	if _peer:
		_peer.disconnect_peer(peer_id)

@rpc("authority", "call_local", "reliable")
func rpc_session_started() -> void:
	EventBus.match_started.emit()

@rpc("authority", "call_local", "reliable")
func rpc_session_ended(victory: bool) -> void:
	EventBus.match_ended.emit()

func _on_peer_connected(id: int) -> void:
	_connected_peers.append(id)
	player_joined.emit(id)
	EventBus.player_joined_session.emit(id)
	print("NetworkManager: プレイヤー接続 id=%d" % id)

func _on_peer_disconnected(id: int) -> void:
	_connected_peers.erase(id)
	player_left.emit(id)
	EventBus.player_left_session.emit(id)
	print("NetworkManager: プレイヤー切断 id=%d" % id)

func _on_connected_to_server() -> void:
	server_connected.emit()
	EventBus.connected_to_server.emit()
	print("NetworkManager: サーバーに接続完了")

func _on_connection_failed() -> void:
	connection_failed.emit()
	_peer = null
	push_warning("NetworkManager: 接続失敗")

func _on_server_disconnected() -> void:
	server_disconnected.emit()
	EventBus.disconnected_from_server.emit()
	disconnect_from_session()
