class_name TowerBase
extends StaticBody3D
## 全タワーの基底クラス

@onready var health_component: HealthComponent = $HealthComponent
@onready var aggro_component: AggroComponent = $AggroComponent
@onready var tower_component: TowerComponent = $TowerComponent
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var tower_data: TowerData

var _tower_level: int = 1

func _ready() -> void:
	add_to_group(&"towers")
	_apply_tower_data()
	_connect_signals()
	_on_placed()

func _apply_tower_data() -> void:
	if tower_data == null:
		return
	health_component.max_health = tower_data.max_health
	if aggro_component:
		aggro_component.detection_radius = tower_data.attack_range * 1.2
	if tower_component:
		tower_component.tower_data = tower_data

func _connect_signals() -> void:
	health_component.died.connect(_on_destroyed)
	if tower_component:
		tower_component.fired.connect(_on_fired)
	health_component.damage_taken.connect(_on_damage_taken)

func _on_placed() -> void:
	pass  # オーバーライド可能

func _on_fired(target: Node, damage: float) -> void:
	_spawn_projectile(target, damage)

func _spawn_projectile(target: Node, damage: float) -> void:
	pass  # 攻撃タワーでオーバーライド

func _on_destroyed() -> void:
	EventBus.tower_destroyed.emit(self)
	if animation_player:
		animation_player.play("destroy")
	await get_tree().create_timer(1.5).timeout
	if is_instance_valid(self):
		queue_free()

func _on_damage_taken(amount: float, _source: Node) -> void:
	EventBus.tower_took_damage.emit(self, amount)

func upgrade() -> bool:
	if tower_data == null:
		return false
	_tower_level += 1
	tower_data.attack_damage *= 1.3
	tower_data.max_health *= 1.2
	health_component.set_max_health(tower_data.max_health)
	EventBus.tower_upgraded.emit(self, _tower_level)
	return true

func get_level() -> int:
	return _tower_level
