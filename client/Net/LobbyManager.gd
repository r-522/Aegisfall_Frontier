class_name LobbyManager
extends Node
## ロビー管理 — プレイヤーリスト・クラス選択・レディ状態

signal lobby_state_changed(player_list: Array)
signal all_ready()
signal lobby_closed()

var _player_states: Dictionary = {}
var _net_manager: NetworkManager

func _ready() -> void:
	_net_manager = get_node_or_null("../NetworkManager")
	if _net_manager:
		_net_manager.player_joined.connect(_on_player_joined)
		_net_manager.player_left.connect(_on_player_left)

func set_player_class(peer_id: int, class_id: StringName) -> void:
	if not _player_states.has(peer_id):
		_player_states[peer_id] = {"class_id": class_id, "ready": false}
	else:
		_player_states[peer_id]["class_id"] = class_id
	_broadcast_lobby_state()

func set_player_ready(peer_id: int, ready: bool) -> void:
	if not _player_states.has(peer_id):
		return
	_player_states[peer_id]["ready"] = ready
	_broadcast_lobby_state()
	_check_all_ready()

func get_player_class(peer_id: int) -> StringName:
	if not _player_states.has(peer_id):
		return &""
	return _player_states[peer_id].get("class_id", &"")

func get_lobby_player_list() -> Array:
	var list := []
	for peer_id in _player_states:
		list.append({
			"peer_id": peer_id,
			"class_id": _player_states[peer_id].get("class_id", &"fighter"),
			"ready": _player_states[peer_id].get("ready", false)
		})
	return list

func _check_all_ready() -> void:
	if _player_states.is_empty():
		return
	for state in _player_states.values():
		if not state.get("ready", false):
			return
	all_ready.emit()

func _broadcast_lobby_state() -> void:
	var player_list := get_lobby_player_list()
	lobby_state_changed.emit(player_list)
	EventBus.lobby_updated.emit(player_list)

func _on_player_joined(peer_id: int) -> void:
	_player_states[peer_id] = {"class_id": &"fighter", "ready": false}
	_broadcast_lobby_state()

func _on_player_left(peer_id: int) -> void:
	_player_states.erase(peer_id)
	_broadcast_lobby_state()
