class_name SiegeTargetStrategy
extends RefCounted
## Siege型敵のターゲット選択戦略
## タワー・構造物専門ターゲット

static func get_best_target(actor: Node, all_candidates: Array[Node]) -> Node:
	var towers: Array[Node] = []
	for candidate in all_candidates:
		if is_instance_valid(candidate) and candidate.is_in_group(&"towers"):
			towers.append(candidate)

	if towers.is_empty():
		return _get_nearest(actor, all_candidates)

	return _get_prioritized_tower(actor, towers)

static func _get_prioritized_tower(actor: Node, towers: Array[Node]) -> Node:
	var attack_towers: Array[Node] = []
	var support_towers: Array[Node] = []
	var other_towers: Array[Node] = []

	for t in towers:
		if t.is_in_group(&"towers_attack"):
			attack_towers.append(t)
		elif t.is_in_group(&"towers_support"):
			support_towers.append(t)
		else:
			other_towers.append(t)

	if not attack_towers.is_empty():
		return _get_nearest(actor, attack_towers)
	if not support_towers.is_empty():
		return _get_nearest(actor, support_towers)
	return _get_nearest(actor, other_towers)

static func _get_nearest(actor: Node, candidates: Array[Node]) -> Node:
	var best: Node = null
	var best_dist_sq: float = INF
	for c in candidates:
		if not is_instance_valid(c):
			continue
		var d := actor.global_position.distance_squared_to(c.global_position)
		if d < best_dist_sq:
			best_dist_sq = d
			best = c
	return best
