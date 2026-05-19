class_name SwarmEnemy
extends EnemyBase
## スウォームエネミー — 高速で群れを成して攻撃する脆弱な雑魚敵
## 群れ行動はSwarmAIが担当し、仲間が近くにいると速度ボーナスを得る

func _ready() -> void:
	add_to_group(&"enemies_swarm")
	super._ready()

func _create_ai() -> EnemyAIBase:
	return SwarmAI.new()
