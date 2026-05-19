class_name ProjectileBase
extends Area3D
## 投射物基底クラス — 方向・速度・貫通・AoEを管理

signal hit_target(target: Node, damage: float)
signal projectile_expired()

@export var speed: float = 25.0
@export var max_range: float = 40.0
@export var lifetime: float = 3.0
@export var is_piercing: bool = false
@export var aoe_radius: float = 0.0

var _direction: Vector3 = Vector3.FORWARD
var _damage: float = 0.0
var _source: Node = null
var _distance_traveled: float = 0.0
var _lifetime_timer: float = 0.0
var _hit_targets: Array[Node] = []
var _homing_target: Node = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	_lifetime_timer = lifetime

func initialize(direction: Vector3, damage: float, source: Node, piercing: bool = false) -> void:
	_direction = direction.normalized()
	_damage = damage
	_source = source
	is_piercing = piercing
	look_at(global_position + _direction)

func initialize_aoe(direction: Vector3, damage: float, radius: float, source: Node) -> void:
	initialize(direction, damage, source)
	aoe_radius = radius

func set_homing_target(target: Node) -> void:
	_homing_target = target

func _physics_process(delta: float) -> void:
	_lifetime_timer -= delta
	if _lifetime_timer <= 0.0:
		_expire()
		return

	if _homing_target != null and is_instance_valid(_homing_target):
		var to_target := (_homing_target.global_position - global_position).normalized()
		_direction = _direction.lerp(to_target, 5.0 * delta).normalized()

	var move := _direction * speed * delta
	global_position += move
	_distance_traveled += move.length()

	if _distance_traveled >= max_range:
		_expire()

func _on_body_entered(body: Node) -> void:
	if body == _source:
		return
	if is_piercing and _hit_targets.has(body):
		return

	if body.is_in_group(&"enemies") or body.is_in_group(&"towers") or body.is_in_group(&"players"):
		_hit_targets.append(body)
		_apply_hit(body)
		if not is_piercing:
			_expire()

func _on_area_entered(area: Node) -> void:
	pass

func _apply_hit(target: Node) -> void:
	if aoe_radius > 0.0:
		_apply_aoe_damage()
	else:
		var health: HealthComponent = target.find_child("HealthComponent")
		if health:
			var actual := health.take_damage(_damage, _source)
			if actual > 0.0:
				hit_target.emit(target, actual)
				EventBus.hit_confirmed.emit(_source, target, actual, false)

func _apply_aoe_damage() -> void:
	var aoe_targets := get_tree().get_nodes_in_group(&"enemies")
	aoe_targets.append_array(get_tree().get_nodes_in_group(&"towers"))
	for target in aoe_targets:
		if not is_instance_valid(target):
			continue
		if global_position.distance_to(target.global_position) <= aoe_radius:
			var health: HealthComponent = target.find_child("HealthComponent")
			if health:
				var actual := health.take_damage(_damage, _source)
				if actual > 0.0:
					hit_target.emit(target, actual)

func _expire() -> void:
	projectile_expired.emit()
	queue_free()
