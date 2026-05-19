class_name MoveToTarget
extends BTNode
## ターゲットへの移動ビヘイビア

var _nav: NavigationAgent3D
var _aggro: AggroComponent
var _data: EnemyData

func _init(nav: NavigationAgent3D, aggro: AggroComponent, data: EnemyData) -> void:
	_nav = nav
	_aggro = aggro
	_data = data

func tick(delta: float, actor: Node) -> Status:
	if _aggro == null or _nav == null:
		return Status.FAILURE

	var target := _aggro.current_target
	if target == null or not is_instance_valid(target):
		return Status.FAILURE

	_nav.target_position = target.global_position

	if _nav.is_navigation_finished():
		return Status.SUCCESS

	var speed := _data.move_speed if _data else 3.0
	var status_comp: StatusEffectComponent = actor.find_child("StatusEffectComponent")
	if status_comp:
		speed *= status_comp.get_speed_multiplier()

	var next_pos := _nav.get_next_path_position()
	var move_dir := (next_pos - actor.global_position).normalized()
	_nav.set_velocity(move_dir * speed)

	return Status.RUNNING
