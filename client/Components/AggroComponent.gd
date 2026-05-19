class_name AggroComponent
extends Node
## ターゲット選択コンポーネント — 敵・タワー両方で使用
## Area3D子ノードで範囲内エンティティを検知し優先度順でターゲット選択

signal target_acquired(target: Node)
signal target_lost()
signal targets_updated()

@export var detection_radius: float = 12.0
@export var target_priority: EnemyData.TargetPriority = EnemyData.TargetPriority.NEAREST
@export var update_interval: float = 0.2

var current_target: Node = null

var _detected_players: Array[Node] = []
var _detected_enemies: Array[Node] = []
var _detected_towers: Array[Node] = []
var _detected_support_towers: Array[Node] = []
var _update_timer: float = 0.0
var _area: Area3D

func _ready() -> void:
	_area = $DetectionArea
	if _area == null:
		_area = _create_detection_area()
	_area.body_entered.connect(_on_body_entered)
	_area.body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	_update_timer -= delta
	if _update_timer <= 0.0:
		_update_timer = update_interval
		_clean_invalid_refs()
		update_target()

func update_target() -> void:
	var new_target := _select_target()
	if new_target != current_target:
		current_target = new_target
		if current_target != null:
			target_acquired.emit(current_target)
		else:
			target_lost.emit()

func get_all_detected_enemies() -> Array[Node]:
	return _detected_enemies.duplicate()

func get_all_in_range() -> Array[Node]:
	var all: Array[Node] = []
	all.append_array(_detected_players)
	all.append_array(_detected_enemies)
	all.append_array(_detected_towers)
	return all

func _select_target() -> Node:
	var owner_pos: Vector3 = get_parent().global_position

	match target_priority:
		EnemyData.TargetPriority.NEAREST:
			return _get_nearest(owner_pos, _detected_players + _detected_towers + _detected_enemies)
		EnemyData.TargetPriority.TOWER_FIRST:
			if _detected_towers.size() > 0:
				return _get_nearest(owner_pos, _detected_towers)
			return _get_nearest(owner_pos, _detected_players)
		EnemyData.TargetPriority.PLAYER_FIRST:
			if _detected_players.size() > 0:
				return _get_nearest(owner_pos, _detected_players)
			return _get_nearest(owner_pos, _detected_towers)
		EnemyData.TargetPriority.SUPPORT_FIRST:
			if _detected_support_towers.size() > 0:
				return _get_nearest(owner_pos, _detected_support_towers)
			var clerics := _get_clerics()
			if clerics.size() > 0:
				return _get_nearest(owner_pos, clerics)
			if _detected_players.size() > 0:
				return _get_nearest(owner_pos, _detected_players)
			return _get_nearest(owner_pos, _detected_towers)
		EnemyData.TargetPriority.STRUCTURE_ONLY:
			return _get_nearest(owner_pos, _detected_towers)

	return null

func _get_nearest(from: Vector3, candidates: Array[Node]) -> Node:
	var best: Node = null
	var best_dist_sq: float = INF
	for node in candidates:
		if not is_instance_valid(node):
			continue
		var d := from.distance_squared_to(node.global_position)
		if d < best_dist_sq:
			best_dist_sq = d
			best = node
	return best

func _get_clerics() -> Array[Node]:
	var result: Array[Node] = []
	for p in _detected_players:
		if is_instance_valid(p) and p.is_in_group(&"class_support"):
			result.append(p)
	return result

func _clean_invalid_refs() -> void:
	_detected_players = _detected_players.filter(func(n): return is_instance_valid(n))
	_detected_enemies = _detected_enemies.filter(func(n): return is_instance_valid(n))
	_detected_towers = _detected_towers.filter(func(n): return is_instance_valid(n))
	_detected_support_towers = _detected_support_towers.filter(func(n): return is_instance_valid(n))

func _on_body_entered(body: Node) -> void:
	if body.is_in_group(&"players"):
		if not _detected_players.has(body):
			_detected_players.append(body)
	elif body.is_in_group(&"enemies"):
		if not _detected_enemies.has(body):
			_detected_enemies.append(body)
	elif body.is_in_group(&"towers"):
		if not _detected_towers.has(body):
			_detected_towers.append(body)
		if body.is_in_group(&"towers_support"):
			if not _detected_support_towers.has(body):
				_detected_support_towers.append(body)
	targets_updated.emit()

func _on_body_exited(body: Node) -> void:
	_detected_players.erase(body)
	_detected_enemies.erase(body)
	_detected_towers.erase(body)
	_detected_support_towers.erase(body)
	if body == current_target:
		update_target()
	targets_updated.emit()

func _create_detection_area() -> Area3D:
	var area := Area3D.new()
	area.name = "DetectionArea"
	area.collision_layer = 0
	area.collision_mask = (1 << 1) | (1 << 2) | (1 << 3)  # Players, Enemies, Towers
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = detection_radius
	shape.shape = sphere
	area.add_child(shape)
	add_child(area)
	return area
