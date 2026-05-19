class_name SiegeEnemy
extends EnemyBase
## シージエネミー — 建築物 (タワー) を最優先で攻撃する包囲兵器型の敵
## enemy_data.structure_damage_multiplier で建物への追加ダメージを設定する

func _create_ai() -> EnemyAIBase:
	return SiegeAI.new()

## タワーへのダメージに structure_damage_multiplier を適用
func _on_attack_target(target: Node) -> void:
	var health: HealthComponent = target.find_child("HealthComponent")
	if health == null:
		return
	var damage := enemy_data.attack_damage if enemy_data else 10.0
	if target.is_in_group(&"towers") and enemy_data and enemy_data.can_attack_structures:
		damage *= enemy_data.structure_damage_multiplier
	var actual := health.take_damage(damage, self)
	if actual > 0.0:
		if animation_player:
			animation_player.play("attack")
		EventBus.hit_confirmed.emit(self, target, actual, false)
