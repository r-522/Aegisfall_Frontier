class_name AssassinTargetStrategy
extends RefCounted
## Assassin型敵のターゲット選択戦略
## 支援塔 > Clericプレイヤー > その他プレイヤー > 攻撃塔 の優先度

static func get_best_target(actor: Node, candidates: Array[Node]) -> Node:
	var scored: Array[Dictionary] = []

	for candidate in candidates:
		if not is_instance_valid(candidate):
			continue
		var score := _score_target(actor, candidate)
		scored.append({"node": candidate, "score": score})

	if scored.is_empty():
		return null

	scored.sort_custom(func(a, b): return a.score > b.score)
	return scored[0].node

static func _score_target(actor: Node, target: Node) -> float:
	var dist := actor.global_position.distance_to(target.global_position)
	var dist_penalty := dist * 0.1
	var base_score := 0.0

	if target.is_in_group(&"towers_support"):
		base_score = 100.0
	elif target.is_in_group(&"class_support"):
		base_score = 80.0
	elif target.is_in_group(&"players"):
		base_score = 50.0
	elif target.is_in_group(&"towers"):
		base_score = 20.0

	var health_comp: HealthComponent = target.find_child("HealthComponent")
	if health_comp:
		base_score += (1.0 - health_comp.get_health_ratio()) * 20.0

	return base_score - dist_penalty
