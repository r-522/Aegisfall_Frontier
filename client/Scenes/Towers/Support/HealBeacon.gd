class_name HealBeacon
extends TowerBase
## 周囲のプレイヤーを定期的に回復し、微量のマナも回復する支援タワー
## TowerComponent・AggroComponent は使用しない

const DEFAULT_TICK_RATE: float = 2.0
const DEFAULT_HEAL: float = 20.0
const DEFAULT_MANA: float = 5.0
const DEFAULT_RADIUS: float = 6.0

var tick_rate: float = DEFAULT_TICK_RATE
var buff_radius: float = DEFAULT_RADIUS

var _tick_timer: float = 0.0
var _buff_area: Area3D = null

func _ready() -> void:
	add_to_group(&"towers_support")
	super._ready()

func _on_placed() -> void:
	# TowerData の値で上書き
	if tower_data:
		tick_rate = tower_data.buff_tick_rate if tower_data.buff_tick_rate > 0.0 else DEFAULT_TICK_RATE
		buff_radius = tower_data.buff_radius if tower_data.buff_radius > 0.0 else DEFAULT_RADIUS

	_setup_buff_area()

	if animation_player and animation_player.has_animation("idle_glow"):
		animation_player.play("idle_glow")

func _setup_buff_area() -> void:
	# シーンに BuffArea がある場合はそれを使用、なければ動的生成
	_buff_area = find_child("BuffArea") as Area3D
	if _buff_area != null:
		return

	var area := Area3D.new()
	area.name = "BuffArea"
	area.collision_layer = 0
	area.collision_mask = 1 << 1  # Playersレイヤー
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = buff_radius
	shape.shape = sphere
	area.add_child(shape)
	add_child(area)
	_buff_area = area

func _physics_process(delta: float) -> void:
	_tick_timer -= delta
	if _tick_timer <= 0.0:
		_tick_timer = tick_rate
		_apply_buffs()

func _apply_buffs() -> void:
	if _buff_area == null:
		return

	var heal_amount: float = tower_data.heal_per_tick if tower_data and tower_data.heal_per_tick > 0.0 else DEFAULT_HEAL
	var mana_amount: float = tower_data.mana_restore_per_tick if tower_data and tower_data.mana_restore_per_tick > 0.0 else DEFAULT_MANA

	var bodies := _buff_area.get_overlapping_bodies()
	for body in bodies:
		if not is_instance_valid(body):
			continue
		if not body.is_in_group(&"players"):
			continue

		# HP 回復
		var hc: HealthComponent = body.find_child("HealthComponent") as HealthComponent
		if hc and not hc.is_dead and not hc.is_full_health():
			hc.heal(heal_amount)
			EventBus.player_healed.emit(body.get_multiplayer_authority(), heal_amount)

		# マナ回復
		var mc: ManaComponent = body.find_child("ManaComponent") as ManaComponent
		if mc:
			mc.restore(mana_amount)

	if animation_player and animation_player.has_animation("heal_pulse"):
		animation_player.play("heal_pulse")

func _spawn_projectile(_target: Node, _damage: float) -> void:
	pass  # 支援タワーは攻撃しない
