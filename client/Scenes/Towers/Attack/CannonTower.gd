class_name CannonTower
extends TowerBase
## 低速・高威力・中範囲AoEの砲撃タワー

const CANNON_BALL_SCENE := "res://Scenes/Projectiles/CannonBall.tscn"

const AOE_RADIUS: float = 3.5
## TowerData の attack_cooldown を上書きする固有クールダウン
const BASE_COOLDOWN: float = 3.0

func _ready() -> void:
	add_to_group(&"towers_attack")
	super._ready()

func _apply_tower_data() -> void:
	super._apply_tower_data()
	# 大砲は攻撃速度を固定値で上書き
	if tower_data:
		tower_data.attack_cooldown = BASE_COOLDOWN

func _on_placed() -> void:
	if animation_player and animation_player.has_animation("idle"):
		animation_player.play("idle")

func _spawn_projectile(target: Node, damage: float) -> void:
	if not ResourceLoader.exists(CANNON_BALL_SCENE):
		push_warning("CannonTower: CannonBall.tscn が見つかりません: " + CANNON_BALL_SCENE)
		_apply_aoe_at(target.global_position, damage)
		return

	var ball_res: PackedScene = load(CANNON_BALL_SCENE)
	if ball_res == null:
		return

	var ball: Node3D = ball_res.instantiate()
	get_tree().current_scene.add_child(ball)
	ball.global_position = global_position + Vector3.UP * 1.0

	var speed: float = tower_data.projectile_speed if tower_data else 18.0
	if ball.has_method("initialize"):
		ball.initialize(target, damage, speed, AOE_RADIUS)

	if ball.has_signal("exploded"):
		ball.exploded.connect(_on_ball_exploded.bind(damage))

	if animation_player and animation_player.has_animation("fire"):
		animation_player.play("fire")

func _on_ball_exploded(explosion_position: Vector3, damage: float) -> void:
	_apply_aoe_at(explosion_position, damage)

func _apply_aoe_at(center: Vector3, damage: float) -> void:
	var enemies := get_tree().get_nodes_in_group(&"enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if enemy.global_position.distance_to(center) > AOE_RADIUS:
			continue
		var hc: HealthComponent = enemy.find_child("HealthComponent") as HealthComponent
		if hc and not hc.is_dead:
			hc.take_damage(damage, self)
			EventBus.enemy_took_damage.emit(enemy, damage)
