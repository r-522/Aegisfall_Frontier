class_name BuffTotem
extends TowerBase
## 範囲内のプレイヤーに EFFECT_HASTE を付与し続ける支援トーテム
## 1秒ごとに判定してバフを付与・除去する

const CHECK_INTERVAL: float = 1.0
const HASTE_BONUS: float = 0.2   # 移動速度 +20%
const HASTE_DURATION: float = 1.5  # チェック間隔より若干長く設定して途切れを防ぐ
const DEFAULT_BUFF_RADIUS: float = 6.0

var _buff_radius: float = DEFAULT_BUFF_RADIUS
var _check_timer: float = 0.0
var _buff_area: Area3D = null
var _buffed_players: Array[Node] = []

func _ready() -> void:
	add_to_group(&"towers_support")
	super._ready()

func _on_placed() -> void:
	if tower_data:
		_buff_radius = tower_data.buff_radius if tower_data.buff_radius > 0.0 else DEFAULT_BUFF_RADIUS

	_setup_buff_area()

	if animation_player and animation_player.has_animation("idle_totem"):
		animation_player.play("idle_totem")

func _setup_buff_area() -> void:
	_buff_area = find_child("BuffArea") as Area3D
	if _buff_area != null:
		_buff_area.body_entered.connect(_on_body_entered)
		_buff_area.body_exited.connect(_on_body_exited)
		return

	var area := Area3D.new()
	area.name = "BuffArea"
	area.collision_layer = 0
	area.collision_mask = 1 << 1  # Playersレイヤー
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
	_check_timer -= delta
	if _check_timer <= 0.0:
		_check_timer = CHECK_INTERVAL
		_refresh_buffs()

func _refresh_buffs() -> void:
	# 無効参照を除去
	_buffed_players = _buffed_players.filter(func(p: Node) -> bool: return is_instance_valid(p))

	for player in _buffed_players:
		var sec: StatusEffectComponent = player.find_child("StatusEffectComponent") as StatusEffectComponent
		if sec:
			# 継続して範囲内にいるプレイヤーはバフを更新する
			sec.apply_effect(
				StatusEffectComponent.EFFECT_HASTE,
				HASTE_DURATION,
				HASTE_BONUS
			)

	if animation_player and animation_player.has_animation("totem_pulse"):
		animation_player.play("totem_pulse")

func _apply_haste(player: Node) -> void:
	var sec: StatusEffectComponent = player.find_child("StatusEffectComponent") as StatusEffectComponent
	if sec:
		sec.apply_effect(
			StatusEffectComponent.EFFECT_HASTE,
			HASTE_DURATION,
			HASTE_BONUS
		)

func _remove_haste(player: Node) -> void:
	if not is_instance_valid(player):
		return
	var sec: StatusEffectComponent = player.find_child("StatusEffectComponent") as StatusEffectComponent
	if sec and sec.has_effect(StatusEffectComponent.EFFECT_HASTE):
		sec.remove_effect(StatusEffectComponent.EFFECT_HASTE)

func _on_body_entered(body: Node) -> void:
	if not is_instance_valid(body) or not body.is_in_group(&"players"):
		return
	if not _buffed_players.has(body):
		_buffed_players.append(body)
		_apply_haste(body)

func _on_body_exited(body: Node) -> void:
	if _buffed_players.has(body):
		_buffed_players.erase(body)
		_remove_haste(body)

func _on_destroyed() -> void:
	# 破壊時にバフを解除
	for player in _buffed_players.duplicate():
		_remove_haste(player)
	super._on_destroyed()

func _spawn_projectile(_target: Node, _damage: float) -> void:
	pass  # 支援タワーは攻撃しない
