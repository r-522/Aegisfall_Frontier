class_name StoneWall
extends TowerBase
## 高耐久の受動的壁タワー — 攻撃能力なし、敵の進路を塞ぐ

func _ready() -> void:
	add_to_group(&"towers_defense")
	add_to_group(&"towers_wall")
	super._ready()

func _on_placed() -> void:
	# TowerComponent・AggroComponent は使用しない (攻撃なし)
	# 壁タワー固有の初期HP設定
	health_component.max_health = 800.0
	health_component.set_max_health(800.0, true)

	if animation_player and animation_player.has_animation("place"):
		animation_player.play("place")

func _spawn_projectile(_target: Node, _damage: float) -> void:
	pass  # 壁タワーは攻撃しない
