class_name FlyingTargetStrategy
extends RefCounted
## 飛行ユニット用ターゲット選択戦略
## ナビゲーションメッシュを無視して直線移動

static func get_best_target(actor: Node, candidates: Array[Node]) -> Node:
	if candidates.is_empty():
		return null
	var best: Node = null
	var best_dist_sq: float = INF
	for candidate in candidates:
		if not is_instance_valid(candidate):
			continue
		var d := actor.global_position.distance_squared_to(candidate.global_position)
		if d < best_dist_sq:
			best_dist_sq = d
			best = candidate
	return best

static func compute_velocity_toward(actor: Node3D, target: Node3D, speed: float, fly_height: float) -> Vector3:
	if target == null or not is_instance_valid(target):
		return Vector3.ZERO
	var target_pos := target.global_position + Vector3.UP * fly_height
	var dir := (target_pos - actor.global_position).normalized()
	return dir * speed
