class_name FleeWhenLow
extends BTNode
## 低HP時に逃走するビヘイビア

var _health: HealthComponent
var _flee_threshold: float
var _flee_speed_multiplier: float

func _init(health: HealthComponent, threshold: float = 0.2, speed_mult: float = 1.5) -> void:
	_health = health
	_flee_threshold = threshold
	_flee_speed_multiplier = speed_mult

func tick(_delta: float, actor: Node) -> Status:
	if _health == null or not is_instance_valid(_health):
		return Status.FAILURE

	if _health.get_health_ratio() > _flee_threshold:
		return Status.FAILURE

	var players := actor.get_tree().get_nodes_in_group(&"players")
	if players.is_empty():
		return Status.FAILURE

	var nearest_player := players[0]
	var min_dist := actor.global_position.distance_squared_to(nearest_player.global_position)
	for p in players:
		var d := actor.global_position.distance_squared_to(p.global_position)
		if d < min_dist:
			min_dist = d
			nearest_player = p

	var flee_dir := (actor.global_position - nearest_player.global_position).normalized()
	if actor is CharacterBody3D:
		actor.velocity = flee_dir * 5.0 * _flee_speed_multiplier
		actor.move_and_slide()

	return Status.RUNNING
