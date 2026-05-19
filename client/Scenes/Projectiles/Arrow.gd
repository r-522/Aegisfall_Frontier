class_name Arrow
extends ProjectileBase
## 弓矢プロジェクタイル — 直線飛行・オプション貫通

func _ready() -> void:
	super._ready()
	speed = 35.0
	max_range = 50.0
	collision_layer = 1 << 4  # Projectiles layer
	collision_mask = (1 << 2) | (1 << 3)  # Enemies, Towers
