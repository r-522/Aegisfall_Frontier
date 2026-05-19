class_name WaveResultScreen
extends CanvasLayer
## WaveResultScreen — ウェーブ終了後のリザルト画面
## EventBus.wave_completed で自動表示。右側からスライドイン。
## 統計 (撃破数・ダメージ・生存タワー数・経過時間・報酬) を表示する。

@onready var root_panel: PanelContainer   = $RootPanel
@onready var wave_title_label: Label      = $RootPanel/VBoxContainer/TitleLabel
@onready var kills_label: Label           = $RootPanel/VBoxContainer/StatsGrid/KillsValueLabel
@onready var damage_label: Label          = $RootPanel/VBoxContainer/StatsGrid/DamageValueLabel
@onready var towers_label: Label          = $RootPanel/VBoxContainer/StatsGrid/TowersValueLabel
@onready var time_label: Label            = $RootPanel/VBoxContainer/StatsGrid/TimeValueLabel
@onready var material_reward_label: Label = $RootPanel/VBoxContainer/RewardSection/MaterialRewardLabel
@onready var gold_reward_label: Label     = $RootPanel/VBoxContainer/RewardSection/GoldRewardLabel
@onready var next_wave_button: Button     = $RootPanel/VBoxContainer/ButtonRow/NextWaveButton
@onready var continue_button: Button      = $RootPanel/VBoxContainer/ButtonRow/ContinueButton

# スライドインの開始 X オフセット (画面右外)
const _SLIDE_OFFSET_X: float = 600.0
const _SLIDE_DURATION: float = 0.35

# ランタイムで計上する統計
var _enemies_killed: int = 0
var _damage_dealt: float = 0.0
var _wave_start_time: float = 0.0
var _wave_elapsed: float    = 0.0
var _surviving_towers: int  = 0
var _last_wave_number: int  = 0

# 報酬: ウェーブ開始時点のスナップショットと終了時点の差分で計算
var _reward_build_material: int = 0
var _reward_gold: int           = 0
var _snapshot_build_material: int = 0
var _snapshot_gold: int           = 0
var _latest_build_material: int   = 0
var _latest_gold: int             = 0

# more_waves は外部 (GameWorld) からセットされる
var has_more_waves: bool = true

func _ready() -> void:
	hide()
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.wave_completed.connect(_on_wave_completed)
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.hit_confirmed.connect(_on_hit_confirmed)
	EventBus.tower_destroyed.connect(_on_tower_destroyed)
	EventBus.resources_changed.connect(_on_resources_changed)

	next_wave_button.pressed.connect(_on_next_wave_pressed)
	continue_button.pressed.connect(_on_continue_pressed)

# ─── EventBus ────────────────────────────────────────────────────────────────

func _on_wave_started(_wave_number: int, _total_enemies: int) -> void:
	# 統計をリセット
	_enemies_killed  = 0
	_damage_dealt    = 0.0
	_wave_start_time = Time.get_ticks_msec() / 1000.0
	_wave_elapsed    = 0.0
	_surviving_towers = _count_living_towers()
	# ウェーブ開始時のリソーススナップショットを保存
	_snapshot_build_material = _latest_build_material
	_snapshot_gold           = _latest_gold

func _on_wave_completed(wave_number: int, success: bool) -> void:
	_last_wave_number = wave_number
	_wave_elapsed     = (Time.get_ticks_msec() / 1000.0) - _wave_start_time
	_surviving_towers = _count_living_towers()
	# 差分を報酬として計算
	_reward_build_material = _latest_build_material - _snapshot_build_material
	_reward_gold           = _latest_gold           - _snapshot_gold

	_populate_stats(wave_number, success)
	_show_slide_in()

func _on_enemy_died(_enemy: Node, _pos: Vector3, _xp: int) -> void:
	_enemies_killed += 1

func _on_hit_confirmed(attacker: Node, _target: Node, damage: float, _is_crit: bool) -> void:
	# プレイヤーまたはタワーからのヒットのみカウント
	if attacker.is_in_group("players") or attacker.is_in_group("towers"):
		_damage_dealt += damage

func _on_tower_destroyed(_tower: Node) -> void:
	_surviving_towers = maxi(0, _surviving_towers - 1)

func _on_resources_changed(build_material: int, gold: int) -> void:
	# 常に最新リソース量を追跡し、ウェーブ開始/終了差分で報酬を算出する
	_latest_build_material = build_material
	_latest_gold           = gold

# ─── 表示 ─────────────────────────────────────────────────────────────────────

func _populate_stats(wave_number: int, success: bool) -> void:
	if success:
		wave_title_label.text = "Wave %d — CLEAR!" % wave_number
		wave_title_label.modulate = Color(0.3, 1.0, 0.4)
	else:
		wave_title_label.text = "Wave %d — FAILED" % wave_number
		wave_title_label.modulate = Color(1.0, 0.3, 0.3)

	kills_label.text   = str(_enemies_killed)
	damage_label.text  = "%.0f" % _damage_dealt
	towers_label.text  = str(_surviving_towers)
	time_label.text    = _format_time(_wave_elapsed)

	material_reward_label.text = "[Mat] +%d" % _reward_build_material
	gold_reward_label.text     = "[G] +%d"   % _reward_gold

	# 「次のウェーブ」ボタンはウェーブが残っているときのみ表示
	next_wave_button.visible = has_more_waves and success
	continue_button.visible  = not (has_more_waves and success)

func _show_slide_in() -> void:
	show()
	InputMapper.release_mouse()

	# 初期位置を画面右外にセット
	root_panel.position.x = _SLIDE_OFFSET_X

	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(root_panel, "position:x", 0.0, _SLIDE_DURATION)

func _hide_slide_out() -> void:
	var tween := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(root_panel, "position:x", _SLIDE_OFFSET_X, _SLIDE_DURATION * 0.75)
	tween.tween_callback(func() -> void:
		hide()
		InputMapper.capture_mouse()
	)

# ─── ボタンハンドラ ───────────────────────────────────────────────────────────

func _on_next_wave_pressed() -> void:
	_hide_slide_out()
	# PhaseManager が wave_completed を受けて COUNTER_ATTACK → BUILD → WAVE_DEFENSE
	# と遷移するため、ここでは単純に画面を閉じるだけでよい

func _on_continue_pressed() -> void:
	_hide_slide_out()

# ─── ヘルパー ─────────────────────────────────────────────────────────────────

func _format_time(seconds: float) -> String:
	var s := int(seconds)
	var m := s / 60
	s = s % 60
	return "%d:%02d" % [m, s]

func _count_living_towers() -> int:
	var towers := get_tree().get_nodes_in_group("towers")
	return towers.size()
