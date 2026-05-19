class_name LightningObelisk
extends TowerBase
## 主ターゲットに雷を落とし、連鎖して周囲の敵に飛び移るオベリスク

const CHAIN_JUMPS: int = 2
const CHAIN_DAMAGE_MULTIPLIER: float = 0.5
const CHAIN_JUMP_RADIUS: float = 6.0

func _ready() -> void:
	add_to_group(&"towers_attack")
	super._ready()

func _on_placed() -> void:
	if animation_player and animation_player.has_animation("idle_charged"):
		animation_player.play("idle_charged")

func _spawn_projectile(target: Node, damage: float) -> void:
	# プロジェクタイルなし — 即時ヒット処理
	_do_chain_lightning(target, damage, CHAIN_JUMPS)

	if animation_player and animation_player.has_animation("discharge"):
		animation_player.play("discharge")

## 主ターゲットにダメージを与え、jumps_left が残っている限り近傍の別の敵に連鎖する
func _do_chain_lightning(primary_target: Node, damage: float, jumps_left: int) -> void:
	if not is_instance_valid(primary_target):
		return

	var hc: HealthComponent = primary_target.find_child("HealthComponent") as HealthComponent
	if hc and not hc.is_dead:
		hc.take_damage(damage, self)
		EventBus.enemy_took_damage.emit(primary_target, damage)
		_play_lightning_effect(primary_target.global_position)

	if jumps_left <= 0:
		return

	# 周囲の敵で、既にヒット済みでないものを探す
	var next_target := _find_chain_target(primary_target)
	if next_target:
		_do_chain_lightning(next_target, damage * CHAIN_DAMAGE_MULTIPLIER, jumps_left - 1)

func _find_chain_target(exclude: Node) -> Node:
	var best: Node = null
	var best_dist: float = CHAIN_JUMP_RADIUS

	var enemies := get_tree().get_nodes_in_group(&"enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy == exclude:
			continue
		var hc: HealthComponent = enemy.find_child("HealthComponent") as HealthComponent
		if hc == null or hc.is_dead:
			continue
		var d := exclude.global_position.distance_to(enemy.global_position)
		if d < best_dist:
			best_dist = d
			best = enemy
	return best

func _play_lightning_effect(at_position: Vector3) -> void:
	# ビジュアルエフェクトのフック — パーティクルシステムがあれば接続する
	EventBus.field_event_triggered.emit(&"lightning_strike", at_position)
