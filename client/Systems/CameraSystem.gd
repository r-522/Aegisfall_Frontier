class_name CameraSystem
extends Node3D
## カメラシェイク・振動エフェクト管理
## グループ "camera_system" でHitStopComponentから参照される

var _shake_magnitude: float = 0.0
var _shake_duration: float = 0.0
var _shake_timer: float = 0.0
var _original_offset: Vector3 = Vector3.ZERO
var _camera: Camera3D = null
var _spring_arm: SpringArm3D = null

func _ready() -> void:
	add_to_group(&"camera_system")

func setup(camera: Camera3D, spring_arm: SpringArm3D = null) -> void:
	_camera = camera
	_spring_arm = spring_arm
	if _spring_arm:
		_original_offset = _spring_arm.position

func shake(magnitude: float, duration: float) -> void:
	if not GameConfig.screen_shake_enabled:
		return
	_shake_magnitude = magnitude * GameConfig.screen_shake_intensity
	_shake_duration = duration
	_shake_timer = duration

func _process(delta: float) -> void:
	if _shake_timer <= 0.0:
		if _spring_arm:
			_spring_arm.position = _original_offset
		return

	_shake_timer -= delta
	var decay := _shake_timer / _shake_duration
	var current_magnitude := _shake_magnitude * decay

	var offset := Vector3(
		randf_range(-current_magnitude, current_magnitude),
		randf_range(-current_magnitude, current_magnitude),
		0.0
	)

	if _spring_arm:
		_spring_arm.position = _original_offset + offset
	elif _camera:
		_camera.position = offset

func reset_shake() -> void:
	_shake_timer = 0.0
	if _spring_arm:
		_spring_arm.position = _original_offset
