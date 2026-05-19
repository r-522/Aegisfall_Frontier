class_name WaveSystem
extends Node
## ウェーブ管理 — スポーン・生存確認・完了通知
## PhaseManager から start_wave() を呼び出す; SpawnSystem と連携して
## 全敵が倒されたときに wave_completed シグナルを発火する

@export var wave_data_set: Array[WaveData] = []

var current_wave_index: int = 0
var _active_enemies: Array[Node] = []
var _is_wave_active: bool = false

@onready var spawn_system: SpawnSystem = $../SpawnSystem

func _ready() -> void:
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.enemy_spawned.connect(_on_enemy_spawned)

## PhaseManager (または PhaseManager 経由の WAVE_DEFENSE フェーズ) から呼ぶ
func start_wave() -> void:
	if current_wave_index >= wave_data_set.size():
		# 全ウェーブクリア済み — 最終スコアを計算して終了
		EventBus.session_ended.emit(true, _calculate_score())
		return

	var wave: WaveData = wave_data_set[current_wave_index]
	_is_wave_active = true
	_active_enemies.clear()
	EventBus.wave_started.emit(wave.wave_number, wave.get_total_enemy_count())
	_spawn_wave(wave)

func _spawn_wave(wave: WaveData) -> void:
	spawn_system.spawn_wave(wave)

func _process(_delta: float) -> void:
	if not _is_wave_active:
		return

	# 死んだノード参照を毎フレーム掃除する
	_active_enemies = _active_enemies.filter(func(e: Node) -> bool: return is_instance_valid(e))

	# SpawnSystem がスポーン完了を通知し、かつ残敵がゼロになったら終了
	if spawn_system and spawn_system.is_spawning_complete() and _active_enemies.is_empty():
		_complete_wave()

func _complete_wave() -> void:
	_is_wave_active = false
	var wave: WaveData = wave_data_set[current_wave_index]

	# ウェーブ報酬を配布
	EventBus.resources_changed.emit(wave.reward_build_material, wave.reward_gold)

	current_wave_index += 1
	EventBus.wave_completed.emit(wave.wave_number, true)

func _on_enemy_died(enemy: Node, _position: Vector3, _xp: int) -> void:
	_active_enemies.erase(enemy)

func _on_enemy_spawned(enemy: Node) -> void:
	if _is_wave_active:
		_active_enemies.append(enemy)

# === クエリ ===

func all_waves_cleared() -> bool:
	return current_wave_index >= wave_data_set.size()

func get_current_wave_number() -> int:
	if current_wave_index < wave_data_set.size():
		return wave_data_set[current_wave_index].wave_number
	return current_wave_index + 1

func get_remaining_enemy_count() -> int:
	_active_enemies = _active_enemies.filter(func(e: Node) -> bool: return is_instance_valid(e))
	return _active_enemies.size()

func _calculate_score() -> int:
	return current_wave_index * 1000
