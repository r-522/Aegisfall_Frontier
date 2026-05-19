class_name CannonBall
extends ProjectileBase
## 大砲弾 — 重力影響・大型AoE爆発

var _gravity_effect: float = 3.0

func _ready() -> void:
	super._ready()
	speed = 20.0
	max_range = 35.0
	aoe_radius = 4.0
	collision_layer = 1 << 4
	collision_mask = (1 << 2) | (1 << 3) | (1 << 0)

func _physics_process(delta: float) -> void:
	_direction.y -= _gravity_effect * delta
	_direction = _direction.normalized()
	super._physics_process(delta)
