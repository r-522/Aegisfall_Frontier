class_name GravityWell
extends TowerBase
## 範囲内の全敵を中心に引き寄せ続ける重力場タワー
## 敵をクラスター化させて他のタワーのAoE効率を高める

const DEFAULT_PULL_FORCE: float = 8.0
const DEFAULT_WELL_RADIUS: float = 7.0
const GRAVITY_EFFECT_ID := &"gravity_well"

var _pull_force: float = DEFAULT_PULL_FORCE
var _well_radius: float = DEFAULT_WELL_RADIUS
var _pull_area: Area3D = null
var _enemies_in_range: Array[Node] = []

func _ready() -> void:
	add_to_group(&"towers_special")
	super._ready()

func _on_placed() -> void:
	if tower_data:
		_pull_force = tower_data.pull_force if tower_data.pull_force > 0.0 else DEFAULT_PULL_FORCE
		_well_radius = tower_data.special_effect_radius if tower_data.special_effect_radius > 0.0 else DEFAULT_WELL_RADIUS

	_setup_pull_area()

	if animation_player and animation_player.has_animation("idle_gravity"):
		animation_player.play("idle_gravity")

func _setup_pull_area() -> void:
	_pull_area = find_child("PullArea") as Area3D
	if _pull_area != null:
		_pull_area.body_entered.connect(_on_body_entered)
		_pull_area.body_exited.connect(_on_body_exited)
		return

	var area := Area3D.new()
	area.name = "PullArea"
	area.collision_layer = 0
	area.collision_mask = 1 << 2  # Enemiesレイヤー
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = _well_radius
	shape.shape = sphere
	area.add_child(shape)
	add_child(area)
	_pull_area = area
	_pull_area.body_entered.connect(_on_body_entered)
	_pull_area.body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	# 無効参照を除去
	_enemies_in_range = _enemies_in_range.filter(func(n: Node) -> bool: return is_instance_valid(n))

	if _enemies_in_range.is_empty():
		return

	var center := global_position
	for enemy in _enemies_in_range:
		_pull_enemy_toward_center(enemy, center, delta)

func _pull_enemy_toward_center(enemy: Node, center: Vector3, delta: float) -> void:
	# CharacterBody3D / RigidBody3D の両方に対応
	var to_center := center - enemy.global_position
	to_center.y = 0.0  # 水平方向のみ引き寄せる

	if to_center.length_squared() < 0.01:
		return  # すでに中心にいる

	var pull_direction := to_center.normalized()
	var pull_delta := pull_direction * _pull_force * delta

	if enemy is CharacterBody3D:
		# CharacterBody3D はvelocityを直接加算して次フレームの move_and_slide に委ねる
		enemy.velocity += pull_delta
	elif enemy is RigidBody3D:
		enemy.apply_central_force(pull_direction * _pull_force)

	# StatusEffectComponent があれば gravity_well エフェクトを付与して視覚的フィードバック
	var sec: StatusEffectComponent = enemy.find_child("StatusEffectComponent") as StatusEffectComponent
	if sec and not sec.has_effect(GRAVITY_EFFECT_ID):
		sec.apply_effect(GRAVITY_EFFECT_ID, 0.3, 0.0)

func _on_body_entered(body: Node) -> void:
	if is_instance_valid(body) and body.is_in_group(&"enemies"):
		if not _enemies_in_range.has(body):
			_enemies_in_range.append(body)

func _on_body_exited(body: Node) -> void:
	_enemies_in_range.erase(body)

func _on_destroyed() -> void:
	# 破壊時にエフェクトを解除
	for enemy in _enemies_in_range.duplicate():
		if is_instance_valid(enemy):
			var sec: StatusEffectComponent = enemy.find_child("StatusEffectComponent") as StatusEffectComponent
			if sec:
				sec.remove_effect(GRAVITY_EFFECT_ID)
	super._on_destroyed()

func _spawn_projectile(_target: Node, _damage: float) -> void:
	pass  # 重力タワーは直接攻撃しない
