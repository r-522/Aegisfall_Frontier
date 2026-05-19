class_name SpawnSystem
extends Node
## スポーンシステム — WaveData に従って敵をインスタンス化し、
## EventBus.enemy_spawned を発火してシーンツリーに追加する

@export var spawn_points: Array[Marker3D] = []

var _is_spawning: bool = false
var _spawn_complete: bool = false

## WaveSystem から呼び出す。内部で非同期スポーンを開始する
func spawn_wave(wave: WaveData) -> void:
	_is_spawning = true
	_spawn_complete = false
	_do_spawn_wave(wave)

## WaveSystem._process から参照し、全スポーン完了を確認する
func is_spawning_complete() -> bool:
	return _spawn_complete

# === 内部処理 ===

func _do_spawn_wave(wave: WaveData) -> void:
	for entry in wave.spawn_entries:
		if entry.spawn_delay_from_wave_start > 0.0:
			await get_tree().create_timer(entry.spawn_delay_from_wave_start).timeout
		await _spawn_entry(entry)

	if wave.boss_entry and wave.boss_entry.enemy_data:
		await _spawn_entry(wave.boss_entry)

	_is_spawning = false
	_spawn_complete = true

func _spawn_entry(entry: WaveData.SpawnEntry) -> void:
	for i in entry.count:
		await get_tree().create_timer(entry.delay_between_spawns).timeout
		var point_idx: int
		if not entry.spawn_point_indices.is_empty():
			point_idx = entry.spawn_point_indices[i % entry.spawn_point_indices.size()]
		else:
			point_idx = 0
		_spawn_enemy(entry.enemy_data, point_idx)

func _spawn_enemy(data: EnemyData, spawn_index: int) -> void:
	if data == null:
		return

	# シーンパスをロード。scene_path プロパティがなければフォールバック
	var scene: PackedScene = null
	if data.get("scene_path") != null and data.scene_path != "":
		scene = load(data.scene_path)
	if scene == null:
		scene = load("res://Scenes/Enemies/SwarmEnemy.tscn")
	if scene == null:
		push_warning("SpawnSystem: スポーンシーンが見つかりません (enemy_id=%s)" % str(data.enemy_id))
		return

	var enemy: Node3D = scene.instantiate()

	# スポーンポイント座標 + 微小ランダムオフセットを付ける
	var base_pos := Vector3.ZERO
	if not spawn_points.is_empty():
		base_pos = spawn_points[spawn_index % spawn_points.size()].global_position
	enemy.global_position = base_pos + Vector3(
		randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)
	)

	get_tree().current_scene.add_child(enemy)

	# EnemyData を注入 (まだ設定されていない場合のみ)
	if enemy.get("enemy_data") == null:
		enemy.set("enemy_data", data)

	# ボスシグナル
	if data.is_boss:
		EventBus.boss_spawned.emit(enemy)
	elif data.is_elite:
		EventBus.elite_enemy_spawned.emit(enemy)

	EventBus.enemy_spawned.emit(enemy)

## デバッグ用: 指定インデックスのスポーンポイント座標を返す
func get_spawn_point_position(index: int) -> Vector3:
	if spawn_points.is_empty():
		return Vector3.ZERO
	return spawn_points[index % spawn_points.size()].global_position
