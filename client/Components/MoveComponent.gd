class_name MoveComponent
extends Node
## 移動・ダッシュ・重力をカプセル化するコンポーネント
## CharacterBody3Dの親ノードに追加して使用

signal dash_started()
signal dash_ended()
signal landed()
signal jumped()

@export var character_data: CharacterData

var _body: CharacterBody3D
var _status: StatusEffectComponent

var _gravity: float = GameConfig.GRAVITY
var _dash_timer: float = 0.0
var _dash_cooldown_timer: float = 0.0
var _dash_direction: Vector3 = Vector3.ZERO
var _is_dashing: bool = false
var _was_on_floor: bool = false

func _ready() -> void:
	_body = get_parent() as CharacterBody3D
	if _body == null:
		push_error("MoveComponent: 親がCharacterBody3Dではありません")
		return
	_status = get_parent().find_child("StatusEffectComponent") as StatusEffectComponent

func tick(delta: float, input_dir: Vector2, camera_basis: Basis) -> void:
	if _body == null:
		return

	_apply_gravity(delta)
	_tick_dash(delta)

	if not _is_dashing:
		_apply_movement(input_dir, camera_basis, delta)

	_check_landing()

func apply_jump() -> bool:
	if character_data == null:
		return false
	if not _body.is_on_floor():
		return false
	_body.velocity.y = character_data.jump_force
	jumped.emit()
	return true

func try_dash(input_dir: Vector2, camera_basis: Basis) -> bool:
	if character_data == null:
		return false
	if _dash_cooldown_timer > 0.0 or _is_dashing:
		return false
	if _status != null and _status.is_stunned():
		return false

	var move_dir := _calculate_move_dir(input_dir, camera_basis)
	if move_dir.length_squared() < 0.01:
		move_dir = -_body.global_basis.z

	_dash_direction = move_dir
	_is_dashing = true
	_dash_timer = character_data.dash_duration
	_dash_cooldown_timer = character_data.dash_cooldown
	_body.velocity = _dash_direction * character_data.dash_speed
	dash_started.emit()
	return true

func can_dash() -> bool:
	return _dash_cooldown_timer <= 0.0 and not _is_dashing

func get_dash_cooldown_ratio() -> float:
	if character_data == null or character_data.dash_cooldown <= 0.0:
		return 0.0
	return _dash_cooldown_timer / character_data.dash_cooldown

func is_dashing() -> bool:
	return _is_dashing

func get_velocity() -> Vector3:
	return _body.velocity if _body != null else Vector3.ZERO

func _apply_gravity(delta: float) -> void:
	if not _body.is_on_floor():
		_body.velocity.y -= _gravity * delta
	elif _body.velocity.y < 0.0:
		_body.velocity.y = 0.0

func _apply_movement(input_dir: Vector2, camera_basis: Basis, delta: float) -> void:
	if character_data == null:
		return

	var speed_mult := 1.0
	if _status != null:
		speed_mult = _status.get_speed_multiplier()

	var move_dir := _calculate_move_dir(input_dir, camera_basis)
	var speed := character_data.move_speed * speed_mult

	_body.velocity.x = move_dir.x * speed
	_body.velocity.z = move_dir.z * speed

	if move_dir.length_squared() > 0.01:
		var target_angle := atan2(-move_dir.x, -move_dir.z)
		_body.rotation.y = lerp_angle(_body.rotation.y, target_angle, 12.0 * delta)

func _tick_dash(delta: float) -> void:
	_dash_cooldown_timer = maxf(0.0, _dash_cooldown_timer - delta)

	if not _is_dashing:
		return
	_dash_timer -= delta
	if _dash_timer <= 0.0:
		_is_dashing = false
		dash_ended.emit()

func _check_landing() -> void:
	var on_floor_now := _body.is_on_floor()
	if on_floor_now and not _was_on_floor:
		landed.emit()
	_was_on_floor = on_floor_now

func _calculate_move_dir(input_dir: Vector2, camera_basis: Basis) -> Vector3:
	if input_dir.length_squared() < 0.01:
		return Vector3.ZERO
	var world_dir := camera_basis * Vector3(input_dir.x, 0.0, input_dir.y)
	world_dir.y = 0.0
	return world_dir.normalized()
