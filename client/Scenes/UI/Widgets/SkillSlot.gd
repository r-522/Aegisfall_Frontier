class_name SkillSlot
extends Control
## SkillSlot ウィジェット — スキルアイコン・クールダウンオーバーレイ・キーバインドヒント
## HUD の SkillBar (HBoxContainer) の各子として配置する

@onready var icon_texture: TextureRect  = $IconTexture
@onready var cooldown_overlay: ColorRect = $CooldownOverlay
@onready var keybind_label: Label        = $KeybindLabel
@onready var unavailable_overlay: ColorRect = $UnavailableOverlay

## キースロットインデックス (0=Q, 1=C, 2=V, 3=Z)
@export var slot_index: int = 0

var _cooldown_ratio: float = 0.0
var _skill_data: SkillData = null

# スロット番号に対応するキー表示文字列
const _KEYBIND_HINTS: Array[String] = ["Q", "C", "V", "Z"]

func _ready() -> void:
	_apply_keybind_hint()
	cooldown_overlay.color = Color(0.0, 0.0, 0.0, 0.65)
	cooldown_overlay.anchor_top    = 1.0
	cooldown_overlay.anchor_bottom = 1.0
	cooldown_overlay.grow_vertical = Control.GROW_DIRECTION_BEGIN
	# SkillData 未設定時は暗転
	_refresh_unavailable()
	set_cooldown_ratio(0.0)

# ── 公開 API ───────────────────────────────────────────────────────────────────

## クールダウン比率 0.0=レディ、1.0=フルクールダウン
func set_cooldown_ratio(ratio: float) -> void:
	_cooldown_ratio = clampf(ratio, 0.0, 1.0)
	# オーバーレイの高さをスロット高さ × ratio に設定
	cooldown_overlay.size.y = size.y * _cooldown_ratio
	# オーバーレイの位置をボトムアンカーに揃える
	cooldown_overlay.position.y = size.y - cooldown_overlay.size.y
	cooldown_overlay.visible = _cooldown_ratio > 0.001

## スキルデータをセットしてアイコン・テキストを更新
func set_skill_data(data: SkillData) -> void:
	_skill_data = data
	if data == null:
		icon_texture.texture = null
		tooltip_text = ""
	else:
		icon_texture.texture = data.icon
		tooltip_text = "%s\nMP: %.0f  CD: %.1fs\n%s" % [
			data.display_name,
			data.mana_cost,
			data.cooldown,
			data.description
		]
	_refresh_unavailable()

# ── 内部ヘルパー ──────────────────────────────────────────────────────────────

func _apply_keybind_hint() -> void:
	if slot_index < _KEYBIND_HINTS.size():
		keybind_label.text = _KEYBIND_HINTS[slot_index]
	else:
		keybind_label.text = str(slot_index + 1)

func _refresh_unavailable() -> void:
	unavailable_overlay.visible = (_skill_data == null)

## サイズ変更時にオーバーレイ位置を再計算
func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		set_cooldown_ratio(_cooldown_ratio)
