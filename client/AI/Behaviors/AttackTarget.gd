class_name AttackTarget
extends BTNode
## 攻撃実行ビヘイビア

var _aggro: AggroComponent
var _data: EnemyData

func _init(aggro: AggroComponent, data: EnemyData) -> void:
	_aggro = aggro
	_data = data

func tick(_delta: float, actor: Node) -> Status:
	if _aggro == null or _data == null:
		return Status.FAILURE

	var target := _aggro.current_target
	if target == null or not is_instance_valid(target):
		return Status.FAILURE

	var dist := actor.global_position.distance_to(target.global_position)
	if dist > _data.attack_range:
		return Status.FAILURE

	if actor.has_method("try_attack"):
		actor.try_attack(target)

	return Status.SUCCESS
