class_name EnemyAIBase
extends RefCounted
## 全敵AIの基底クラス — ステートマシンの共通インタフェースを定義
## サブクラスはtick()をオーバーライドして固有行動を実装する

enum State {
	IDLE,
	CHASE,
	ATTACK,
	FLEE,
	SPECIAL,
}

var _owner: EnemyBase
var _enemy_data: EnemyData
var _aggro: AggroComponent
var _nav: NavigationAgent3D
var _state: State = State.IDLE
var _special_timer: float = 0.0

## 初期化 — _ready()後にEnemyBaseから呼ばれる
func initialize(owner_node: EnemyBase, data: EnemyData, aggro: AggroComponent, nav: NavigationAgent3D) -> void:
	_owner = owner_node
	_enemy_data = data
	_aggro = aggro
	_nav = nav

## 毎フレーム呼ばれるメインループ — サブクラスでオーバーライド
func tick(delta: float) -> void:
	_special_timer = maxf(0.0, _special_timer - delta)
	var target := _aggro.current_target if _aggro else null

	match _state:
		State.IDLE:
			_tick_idle(delta, target)
		State.CHASE:
			_tick_chase(delta, target)
		State.ATTACK:
			_tick_attack(delta, target)
		State.FLEE:
			_tick_flee(delta, target)
		State.SPECIAL:
			_tick_special(delta, target)

func _tick_idle(_delta: float, target: Node) -> void:
	if target != null and is_instance_valid(target):
		_state = State.CHASE

func _tick_chase(delta: float, target: Node) -> void:
	if target == null or not is_instance_valid(target):
		_state = State.IDLE
		return

	_navigate_toward(target.global_position)

	if _enemy_data and _owner.global_position.distance_to(target.global_position) <= _enemy_data.attack_range:
		_state = State.ATTACK

func _tick_attack(_delta: float, target: Node) -> void:
	if target == null or not is_instance_valid(target):
		_state = State.IDLE
		return

	_owner.try_attack(target)

	if _enemy_data and _owner.global_position.distance_to(target.global_position) > _enemy_data.attack_range * 1.2:
		_state = State.CHASE

func _tick_flee(_delta: float, _target: Node) -> void:
	pass

func _tick_special(_delta: float, _target: Node) -> void:
	pass

## ナビゲーションエージェント経由で目標地点へ移動ベクトルを送る
func _navigate_toward(target_position: Vector3) -> void:
	if _nav == null or not is_instance_valid(_nav):
		return
	_nav.target_position = target_position
	if _nav.is_navigation_finished():
		return
	var speed := _enemy_data.move_speed if _enemy_data else 3.0
	if _owner.status_effect_component:
		speed *= _owner.status_effect_component.get_speed_multiplier()
	var next_pos := _nav.get_next_path_position()
	var direction := (_owner.global_position.direction_to(next_pos))
	direction.y = 0.0
	_nav.set_velocity(direction.normalized() * speed)
