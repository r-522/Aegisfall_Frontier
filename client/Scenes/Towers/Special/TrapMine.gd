class_name TrapMine
extends TowerBase
## プレイヤーが設置できる罠地雷 — 敵が近づくと爆発してAoEダメージを与え自壊する

const TRIGGER_RADIUS: float = 2.0
const EXPLOSION_RADIUS: float = 4.0
const DEFAULT_DAMAGE: float = 120.0

var _owner_player: Node = null
var _triggered: bool = false
var _trigger_area: Area3D = null

func _ready() -> void:
	add_to_group(&"towers_special")
	super._ready()

func _on_placed() -> void:
	_setup_trigger_area()

	# 設置直後はわずかに無敵 (誤爆防止)
	if animation_player and animation_player.has_animation("arm"):
		animation_player.play("arm")

## 設置したプレイヤーノードを登録する
func set_owner_player(player: Node) -> void:
	_owner_player = player

func _setup_trigger_area() -> void:
	_trigger_area = find_child("TriggerArea") as Area3D
	if _trigger_area != null:
		_trigger_area.body_entered.connect(_on_trigger_body_entered)
		return

	var area := Area3D.new()
	area.name = "TriggerArea"
	area.collision_layer = 0
	area.collision_mask = 1 << 2  # Enemiesレイヤー
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = TRIGGER_RADIUS
	shape.shape = sphere
	area.add_child(shape)
	add_child(area)
	_trigger_area = area
	_trigger_area.body_entered.connect(_on_trigger_body_entered)

func _on_trigger_body_entered(body: Node) -> void:
	if _triggered:
		return
	if not is_instance_valid(body) or not body.is_in_group(&"enemies"):
		return
	_explode()

func _explode() -> void:
	if _triggered:
		return
	_triggered = true

	# トリガーエリアを即時無効化して二重起爆を防ぐ
	if is_instance_valid(_trigger_area):
		_trigger_area.monitoring = false

	var explosion_center := global_position
	var damage: float = tower_data.attack_damage if tower_data else DEFAULT_DAMAGE
	var radius: float = EXPLOSION_RADIUS

	# 範囲内の全敵にダメージ
	var enemies := get_tree().get_nodes_in_group(&"enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if enemy.global_position.distance_to(explosion_center) > radius:
			continue
		var hc: HealthComponent = enemy.find_child("HealthComponent") as HealthComponent
		if hc and not hc.is_dead:
			hc.take_damage(damage, self if _owner_player == null else _owner_player)
			EventBus.enemy_took_damage.emit(enemy, damage)

	EventBus.field_event_triggered.emit(&"mine_explosion", explosion_center)

	if animation_player and animation_player.has_animation("explode"):
		animation_player.play("explode")
		await animation_player.animation_finished
	elif is_instance_valid(self):
		await get_tree().create_timer(0.3).timeout

	if is_instance_valid(self):
		queue_free()

func _spawn_projectile(_target: Node, _damage: float) -> void:
	pass  # 罠タワーは通常攻撃しない
