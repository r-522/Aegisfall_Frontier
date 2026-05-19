extends Node
## ヘッドレスサーバーエントリポイント
## 起動: godot --headless --dedicated-server

var _net_manager: NetworkManager
var _game_loop: ServerGameLoop

func _ready() -> void:
	if not OS.has_feature("dedicated_server") and not "--dedicated-server" in OS.get_cmdline_args():
		push_warning("Server: 非サーバー環境での起動 — 無視します")
		return

	print("=== Aegisfall Frontier Dedicated Server ===")
	print("Godot version: ", Engine.get_version_info().string)
	print("Time: ", Time.get_datetime_string_from_system())

	_initialize_server()

func _initialize_server() -> void:
	_net_manager = NetworkManager.new()
	_net_manager.name = "NetworkManager"
	add_child(_net_manager)

	var port := _get_port_arg()
	var err := _net_manager.host_game(port)
	if err != OK:
		push_error("Server: ポート %d でのホスト失敗" % port)
		get_tree().quit(1)
		return

	print("Server: ポート %d で待受開始" % port)

	_game_loop = ServerGameLoop.new()
	_game_loop.name = "ServerGameLoop"
	add_child(_game_loop)

	_net_manager.player_joined.connect(_on_player_joined)
	_net_manager.player_left.connect(_on_player_left)

func _get_port_arg() -> int:
	var args := OS.get_cmdline_args()
	for i in args.size():
		if args[i] == "--port" and i + 1 < args.size():
			return args[i + 1].to_int()
	return GameConfig.DEFAULT_SERVER_PORT

func _on_player_joined(peer_id: int) -> void:
	print("Server: プレイヤー接続 id=%d, 現在人数=%d" % [peer_id, _net_manager.get_player_count()])
	if _net_manager.get_player_count() >= 1:
		_start_game_if_ready()

func _on_player_left(peer_id: int) -> void:
	print("Server: プレイヤー切断 id=%d" % peer_id)

func _start_game_if_ready() -> void:
	if _game_loop:
		_game_loop.start_session()

func _process(_delta: float) -> void:
	pass
