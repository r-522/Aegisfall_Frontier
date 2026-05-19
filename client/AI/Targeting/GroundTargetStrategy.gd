class_name GroundTargetStrategy
extends RefCounted
## 地上ユニット用ターゲット選択戦略
## NavigationAgent3Dを使用して到達可能なターゲットを選択

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

static func is_reachable(actor: Node, target: Node) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	var nav_map := actor.get_world_3d().get_navigation_map() if actor is Node3D else RID()
	if not nav_map.is_valid():
		return true
	var path := NavigationServer3D.map_get_path(nav_map, actor.global_position, target.global_position, true)
	return path.size() > 0
