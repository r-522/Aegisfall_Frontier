class_name Ballista
extends TowerBase
## 直線上の全ての敵を貫通する大型クロスボウタワー

const ARROW_SCENE := "res://Scenes/Projectiles/Arrow.tscn"

@onready var _barrel: Node3D = $Barrel

func _ready() -> void:
	add_to_group(&"towers_attack")
	super._ready()

func _on_placed() -> void:
	if animation_player and animation_player.has_animation("idle"):
		animation_player.play("idle")

func _process(delta: float) -> void:
	if tower_component == null:
		return
	var target := tower_component.get_current_target()
	if target == null or not is_instance_valid(target):
		return
	_rotate_toward_target(target, delta)

func _rotate_toward_target(target: Node, delta: float) -> void:
	var pivot: Node3D = _barrel if is_instance_valid(_barrel) else self
	var direction := (target.global_position - pivot.global_position)
	direction.y = 0.0
	if direction.is_zero_approx():
		return
	var target_basis := Basis.looking_at(direction.normalized(), Vector3.UP)
	pivot.global_basis = pivot.global_basis.slerp(target_basis, clampf(delta * 6.0, 0.0, 1.0))

func _spawn_projectile(target: Node, damage: float) -> void:
	if not ResourceLoader.exists(ARROW_SCENE):
		push_warning("Ballista: Arrow.tscn が見つかりません: " + ARROW_SCENE)
		return

	var arrow_res: PackedScene = load(ARROW_SCENE)
	if arrow_res == null:
		return

	var arrow: Node3D = arrow_res.instantiate()
	get_tree().current_scene.add_child(arrow)
	arrow.global_position = global_position + Vector3.UP * 1.4

	var speed: float = tower_data.projectile_speed if tower_data else 35.0
	if arrow.has_method("initialize"):
		arrow.initialize(target, damage, speed)

	# 貫通フラグを設定
	if "is_piercing" in arrow:
		arrow.is_piercing = true

	if animation_player and animation_player.has_animation("fire"):
		animation_player.play("fire")
