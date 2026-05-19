class_name AssassinEnemy
extends EnemyBase
## アサシンエネミー — サポートキャラを優先狙いし、ブリンクで近距離テレポートする
## ブリンクは一定クールダウンで発動し、ターゲットの背後に瞬間移動する

const BLINK_RANGE: float = 10.0
const BLINK_COOLDOWN: float = 8.0
const BLINK_OFFSET: float = 1.2

var _blink_timer: float = 0.0

func _create_ai() -> EnemyAIBase:
	return AssassinAI.new()

func _physics_process(delta: float) -> void:
	_blink_timer = maxf(0.0, _blink_timer - delta)
	super._physics_process(delta)

## ブリンク: ターゲットの背後にテレポートする
## AssassinAIまたは外部から呼び出す
func try_blink(target: Node) -> bool:
	if _blink_timer > 0.0 or target == null or not is_instance_valid(target):
		return false
	var dist := global_position.distance_to(target.global_position)
	if dist > BLINK_RANGE:
		return false

	# ターゲットの背後に出現する位置を計算
	var to_enemy := (global_position - target.global_position).normalized()
	to_enemy.y = 0.0
	var blink_pos := target.global_position + to_enemy.normalized() * BLINK_OFFSET
	blink_pos.y = global_position.y

	global_position = blink_pos
	_blink_timer = BLINK_COOLDOWN
	EventBus.field_event_triggered.emit(&"assassin_blink", blink_pos)
	return true
