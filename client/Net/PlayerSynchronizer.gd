class_name PlayerSynchronizer
extends Node
## プレイヤー状態同期 — Godot4 MultiplayerSynchronizer連携
## ローカルプレイヤーの入力をサーバーに送信
## リモートプレイヤーの位置・状態を補間

@export var player_node: PlayerBase

# MultiplayerSynchronizerノードがsceneに存在する前提
# (Inspector で position, rotation, velocity, _state を同期対象に設定)

var _interpolation_buffer: Array[Dictionary] = []
const BUFFER_SIZE: int = 3

@rpc("any_peer", "call_local", "unreliable")
func sync_position(pos: Vector3, rot: Vector3, vel: Vector3) -> void:
	if player_node == null:
		return
	if player_node.is_local_player:
		return  # ローカルは自分で制御

	_interpolation_buffer.append({
		"position": pos,
		"rotation": rot,
		"velocity": vel,
		"timestamp": Time.get_ticks_msec()
	})
	if _interpolation_buffer.size() > BUFFER_SIZE:
		_interpolation_buffer.pop_front()

@rpc("any_peer", "call_local", "reliable")
func sync_state(state_int: int) -> void:
	if player_node == null or player_node.is_local_player:
		return
	player_node._state = state_int as PlayerBase.State

func _physics_process(_delta: float) -> void:
	if player_node == null or player_node.is_local_player:
		return
	if _interpolation_buffer.size() < 2:
		return

	var from := _interpolation_buffer[0]
	var to := _interpolation_buffer[1]
	var now := Time.get_ticks_msec()
	var t := float(now - from.timestamp) / float(to.timestamp - from.timestamp)
	t = clampf(t, 0.0, 1.0)

	player_node.global_position = from.position.lerp(to.position, t)
	player_node.rotation = Vector3(
		lerp_angle(from.rotation.x, to.rotation.x, t),
		lerp_angle(from.rotation.y, to.rotation.y, t),
		lerp_angle(from.rotation.z, to.rotation.z, t)
	)

	if t >= 1.0:
		_interpolation_buffer.pop_front()
