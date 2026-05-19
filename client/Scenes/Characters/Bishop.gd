class_name Bishop
extends PlayerBase
## Bishop — 回復と白魔法の上位職、強力な範囲回復と復活魔法を操る
## TODO: フル実装予定

func _ready() -> void:
	add_to_group(&"class_support")
	super._ready()

func _do_normal_attack() -> void:
	# TODO: クラス固有の通常攻撃
	_combo_count = (_combo_count % 2) + 1
	_combo_reset_timer = COMBO_RESET_TIME
	if animation_player:
		animation_player.play("attack_%d" % _combo_count)
	_state = State.ATTACKING
	_attack_timer = 1.0 / character_data.attack_speed if character_data else 1.0
	# プレースホルダーダメージ
	var enemies := get_tree().get_nodes_in_group(&"enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and global_position.distance_to(enemy.global_position) < 2.5:
			var health: HealthComponent = enemy.find_child("HealthComponent")
			if health:
				health.take_damage(character_data.base_attack_damage if character_data else 20.0, self)

func _do_heavy_attack() -> void:
	# TODO: クラス固有の強攻撃 (神の裁き)
	_state = State.HEAVY_ATTACKING
	_attack_timer = 1.5
	if animation_player:
		animation_player.play("heavy_attack")

func _execute_skill(index: int, skill_data: SkillData) -> void:
	# TODO: 4スキル実装 (範囲回復・蘇生・強化・聖なる盾スキル群)
	pass
