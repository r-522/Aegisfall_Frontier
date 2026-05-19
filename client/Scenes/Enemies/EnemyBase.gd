class_name EnemyBase
extends CharacterBody3D
## 全敵ユニットの基底クラス
## コンポーネント連携・ナビゲーション・AI委譲・死亡処理を担当
## 固有AI生成とダメージ処理はサブクラスでオーバーライド

@onready var health_component: HealthComponent = $HealthComponent
@onready var aggro_component: AggroComponent = $AggroComponent
@onready var status_effect_component: StatusEffectComponent = $StatusEffectComponent
@onready var hit_stop_component: HitStopComponent = $HitStopComponent
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var enemy_data: EnemyData
## マルチプレイヤー: この敵を制御するピアID
@export var player_id_authority: int = 1

var _ai: EnemyAIBase
var _attack_timer: float = 0.0
var _is_dead: bool = false

func _ready() -> void:
	add_to_group(&"enemies")
	if enemy_data:
		health_component.max_health = enemy_data.max_health
		health_component.defense = enemy_data.defense
		aggro_component.detection_radius = enemy_data.detection_range
		aggro_component.target_priority = enemy_data.target_priority
	health_component.died.connect(_on_died)
	health_component.damage_taken.connect(_on_damage_taken)
	nav_agent.velocity_computed.connect(_on_velocity_computed)
	_ai = _create_ai()
	if _ai:
		_ai.initialize(self, enemy_data, aggro_component, nav_agent)

func _physics_process(delta: float) -> void:
	if _is_dead:
		return
	_attack_timer = maxf(0.0, _attack_timer - delta)
	if _ai:
		_ai.tick(delta)

func _on_velocity_computed(safe_velocity: Vector3) -> void:
	velocity = safe_velocity
	move_and_slide()

## AIインスタンスを生成して返す — サブクラスでオーバーライド
func _create_ai() -> EnemyAIBase:
	return EnemyAIBase.new()

## 攻撃を試みる。クールダウン中・射程外なら何もしない
func try_attack(target: Node) -> void:
	if _attack_timer > 0.0 or target == null or not is_instance_valid(target):
		return
	if enemy_data == null:
		return
	var dist := global_position.distance_to(target.global_position)
	if dist > enemy_data.attack_range:
		return
	_attack_timer = enemy_data.attack_cooldown
	_on_attack_target(target)

## 実際のダメージ処理 — サブクラスでオーバーライド可
func _on_attack_target(target: Node) -> void:
	var health: HealthComponent = target.find_child("HealthComponent")
	if health == null:
		return
	var damage := enemy_data.attack_damage if enemy_data else 10.0
	if target.is_in_group(&"towers") and enemy_data and enemy_data.can_attack_structures:
		damage *= enemy_data.structure_damage_multiplier
	var actual := health.take_damage(damage, self)
	if actual > 0.0:
		if animation_player:
			animation_player.play("attack")
		EventBus.hit_confirmed.emit(self, target, actual, false)

func _on_died() -> void:
	_is_dead = true
	if animation_player:
		animation_player.play("death")
	if enemy_data:
		EventBus.enemy_died.emit(self, global_position, enemy_data.xp_reward)
		EventBus.resources_changed.emit(0, enemy_data.gold_reward)
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(self):
		queue_free()

func _on_damage_taken(amount: float, source: Node) -> void:
	if hit_stop_component:
		hit_stop_component.trigger_normal_hit_stop()
	EventBus.enemy_took_damage.emit(self, amount)
