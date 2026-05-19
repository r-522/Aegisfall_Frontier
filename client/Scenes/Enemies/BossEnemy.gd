class_name BossEnemy
extends EnemyBase
## Boss Enemy — 3フェーズ制で行動が変化する強敵

signal phase_changed(new_phase: int)

const PHASE_2_THRESHOLD: float = 0.6
const PHASE_3_THRESHOLD: float = 0.3

var _current_phase: int = 1
var _phase_attack_timer: float = 0.0
const PHASE_ATTACK_COOLDOWN: float = 8.0
var _special_cooldown: float = 0.0

func _ready() -> void:
	super._ready()
	add_to_group(&"enemies_boss")
	health_component.health_changed.connect(_check_phase_transition)
	EventBus.boss_spawned.emit(self)

func _create_ai() -> EnemyAIBase:
	return EnemyAIBase.new()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_phase_attack_timer = maxf(0.0, _phase_attack_timer - delta)
	_special_cooldown = maxf(0.0, _special_cooldown - delta)

	if _phase_attack_timer <= 0.0:
		_phase_attack_timer = PHASE_ATTACK_COOLDOWN / float(_current_phase)
		_execute_phase_attack()

func _execute_phase_attack() -> void:
	match _current_phase:
		1: _phase1_attack()
		2: _phase2_attack()
		3: _phase3_attack()

func _phase1_attack() -> void:
	var target := aggro_component.current_target if aggro_component else null
	if target:
		_on_attack_target(target)

func _phase2_attack() -> void:
	var target := aggro_component.current_target if aggro_component else null
	if target:
		_on_attack_target(target)
	_aoe_slam()

func _phase3_attack() -> void:
	var target := aggro_component.current_target if aggro_component else null
	if target:
		_on_attack_target(target)
	_aoe_slam()
	if _special_cooldown <= 0.0:
		_special_cooldown = 12.0
		_summon_minions()

func _aoe_slam() -> void:
	if animation_player:
		animation_player.play("slam")
	var radius := 5.0 * float(_current_phase) * 0.5
	var damage := (enemy_data.attack_damage if enemy_data else 30.0) * 0.8

	var players := get_tree().get_nodes_in_group(&"players")
	for p in players:
		if is_instance_valid(p) and global_position.distance_to(p.global_position) <= radius:
			var health: HealthComponent = p.find_child("HealthComponent")
			if health:
				health.take_damage(damage, self)

func _summon_minions() -> void:
	var scene: PackedScene = load("res://Scenes/Enemies/SwarmEnemy.tscn")
	if scene == null:
		return
	for i in 4:
		var angle := (float(i) / 4.0) * TAU
		var offset := Vector3(cos(angle) * 3.0, 0.0, sin(angle) * 3.0)
		var minion: Node3D = scene.instantiate()
		get_tree().current_scene.add_child(minion)
		minion.global_position = global_position + offset
		EventBus.enemy_spawned.emit(minion)

func _check_phase_transition(current_hp: float, max_hp: float) -> void:
	var ratio := current_hp / max_hp
	var new_phase := 1
	if ratio <= PHASE_3_THRESHOLD:
		new_phase = 3
	elif ratio <= PHASE_2_THRESHOLD:
		new_phase = 2

	if new_phase != _current_phase:
		_current_phase = new_phase
		phase_changed.emit(_current_phase)
		EventBus.boss_phase_changed.emit(self, _current_phase)
		_on_phase_entered(_current_phase)

func _on_phase_entered(phase: int) -> void:
	if animation_player:
		animation_player.play("phase_transition")
	if enemy_data:
		match phase:
			2:
				enemy_data.move_speed *= 1.3
				enemy_data.attack_damage *= 1.2
			3:
				enemy_data.move_speed *= 1.5
				enemy_data.attack_damage *= 1.5
