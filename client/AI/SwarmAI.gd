class_name SwarmAI
extends EnemyAIBase
## スウォームAI — 高速で群れを成して突進する
## 仲間のSwarmEnemyが近くにいると速度ボーナスを得る (フレアリング)

const FLOCK_SPEED_BONUS: float = 0.25
const FLOCK_RADIUS: float = 4.0
const FLOCK_MAX_BONUS_COUNT: int = 4

func _tick_chase(delta: float, target: Node) -> void:
	if target == null or not is_instance_valid(target):
		_state = State.IDLE
		return

	var base_speed := _enemy_data.move_speed if _enemy_data else 5.0
	if _owner.status_effect_component:
		base_speed *= _owner.status_effect_component.get_speed_multiplier()

	# 近くの仲間の数に応じた速度ボーナス
	var swarm_count := _count_nearby_swarm()
	var bonus := minf(float(swarm_count), float(FLOCK_MAX_BONUS_COUNT)) * FLOCK_SPEED_BONUS
	var final_speed := base_speed * (1.0 + bonus)

	if _nav == null or not is_instance_valid(_nav):
		return
	_nav.target_position = target.global_position
	if not _nav.is_navigation_finished():
		var next_pos := _nav.get_next_path_position()
		var direction := _owner.global_position.direction_to(next_pos)
		direction.y = 0.0
		_nav.set_velocity(direction.normalized() * final_speed)

	if _enemy_data and _owner.global_position.distance_to(target.global_position) <= _enemy_data.attack_range:
		_state = State.ATTACK

func _count_nearby_swarm() -> int:
	var count := 0
	var all_swarms := _owner.get_tree().get_nodes_in_group(&"enemies_swarm")
	for s in all_swarms:
		if s == _owner or not is_instance_valid(s):
			continue
		if _owner.global_position.distance_to(s.global_position) <= FLOCK_RADIUS:
			count += 1
	return count
