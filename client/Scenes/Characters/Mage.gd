class_name Mage
extends PlayerBase
## Mage — 遠距離魔法攻撃・範囲制圧・タワー強化が特徴
## 属性コンボによるダメージ倍増が固有メカニズム

const PROJECTILE_SCENE := "res://Scenes/Projectiles/MageBolt.tscn"
const ARCANE_BLAST_SCENE := "res://Scenes/Projectiles/ArcaneBlast.tscn"

var _arcane_surge_active: bool = false
var _arcane_surge_timer: float = 0.0
var _frost_nova_available: bool = false

func _ready() -> void:
	add_to_group(&"class_magic")
	super._ready()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _arcane_surge_active:
		_arcane_surge_timer -= delta
		if _arcane_surge_timer <= 0.0:
			_arcane_surge_active = false

func _do_normal_attack() -> void:
	_combo_count = (_combo_count % 2) + 1
	_combo_reset_timer = COMBO_RESET_TIME

	if animation_player:
		animation_player.play("staff_attack_%d" % _combo_count)
	_state = State.ATTACKING
	_attack_timer = 1.0 / character_data.attack_speed

	var damage := character_data.base_attack_damage
	if _arcane_surge_active:
		damage *= 1.5

	_fire_projectile(PROJECTILE_SCENE, damage, get_aim_target())

func _do_heavy_attack() -> void:
	_combo_count = 0
	if animation_player:
		animation_player.play("charged_bolt")
	_state = State.HEAVY_ATTACKING
	_attack_timer = (1.0 / character_data.attack_speed) * 2.0

	var damage := character_data.base_heavy_attack_damage
	if _arcane_surge_active:
		damage *= 1.5

	_fire_projectile(ARCANE_BLAST_SCENE, damage, get_aim_target())
	hit_stop_component.trigger_camera_shake()

func _execute_skill(index: int, skill_data: SkillData) -> void:
	match index:
		0: _skill_fireball(skill_data)
		1: _skill_blink(skill_data)
		2: _skill_frost_nova(skill_data)
		3: _skill_arcane_surge(skill_data)

func _skill_fireball(skill: SkillData) -> void:
	if animation_player:
		animation_player.play("cast_fireball")
	_state = State.CASTING
	_attack_timer = 0.8

	var target_pos := get_aim_target()
	var dmg := skill.damage
	if _arcane_surge_active:
		dmg *= 1.5
	if _frost_nova_available:
		dmg *= 2.0
		_frost_nova_available = false

	_create_fireball(target_pos, dmg, skill.effect_radius)
	hit_stop_component.trigger_camera_shake(0.25)

func _skill_blink(skill: SkillData) -> void:
	if animation_player:
		animation_player.play("blink")

	var target_pos := get_aim_target(8.0)
	var blink_dir := (target_pos - global_position).normalized()
	var blink_dist := minf(target_pos.distance_to(global_position), 8.0)

	global_position += blink_dir * blink_dist
	health_component.apply_invincibility(0.2)

func _skill_frost_nova(skill: SkillData) -> void:
	if animation_player:
		animation_player.play("frost_nova")

	var enemies := get_tree().get_nodes_in_group(&"enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if global_position.distance_to(enemy.global_position) <= skill.effect_radius:
			var status: StatusEffectComponent = enemy.find_child("StatusEffectComponent")
			if status:
				status.apply_effect(StatusEffectComponent.EFFECT_FROZEN, skill.duration, 0.5)
			var health: HealthComponent = enemy.find_child("HealthComponent")
			if health:
				health.take_damage(skill.damage, self)

	_frost_nova_available = true

func _skill_arcane_surge(skill: SkillData) -> void:
	if animation_player:
		animation_player.play("arcane_surge")

	_arcane_surge_active = true
	_arcane_surge_timer = skill.duration

	var towers := get_tree().get_nodes_in_group(&"towers")
	for tower in towers:
		if not is_instance_valid(tower):
			continue
		if global_position.distance_to(tower.global_position) <= skill.effect_radius:
			var tower_comp: TowerComponent = tower.find_child("TowerComponent")
			if tower_comp and tower_comp.tower_data:
				EventBus.status_effect_applied.emit(tower, &"tower_empowered", skill.duration)

	hit_stop_component.trigger_camera_shake(0.3)

func _fire_projectile(scene_path: String, damage: float, target_pos: Vector3) -> void:
	var scene: PackedScene = load(scene_path)
	if scene == null:
		return
	var proj: Node3D = scene.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position + Vector3.UP * 1.2

	if proj.has_method("initialize"):
		proj.initialize(target_pos - proj.global_position, damage, self)

func _create_fireball(target_pos: Vector3, damage: float, radius: float) -> void:
	var scene: PackedScene = load(ARCANE_BLAST_SCENE)
	if scene == null:
		return
	var fireball: Node3D = scene.instantiate()
	get_tree().current_scene.add_child(fireball)
	fireball.global_position = global_position + Vector3.UP * 1.2

	if fireball.has_method("initialize_aoe"):
		fireball.initialize_aoe(target_pos - fireball.global_position, damage, radius, self)
