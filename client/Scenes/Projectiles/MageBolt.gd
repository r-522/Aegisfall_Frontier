class_name MageBolt
extends ProjectileBase
## 魔法ボルト — 汎用魔法系プロジェクタイル

func _ready() -> void:
	super._ready()
	speed = 28.0
	max_range = 25.0
	collision_layer = 1 << 4
	collision_mask = (1 << 2) | (1 << 3)
