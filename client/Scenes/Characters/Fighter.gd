class_name Fighter
extends PlayerBase
## Fighter — 近接攻撃主体のクラス
## コンボシステム・スタンス切替・前線維持が特徴

var _combo_max: int = 3
var _in_battle_cry: bool = false
var _battle_cry_timer: float = 0.0

func _ready() -> void:
	add_to_group(&"class_melee")
	super._ready()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _in_battle_cry:
		_battle_cry_timer -= delta
		if _battle_cry_timer <= 0.0:
			_in_battle_cry = false

func _do_normal_attack() -> void:
	_combo_count = (_combo_count % _combo_max) + 1
	_combo_reset_timer = COMBO_RESET_TIME

	var anim_name := "combo_%d" % _combo_count
	if animation_player:
		animation_player.play(anim_name)

	_state = State.ATTACKING
	_attack_timer = 1.0 / character_data.attack_speed

	var damage := character_data.base_attack_damage
	if _in_battle_cry:
		damage *= 1.3
	if _combo_count == _combo_max:
		damage *= 1.5

	_activate_melee_hitbox(damage, 2.0)
	hit_stop_component.trigger_normal_hit_stop()
	hit_stop_component.trigger_camera_shake()

func _do_heavy_attack() -> void:
	_combo_count = 0
	if animation_player:
		animation_player.play("heavy_attack")
	_state = State.HEAVY_ATTACKING
	_attack_timer = (1.0 / character_data.attack_speed) * 1.8

	var damage := character_data.base_heavy_attack_damage
	if _in_battle_cry:
		damage *= 1.3

	_activate_melee_hitbox(damage, 2.5)
	hit_stop_component.trigger_heavy_hit_stop()
	hit_stop_component.trigger_heavy_camera_shake()

func _execute_skill(index: int, skill_data: SkillData) -> void:
	match index:
		0: _skill_shield_bash(skill_data)
		1: _skill_whirlwind(skill_data)
		2: _skill_battle_cry(skill_data)
		3: _skill_berserker_rage(skill_data)

func _skill_shield_bash(skill: SkillData) -> void:
	if animation_player:
		animation_player.play("shield_bash")
	_state = State.CASTING
	_attack_timer = 0.6

	var forward := get_forward_direction()
	var bash_damage := skill.damage
	var knock := skill.knockback_force

	_activate_cone_hitbox(bash_damage, 2.5, 60.0, knock)
	hit_stop_component.trigger_heavy_hit_stop()

func _skill_whirlwind(skill: SkillData) -> void:
	if animation_player:
		animation_player.play("whirlwind")
	_state = State.CASTING
	_attack_timer = 1.0

	_activate_aoe_hitbox(skill.damage, skill.effect_radius)
	hit_stop_component.trigger_heavy_hit_stop()
	hit_stop_component.trigger_heavy_camera_shake()

func _skill_battle_cry(skill: SkillData) -> void:
	if animation_player:
		animation_player.play("battle_cry")
	_in_battle_cry = true
	_battle_cry_timer = skill.duration

	EventBus.status_effect_applied.emit(self, StatusEffectComponent.EFFECT_HASTE, skill.duration)

func _skill_berserker_rage(skill: SkillData) -> void:
	if animation_player:
		animation_player.play("berserker_rage")

	var targets := get_tree().get_nodes_in_group(&"players")
	for t in targets:
		var health: HealthComponent = t.find_child("HealthComponent")
		if health:
			health.apply_invincibility(skill.duration * 0.5)

	health_component.set_max_health(character_data.max_health * 1.5)
	_in_battle_cry = true
	_battle_cry_timer = skill.duration
	hit_stop_component.trigger_camera_shake(0.5)

func _activate_melee_hitbox(damage: float, range_mult: float) -> void:
	var forward := get_forward_direction()
	var hit_pos := global_position + forward * (character_data.attack_range * range_mult * 0.5)
	_sphere_damage(hit_pos, character_data.attack_range * range_mult * 0.5, damage)

func _activate_cone_hitbox(damage: float, range: float, angle_deg: float, knockback: float) -> void:
	var forward := get_forward_direction()
	var enemies := get_tree().get_nodes_in_group(&"enemies")
	var angle_rad := deg_to_rad(angle_deg * 0.5)
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var to_enemy := (enemy.global_position - global_position)
		if to_enemy.length() > range:
			continue
		var dir_2d := Vector2(to_enemy.x, to_enemy.z).normalized()
		var fwd_2d := Vector2(forward.x, forward.z).normalized()
		if dir_2d.dot(fwd_2d) < cos(angle_rad):
			continue
		_apply_damage_to(enemy, damage, knockback)

func _activate_aoe_hitbox(damage: float, radius: float) -> void:
	_sphere_damage(global_position, radius, damage)

func _sphere_damage(center: Vector3, radius: float, damage: float) -> void:
	var enemies := get_tree().get_nodes_in_group(&"enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if center.distance_to(enemy.global_position) <= radius:
			_apply_damage_to(enemy, damage, 0.0)

func _apply_damage_to(enemy: Node, damage: float, knockback: float) -> void:
	var health: HealthComponent = enemy.find_child("HealthComponent")
	if health == null:
		return
	var actual := health.take_damage(damage, self)
	if actual > 0.0:
		EventBus.hit_confirmed.emit(self, enemy, actual, false)
	if knockback > 0.0 and enemy is CharacterBody3D:
		var dir := (enemy.global_position - global_position).normalized()
		enemy.velocity += dir * knockback
