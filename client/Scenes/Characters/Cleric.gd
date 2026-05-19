class_name Cleric
extends PlayerBase
## Cleric — 回復・バフ・召喚支援が特徴
## 近傍味方への継続回復オーラを常時発動

const HEAL_AURA_INTERVAL: float = 2.0
const HEAL_AURA_RADIUS: float = 8.0
const HEAL_AURA_AMOUNT: float = 5.0

var _aura_timer: float = 0.0
var _divine_intervention_active: bool = false

func _ready() -> void:
	add_to_group(&"class_support")
	super._ready()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_tick_heal_aura(delta)

func _do_normal_attack() -> void:
	_combo_count = (_combo_count % 2) + 1
	_combo_reset_timer = COMBO_RESET_TIME

	if animation_player:
		animation_player.play("mace_strike_%d" % _combo_count)
	_state = State.ATTACKING
	_attack_timer = 1.0 / character_data.attack_speed

	var forward := get_forward_direction()
	var hit_pos := global_position + forward * 1.5
	_sphere_damage(hit_pos, 1.5, character_data.base_attack_damage)
	hit_stop_component.trigger_normal_hit_stop()

func _do_heavy_attack() -> void:
	_combo_count = 0
	if animation_player:
		animation_player.play("divine_smash")
	_state = State.HEAVY_ATTACKING
	_attack_timer = (1.0 / character_data.attack_speed) * 2.0

	var hit_pos := global_position + get_forward_direction() * 2.0
	_sphere_damage(hit_pos, 2.5, character_data.base_heavy_attack_damage)
	hit_stop_component.trigger_heavy_hit_stop()
	hit_stop_component.trigger_heavy_camera_shake()

func _execute_skill(index: int, skill_data: SkillData) -> void:
	match index:
		0: _skill_holy_bolt(skill_data)
		1: _skill_barrier(skill_data)
		2: _skill_smite(skill_data)
		3: _skill_divine_intervention(skill_data)

func _skill_holy_bolt(skill: SkillData) -> void:
	if animation_player:
		animation_player.play("cast_holy_bolt")
	_state = State.CASTING
	_attack_timer = 0.6

	var target_pos := get_aim_target(20.0)
	var bolt_scene: PackedScene = load("res://Scenes/Projectiles/MageBolt.tscn")
	if bolt_scene:
		var bolt: Node3D = bolt_scene.instantiate()
		get_tree().current_scene.add_child(bolt)
		bolt.global_position = global_position + Vector3.UP * 1.2
		if bolt.has_method("initialize"):
			bolt.initialize(target_pos - bolt.global_position, skill.damage, self)

	var nearby_allies := _get_nearby_allies(5.0)
	for ally in nearby_allies:
		var ally_health: HealthComponent = ally.find_child("HealthComponent")
		if ally_health:
			ally_health.heal(skill.heal_amount * 0.5)

func _skill_barrier(skill: SkillData) -> void:
	if animation_player:
		animation_player.play("cast_barrier")

	var nearby_allies := _get_nearby_allies(skill.effect_radius)
	for ally in nearby_allies:
		var ally_health: HealthComponent = ally.find_child("HealthComponent")
		if ally_health:
			ally_health.apply_invincibility(skill.duration)
		var ally_status: StatusEffectComponent = ally.find_child("StatusEffectComponent")
		if ally_status:
			ally_status.apply_effect(StatusEffectComponent.EFFECT_SHIELDED, skill.duration, skill.buff_defense_add)

	EventBus.status_effect_applied.emit(self, StatusEffectComponent.EFFECT_SHIELDED, skill.duration)

func _skill_smite(skill: SkillData) -> void:
	if animation_player:
		animation_player.play("smite")
	_state = State.CASTING
	_attack_timer = 0.7

	var target_pos := get_aim_target(15.0)
	var enemies := get_tree().get_nodes_in_group(&"enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if target_pos.distance_to(enemy.global_position) <= 2.5:
			var health: HealthComponent = enemy.find_child("HealthComponent")
			if health:
				health.take_damage(skill.damage, self)
			var status: StatusEffectComponent = enemy.find_child("StatusEffectComponent")
			if status:
				status.apply_effect(StatusEffectComponent.EFFECT_STUNNED, skill.duration)

	hit_stop_component.trigger_heavy_camera_shake()

func _skill_divine_intervention(skill: SkillData) -> void:
	if animation_player:
		animation_player.play("divine_intervention")
	_divine_intervention_active = true

	var all_players := get_tree().get_nodes_in_group(&"players")
	for player in all_players:
		if not is_instance_valid(player):
			continue
		var p_health: HealthComponent = player.find_child("HealthComponent")
		if p_health == null:
			continue
		if p_health.is_dead:
			p_health.is_dead = false
			p_health.heal(p_health.max_health * 0.3)
			EventBus.player_respawned.emit(player_id, player.global_position)
		else:
			p_health.heal(p_health.max_health * skill.heal_amount / 100.0)
		p_health.apply_invincibility(skill.duration * 0.5)

	EventBus.status_effect_applied.emit(self, &"divine_grace", skill.duration)
	hit_stop_component.trigger_camera_shake(0.4)

func _tick_heal_aura(delta: float) -> void:
	_aura_timer -= delta
	if _aura_timer > 0.0:
		return
	_aura_timer = HEAL_AURA_INTERVAL

	var nearby := _get_nearby_allies(HEAL_AURA_RADIUS)
	var heal_amount := HEAL_AURA_AMOUNT
	if _divine_intervention_active:
		heal_amount *= 2.0

	for ally in nearby:
		var ally_health: HealthComponent = ally.find_child("HealthComponent")
		if ally_health and not ally_health.is_full_health():
			ally_health.heal(heal_amount)
			EventBus.player_healed.emit(ally.get("player_id") if ally.get("player_id") != null else 0, heal_amount)

func _get_nearby_allies(radius: float) -> Array[Node]:
	var result: Array[Node] = []
	var players := get_tree().get_nodes_in_group(&"players")
	for p in players:
		if not is_instance_valid(p):
			continue
		if global_position.distance_to(p.global_position) <= radius:
			result.append(p)
	return result

func _sphere_damage(center: Vector3, radius: float, damage: float) -> void:
	var enemies := get_tree().get_nodes_in_group(&"enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if center.distance_to(enemy.global_position) <= radius:
			var health: HealthComponent = enemy.find_child("HealthComponent")
			if health:
				var actual := health.take_damage(damage, self)
				if actual > 0.0:
					EventBus.hit_confirmed.emit(self, enemy, actual, false)
