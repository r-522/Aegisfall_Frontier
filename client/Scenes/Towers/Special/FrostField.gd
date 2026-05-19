class_name FrostField
extends TowerBase
## 範囲内の全敵に継続的にSLOWを付与する氷結フィールドタワー
## 攻撃能力なし — 視覚的に青く脈動するArea3D

const SLOW_INTERVAL: float = 0.5
const DEFAULT_SLOW_DURATION: float = 1.0  # インターバルより長く設定して途切れを防ぐ
const DEFAULT_SLOW_VALUE: float = 0.4     # 移動速度40%低下
const DEFAULT_FROST_RADIUS: float = 5.0

var _slow_timer: float = 0.0
var _frost_radius: float = DEFAULT_FROST_RADIUS
var _slow_duration: float = DEFAULT_SLOW_DURATION
var _slow_value: float = DEFAULT_SLOW_VALUE
var _frost_area: Area3D = null

func _ready() -> void:
	add_to_group(&"towers_support")
	super._ready()

func _on_placed() -> void:
	if tower_data:
		_frost_radius = tower_data.buff_radius if tower_data.buff_radius > 0.0 else DEFAULT_FROST_RADIUS
		_slow_value   = tower_data.slow_multiplier if tower_data.slow_multiplier > 0.0 else DEFAULT_SLOW_VALUE
		_slow_duration = tower_data.buff_tick_rate * 2.0 if tower_data.buff_tick_rate > 0.0 else DEFAULT_SLOW_DURATION

	_setup_frost_area()

	if animation_player and animation_player.has_animation("idle_frost"):
		animation_player.play("idle_frost")

func _setup_frost_area() -> void:
	_frost_area = find_child("FrostArea") as Area3D
	if _frost_area != null:
		return

	var area := Area3D.new()
	area.name = "FrostArea"
	area.collision_layer = 0
	area.collision_mask = 1 << 2  # Enemiesレイヤー
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = _frost_radius
	shape.shape = sphere
	area.add_child(shape)
	add_child(area)
	_frost_area = area

func _physics_process(delta: float) -> void:
	_slow_timer -= delta
	if _slow_timer <= 0.0:
		_slow_timer = SLOW_INTERVAL
		_apply_slow_to_enemies()

func _apply_slow_to_enemies() -> void:
	if _frost_area == null:
		return

	var bodies := _frost_area.get_overlapping_bodies()
	var hit_any := false

	for body in bodies:
		if not is_instance_valid(body):
			continue
		if not body.is_in_group(&"enemies"):
			continue

		var sec: StatusEffectComponent = body.find_child("StatusEffectComponent") as StatusEffectComponent
		if sec:
			sec.apply_effect(
				StatusEffectComponent.EFFECT_SLOW,
				_slow_duration,
				_slow_value
			)
			hit_any = true

	if hit_any and animation_player and animation_player.has_animation("frost_pulse"):
		animation_player.play("frost_pulse")

func _spawn_projectile(_target: Node, _damage: float) -> void:
	pass  # フロストフィールドは攻撃しない
