class_name ArcaneBlast
extends ProjectileBase
## 魔法弾プロジェクタイル — AoE爆発・デバフ付与

func _ready() -> void:
	super._ready()
	speed = 22.0
	max_range = 30.0
	aoe_radius = 3.0
	collision_layer = 1 << 4
	collision_mask = (1 << 2) | (1 << 3) | (1 << 0)  # Enemies, Towers, World

func _apply_hit(target: Node) -> void:
	super._apply_hit(target)
	# 50%でWEAKENEDを付与
	if randf() < 0.5:
		var aoe_enemies := get_tree().get_nodes_in_group(&"enemies")
		for enemy in aoe_enemies:
			if is_instance_valid(enemy) and global_position.distance_to(enemy.global_position) <= aoe_radius:
				var status: StatusEffectComponent = enemy.find_child("StatusEffectComponent")
				if status:
					status.apply_effect(StatusEffectComponent.EFFECT_WEAKENED, 4.0, 0.25)
