class_name FlyingAI
extends EnemyAIBase
## フライングAI — ナビメッシュを使わず直線飛行でターゲットへ向かう
## 高さを維持しながら水平方向にターゲットへ接近する

func tick(delta: float) -> void:
	_special_timer = maxf(0.0, _special_timer - delta)
	var target := _aggro.current_target if _aggro else null

	match _state:
		State.IDLE:
			_tick_idle(delta, target)
		State.CHASE:
			_tick_fly_chase(delta, target)
		State.ATTACK:
			_tick_attack(delta, target)
		State.FLEE:
			_tick_flee(delta, target)

func _tick_fly_chase(delta: float, target: Node) -> void:
	if target == null or not is_instance_valid(target):
		_state = State.IDLE
		return

	var speed := _enemy_data.move_speed if _enemy_data else 4.0
	if _owner.status_effect_component:
		speed *= _owner.status_effect_component.get_speed_multiplier()

	# 目標位置: ターゲットの真上の飛行高度
	var fly_height := _enemy_data.fly_height if _enemy_data else 3.0
	var target_pos := target.global_position
	var desired_pos := Vector3(target_pos.x, target_pos.y + fly_height, target_pos.z)

	var direction := _owner.global_position.direction_to(desired_pos)
	_owner.velocity = direction * speed
	_owner.move_and_slide()

	var dist_xz := Vector2(_owner.global_position.x - target_pos.x, _owner.global_position.z - target_pos.z).length()
	var attack_range := _enemy_data.attack_range if _enemy_data else 2.0
	if dist_xz <= attack_range:
		_state = State.ATTACK

func _tick_attack(_delta: float, target: Node) -> void:
	if target == null or not is_instance_valid(target):
		_state = State.IDLE
		return

	_owner.try_attack(target)

	var dist_xz := Vector2(
		_owner.global_position.x - target.global_position.x,
		_owner.global_position.z - target.global_position.z
	).length()
	var attack_range := _enemy_data.attack_range if _enemy_data else 2.0
	if dist_xz > attack_range * 1.2:
		_state = State.CHASE
