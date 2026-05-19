class_name ServerGameLoop
extends Node
## サーバー側ゲームループ — 権威ある物理/AI実行
## ティックレート: 30Hz

const SERVER_TICK_RATE: int = GameConfig.SERVER_TICK_RATE
const TICK_INTERVAL: float = 1.0 / SERVER_TICK_RATE

var _tick_timer: float = 0.0
var _session_active: bool = false
var _tick_count: int = 0
var _phase_manager: PhaseManager = null
var _wave_system: WaveSystem = null

func _ready() -> void:
	print("ServerGameLoop: 初期化完了 (%dHz)" % SERVER_TICK_RATE)

func start_session() -> void:
	if _session_active:
		return
	_session_active = true
	_tick_count = 0
	print("ServerGameLoop: セッション開始")
	EventBus.session_started.emit()

func stop_session() -> void:
	_session_active = false
	print("ServerGameLoop: セッション終了")

func _physics_process(delta: float) -> void:
	if not _session_active:
		return

	_tick_timer += delta
	if _tick_timer < TICK_INTERVAL:
		return

	_tick_timer -= TICK_INTERVAL
	_tick_count += 1
	_server_tick(_tick_count)

func _server_tick(tick: int) -> void:
	# 敵のAI処理 (権威ある実行)
	var enemies := get_tree().get_nodes_in_group(&"enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.has_method("_physics_process"):
			pass  # NavigationAgent3Dが自動処理

	# 定期的なデバッグログ (10秒ごと)
	if tick % (SERVER_TICK_RATE * 10) == 0:
		var enemy_count := get_tree().get_nodes_in_group(&"enemies").size()
		var player_count := get_tree().get_nodes_in_group(&"players").size()
		print("Server tick %d | Enemies: %d | Players: %d" % [tick, enemy_count, player_count])
