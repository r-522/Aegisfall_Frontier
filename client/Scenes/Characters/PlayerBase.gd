class_name PlayerBase
extends CharacterBody3D
## 全プレイヤークラスの基底クラス
## 移動・カメラ・入力ハンドリング・コンポーネント連携を担当
## スキル発動とクラス固有攻撃はサブクラスでオーバーライド

@onready var health_component: HealthComponent = $HealthComponent
@onready var mana_component: ManaComponent = $ManaComponent
@onready var skill_component: SkillComponent = $SkillComponent
@onready var hit_stop_component: HitStopComponent = $HitStopComponent
@onready var status_effect_component: StatusEffectComponent = $StatusEffectComponent
@onready var move_component: MoveComponent = $MoveComponent
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var hitbox_area: Area3D = $HitboxArea

@export var character_data: CharacterData
@export var player_id: int = 1

var is_local_player: bool = false

enum State {
	IDLE,
	MOVING,
	JUMPING,
	FALLING,
	DASHING,
	CROUCHING,
	ATTACKING,
	HEAVY_ATTACKING,
	CASTING,
	DEAD
}

var _state: State = State.IDLE
var _attack_timer: float = 0.0
var _combo_count: int = 0
var _combo_reset_timer: float = 0.0
var _level: int = 1
var _experience: int = 0

const COMBO_RESET_TIME: float = 0.8
const CAMERA_MOUSE_SENSITIVITY_MULT: float = 1.0

func _ready() -> void:
	add_to_group(&"players")
	_setup_multiplayer()
	_apply_character_data()
	_connect_signals()
	if is_local_player:
		camera.make_current()
		camera.fov = GameConfig.camera_fov
		InputMapper.capture_mouse()

func _setup_multiplayer() -> void:
	if multiplayer.has_multiplayer_peer():
		is_local_player = (multiplayer.get_unique_id() == player_id)
	else:
		is_local_player = true

	if not is_local_player:
		set_process(false)
		set_physics_process(false)
		if camera:
			camera.current = false

func _apply_character_data() -> void:
	if character_data == null:
		return
	health_component.max_health = character_data.max_health
	health_component.defense = character_data.base_defense
	mana_component.max_mana = character_data.max_mana
	mana_component.regen_rate = character_data.mana_regen_rate
	skill_component.skills = character_data.skills
	move_component.character_data = character_data

func _connect_signals() -> void:
	health_component.died.connect(_on_died)
	health_component.damage_taken.connect(_on_damage_taken)
	skill_component.skill_used.connect(_on_skill_used)
	move_component.landed.connect(_on_landed)
	move_component.dash_started.connect(_on_dash_started)
	move_component.dash_ended.connect(_on_dash_ended)

func _physics_process(delta: float) -> void:
	if _state == State.DEAD:
		return

	_update_attack_timer(delta)
	_update_combo_timer(delta)

	var input_dir := InputMapper.get_move_vector()
	var cam_basis := camera_pivot.global_basis

	move_component.tick(delta, input_dir, cam_basis)

	_handle_jump()
	_handle_dash(input_dir, cam_basis)
	_handle_crouch()
	_handle_attacks()
	_handle_skills()
	_handle_ui_input()

	_update_state(input_dir)
	_update_animation()

	move_and_slide()

func _input(event: InputEvent) -> void:
	if not is_local_player or _state == State.DEAD:
		return
	if event is InputEventMouseMotion and InputMapper.is_mouse_captured():
		_rotate_camera(event.relative)

func _handle_jump() -> void:
	if InputMapper.is_jump_just_pressed() and _state != State.DASHING:
		if move_component.apply_jump():
			_state = State.JUMPING

func _handle_dash(input_dir: Vector2, cam_basis: Basis) -> void:
	if InputMapper.is_dodge_just_pressed():
		move_component.try_dash(input_dir, cam_basis)

func _handle_crouch() -> void:
	if InputMapper.is_crouch_just_pressed():
		if _state == State.CROUCHING:
			_state = State.IDLE
		elif is_on_floor() and _state not in [State.ATTACKING, State.DASHING]:
			_state = State.CROUCHING

func _handle_attacks() -> void:
	if _attack_timer > 0.0:
		return
	if _state in [State.DEAD, State.DASHING]:
		return

	if InputMapper.is_attack_normal_just_pressed():
		_do_normal_attack()
	elif InputMapper.is_attack_heavy_just_pressed():
		_do_heavy_attack()

func _handle_skills() -> void:
	if _state in [State.DEAD, State.DASHING]:
		return
	var slot := InputMapper.get_pressed_skill_slot()
	if slot >= 0:
		skill_component.try_use_skill(slot, mana_component)

func _handle_ui_input() -> void:
	if InputMapper.is_pause_just_pressed():
		EventBus.dialog_started.emit(&"pause_menu")
	if InputMapper.is_inventory_just_pressed():
		EventBus.inventory_opened.emit()
	if InputMapper.is_build_menu_just_pressed():
		EventBus.build_mode_toggled.emit(true)

func _update_state(input_dir: Vector2) -> void:
	if _state == State.DEAD:
		return
	if move_component.is_dashing():
		_state = State.DASHING
		return
	if _state in [State.ATTACKING, State.HEAVY_ATTACKING, State.CASTING]:
		return
	if _state == State.CROUCHING:
		return
	if not is_on_floor():
		_state = State.JUMPING if velocity.y > 0.0 else State.FALLING
		return
	if input_dir.length_squared() > 0.01:
		_state = State.MOVING
	else:
		_state = State.IDLE

func _update_animation() -> void:
	if animation_player == null:
		return
	match _state:
		State.IDLE:
			animation_player.play("idle")
		State.MOVING:
			animation_player.play("walk")
		State.JUMPING:
			animation_player.play("jump")
		State.FALLING:
			animation_player.play("fall")
		State.DASHING:
			animation_player.play("dash")
		State.CROUCHING:
			animation_player.play("crouch_idle")
		State.DEAD:
			animation_player.play("death")

func _update_attack_timer(delta: float) -> void:
	if _attack_timer > 0.0:
		_attack_timer = maxf(0.0, _attack_timer - delta)
		if _attack_timer <= 0.0 and _state in [State.ATTACKING, State.HEAVY_ATTACKING]:
			_state = State.IDLE

func _update_combo_timer(delta: float) -> void:
	if _combo_reset_timer > 0.0:
		_combo_reset_timer -= delta
		if _combo_reset_timer <= 0.0:
			_combo_count = 0

func _rotate_camera(mouse_delta: Vector2) -> void:
	var sensitivity := GameConfig.mouse_sensitivity * CAMERA_MOUSE_SENSITIVITY_MULT
	camera_pivot.rotation.y -= mouse_delta.x * sensitivity
	camera_pivot.rotation.x = clampf(
		camera_pivot.rotation.x - mouse_delta.y * sensitivity,
		-PI / 3.0,
		PI / 4.0
	)

# === オーバーライド対象メソッド ===
func _do_normal_attack() -> void:
	pass

func _do_heavy_attack() -> void:
	pass

func _on_skill_used(index: int, skill_data: SkillData) -> void:
	_execute_skill(index, skill_data)
	EventBus.player_skill_used.emit(player_id, index)

func _execute_skill(index: int, _skill_data: SkillData) -> void:
	pass

# === イベントハンドラ ===
func _on_died() -> void:
	_state = State.DEAD
	if animation_player:
		animation_player.play("death")
	EventBus.player_died.emit(player_id)
	_start_respawn_timer()

func _on_damage_taken(amount: float, source: Node) -> void:
	hit_stop_component.trigger_normal_hit_stop()
	hit_stop_component.trigger_camera_shake()
	EventBus.player_took_damage.emit(player_id, amount, source)

func _on_landed() -> void:
	if animation_player:
		animation_player.play("land")

func _on_dash_started() -> void:
	_state = State.DASHING
	health_component.apply_invincibility(GameConfig.DODGE_INVINCIBILITY_DURATION)

func _on_dash_ended() -> void:
	if _state == State.DASHING:
		_state = State.IDLE

func _start_respawn_timer() -> void:
	await get_tree().create_timer(GameConfig.RESPAWN_DELAY).timeout
	if is_instance_valid(self):
		_respawn()

func _respawn() -> void:
	health_component.heal(health_component.max_health)
	health_component.is_dead = false
	_state = State.IDLE
	EventBus.player_respawned.emit(player_id, global_position)

# === ユーティリティ ===
func get_forward_direction() -> Vector3:
	return -camera_pivot.global_basis.z

func get_aim_target(max_distance: float = 30.0) -> Vector3:
	var ray_origin := camera.global_position
	var ray_dir := -camera.global_basis.z
	var ray_end := ray_origin + ray_dir * max_distance
	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end, 0b0001)
	var result := space_state.intersect_ray(query)
	if result.is_empty():
		return ray_end
	return result.position

func add_experience(amount: int) -> void:
	_experience += amount
	EventBus.xp_gained.emit(player_id, amount)
	var xp_needed := _level * 100
	if _experience >= xp_needed:
		_experience -= xp_needed
		_level += 1
		EventBus.player_level_up.emit(player_id, _level)
