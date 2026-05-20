class_name WaveSystem
extends Node
## ウェーブ管理 — スポーン・生存確認・完了通知
## PhaseManager から start_wave() を呼び出す; SpawnSystem と連携して
## 全敵が倒されたときに wave_completed シグナルを発火する

@export var wave_data_set: Array[WaveData] = []

var current_wave_index: int = 0
var _active_enemies: Array[Node] = []
var _is_wave_active: bool = false

@onready var spawn_system: SpawnSystem = $"../SpawnSystem"

func _ready() -> void:
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.enemy_spawned.connect(_on_enemy_spawned)

## PhaseManager (または PhaseManager 経由の WAVE_DEFENSE フェーズ) から呼ぶ
func start_wave() -> void:
	if current_wave_index >= wave_data_set.size():
		EventBus.session_ended.emit(true, _calculate_score())
		return

	var wave: WaveData = wave_data_set[current_wave_index]
	if wave.spawn_entries.is_empty():
		_fill_procedural_entries(wave)
	_is_wave_active = true
	_active_enemies.clear()
	EventBus.wave_started.emit(wave.wave_number, wave.get_total_enemy_count())
	_spawn_wave(wave)

## spawn_entries が空の場合、wave_number に応じて手続き的に生成する
func _fill_procedural_entries(wave: WaveData) -> void:
	var wn := wave.wave_number
	var swarm_data: EnemyData = load("res://Data/Enemies/swarm_data.tres")
	var tank_data: EnemyData = load("res://Data/Enemies/tank_data.tres")
	var flying_data: EnemyData = load("res://Data/Enemies/flying_data.tres")
	var elite_swarm_data: EnemyData = load("res://Data/Enemies/elite_swarm_data.tres")
	var boss_data: EnemyData = load("res://Data/Enemies/boss_data.tres")

	var swarm_entry := WaveData.SpawnEntry.new()
	swarm_entry.enemy_data = swarm_data
	swarm_entry.count = 6 + wn * 2
	swarm_entry.delay_between_spawns = 0.6
	swarm_entry.spawn_point_indices = [0, 1, 2]
	swarm_entry.spawn_delay_from_wave_start = 0.0
	wave.spawn_entries.append(swarm_entry)

	if wn >= 2 and tank_data:
		var tank_entry := WaveData.SpawnEntry.new()
		tank_entry.enemy_data = tank_data
		tank_entry.count = 1 + wn / 2
		tank_entry.delay_between_spawns = 2.0
		tank_entry.spawn_point_indices = [0, 1]
		tank_entry.spawn_delay_from_wave_start = 5.0
		wave.spawn_entries.append(tank_entry)

	if wn >= 3 and flying_data:
		var fly_entry := WaveData.SpawnEntry.new()
		fly_entry.enemy_data = flying_data
		fly_entry.count = 2 + wn
		fly_entry.delay_between_spawns = 1.0
		fly_entry.spawn_point_indices = [3, 4]
		fly_entry.spawn_delay_from_wave_start = 8.0
		wave.spawn_entries.append(fly_entry)

	if wn >= 4 and elite_swarm_data:
		var elite_entry := WaveData.SpawnEntry.new()
		elite_entry.enemy_data = elite_swarm_data
		elite_entry.count = 2
		elite_entry.delay_between_spawns = 3.0
		elite_entry.spawn_point_indices = [0, 1, 2]
		elite_entry.spawn_delay_from_wave_start = 12.0
		wave.spawn_entries.append(elite_entry)

	if wn >= 5 and boss_data and wave.boss_entry == null:
		var boss_entry := WaveData.SpawnEntry.new()
		boss_entry.enemy_data = boss_data
		boss_entry.count = 1
		boss_entry.delay_between_spawns = 0.0
		boss_entry.spawn_point_indices = [0]
		boss_entry.spawn_delay_from_wave_start = 20.0
		wave.boss_entry = boss_entry

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
