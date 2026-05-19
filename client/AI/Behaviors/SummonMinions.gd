class_name SummonMinions
extends BTNode
## ミニオン召喚ビヘイビア

var _data: EnemyData
var _summon_timer: float = 0.0
var _summon_cooldown: float = 15.0
var _max_minions: int = 3
var _current_minions: Array[Node] = []

func _init(data: EnemyData, cooldown: float = 15.0) -> void:
	_data = data
	_summon_cooldown = cooldown
	_summon_timer = cooldown * 0.5

func tick(delta: float, actor: Node) -> Status:
	if _data == null or not _data.can_summon_minions:
		return Status.FAILURE

	_current_minions = _current_minions.filter(func(m): return is_instance_valid(m))

	_summon_timer -= delta
	if _summon_timer > 0.0:
		return Status.FAILURE

	if _current_minions.size() >= _max_minions:
		return Status.FAILURE

	_summon_timer = _summon_cooldown
	_do_summon(actor)
	return Status.SUCCESS

func _do_summon(summoner: Node) -> void:
	if _data.minion_type_id.is_empty():
		return

	var minion_count := _data.minion_count
	for i in minion_count:
		var angle := (float(i) / float(minion_count)) * TAU
		var offset := Vector3(cos(angle) * 2.0, 0.0, sin(angle) * 2.0)
		var spawn_pos := summoner.global_position + offset

		var minion_path := "res://Scenes/Enemies/GoblinScout.tscn"
		var scene: PackedScene = load(minion_path)
		if scene == null:
			continue
		var minion: Node3D = scene.instantiate()
		summoner.get_tree().current_scene.add_child(minion)
		minion.global_position = spawn_pos
		_current_minions.append(minion)
		EventBus.enemy_spawned.emit(minion)
