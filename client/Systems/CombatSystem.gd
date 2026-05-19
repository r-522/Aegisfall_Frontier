class_name CombatSystem
extends Node
## 戦闘演算の静的ヘルパークラス
## ダメージ計算・適用・ステータス付与・ヒール・距離ボーナスを提供する
## 本クラスは状態を持たない static クラスとして使用する

# ========================================================================== #
# 定数
# ========================================================================== #

## 防御力に対するダメージ減衰係数 (線形減衰: damage = raw - defense * factor)
const DEFENSE_REDUCTION_FACTOR: float = 1.0

## クリティカル時のデフォルト倍率 (TowerData / CharacterData が上書き可能)
const DEFAULT_CRIT_MULTIPLIER: float = 2.0

## 最低ダメージ保証 (0 ダメージ無効)
const MIN_DAMAGE: float = 1.0

## 遠距離キルボーナスが始まる距離 (m)
const LONG_RANGE_BONUS_START: float = 20.0
## 遠距離ボーナスの最大倍率
const LONG_RANGE_BONUS_MAX: float = 1.5
## ボーナスが最大に達する距離 (m)
const LONG_RANGE_BONUS_FULL_RANGE: float = 60.0

# ========================================================================== #
# ダメージ計算
# ========================================================================== #

## 生ダメージ・防御力・クリティカル確率からダメージ量を計算する
## 戻り値: { "damage": float, "is_crit": bool }
static func calculate_damage(
		raw: float,
		defense: float,
		crit_chance: float,
		crit_multiplier: float = DEFAULT_CRIT_MULTIPLIER
) -> Dictionary:
	var is_crit := randf() < clampf(crit_chance, 0.0, 1.0)
	var reduced := maxf(MIN_DAMAGE, raw - defense * DEFENSE_REDUCTION_FACTOR)
	var final_damage := reduced * crit_multiplier if is_crit else reduced
	return { "damage": final_damage, "is_crit": is_crit }

## ターゲットノードの HealthComponent にダメージを適用する
## HealthComponent が存在しない場合は take_damage() メソッドに直接委譲する
## 適用された実ダメージ量を返す
static func apply_damage_to_node(target: Node, amount: float, source: Node) -> float:
	if target == null or not is_instance_valid(target):
		return 0.0

	var health: HealthComponent = target.get_node_or_null("HealthComponent")
	if health:
		var dealt := health.take_damage(amount, source)
		EventBus.enemy_took_damage.emit(target, dealt)
		EventBus.hit_confirmed.emit(source, target, dealt, false)
		return dealt

	# フォールバック: take_damage メソッドを直接呼ぶ
	if target.has_method("take_damage"):
		target.take_damage(amount, source)
		return amount

	return 0.0

## ターゲットノードを回復する
## 適用された実ヒール量を返す
static func apply_heal_to_node(target: Node, amount: float) -> float:
	if target == null or not is_instance_valid(target):
		return 0.0

	var health: HealthComponent = target.get_node_or_null("HealthComponent")
	if health:
		var before := health.current_health
		health.heal(amount)
		return health.current_health - before

	if target.has_method("heal"):
		target.heal(amount)
		return amount

	return 0.0

# ========================================================================== #
# ステータス効果
# ========================================================================== #

## ターゲットの StatusEffectComponent にステータス効果を適用する
## コンポーネントが存在しない場合は何もしない
static func apply_status_to_node(
		target: Node,
		effect_id: StringName,
		duration: float,
		value: float = 0.0,
		tick_rate: float = 0.0,
		stacks: int = 1
) -> void:
	if target == null or not is_instance_valid(target):
		return

	var sec: StatusEffectComponent = target.get_node_or_null("StatusEffectComponent")
	if sec:
		sec.apply_effect(effect_id, duration, value, tick_rate, stacks)
	# EventBus への通知は StatusEffectComponent 内部で行われる

# ========================================================================== #
# 遠距離ボーナス
# ========================================================================== #

## キル距離に応じたボーナス乗数を返す (1.0 以上)
## 距離が LONG_RANGE_BONUS_START 未満なら 1.0
## LONG_RANGE_BONUS_FULL_RANGE 以上なら LONG_RANGE_BONUS_MAX
static func get_kill_distance_bonus(distance: float) -> float:
	if distance < LONG_RANGE_BONUS_START:
		return 1.0
	var t := clampf(
		(distance - LONG_RANGE_BONUS_START) / (LONG_RANGE_BONUS_FULL_RANGE - LONG_RANGE_BONUS_START),
		0.0,
		1.0
	)
	return lerpf(1.0, LONG_RANGE_BONUS_MAX, t)

# ========================================================================== #
# 複合ヘルパー
# ========================================================================== #

## calculate_damage → apply_damage_to_node を一度に行うショートカット
## 戻り値: { "damage": float, "is_crit": bool }
static func deal_damage(
		target: Node,
		raw: float,
		defense: float,
		crit_chance: float,
		source: Node,
		crit_multiplier: float = DEFAULT_CRIT_MULTIPLIER
) -> Dictionary:
	var result := calculate_damage(raw, defense, crit_chance, crit_multiplier)
	var dealt := apply_damage_to_node(target, result.damage, source)
	result["damage"] = dealt

	# クリティカルシグナルを再発火 (is_crit が true のとき)
	if result.is_crit:
		EventBus.hit_confirmed.emit(source, target, dealt, true)

	return result

## ノードの防御力を安全に取得するユーティリティ
## HealthComponent.defense → EnemyData.defense → 0.0 の順に探す
static func get_defense(node: Node) -> float:
	var health: HealthComponent = node.get_node_or_null("HealthComponent")
	if health:
		return health.defense

	var data: EnemyData = node.get("enemy_data") as EnemyData
	if data:
		return data.defense

	return 0.0
