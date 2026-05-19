class_name AssassinAI
extends EnemyAIBase
## アサシンAI — サポート優先ターゲット・ブリンクによる奇襲を担当
## ターゲットへの接近時にブリンクを試み、背後から攻撃する

const BLINK_TRIGGER_RANGE: float = 8.0

func _tick_chase(delta: float, target: Node) -> void:
	if target == null or not is_instance_valid(target):
		_state = State.IDLE
		return

	var dist := _owner.global_position.distance_to(target.global_position)

	# ブリンク射程内であればテレポートを試みる
	if dist <= BLINK_TRIGGER_RANGE and _owner.has_method(&"try_blink"):
		if _owner.try_blink(target):
			_state = State.ATTACK
			return

	_navigate_toward(target.global_position)

	if _enemy_data and dist <= _enemy_data.attack_range:
		_state = State.ATTACK

func _tick_attack(_delta: float, target: Node) -> void:
	if target == null or not is_instance_valid(target):
		_state = State.IDLE
		return

	_owner.try_attack(target)

	if _enemy_data and _owner.global_position.distance_to(target.global_position) > _enemy_data.attack_range * 1.2:
		_state = State.CHASE
