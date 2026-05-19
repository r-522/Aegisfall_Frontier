class_name SiegeAI
extends EnemyAIBase
## シージAI — 建築物 (タワー) を最優先に攻撃する
## プレイヤーが攻撃してきても基本的に構造物攻撃を継続する

func _tick_idle(_delta: float, target: Node) -> void:
	if target != null and is_instance_valid(target):
		_state = State.CHASE

func _tick_chase(delta: float, target: Node) -> void:
	if target == null or not is_instance_valid(target):
		_state = State.IDLE
		return

	# タワーが見つかれば優先的に向かう
	var tower_target := _get_nearest_structure()
	var actual_target := tower_target if tower_target != null else target

	_navigate_toward(actual_target.global_position)

	if _enemy_data and _owner.global_position.distance_to(actual_target.global_position) <= _enemy_data.attack_range:
		_state = State.ATTACK

func _tick_attack(_delta: float, target: Node) -> void:
	var tower_target := _get_nearest_structure()
	var actual_target := tower_target if tower_target != null else target

	if actual_target == null or not is_instance_valid(actual_target):
		_state = State.IDLE
		return

	_owner.try_attack(actual_target)

	if _enemy_data and _owner.global_position.distance_to(actual_target.global_position) > _enemy_data.attack_range * 1.2:
		_state = State.CHASE

func _get_nearest_structure() -> Node:
	if _aggro == null:
		return null
	var towers := _owner.get_tree().get_nodes_in_group(&"towers")
	var best: Node = null
	var best_dist_sq := INF
	for tower in towers:
		if not is_instance_valid(tower):
			continue
		var d := _owner.global_position.distance_squared_to(tower.global_position)
		if d < best_dist_sq:
			best_dist_sq = d
			best = tower
	return best
