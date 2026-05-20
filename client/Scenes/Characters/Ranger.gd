class_name Ranger
extends PlayerBase
## Ranger — 遠距離弓・トラップ・索敵特化クラス
## フォーカスゲージで強化スキルが使用可能

const ARROW_SCENE := "res://Scenes/Projectiles/Arrow.tscn"

var _focus: float = 0.0
var _max_focus: float = 100.0
var _in_shadow_step: bool = false
var _shadow_step_timer: float = 0.0

func _ready() -> void:
	add_to_group(&"class_agile")
	super._ready()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _in_shadow_step:
		_shadow_step_timer -= delta
		if _shadow_step_timer <= 0.0:
			_in_shadow_step = false

func _do_normal_attack() -> void:
	_combo_count = (_combo_count % 3) + 1
	_combo_reset_timer = COMBO_RESET_TIME

	if animation_player:
		animation_player.play("shoot_%d" % _combo_count)
	_state = State.ATTACKING
	_attack_timer = 1.0 / character_data.attack_speed

	var damage := character_data.base_attack_damage
	if _in_shadow_step:
		damage *= 1.5

	_fire_arrow(get_aim_target(40.0), damage, false)
	_gain_focus(8.0)

func _do_heavy_attack() -> void:
	_combo_count = 0
	if animation_player:
		animation_player.play("power_shot")
	_state = State.HEAVY_ATTACKING
	_attack_timer = (1.0 / character_data.attack_speed) * 2.5

	var damage := character_data.base_heavy_attack_damage
	_fire_arrow(get_aim_target(60.0), damage, true)
	hit_stop_component.trigger_camera_shake()

func _execute_skill(index: int, skill_data: SkillData) -> void:
	match index:
		0: _skill_volley(skill_data)
		1: _skill_smoke_bomb(skill_data)
		2: _skill_snare_trap(skill_data)
		3: _skill_rain_of_arrows(skill_data)

func _skill_volley(skill: SkillData) -> void:
	if animation_player:
		animation_player.play("volley")
	_state = State.CASTING
	_attack_timer = 1.0

	var target_pos := get_aim_target(35.0)
	var spread := 15.0
	for i in skill.projectile_count:
		var angle := (float(i) / float(skill.projectile_count - 1) - 0.5) * spread
		var dir := (target_pos - global_position).normalized()
		var rotated_dir := dir.rotated(Vector3.UP, deg_to_rad(angle))
		_fire_arrow_dir(rotated_dir, skill.damage, false)

	hit_stop_component.trigger_camera_shake(0.15)

func _skill_smoke_bomb(skill: SkillData) -> void:
	if animation_player:
		animation_player.play("throw_smoke")

	var throw_pos := global_position + get_forward_direction() * 4.0

	var enemies_in_range := get_tree().get_nodes_in_group(&"enemies")
	for enemy in enemies_in_range:
		if not is_instance_valid(enemy):
			continue
		if throw_pos.distance_to(enemy.global_position) <= skill.effect_radius:
			var status: StatusEffectComponent = enemy.find_child("StatusEffectComponent")
			if status:
				status.apply_effect(StatusEffectComponent.EFFECT_WEAKENED, skill.duration, 0.3)

	_in_shadow_step = true
	_shadow_step_timer = skill.duration * 0.5

func _skill_snare_trap(skill: SkillData) -> void:
	if animation_player:
		animation_player.play("set_trap")

	var trap_scene: PackedScene = load("res://Scenes/Towers/Special/TrapMine.tscn")
	if trap_scene:
		var trap: Node3D = trap_scene.instantiate()
		get_tree().current_scene.add_child(trap)
		trap.global_position = global_position + get_forward_direction() * 2.0
		if trap.has_method("set_owner_player"):
			trap.set_owner_player(self, skill.damage)

func _skill_rain_of_arrows(skill: SkillData) -> void:
	if animation_player:
		animation_player.play("rain_of_arrows")
	_state = State.CASTING
	_attack_timer = 1.5

	var target_pos := get_aim_target(30.0)
	_start_rain_of_arrows(target_pos, skill.damage, skill.effect_radius, int(skill.duration * 2))

func _start_rain_of_arrows(center: Vector3, damage: float, radius: float, arrow_count: int) -> void:
	for i in arrow_count:
		if not is_instance_valid(self):
			return
		var offset := Vector3(
			randf_range(-radius, radius),
			5.0,
			randf_range(-radius, radius)
		)
		var drop_pos := center + offset
		var enemies := get_tree().get_nodes_in_group(&"enemies")
		for enemy in enemies:
			if is_instance_valid(enemy) and drop_pos.distance_to(enemy.global_position) < 1.5:
				var health: HealthComponent = enemy.find_child("HealthComponent")
				if health:
					health.take_damage(damage, self)
		await get_tree().create_timer(0.15).timeout

func _fire_arrow(target_pos: Vector3, damage: float, is_piercing: bool) -> void:
	var dir := (target_pos - global_position).normalized()
	_fire_arrow_dir(dir, damage, is_piercing)

func _fire_arrow_dir(direction: Vector3, damage: float, is_piercing: bool) -> void:
	var scene: PackedScene = load(ARROW_SCENE)
	if scene == null:
		return
	var arrow: Node3D = scene.instantiate()
	get_tree().current_scene.add_child(arrow)
	arrow.global_position = global_position + Vector3.UP * 1.4

	if arrow.has_method("initialize"):
		arrow.initialize(direction, damage, self, is_piercing)

func _gain_focus(amount: float) -> void:
	_focus = minf(_focus + amount, _max_focus)

func get_focus_ratio() -> float:
	return _focus / _max_focus
