class_name WaveCounter
extends Control
## WaveCounter ウィジェット — 現在のウェーブ番号と残敵プログレスバーを表示
## EventBus.wave_started / enemy_died / wave_completed に接続して自動更新する

@onready var wave_label: Label        = $VBoxContainer/WaveLabel
@onready var progress_bar: ProgressBar = $VBoxContainer/EnemyProgressBar
@onready var enemy_label: Label       = $VBoxContainer/EnemyLabel

var _current_wave: int   = 0
var _total_waves: int    = 0
var _total_enemies: int  = 0
var _remaining_enemies: int = 0

func _ready() -> void:
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.wave_completed.connect(_on_wave_completed)

	progress_bar.min_value = 0.0
	progress_bar.max_value = 1.0
	progress_bar.value     = 0.0

	wave_label.text  = "Wave -/-"
	enemy_label.text = ""

# ── 公開 API ───────────────────────────────────────────────────────────────────

## 現在・合計ウェーブ数をセットして表示を更新する
func set_wave(number: int, total: int) -> void:
	_current_wave = number
	_total_waves  = total
	_refresh_wave_label()

## 残敵数と合計敵数をセットしてプログレスバーを更新する
func set_enemy_count(remaining: int, total: int) -> void:
	_remaining_enemies = remaining
	_total_enemies     = total
	_refresh_enemy_display()

# ── EventBus ハンドラ ──────────────────────────────────────────────────────────

func _on_wave_started(wave_number: int, total_enemies: int) -> void:
	_current_wave      = wave_number
	_total_enemies     = total_enemies
	_remaining_enemies = total_enemies
	_refresh_wave_label()
	_refresh_enemy_display()

func _on_enemy_died(_enemy: Node, _pos: Vector3, _xp: int) -> void:
	_remaining_enemies = maxi(0, _remaining_enemies - 1)
	_refresh_enemy_display()

func _on_wave_completed(_wave_number: int, success: bool) -> void:
	_remaining_enemies = 0
	if success:
		enemy_label.text  = "CLEAR!"
		progress_bar.value = 1.0
	else:
		enemy_label.text  = "FAILED"

# ── 内部ヘルパー ──────────────────────────────────────────────────────────────

func _refresh_wave_label() -> void:
	if _total_waves > 0:
		wave_label.text = "Wave %d / %d" % [_current_wave, _total_waves]
	else:
		wave_label.text = "Wave %d" % _current_wave

func _refresh_enemy_display() -> void:
	enemy_label.text = "Enemies: %d / %d" % [_remaining_enemies, _total_enemies]

	var ratio: float = 0.0
	if _total_enemies > 0:
		ratio = 1.0 - float(_remaining_enemies) / float(_total_enemies)

	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(progress_bar, "value", ratio, 0.25)
