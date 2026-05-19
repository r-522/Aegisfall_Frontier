class_name TankEnemy
extends EnemyBase
## タンクエネミー — 高HPと高防御を持つ重装甲の近接敵
## TankAIによってチャージ突撃が発動する

func _create_ai() -> EnemyAIBase:
	return TankAI.new()
