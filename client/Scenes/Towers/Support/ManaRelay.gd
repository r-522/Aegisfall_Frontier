class_name ManaRelay
extends TowerBase
## 周囲のプレイヤーにマナを供給し、近接タワーの攻撃速度を15%向上させる支援タワー

const MANA_RESTORE_INTERVAL: float = 2.0
const DEFAULT_MANA_RESTORE: float = 10.0
const DEFAULT_BUFF_RADIUS: float = 7.0
const ATTACK_SPEED_BONUS: float = 0.15  # +15%

var _mana_timer: float = 0.0
var _buff_radius: float = DEFAULT_BUFF_RADIUS
var _buffed_towers: Array[Node] = []
var _buff_area: Area3D = null

func _ready() -> void:
	add_to_group(&"towers_support")
	super._ready()

func _on_placed() -> void:
	if tower_data:
		_buff_radius = tower_data.buff_radius if tower_data.buff_radius > 0.0 else DEFAULT_BUFF_RADIUS

	_setup_buff_area()
	_apply_tower_speed_buff()

	if animation_player and animation_player.has_animation("idle_relay"):
		animation_player.play("idle_relay")

func _setup_buff_area() -> void:
	_buff_area = find_child("BuffArea") as Area3D
	if _buff_area != null:
		_buff_area.body_entered.connect(_on_body_entered)
		_buff_area.body_exited.connect(_on_body_exited)
		return

	var area := Area3D.new()
	area.name = "BuffArea"
	area.collision_layer = 0
	area.collision_mask = (1 << 1) | (1 << 3)  # Players + Towers
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = _buff_radius
	shape.shape = sphere
	area.add_child(shape)
	add_child(area)
	_buff_area = area
	_buff_area.body_entered.connect(_on_body_entered)
	_buff_area.body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	_mana_timer -= delta
	if _mana_timer <= 0.0:
		_mana_timer = MANA_RESTORE_INTERVAL
		_restore_mana_to_nearby_players()

## 起動時および範囲変化時に付近のタワーに攻撃速度バフを付与
func _apply_tower_speed_buff() -> void:
	if _buff_area == null:
		return
	var bodies := _buff_area.get_overlapping_bodies()
	for body in bodies:
		if is_instance_valid(body) and body.is_in_group(&"towers") and body != self:
			_buff_tower(body)

func _buff_tower(tower: Node) -> void:
	if not is_instance_valid(tower) or _buffed_towers.has(tower):
		return
	# TowerComponent の attack_cooldown を短縮することで攻撃速度を向上させる
	var tc: TowerComponent = tower.find_child("TowerComponent") as TowerComponent
	if tc and tc.tower_data:
		tc.tower_data.attack_cooldown = maxf(
			tc.tower_data.attack_cooldown * (1.0 - ATTACK_SPEED_BONUS),
			0.1
		)
	_buffed_towers.append(tower)

func _unbuff_tower(tower: Node) -> void:
	if not _buffed_towers.has(tower):
		return
	# バフを解除して元の攻撃速度に戻す (逆算)
	var tc: TowerComponent = tower.find_child("TowerComponent") as TowerComponent
	if tc and tc.tower_data:
		tc.tower_data.attack_cooldown = tc.tower_data.attack_cooldown / (1.0 - ATTACK_SPEED_BONUS)
	_buffed_towers.erase(tower)

func _restore_mana_to_nearby_players() -> void:
	if _buff_area == null:
		return
	var mana_amount: float = tower_data.mana_restore_per_tick if tower_data and tower_data.mana_restore_per_tick > 0.0 else DEFAULT_MANA_RESTORE
	var bodies := _buff_area.get_overlapping_bodies()
	for body in bodies:
		if not is_instance_valid(body):
			continue
		if not body.is_in_group(&"players"):
			continue
		var mc: ManaComponent = body.find_child("ManaComponent") as ManaComponent
		if mc:
			mc.restore(mana_amount)

	if animation_player and animation_player.has_animation("relay_pulse"):
		animation_player.play("relay_pulse")

func _on_body_entered(body: Node) -> void:
	if is_instance_valid(body) and body.is_in_group(&"towers") and body != self:
		_buff_tower(body)

func _on_body_exited(body: Node) -> void:
	if _buffed_towers.has(body):
		_unbuff_tower(body)

func _on_destroyed() -> void:
	# 破壊時にバフを解除してから消去
	for tower in _buffed_towers.duplicate():
		_unbuff_tower(tower)
	super._on_destroyed()

func _spawn_projectile(_target: Node, _damage: float) -> void:
	pass  # 支援タワーは攻撃しない
