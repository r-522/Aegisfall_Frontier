class_name SpikeBarricade
extends TowerBase
## 接触した敵にスパイクダメージを与え続ける防衛バリケード

const SPIKE_DAMAGE: float = 20.0
const SPIKE_INTERVAL: float = 0.5

@onready var _spike_area: Area3D = $SpikeArea

var _enemies_in_contact: Array[Node] = []
var _spike_timer: float = 0.0

func _ready() -> void:
	add_to_group(&"towers_defense")
	super._ready()

func _on_placed() -> void:
	_setup_spike_area()
	if animation_player and animation_player.has_animation("idle"):
		animation_player.play("idle")

func _setup_spike_area() -> void:
	if _spike_area != null:
		_spike_area.body_entered.connect(_on_body_entered)
		_spike_area.body_exited.connect(_on_body_exited)
		return
	# シーンにSpikeAreaが存在しない場合のフォールバック
	var area := Area3D.new()
	area.name = "SpikeArea"
	area.collision_layer = 0
	area.collision_mask = 1 << 2  # Enemiesレイヤー
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.0, 1.0, 2.0)
	shape.shape = box
	area.add_child(shape)
	add_child(area)
	_spike_area = area
	_spike_area.body_entered.connect(_on_body_entered)
	_spike_area.body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	_spike_timer -= delta
	if _spike_timer <= 0.0:
		_spike_timer = SPIKE_INTERVAL
		_apply_spike_damage()

func _apply_spike_damage() -> void:
	# 無効参照を先に除去
	_enemies_in_contact = _enemies_in_contact.filter(
		func(n: Node) -> bool: return is_instance_valid(n)
	)

	for enemy in _enemies_in_contact:
		var hc: HealthComponent = enemy.find_child("HealthComponent") as HealthComponent
		if hc and not hc.is_dead:
			hc.take_damage(SPIKE_DAMAGE, self)
			EventBus.enemy_took_damage.emit(enemy, SPIKE_DAMAGE)

	if _enemies_in_contact.size() > 0 and animation_player and animation_player.has_animation("spike"):
		animation_player.play("spike")

func _on_body_entered(body: Node) -> void:
	if body.is_in_group(&"enemies") and not _enemies_in_contact.has(body):
		_enemies_in_contact.append(body)

func _on_body_exited(body: Node) -> void:
	_enemies_in_contact.erase(body)
