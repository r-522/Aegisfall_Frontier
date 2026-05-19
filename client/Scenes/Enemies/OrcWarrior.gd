class_name OrcWarrior
extends EnemyBase
## Orc Warrior — タフな近接戦士・バトルクライで強化可能

const BATTLE_CRY_COOLDOWN: float = 20.0
const BATTLE_CRY_RADIUS: float = 10.0
const BATTLE_CRY_BUFF_DURATION: float = 8.0

var _battle_cry_timer: float = 0.0
var _in_rage: bool = false

func _ready() -> void:
	super._ready()
	add_to_group(&"enemies_orc")

func _create_ai() -> EnemyAIBase:
	return TankAI.new()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_battle_cry_timer = maxf(0.0, _battle_cry_timer - delta)

	if health_component and not health_component.is_dead:
		if health_component.get_health_ratio() < 0.5 and not _in_rage:
			_activate_rage()

func _activate_rage() -> void:
	_in_rage = true
	if enemy_data:
		enemy_data.attack_damage *= 1.5
		enemy_data.move_speed *= 1.2
	if animation_player:
		animation_player.play("rage")
	_battle_cry(global_position)

func _battle_cry(from_pos: Vector3) -> void:
	if _battle_cry_timer > 0.0:
		return
	_battle_cry_timer = BATTLE_CRY_COOLDOWN

	var allies := get_tree().get_nodes_in_group(&"enemies_orc")
	for ally in allies:
		if is_instance_valid(ally) and from_pos.distance_to(ally.global_position) <= BATTLE_CRY_RADIUS:
			var status: StatusEffectComponent = ally.find_child("StatusEffectComponent")
			if status:
				status.apply_effect(StatusEffectComponent.EFFECT_HASTE, BATTLE_CRY_BUFF_DURATION, 0.3)
