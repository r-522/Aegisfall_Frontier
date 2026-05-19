class_name MainMenu
extends CanvasLayer
## メインメニュー — ホスト/参加/ソロ/設定/終了
## NetworkManager.host_game() / join_game(ip) でセッションを開始する

const GAME_SCENE: String = "res://client/Scenes/Main/GameWorld.tscn"
const VERSION: String    = "v0.1.0"

@onready var title_label: Label           = $CenterContainer/VBoxContainer/TitleLabel
@onready var version_label: Label         = $CenterContainer/VBoxContainer/VersionLabel
@onready var host_button: Button          = $CenterContainer/VBoxContainer/ButtonPanel/HostButton
@onready var join_button: Button          = $CenterContainer/VBoxContainer/ButtonPanel/JoinButton
@onready var solo_button: Button          = $CenterContainer/VBoxContainer/ButtonPanel/SoloButton
@onready var settings_button: Button      = $CenterContainer/VBoxContainer/ButtonPanel/SettingsButton
@onready var quit_button: Button          = $CenterContainer/VBoxContainer/ButtonPanel/QuitButton

# Join パネル
@onready var join_panel: PanelContainer   = $JoinPanel
@onready var ip_input: LineEdit           = $JoinPanel/VBoxContainer/IPLineEdit
@onready var port_input: LineEdit         = $JoinPanel/VBoxContainer/PortLineEdit
@onready var connect_button: Button       = $JoinPanel/VBoxContainer/ButtonRow/ConnectButton
@onready var join_back_button: Button     = $JoinPanel/VBoxContainer/ButtonRow/BackButton
@onready var join_status_label: Label     = $JoinPanel/VBoxContainer/StatusLabel

# 設定パネル (埋め込み)
@onready var settings_panel: PanelContainer  = $SettingsPanel
@onready var master_volume_slider: HSlider   = $SettingsPanel/VBoxContainer/AudioSection/MasterVolumeSlider
@onready var music_volume_slider: HSlider    = $SettingsPanel/VBoxContainer/AudioSection/MusicVolumeSlider
@onready var sfx_volume_slider: HSlider      = $SettingsPanel/VBoxContainer/AudioSection/SFXVolumeSlider
@onready var sensitivity_slider: HSlider     = $SettingsPanel/VBoxContainer/ControlsSection/SensitivitySlider
@onready var quality_dropdown: OptionButton  = $SettingsPanel/VBoxContainer/VideoSection/QualityDropdown
@onready var settings_apply_button: Button   = $SettingsPanel/VBoxContainer/ButtonRow/ApplyButton
@onready var settings_back_button: Button    = $SettingsPanel/VBoxContainer/ButtonRow/BackButton

func _ready() -> void:
	InputMapper.release_mouse()

	title_label.text   = "Aegisfall Frontier"
	version_label.text = VERSION

	_wire_main_buttons()
	_wire_join_buttons()
	_wire_settings_buttons()
	_populate_quality_dropdown()

	join_panel.hide()
	settings_panel.hide()

	EventBus.connected_to_server.connect(_on_connected_to_server)

# ─── メインボタン ──────────────────────────────────────────────────────────────

func _wire_main_buttons() -> void:
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	solo_button.pressed.connect(_on_solo_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_host_pressed() -> void:
	host_button.disabled = true
	host_button.text = "Starting..."
	var err := NetworkManager.host_game()
	if err != OK:
		host_button.disabled = false
		host_button.text = "Host Game"
		push_warning("MainMenu: ホスト開始失敗 err=%d" % err)
		return
	_load_game_scene()

func _on_join_pressed() -> void:
	join_panel.show()
	join_status_label.text = ""
	ip_input.text   = ""
	port_input.text = str(GameConfig.DEFAULT_SERVER_PORT)
	ip_input.grab_focus()

func _on_solo_pressed() -> void:
	# シングルプレイ — ネットワーク不使用でゲームシーンを直接ロード
	_load_game_scene()

func _on_settings_pressed() -> void:
	_load_settings_into_ui()
	settings_panel.show()

func _on_quit_pressed() -> void:
	get_tree().quit()

# ─── Join パネル ──────────────────────────────────────────────────────────────

func _wire_join_buttons() -> void:
	connect_button.pressed.connect(_on_connect_pressed)
	join_back_button.pressed.connect(join_panel.hide)

func _on_connect_pressed() -> void:
	var ip: String   = ip_input.text.strip_edges()
	var port_str: String = port_input.text.strip_edges()

	if ip.is_empty():
		join_status_label.text = "Please enter a server IP."
		return

	var port: int = GameConfig.DEFAULT_SERVER_PORT
	if port_str.is_valid_int():
		port = port_str.to_int()

	join_status_label.text   = "Connecting to %s:%d..." % [ip, port]
	connect_button.disabled  = true

	var err := NetworkManager.join_game(ip, port)
	if err != OK:
		join_status_label.text  = "Connection failed (err %d)." % err
		connect_button.disabled = false

func _on_connected_to_server() -> void:
	join_status_label.text = "Connected! Loading game..."
	_load_game_scene()

# ─── 設定パネル ───────────────────────────────────────────────────────────────

func _wire_settings_buttons() -> void:
	settings_apply_button.pressed.connect(_apply_settings)
	settings_back_button.pressed.connect(settings_panel.hide)

func _populate_quality_dropdown() -> void:
	quality_dropdown.clear()
	quality_dropdown.add_item("Low",    0)
	quality_dropdown.add_item("Medium", 1)
	quality_dropdown.add_item("High",   2)
	quality_dropdown.add_item("Ultra",  3)

func _load_settings_into_ui() -> void:
	master_volume_slider.value = GameConfig.master_volume
	music_volume_slider.value  = GameConfig.music_volume
	sfx_volume_slider.value    = GameConfig.sfx_volume
	sensitivity_slider.value   = GameConfig.mouse_sensitivity
	quality_dropdown.selected  = GameConfig.graphics_quality

func _apply_settings() -> void:
	GameConfig.master_volume     = master_volume_slider.value
	GameConfig.music_volume      = music_volume_slider.value
	GameConfig.sfx_volume        = sfx_volume_slider.value
	GameConfig.mouse_sensitivity = sensitivity_slider.value
	GameConfig.graphics_quality  = quality_dropdown.selected

	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Master"),
		linear_to_db(GameConfig.master_volume))
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Music"),
		linear_to_db(GameConfig.music_volume))
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("SFX"),
		linear_to_db(GameConfig.sfx_volume))

	GameConfig.save_user_config()
	settings_panel.hide()

# ─── シーン遷移 ───────────────────────────────────────────────────────────────

func _load_game_scene() -> void:
	InputMapper.capture_mouse()
	get_tree().change_scene_to_file(GAME_SCENE)
