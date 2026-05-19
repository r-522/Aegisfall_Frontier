class_name HealthBar
extends Control
## HealthBar ウィジェット — HP比率に応じて赤→橙→黄のグラデーション
## ProgressBarの値変化はスムーズなTweenで補間する

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var value_label: Label = $ValueLabel

var _current_hp: float = 1.0
var _max_hp: float = 1.0
var _show_numbers: bool = true
var _tween: Tween = null

# HP比率に対応した色テーブル
const _COLOR_FULL: Color   = Color(0.20, 0.85, 0.20)   # 緑
const _COLOR_MID: Color    = Color(0.95, 0.55, 0.05)   # 橙
const _COLOR_LOW: Color    = Color(0.90, 0.15, 0.10)   # 赤

func _ready() -> void:
	progress_bar.min_value = 0.0
	progress_bar.max_value = 1.0
	progress_bar.value     = 1.0
	value_label.visible    = _show_numbers
	_apply_color(1.0)

# ── 公開 API ───────────────────────────────────────────────────────────────────

## メインの更新エントリポイント。HUD や EventBus ハンドラから呼ぶ。
func update(current: float, max_hp: float) -> void:
	_current_hp = current
	_max_hp     = max_hp if max_hp > 0.0 else 1.0

	var ratio: float = clampf(_current_hp / _max_hp, 0.0, 1.0)

	# 既存 Tween があればキャンセル
	if _tween and _tween.is_valid():
		_tween.kill()

	_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(progress_bar, "value", ratio, 0.18)

	_apply_color(ratio)
	_refresh_label()

## 数値ラベルを表示 / 非表示する
func set_show_numbers(enabled: bool) -> void:
	_show_numbers  = enabled
	value_label.visible = enabled

# ── 内部ヘルパー ──────────────────────────────────────────────────────────────

func _apply_color(ratio: float) -> void:
	var col: Color
	if ratio >= 0.5:
		# 緑 → 橙 (0.5〜1.0 を 0.0〜1.0 に正規化)
		col = _COLOR_FULL.lerp(_COLOR_MID, 1.0 - (ratio - 0.5) * 2.0)
	else:
		# 橙 → 赤 (0.0〜0.5 を 0.0〜1.0 に正規化)
		col = _COLOR_MID.lerp(_COLOR_LOW, 1.0 - ratio * 2.0)

	# StyleBoxFlatを動的に取得して色を設定する
	var stylebox := progress_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if stylebox != null:
		var sb_copy := stylebox.duplicate() as StyleBoxFlat
		sb_copy.bg_color = col
		progress_bar.add_theme_stylebox_override("fill", sb_copy)
	else:
		# StyleBoxが取れない場合は modulate で代替
		progress_bar.modulate = col

func _refresh_label() -> void:
	if not _show_numbers:
		return
	value_label.text = "%d / %d" % [int(_current_hp), int(_max_hp)]
