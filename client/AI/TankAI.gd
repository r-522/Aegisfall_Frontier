class_name TankAI
extends EnemyAIBase
## タンクAI — 重装甲でゆっくり前進し、一定距離でチャージ突撃する

const CHARGE_RANGE: float = 8.0
const CHARGE_COOLDOWN: float = 6.0
const CHARGE_DURATION: float = 0.6
const CHARGE_SPEED_MULT: float = 3.5

var _charge_cooldown: float = 0.0
var _is_charging: bool = false
var _charge_timer: float = 0.0
var _charge_direction: Vector3 = Vector3.ZERO

func tick(delta: float) -> void:
	_charge_cooldown = maxf(0.0, _charge_cooldown - delta)

	if _is_charging:
		_update_charge(delta)
		return

	super.tick(delta)

func _tick_chase(delta: float, target: Node) -> void:
	if target == null or not is_instance_valid(target):
		_state = State.IDLE
		return

	var dist := _owner.global_position.distance_to(target.global_position)

	# チャージ可能距離に入っていてクールダウンが明けていれば突撃
	if dist <= CHARGE_RANGE and dist > (_enemy_data.attack_range if _enemy_data else 1.5) and _charge_cooldown <= 0.0:
		_begin_charge(target)
		return

	_navigate_toward(target.global_position)

	if _enemy_data and dist <= _enemy_data.attack_range:
		_state = State.ATTACK

func _begin_charge(target: Node) -> void:
	_is_charging = true
	_charge_timer = CHARGE_DURATION
	_charge_direction = _owner.global_position.direction_to(target.global_position)
	_charge_direction.y = 0.0
	_charge_direction = _charge_direction.normalized()
	_charge_cooldown = CHARGE_COOLDOWN
	if _owner.animation_player:
		_owner.animation_player.play("charge")

func _update_charge(delta: float) -> void:
	_charge_timer -= delta
	var speed := (_enemy_data.move_speed if _enemy_data else 3.0) * CHARGE_SPEED_MULT
	_owner.velocity = _charge_direction * speed
	_owner.move_and_slide()

	# チャージ中に当たった対象にダメージ
	for i in _owner.get_slide_collision_count():
		var col := _owner.get_slide_collision(i)
		var collider := col.get_collider()
		if collider and is_instance_valid(collider) and collider != _owner:
			if collider.is_in_group(&"players") or collider.is_in_group(&"towers"):
				_owner.try_attack(collider)

	if _charge_timer <= 0.0:
		_is_charging = false
		_state = State.CHASE
