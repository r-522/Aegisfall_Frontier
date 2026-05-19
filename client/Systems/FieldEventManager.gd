class_name FieldEventManager
extends Node
## フィールドイベントマネージャー
## 探索・カウンターアタック フェーズ中に一定間隔でランダムなフィールドイベントを発生させる
##
## イベント種類:
##   "raid"          — 補給ラインへの奇襲。supply_line_attacked を発火
##   "npc_rescue"    — 捕虜 NPC の救出依頼。npc_rescued を発火
##   "treasure"      — 隠された宝箱の出現。resources_changed を発火
##   "mini_dungeon"  — ランダムミニダンジョンのポップ
##   "world_invasion"— 大規模侵攻イベント (波状強化)

signal event_triggered(event_id: StringName, position: Vector3, payload: Dictionary)

# ========================================================================== #
# 定数
# ========================================================================== #

## フィールドイベントの標準発生間隔 (秒)
const EVENT_INTERVAL: float = 120.0
## 同時に存在できるアクティブイベントの上限
const MAX_ACTIVE_EVENTS: int = 3
## ワールドスペースでのイベントスポーン範囲 (中心からの半径 m)
const WORLD_SPAWN_RADIUS: float = 60.0

# ========================================================================== #
# エクスポート
# ========================================================================== #

@export var enabled: bool = true

## イベント発生間隔 (デフォルト: EVENT_INTERVAL)
@export var interval_override: float = 0.0

## イベント候補プール (順序は重み抽選で決まる)
@export var event_pool: Array[Dictionary] = []

# ========================================================================== #
# ランタイム状態
# ========================================================================== #

var _active_events: Array[Dictionary] = []
var _event_timer: float = 0.0
var _is_active_phase: bool = false

# ========================================================================== #
# ライフサイクル
# ========================================================================== #

func _ready() -> void:
	_build_default_event_pool()
	EventBus.exploration_phase_started.connect(_on_exploration_started)
	EventBus.assault_phase_started.connect(_on_assault_started)
	EventBus.build_phase_started.connect(_on_inactive_phase)
	EventBus.defense_phase_started.connect(_on_inactive_phase)
	EventBus.session_ended.connect(_on_session_ended)
	set_process(false)

func _process(delta: float) -> void:
	if not enabled or not _is_active_phase:
		return

	_event_timer -= delta
	if _event_timer <= 0.0:
		_event_timer = _get_effective_interval()
		_trigger_random_event()

	_tick_active_events(delta)

# ========================================================================== #
# イベントプールの初期構築
# ========================================================================== #

func _build_default_event_pool() -> void:
	if not event_pool.is_empty():
		return  # インスペクターで上書きされている場合はスキップ

	event_pool = [
		{
			"id":          &"raid",
			"weight":      3.0,
			"duration":    60.0,
			"description": "補給ラインへの奇襲"
		},
		{
			"id":          &"npc_rescue",
			"weight":      2.5,
			"duration":    90.0,
			"description": "捕虜 NPC の救出依頼"
		},
		{
			"id":          &"treasure",
			"weight":      2.0,
			"duration":    30.0,
			"description": "隠された宝箱の出現"
		},
		{
			"id":          &"mini_dungeon",
			"weight":      1.5,
			"duration":    180.0,
			"description": "ミニダンジョンのポップ"
		},
		{
			"id":          &"world_invasion",
			"weight":      0.8,
			"duration":    120.0,
			"description": "大規模侵攻イベント"
		},
	]

# ========================================================================== #
# イベント発火
# ========================================================================== #

## ランダムなイベントを抽選し、アクティブリストに追加・発火する
func _trigger_random_event() -> void:
	if _active_events.size() >= MAX_ACTIVE_EVENTS:
		return
	if event_pool.is_empty():
		return

	var template := _roll_event_from_pool()
	if template.is_empty():
		return

	var spawn_pos := _random_spawn_position()
	var event_instance: Dictionary = {
		"id":          template.get("id", &"unknown"),
		"position":    spawn_pos,
		"duration":    float(template.get("duration", 60.0)),
		"elapsed":     0.0,
		"completed":   false,
		"payload":     {}
	}

	_active_events.append(event_instance)
	_execute_event(event_instance)

	event_triggered.emit(event_instance.id, spawn_pos, event_instance.payload)
	EventBus.field_event_triggered.emit(event_instance.id, spawn_pos)

## イベント種類に応じた固有処理を実行する
func _execute_event(event: Dictionary) -> void:
	match event.id:

		&"raid":
			# supply_line_attacked を発火してネットワーク / AI に通知する
			var supply_node: Node = _find_nearest_supply_node(event.position)
			if supply_node:
				EventBus.supply_line_attacked.emit(supply_node)
				event.payload["supply_node"] = supply_node

		&"npc_rescue":
			# NPC ノードが存在する場合は発火。なければペイロードにマーカーを置く
			var npc: Node = _find_npc_to_rescue(event.position)
			if npc:
				event.payload["npc"] = npc
			else:
				event.payload["rescue_position"] = event.position

		&"treasure":
			# 即時リソース付与 (小規模ボーナス)
			var bonus_material := randi_range(50, 150)
			var bonus_gold     := randi_range(30, 80)
			EventBus.resources_changed.emit(bonus_material, bonus_gold)
			event.payload["material"] = bonus_material
			event.payload["gold"]     = bonus_gold
			# 宝箱は発火後すぐ完了扱い
			event.completed = true

		&"mini_dungeon":
			# ダンジョン出現をシグナルとペイロードで通知するだけ
			event.payload["dungeon_position"] = event.position

		&"world_invasion":
			# 強化ウェーブフラグを UI / WaveSystem に伝える
			event.payload["invasion_scale"] = 1.5

## アクティブイベントを毎フレーム更新し、タイムアウトしたものを完了させる
func _tick_active_events(delta: float) -> void:
	for event in _active_events:
		if event.completed:
			continue
		event.elapsed += delta
		if event.elapsed >= event.duration:
			event.completed = true

	_active_events = _active_events.filter(
		func(e: Dictionary) -> bool: return not e.completed
	)

# ========================================================================== #
# パブリック API
# ========================================================================== #

## 指定 ID のイベントを即時強制発火する (デバッグ・スクリプト用)
func force_trigger_event(event_id: StringName) -> void:
	for template in event_pool:
		if template.get("id") == event_id:
			var spawn_pos := _random_spawn_position()
			var event_instance: Dictionary = {
				"id":        template.get("id", &"unknown"),
				"position":  spawn_pos,
				"duration":  float(template.get("duration", 60.0)),
				"elapsed":   0.0,
				"completed": false,
				"payload":   {}
			}
			_active_events.append(event_instance)
			_execute_event(event_instance)
			event_triggered.emit(event_instance.id, spawn_pos, event_instance.payload)
			EventBus.field_event_triggered.emit(event_instance.id, spawn_pos)
			return
	push_warning("FieldEventManager: イベント ID '%s' がプールに見つかりません" % str(event_id))

## 現在アクティブなイベント一覧を返す (読み取り専用コピー)
func get_active_events() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for e in _active_events:
		result.append(e.duplicate())
	return result

## アクティブイベント数を返す
func get_active_event_count() -> int:
	return _active_events.size()

## 次のイベント発生までの残り秒数を返す
func get_time_until_next_event() -> float:
	return maxf(0.0, _event_timer)

# ========================================================================== #
# 内部ユーティリティ
# ========================================================================== #

func _get_effective_interval() -> float:
	return interval_override if interval_override > 0.0 else EVENT_INTERVAL

func _roll_event_from_pool() -> Dictionary:
	var total := 0.0
	for t in event_pool:
		total += float(t.get("weight", 1.0))

	var roll := randf() * total
	var cumulative := 0.0
	for t in event_pool:
		cumulative += float(t.get("weight", 1.0))
		if roll <= cumulative:
			return t
	return {}

func _random_spawn_position() -> Vector3:
	var angle := randf() * TAU
	var radius := randf_range(10.0, WORLD_SPAWN_RADIUS)
	return Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)

func _find_nearest_supply_node(near_pos: Vector3) -> Node:
	var supply_nodes := get_tree().get_nodes_in_group(&"supply_lines")
	if supply_nodes.is_empty():
		return null
	var nearest: Node = supply_nodes[0]
	var best_dist := INF
	for node in supply_nodes:
		if node is Node3D:
			var d := near_pos.distance_squared_to((node as Node3D).global_position)
			if d < best_dist:
				best_dist = d
				nearest = node
	return nearest

func _find_npc_to_rescue(near_pos: Vector3) -> Node:
	var npcs := get_tree().get_nodes_in_group(&"rescuable_npcs")
	if npcs.is_empty():
		return null
	var nearest: Node = npcs[0]
	var best_dist := INF
	for node in npcs:
		if node is Node3D:
			var d := near_pos.distance_squared_to((node as Node3D).global_position)
			if d < best_dist:
				best_dist = d
				nearest = node
	return nearest

# ========================================================================== #
# フェーズ連携ハンドラ
# ========================================================================== #

func _on_exploration_started() -> void:
	_is_active_phase = true
	_event_timer = _get_effective_interval()
	set_process(true)

func _on_assault_started() -> void:
	_is_active_phase = true
	_event_timer = _get_effective_interval() * 0.5  # カウンターアタック中は頻度を上げる
	set_process(true)

func _on_inactive_phase(_arg = null) -> void:
	_is_active_phase = false
	set_process(false)

func _on_session_ended(_victory: bool, _score: int) -> void:
	_is_active_phase = false
	_active_events.clear()
	set_process(false)
