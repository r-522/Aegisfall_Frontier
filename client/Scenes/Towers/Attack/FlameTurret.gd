class_name FlameTurret
extends TowerBase
## 現在のターゲットに継続的な炎ビームダメージを与える攻撃タワー
## プロジェクタイルは使用せず、_process で毎フレーム直接ダメージを与える

const DEFAULT_DAMAGE_PER_SECOND: float = 40.0
const BURN_DURATION: float = 2.0
const BURN_TICK_RATE: float = 0.5
const BURN_TICK_DAMAGE: float = 5.0
const BEAM_RANGE: float = 8.0

@onready var _barrel: Node3D = $Barrel

var _damage_per_second: float = DEFAULT_DAMAGE_PER_SECOND
var _is_firing: bool = false

func _ready() -> void:
	add_to_group(&"towers_attack")
	super._ready()

func _apply_tower_data() -> void:
	super._apply_tower_data()
	if tower_data:
		_damage_per_second = tower_data.attack_damage if tower_data.attack_damage > 0.0 else DEFAULT_DAMAGE_PER_SECOND

func _on_placed() -> void:
	if animation_player and animation_player.has_animation("idle"):
		animation_player.play("idle")

func _process(delta: float) -> void:
	if tower_component == null:
		return

	var target := tower_component.get_current_target()

	# ターゲットがいなければビームを止める
	if target == null or not is_instance_valid(target):
		if _is_firing:
			_stop_beam()
		return

	# 射程チェック — ターゲットが遠すぎる場合はビームを止める
	var dist := global_position.distance_to(target.global_position)
	var range: float = tower_data.attack_range if tower_data else BEAM_RANGE
	if dist > range:
		if _is_firing:
			_stop_beam()
		return

	# 砲塔を回転させてターゲットに向ける
	_rotate_toward_target(target, delta)

	# ビームダメージを毎フレーム適用
	if not _is_firing:
		_start_beam()

	var hc: HealthComponent = target.find_child("HealthComponent") as HealthComponent
	if hc and not hc.is_dead:
		var frame_damage := _damage_per_second * delta
		hc.take_damage(frame_damage, self)
		EventBus.enemy_took_damage.emit(target, frame_damage)

		# 燃焼デバフを継続して更新する
		var sec: StatusEffectComponent = target.find_child("StatusEffectComponent") as StatusEffectComponent
		if sec:
			sec.apply_effect(
				StatusEffectComponent.EFFECT_BURN,
				BURN_DURATION,
				BURN_TICK_DAMAGE,
				BURN_TICK_RATE
			)

func _rotate_toward_target(target: Node, delta: float) -> void:
	var pivot: Node3D = _barrel if is_instance_valid(_barrel) else self
	var direction := (target.global_position - pivot.global_position)
	direction.y = 0.0
	if direction.is_zero_approx():
		return
	var target_basis := Basis.looking_at(direction.normalized(), Vector3.UP)
	pivot.global_basis = pivot.global_basis.slerp(target_basis, clampf(delta * 10.0, 0.0, 1.0))

func _start_beam() -> void:
	_is_firing = true
	if animation_player and animation_player.has_animation("fire_beam"):
		animation_player.play("fire_beam")
	EventBus.field_event_triggered.emit(&"flame_beam_start", global_position)

func _stop_beam() -> void:
	_is_firing = false
	if animation_player and animation_player.has_animation("idle"):
		animation_player.play("idle")
	EventBus.field_event_triggered.emit(&"flame_beam_stop", global_position)

## TowerComponent の通常 fired シグナル経由の攻撃は使用しない
## (_process で直接ダメージを与えるため)
func _spawn_projectile(_target: Node, _damage: float) -> void:
	pass
