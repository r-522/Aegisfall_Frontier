class_name TowerComponent
extends Node
## タワーの自動攻撃・ターゲット追尾・射撃を担当するコンポーネント

signal fired(target: Node, damage: float)
signal target_changed(new_target: Node)
signal attack_started(target: Node)

@export var tower_data: TowerData

var _fire_timer: float = 0.0
var _current_target: Node = null
var _aggro: AggroComponent

func _ready() -> void:
	_aggro = get_parent().find_child("AggroComponent") as AggroComponent
	if _aggro == null:
		push_error("TowerComponent: AggroComponentが見つかりません — " + get_parent().name)
		return
	_aggro.target_acquired.connect(_on_target_acquired)
	_aggro.target_lost.connect(_on_target_lost)

func _process(delta: float) -> void:
	if tower_data == null:
		return
	if _current_target == null or not is_instance_valid(_current_target):
		_current_target = null
		return

	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_try_fire()
		_fire_timer = tower_data.attack_cooldown

func _try_fire() -> void:
	if tower_data.attack_behavior == TowerData.AttackBehavior.NONE:
		return
	if tower_data.attack_behavior == TowerData.AttackBehavior.TRAP:
		return

	var calc_damage := tower_data.attack_damage
	attack_started.emit(_current_target)
	fired.emit(_current_target, calc_damage)

func get_current_target() -> Node:
	return _current_target

func force_set_target(target: Node) -> void:
	_current_target = target
	target_changed.emit(_current_target)

func is_in_attack_range(target_pos: Vector3) -> bool:
	if tower_data == null:
		return false
	var owner_pos: Vector3 = get_parent().global_position
	return owner_pos.distance_to(target_pos) <= tower_data.attack_range

func _on_target_acquired(target: Node) -> void:
	_current_target = target
	_fire_timer = 0.0
	target_changed.emit(_current_target)

func _on_target_lost() -> void:
	_current_target = null
	target_changed.emit(null)
