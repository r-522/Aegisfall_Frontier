class_name ResourceDisplay
extends Control
## ResourceDisplay ウィジェット — ビルドマテリアルとゴールドの表示
## 値変化時にバウンスアニメーションを再生する
## EventBus.resources_changed に接続、または個別メソッドで直接更新可能

@onready var material_label: Label = $HBoxContainer/MaterialLabel
@onready var gold_label: Label     = $HBoxContainer/GoldLabel
@onready var material_icon: TextureRect = $HBoxContainer/MaterialIcon
@onready var gold_icon: TextureRect     = $HBoxContainer/GoldIcon

var _build_material: int = 0
var _gold: int           = 0

## ラベルに表示するアイコン文字列（テクスチャが未設定の場合のフォールバック）
const _MATERIAL_PREFIX: String = "[Mat] "
const _GOLD_PREFIX: String     = "[G] "

func _ready() -> void:
	EventBus.resources_changed.connect(_on_resources_changed)
	_refresh_display()

# ── 公開 API ───────────────────────────────────────────────────────────────────

func update_build_material(amount: int) -> void:
	var changed: bool = amount != _build_material
	_build_material   = amount
	_refresh_material_label()
	if changed:
		_bounce(material_label)

func update_gold(amount: int) -> void:
	var changed: bool = amount != _gold
	_gold             = amount
	_refresh_gold_label()
	if changed:
		_bounce(gold_label)

# ── 内部ヘルパー ──────────────────────────────────────────────────────────────

func _on_resources_changed(build_material: int, gold: int) -> void:
	var mat_changed:  bool = build_material != _build_material
	var gold_changed: bool = gold != _gold

	_build_material = build_material
	_gold           = gold

	_refresh_display()

	if mat_changed:
		_bounce(material_label)
	if gold_changed:
		_bounce(gold_label)

func _refresh_display() -> void:
	_refresh_material_label()
	_refresh_gold_label()

func _refresh_material_label() -> void:
	material_label.text = _MATERIAL_PREFIX + str(_build_material)

func _refresh_gold_label() -> void:
	gold_label.text = _GOLD_PREFIX + str(_gold)

## 対象ノードを一瞬スケールアップしてから元に戻すバウンス
func _bounce(target: Control) -> void:
	var tween := target.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	target.pivot_offset = target.size * 0.5
	tween.tween_property(target, "scale", Vector2(1.25, 1.25), 0.08)
	tween.tween_property(target, "scale", Vector2.ONE,         0.20)
