class_name EliteTank
extends TankEnemy
## エリートタンク — 通常タンクより大型・高耐久のエリート個体
## 戦闘中に継続的なHP再生能力を持つ

const REGEN_INTERVAL: float = 1.0
const REGEN_AMOUNT_RATIO: float = 0.015  # 最大HPの1.5%/秒

var is_elite: bool = true
var _regen_timer: float = 0.0

func _ready() -> void:
	super._ready()
	EventBus.elite_enemy_spawned.emit(self)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _is_dead:
		return
	_regen_timer += delta
	if _regen_timer >= REGEN_INTERVAL:
		_regen_timer -= REGEN_INTERVAL
		_tick_regeneration()

## 毎秒最大HPの一定割合を回復する
func _tick_regeneration() -> void:
	if health_component == null or health_component.is_dead:
		return
	if health_component.is_full_health():
		return
	var regen_amount := health_component.max_health * REGEN_AMOUNT_RATIO
	health_component.heal(regen_amount)
