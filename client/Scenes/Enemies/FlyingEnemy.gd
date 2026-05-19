class_name FlyingEnemy
extends EnemyBase
## フライングエネミー — ナビメッシュを無視して直線飛行でターゲットへ向かう
## fly_height はenemy_data.fly_height から取得するが、インスペクタで個別上書きも可能

@export var fly_height: float = 3.0

func _ready() -> void:
	# enemy_dataの飛行高度を優先する
	if enemy_data and enemy_data.fly_height > 0.0:
		fly_height = enemy_data.fly_height
	super._ready()

func _create_ai() -> EnemyAIBase:
	return FlyingAI.new()

## FlyingAIはNavMeshを使わず直接velocityを設定するため、
## nav_agentのvelocity_computedコールバックは使用しない
func _on_velocity_computed(_safe_velocity: Vector3) -> void:
	pass
