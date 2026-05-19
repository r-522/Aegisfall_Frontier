class_name GoblinScout
extends EnemyBase
## ゴブリンスカウト — 広い索敵範囲で先行し、近くのゴブリンに敵を知らせる
## アラートを出すと周囲のゴブリンがアグロ状態になる

const ALERT_RADIUS: float = 18.0
const ALERT_COOLDOWN: float = 15.0
const DETECTION_BONUS: float = 6.0  # 基本索敵範囲へ加算するボーナス

var _alert_timer: float = 0.0
var _has_alerted: bool = false

func _ready() -> void:
	add_to_group(&"enemies_goblin")
	super._ready()
	# 索敵範囲ボーナスを適用
	if aggro_component:
		aggro_component.detection_radius += DETECTION_BONUS

func _physics_process(delta: float) -> void:
	_alert_timer = maxf(0.0, _alert_timer - delta)
	super._physics_process(delta)
	# 初めてターゲットを発見したとき、または定期的に周囲へアラートを送る
	var target := aggro_component.current_target if aggro_component else null
	if target != null and _alert_timer <= 0.0:
		_alert_nearby_goblins(target)

func _create_ai() -> EnemyAIBase:
	return EnemyAIBase.new()

## 周囲のゴブリン系敵にターゲット情報を伝達してアグロを起こさせる
func _alert_nearby_goblins(target: Node) -> void:
	_alert_timer = ALERT_COOLDOWN
	if not _has_alerted:
		_has_alerted = true
		EventBus.field_event_triggered.emit(&"goblin_alert", global_position)

	var goblins := get_tree().get_nodes_in_group(&"enemies_goblin")
	for goblin in goblins:
		if goblin == self or not is_instance_valid(goblin):
			continue
		if global_position.distance_to(goblin.global_position) > ALERT_RADIUS:
			continue
		var goblin_aggro: AggroComponent = goblin.find_child("AggroComponent")
		if goblin_aggro:
			goblin_aggro.update_target()
