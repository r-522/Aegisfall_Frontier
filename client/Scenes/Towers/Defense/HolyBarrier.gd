class_name HolyBarrier
extends TowerBase
## 神聖な光で周囲のプレイヤーを定期的に回復する防衛タワー

const HEAL_RADIUS: float = 4.0
const HEAL_AMOUNT: float = 15.0
const HEAL_INTERVAL: float = 3.0

@onready var _heal_area: Area3D = $HealArea

var _heal_timer: float = HEAL_INTERVAL

func _ready() -> void:
	add_to_group(&"towers_defense")
	super._ready()

func _on_placed() -> void:
	_setup_heal_area()
	if animation_player and animation_player.has_animation("idle_glow"):
		animation_player.play("idle_glow")

func _setup_heal_area() -> void:
	# HealArea が存在しない場合はランタイムで生成
	if _heal_area != null:
		return
	var area := Area3D.new()
	area.name = "HealArea"
	area.collision_layer = 0
	area.collision_mask = 1 << 1  # Playersレイヤー
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = HEAL_RADIUS
	shape.shape = sphere
	area.add_child(shape)
	add_child(area)
	_heal_area = area

func _physics_process(delta: float) -> void:
	_heal_timer -= delta
	if _heal_timer <= 0.0:
		_heal_timer = HEAL_INTERVAL
		_apply_heal_to_nearby_players()

func _apply_heal_to_nearby_players() -> void:
	if _heal_area == null:
		return

	var bodies := _heal_area.get_overlapping_bodies()
	for body in bodies:
		if not is_instance_valid(body):
			continue
		if not body.is_in_group(&"players"):
			continue
		var hc: HealthComponent = body.find_child("HealthComponent") as HealthComponent
		if hc and not hc.is_dead:
			hc.heal(HEAL_AMOUNT)
			EventBus.player_healed.emit(body.get_multiplayer_authority(), HEAL_AMOUNT)

	if animation_player and animation_player.has_animation("heal_pulse"):
		animation_player.play("heal_pulse")
