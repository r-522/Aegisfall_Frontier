class_name EliteSwarm
extends SwarmEnemy
## エリートスウォーム — 通常スウォームより大型・高耐久のエリート個体
## 周囲の通常スウォームを呼び寄せる「召集」能力を持つ

const RALLY_RADIUS: float = 15.0
const RALLY_COOLDOWN: float = 12.0

var is_elite: bool = true
var _rally_timer: float = 0.0

func _ready() -> void:
	super._ready()
	# エリートとして登録
	EventBus.elite_enemy_spawned.emit(self)

func _physics_process(delta: float) -> void:
	_rally_timer = maxf(0.0, _rally_timer - delta)
	super._physics_process(delta)
	if _rally_timer <= 0.0:
		_try_rally_swarms()

## 周囲の通常スウォームエネミーをアグロさせる
func _try_rally_swarms() -> void:
	var target := aggro_component.current_target if aggro_component else null
	if target == null:
		return
	_rally_timer = RALLY_COOLDOWN
	var swarms := get_tree().get_nodes_in_group(&"enemies_swarm")
	for swarm in swarms:
		if swarm == self or not is_instance_valid(swarm):
			continue
		if swarm is EliteSwarm:
			continue
		if global_position.distance_to(swarm.global_position) <= RALLY_RADIUS:
			# 対象の AggroComponent に直接ターゲットを渡して起こす
			var swarm_aggro: AggroComponent = swarm.find_child("AggroComponent")
			if swarm_aggro:
				swarm_aggro.update_target()
