class_name SelectTarget
extends BTNode
## ターゲット選択ビヘイビア — AggroComponentに委譲

var _aggro: AggroComponent

func _init(aggro: AggroComponent) -> void:
	_aggro = aggro

func tick(_delta: float, _actor: Node) -> Status:
	if _aggro == null:
		return Status.FAILURE
	_aggro.update_target()
	if _aggro.current_target != null and is_instance_valid(_aggro.current_target):
		return Status.SUCCESS
	return Status.FAILURE
