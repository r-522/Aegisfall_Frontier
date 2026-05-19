class_name ResourceSystem
extends Node
## リソース管理 — ビルドマテリアルとゴールドの加算・消費・照会
## 敵死亡時に EnemyData.build_material_reward / gold_reward を自動付与する

signal build_material_changed(new_amount: int)
signal gold_changed(new_amount: int)

var _build_material: int = GameConfig.STARTING_BUILD_MATERIAL
var _gold: int = GameConfig.STARTING_GOLD

func _ready() -> void:
	EventBus.enemy_died.connect(_on_enemy_died)

# ========================================================================== #
# クエリ
# ========================================================================== #

func get_build_material() -> int:
	return _build_material

func get_gold() -> int:
	return _gold

func can_afford_tower(data: TowerData) -> bool:
	return _build_material >= data.build_cost

func can_spend_build_material(amount: int) -> bool:
	return _build_material >= amount

func can_spend_gold(amount: int) -> bool:
	return _gold >= amount

# ========================================================================== #
# 加算
# ========================================================================== #

func add_build_material(amount: int) -> void:
	if amount <= 0:
		return
	_build_material += amount
	build_material_changed.emit(_build_material)
	EventBus.resources_changed.emit(_build_material, _gold)

func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	_gold += amount
	gold_changed.emit(_gold)
	EventBus.resources_changed.emit(_build_material, _gold)

# ========================================================================== #
# 消費
# ========================================================================== #

## 成功時 true を返す。残高不足なら何も変更せず false を返す
func spend_build_material(amount: int) -> bool:
	if amount <= 0:
		return true
	if _build_material < amount:
		return false
	_build_material -= amount
	build_material_changed.emit(_build_material)
	EventBus.resources_changed.emit(_build_material, _gold)
	return true

## 成功時 true を返す。残高不足なら何も変更せず false を返す
func spend_gold(amount: int) -> bool:
	if amount <= 0:
		return true
	if _gold < amount:
		return false
	_gold -= amount
	gold_changed.emit(_gold)
	EventBus.resources_changed.emit(_build_material, _gold)
	return true

# ========================================================================== #
# イベントハンドラ
# ========================================================================== #

func _on_enemy_died(enemy: Node, _position: Vector3, _xp: int) -> void:
	var data: EnemyData = enemy.get("enemy_data") as EnemyData
	if data == null:
		return
	add_build_material(int(data.build_material_reward))
	add_gold(data.gold_reward)
