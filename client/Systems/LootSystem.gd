class_name LootSystem
extends Node
## ルートシステム — 敵死亡時にアイテムをランダムドロップする
## loot_table は enemy_id (StringName) → Array[LootEntry] のマッピング
## アイテムはワールド上のピックアップノードとしてスポーンする

# --- ルートエントリ ---
## loot_table の値配列に入れる軽量な内部構造
class LootEntry:
	var item_data: Resource          ## ItemData (または代替 Resource)
	var weight: float = 1.0          ## ドロップ抽選の重み
	var min_count: int = 1
	var max_count: int = 1
	var guaranteed: bool = false     ## true の場合は重み抽選なしで必ずドロップ

	func _init(data: Resource, w: float = 1.0,
			   mn: int = 1, mx: int = 1, g: bool = false) -> void:
		item_data = data
		weight = w
		min_count = mn
		max_count = mx
		guaranteed = g

# ========================================================================== #
# エクスポート & 設定
# ========================================================================== #

## enemy_id (StringName) → Array[LootEntry]
## スクリプトから register_loot_table() で登録するか、
## サブクラスで _build_loot_table() をオーバーライドして構築する
var loot_table: Dictionary = {}

## ドロップするピックアップのシーンパス
@export var pickup_scene_path: String = "res://Scenes/Items/ItemPickup.tscn"

## グローバルなドロップ率乗数 (ゲーム難易度スケール用)
@export var drop_rate_multiplier: float = 1.0

## ドロップ位置の垂直オフセット (地面めり込み防止)
const _SPAWN_HEIGHT_OFFSET: float = 0.5
## ドロップ物のランダム水平散布半径
const _SCATTER_RADIUS: float = 0.8

# ========================================================================== #
# ライフサイクル
# ========================================================================== #

func _ready() -> void:
	EventBus.enemy_died.connect(_on_enemy_died)
	_build_loot_table()

## サブクラスでオーバーライドしてルートテーブルを構築する
## デフォルトはテーブルを空のまま維持する
func _build_loot_table() -> void:
	pass

# ========================================================================== #
# パブリック API
# ========================================================================== #

## 指定 enemy_id のルートエントリ配列を登録する
## 既存エントリは上書きする
func register_loot_table(enemy_id: StringName, entries: Array) -> void:
	loot_table[enemy_id] = entries

## ルートエントリを既存テーブルに追加する
func add_loot_entry(enemy_id: StringName, entry: LootEntry) -> void:
	if not loot_table.has(enemy_id):
		loot_table[enemy_id] = []
	loot_table[enemy_id].append(entry)

## 敵ノードと死亡座標を受け取り、ドロップ抽選 → スポーンを実行する
func try_drop_loot(enemy: Node, position: Vector3) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return

	var enemy_data: EnemyData = enemy.get("enemy_data") as EnemyData
	var enemy_id: StringName = enemy_data.enemy_id if enemy_data else &""

	# テーブルが存在しない場合はドロップなし
	var entries: Array = loot_table.get(enemy_id, [])
	if entries.is_empty():
		return

	# 敵の loot_weight で全体確率をスケールする
	var loot_weight_scale: float = enemy_data.loot_weight if enemy_data else 1.0
	var effective_multiplier := drop_rate_multiplier * loot_weight_scale

	for entry in entries:
		if not (entry is LootEntry):
			continue

		if entry.guaranteed:
			_spawn_pickup(entry.item_data, position, _random_count(entry))
			continue

		# 重み抽選
		var roll := randf()
		var threshold := clampf(
			(entry.weight / _get_total_weight(entries)) * effective_multiplier,
			0.0,
			1.0
		)
		if roll < threshold:
			_spawn_pickup(entry.item_data, position, _random_count(entry))

## グローバル ルートテーブルから weight を加味したランダムな LootEntry を 1 件返す
## enemy_id に対応するエントリがなければ null を返す
func roll_random_entry(enemy_id: StringName) -> LootEntry:
	var entries: Array = loot_table.get(enemy_id, [])
	if entries.is_empty():
		return null

	var total := _get_total_weight(entries)
	var roll := randf() * total
	var cumulative := 0.0
	for entry in entries:
		if not (entry is LootEntry):
			continue
		cumulative += entry.weight
		if roll <= cumulative:
			return entry
	return null

# ========================================================================== #
# ピックアップスポーン
# ========================================================================== #

func _spawn_pickup(item_data: Resource, base_position: Vector3, count: int) -> void:
	if item_data == null:
		return

	var scene: PackedScene = _get_pickup_scene()

	for i in count:
		var scatter_offset := Vector3(
			randf_range(-_SCATTER_RADIUS, _SCATTER_RADIUS),
			_SPAWN_HEIGHT_OFFSET,
			randf_range(-_SCATTER_RADIUS, _SCATTER_RADIUS)
		)
		var spawn_pos := base_position + scatter_offset

		if scene:
			var pickup: Node3D = scene.instantiate()
			pickup.global_position = spawn_pos

			# ItemPickup が item_data プロパティを持つ前提
			if pickup.get("item_data") != null or pickup.has_method("set_item_data"):
				if pickup.has_method("set_item_data"):
					pickup.call("set_item_data", item_data)
				else:
					pickup.set("item_data", item_data)

			get_tree().current_scene.add_child(pickup)
		else:
			# フォールバック: OmniLight3D でドロップを可視化する
			_spawn_debug_pickup(item_data, spawn_pos)

func _get_pickup_scene() -> PackedScene:
	if pickup_scene_path != "" and ResourceLoader.exists(pickup_scene_path):
		return load(pickup_scene_path)
	return null

func _spawn_debug_pickup(item_data: Resource, position: Vector3) -> void:
	var light := OmniLight3D.new()
	light.global_position = position
	light.omni_range = 1.5
	light.light_energy = 2.0
	light.light_color = Color.YELLOW
	light.set_meta(&"debug_loot_item", item_data)
	get_tree().current_scene.add_child(light)

	# 10 秒後に自動消去
	get_tree().create_timer(10.0).timeout.connect(func() -> void:
		if is_instance_valid(light):
			light.queue_free()
	)

# ========================================================================== #
# 内部ユーティリティ
# ========================================================================== #

func _get_total_weight(entries: Array) -> float:
	var total := 0.0
	for entry in entries:
		if entry is LootEntry and not entry.guaranteed:
			total += entry.weight
	return maxf(total, 0.001)

func _random_count(entry: LootEntry) -> int:
	return randi_range(entry.min_count, entry.max_count)

# ========================================================================== #
# イベントハンドラ
# ========================================================================== #

func _on_enemy_died(enemy: Node, position: Vector3, _xp: int) -> void:
	try_drop_loot(enemy, position)
