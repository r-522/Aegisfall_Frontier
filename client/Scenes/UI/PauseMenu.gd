class_name PauseMenu
extends CanvasLayer
## ポーズメニュー — 設定パネル付き Resume/Settings/Quit
## EventBus.dialog_started("pause_menu") で開く
## GameConfig.save_user_config() で設定を永続化

@onready var main_panel: PanelContainer = $MainPanel
@onready var settings_panel: PanelContainer = $SettingsPanel

# メインパネルボタン
@onready var resume_button: Button = $MainPanel/VBoxContainer/ResumeButton
@onready var settings_button: Button = $MainPanel/VBoxContainer/SettingsButton
@onready var quit_button: Button = $MainPanel/VBoxContainer/QuitButton

# 設定パネル — オーディオ
@onready var master_volume_slider: HSlider = $SettingsPanel/VBoxContainer/AudioSection/MasterVolumeSlider
@onready var music_volume_slider: HSlider = $SettingsPanel/VBoxContainer/AudioSection/MusicVolumeSlider
@onready var sfx_volume_slider: HSlider = $SettingsPanel/VBoxContainer/AudioSection/SFXVolumeSlider
@onready var voice_volume_slider: HSlider = $SettingsPanel/VBoxContainer/AudioSection/VoiceVolumeSlider

# 設定パネル — コントロール
@onready var sensitivity_slider: HSlider = $SettingsPanel/VBoxContainer/ControlsSection/SensitivitySlider

# 設定パネル — ビデオ
@onready var quality_dropdown: OptionButton = $SettingsPanel/VBoxContainer/VideoSection/QualityDropdown

# 設定パネル — ボタン
@onready var settings_apply_button: Button = $SettingsPanel/VBoxContainer/ButtonRow/ApplyButton
@onready var settings_back_button: Button = $SettingsPanel/VBoxContainer/ButtonRow/BackButton

func _ready() -> void:
	_wire_buttons()
	_populate_quality_dropdown()
	settings_panel.hide()
	hide()

	EventBus.dialog_started.connect(_on_dialog_started)
	EventBus.dialog_ended.connect(_on_dialog_ended)

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_just_pressed("pause"):
		_resume()

# ─── ボタン接続 ──────────────────────────────────────────────────────────────

func _wire_buttons() -> void:
	resume_button.pressed.connect(_resume)
	settings_button.pressed.connect(_open_settings)
	quit_button.pressed.connect(_quit)
	settings_apply_button.pressed.connect(_apply_settings)
	settings_back_button.pressed.connect(_close_settings)

func _populate_quality_dropdown() -> void:
	quality_dropdown.clear()
	quality_dropdown.add_item("Low",    0)
	quality_dropdown.add_item("Medium", 1)
	quality_dropdown.add_item("High",   2)
	quality_dropdown.add_item("Ultra",  3)

# ─── メインパネル操作 ─────────────────────────────────────────────────────────

func _resume() -> void:
	get_tree().paused = false
	InputMapper.capture_mouse()
	EventBus.dialog_ended.emit(&"pause_menu")
	hide()

func _open_settings() -> void:
	_load_settings_into_ui()
	main_panel.hide()
	settings_panel.show()

func _quit() -> void:
	get_tree().paused = false
	get_tree().quit()

# ─── 設定パネル操作 ───────────────────────────────────────────────────────────

func _load_settings_into_ui() -> void:
	master_volume_slider.value   = GameConfig.master_volume
	music_volume_slider.value    = GameConfig.music_volume
	sfx_volume_slider.value      = GameConfig.sfx_volume
	voice_volume_slider.value    = GameConfig.voice_volume
	sensitivity_slider.value     = GameConfig.mouse_sensitivity
	quality_dropdown.selected    = GameConfig.graphics_quality

func _apply_settings() -> void:
	GameConfig.master_volume    = master_volume_slider.value
	GameConfig.music_volume     = music_volume_slider.value
	GameConfig.sfx_volume       = sfx_volume_slider.value
	GameConfig.voice_volume     = voice_volume_slider.value
	GameConfig.mouse_sensitivity = sensitivity_slider.value
	GameConfig.graphics_quality  = quality_dropdown.selected

	# オーディオバスへ即時反映
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
	_close_settings()

func _close_settings() -> void:
	settings_panel.hide()
	main_panel.show()

# ─── EventBus ────────────────────────────────────────────────────────────────

func _on_dialog_started(dialog_id: StringName) -> void:
	if dialog_id != &"pause_menu":
		return
	get_tree().paused = true
	InputMapper.release_mouse()
	main_panel.show()
	settings_panel.hide()
	show()

func _on_dialog_ended(dialog_id: StringName) -> void:
	if dialog_id == &"pause_menu" and visible:
		_resume()
