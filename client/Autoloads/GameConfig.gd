extends Node
## 読み取り専用ゲーム定数とユーザー設定

# === マルチプレイヤー設定 ===
const MAX_PLAYERS: int = 4
const DEFAULT_SERVER_PORT: int = 7777
const SERVER_TICK_RATE: int = 30
const CLIENT_INTERPOLATION_RATE: int = 60

# === ビルド/タワー設定 ===
const TOWER_GRID_SIZE: float = 2.5
const MAX_TOWERS_PER_PLAYER: int = 50
const TOWER_SELL_REFUND_RATE: float = 0.7

# === フェーズ時間設定 ===
const EXPLORATION_PHASE_DURATION: float = 90.0
const BUILD_PHASE_DURATION: float = 60.0
const COUNTER_ATTACK_PHASE_DURATION: float = 120.0
const WAVE_RESULTS_DELAY: float = 3.0

# === 戦闘感触設定 ===
const HIT_STOP_DURATION: float = 0.06
const HIT_STOP_HEAVY_DURATION: float = 0.12
const CAMERA_SHAKE_NORMAL_MAGNITUDE: float = 0.15
const CAMERA_SHAKE_HEAVY_MAGNITUDE: float = 0.4
const CAMERA_SHAKE_DURATION: float = 0.25
const CAMERA_SHAKE_DECAY: float = 10.0

# === プレイヤー共通設定 ===
const GRAVITY: float = 12.0
const DODGE_INVINCIBILITY_DURATION: float = 0.3
const RESPAWN_DELAY: float = 10.0
const INTERACT_DISTANCE: float = 3.0

# === 難易度設定 ===
const ENEMY_HEALTH_SCALE_PER_PLAYER: float = 0.4
const ENEMY_DAMAGE_SCALE_PER_WAVE: float = 0.05
const ELITE_SPAWN_CHANCE_BASE: float = 0.05
const ELITE_SPAWN_CHANCE_PER_WAVE: float = 0.01

# === スタートリソース ===
const STARTING_BUILD_MATERIAL: int = 300
const STARTING_GOLD: int = 0
const BUILD_MATERIAL_PER_WAVE_KILL: float = 0.5
const GOLD_PER_KILL: int = 5

# === 視覚設定 ===
const FOG_DENSITY: float = 0.008
const AMBIENT_LIGHT_ENERGY: float = 0.3

# ユーザー設定 (user://config.cfg から読み込み)
var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 1.0
var voice_volume: float = 1.0
var mouse_sensitivity: float = 0.002
var camera_fov: float = 75.0
var show_damage_numbers: bool = true
var screen_shake_enabled: bool = true
var screen_shake_intensity: float = 1.0
var graphics_quality: int = 2  # 0=Low, 1=Medium, 2=High, 3=Ultra

const _CONFIG_PATH: String = "user://config.cfg"

func _ready() -> void:
	_load_user_config()

func _load_user_config() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(_CONFIG_PATH) != OK:
		return
	master_volume = cfg.get_value("audio", "master_volume", master_volume)
	music_volume = cfg.get_value("audio", "music_volume", music_volume)
	sfx_volume = cfg.get_value("audio", "sfx_volume", sfx_volume)
	voice_volume = cfg.get_value("audio", "voice_volume", voice_volume)
	mouse_sensitivity = cfg.get_value("controls", "mouse_sensitivity", mouse_sensitivity)
	camera_fov = cfg.get_value("video", "camera_fov", camera_fov)
	show_damage_numbers = cfg.get_value("gameplay", "show_damage_numbers", show_damage_numbers)
	screen_shake_enabled = cfg.get_value("gameplay", "screen_shake_enabled", screen_shake_enabled)
	screen_shake_intensity = cfg.get_value("gameplay", "screen_shake_intensity", screen_shake_intensity)
	graphics_quality = cfg.get_value("video", "graphics_quality", graphics_quality)

func save_user_config() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.set_value("audio", "voice_volume", voice_volume)
	cfg.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	cfg.set_value("video", "camera_fov", camera_fov)
	cfg.set_value("gameplay", "show_damage_numbers", show_damage_numbers)
	cfg.set_value("gameplay", "screen_shake_enabled", screen_shake_enabled)
	cfg.set_value("gameplay", "screen_shake_intensity", screen_shake_intensity)
	cfg.set_value("video", "graphics_quality", graphics_quality)
	cfg.save(_CONFIG_PATH)
