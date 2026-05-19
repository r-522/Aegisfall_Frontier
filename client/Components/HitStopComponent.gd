class_name HitStopComponent
extends Node
## ヒットストップ (打撃時の一瞬フリーズ) + カメラシェイクを管理
## 攻撃の重量感を演出する最重要コンポーネント

signal hit_stop_started(duration: float)
signal hit_stop_ended()

var _is_active: bool = false
var _timer: float = 0.0
var _animation_player: AnimationPlayer

func _ready() -> void:
	_animation_player = get_parent().find_child("AnimationPlayer") as AnimationPlayer

func _process(delta: float) -> void:
	if not _is_active:
		return
	_timer -= delta
	if _timer <= 0.0:
		_end_hit_stop()

func trigger_normal_hit_stop() -> void:
	_start_hit_stop(GameConfig.HIT_STOP_DURATION)

func trigger_heavy_hit_stop() -> void:
	_start_hit_stop(GameConfig.HIT_STOP_HEAVY_DURATION)

func trigger_custom_hit_stop(duration: float) -> void:
	_start_hit_stop(duration)

func trigger_camera_shake(magnitude: float = -1.0) -> void:
	if not GameConfig.screen_shake_enabled:
		return
	var cam_sys := get_tree().get_first_node_in_group(&"camera_system")
	if cam_sys == null:
		return
	var actual_magnitude := (GameConfig.CAMERA_SHAKE_NORMAL_MAGNITUDE if magnitude < 0.0 else magnitude)
	actual_magnitude *= GameConfig.screen_shake_intensity
	cam_sys.shake(actual_magnitude, GameConfig.CAMERA_SHAKE_DURATION)

func trigger_heavy_camera_shake() -> void:
	trigger_camera_shake(GameConfig.CAMERA_SHAKE_HEAVY_MAGNITUDE)

func is_active() -> bool:
	return _is_active

func _start_hit_stop(duration: float) -> void:
	if _is_active and _timer >= duration:
		return
	_is_active = true
	_timer = duration
	if _animation_player != null:
		_animation_player.speed_scale = 0.0
	hit_stop_started.emit(duration)

func _end_hit_stop() -> void:
	_is_active = false
	if _animation_player != null:
		_animation_player.speed_scale = 1.0
	hit_stop_ended.emit()
