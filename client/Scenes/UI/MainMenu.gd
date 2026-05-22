class_name MainMenu
extends CanvasLayer

const GAME_SCENE: String = "res://Scenes/Main/Main.tscn"
const VERSION: String = "v0.1.0"

@onready var version_label: Label = $Control/Center/VBox/VersionLabel
@onready var single_button: Button = $Control/Center/VBox/SingleButton
@onready var multi_button: Button = $Control/Center/VBox/MultiButton
@onready var settings_button: Button = $Control/Center/VBox/SettingsButton

@onready var multi_panel: PanelContainer = $Control/MultiPanel
@onready var ip_input: LineEdit = $Control/MultiPanel/VBox/IPInput
@onready var port_input: LineEdit = $Control/MultiPanel/VBox/PortInput
@onready var host_button: Button = $Control/MultiPanel/VBox/Buttons/HostButton
@onready var connect_button: Button = $Control/MultiPanel/VBox/Buttons/ConnectButton
@onready var multi_back_button: Button = $Control/MultiPanel/VBox/BackButton
@onready var multi_status: Label = $Control/MultiPanel/VBox/StatusLabel

@onready var settings_panel: PanelContainer = $Control/SettingsPanel
@onready var master_slider: HSlider = $Control/SettingsPanel/VBox/MasterSlider
@onready var music_slider: HSlider = $Control/SettingsPanel/VBox/MusicSlider
@onready var sfx_slider: HSlider = $Control/SettingsPanel/VBox/SFXSlider
@onready var settings_back_button: Button = $Control/SettingsPanel/VBox/BackButton

func _ready() -> void:
	InputMapper.release_mouse()
	version_label.text = VERSION

	single_button.pressed.connect(_start_single)
	multi_button.pressed.connect(_show_multi_panel)
	settings_button.pressed.connect(_show_settings)

	host_button.pressed.connect(_host_game)
	connect_button.pressed.connect(_join_game)
	multi_back_button.pressed.connect(multi_panel.hide)

	settings_back_button.pressed.connect(_apply_and_close_settings)

	multi_panel.hide()
	settings_panel.hide()

	ip_input.text = "127.0.0.1"
	port_input.text = str(GameConfig.DEFAULT_SERVER_PORT)

	EventBus.connected_to_server.connect(_on_connected)

func _start_single() -> void:
	InputMapper.capture_mouse()
	get_tree().change_scene_to_file(GAME_SCENE)

func _show_multi_panel() -> void:
	multi_status.text = ""
	multi_panel.show()
	ip_input.grab_focus()

func _show_settings() -> void:
	master_slider.value = GameConfig.master_volume
	music_slider.value = GameConfig.music_volume
	sfx_slider.value = GameConfig.sfx_volume
	settings_panel.show()

func _host_game() -> void:
	host_button.disabled = true
	var err: int = NetworkManager.host_game()
	if err != OK:
		host_button.disabled = false
		multi_status.text = "ホスト開始失敗 (err %d)" % err
		return
	InputMapper.capture_mouse()
	get_tree().change_scene_to_file(GAME_SCENE)

func _join_game() -> void:
	var ip: String = ip_input.text.strip_edges()
	if ip.is_empty():
		multi_status.text = "IPアドレスを入力してください"
		return
	var port: int = GameConfig.DEFAULT_SERVER_PORT
	if port_input.text.strip_edges().is_valid_int():
		port = port_input.text.strip_edges().to_int()
	multi_status.text = "%s:%d に接続中..." % [ip, port]
	connect_button.disabled = true
	var err: int = NetworkManager.join_game(ip, port)
	if err != OK:
		multi_status.text = "接続失敗 (err %d)" % err
		connect_button.disabled = false

func _on_connected() -> void:
	multi_status.text = "接続しました。起動中..."
	InputMapper.capture_mouse()
	get_tree().change_scene_to_file(GAME_SCENE)

func _apply_and_close_settings() -> void:
	GameConfig.master_volume = master_slider.value
	GameConfig.music_volume = music_slider.value
	GameConfig.sfx_volume = sfx_slider.value
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Master"), linear_to_db(master_slider.value))
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Music"), linear_to_db(music_slider.value))
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("SFX"), linear_to_db(sfx_slider.value))
	GameConfig.save_user_config()
	settings_panel.hide()
