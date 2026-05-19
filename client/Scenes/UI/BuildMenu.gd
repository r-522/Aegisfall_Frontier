class_name BuildMenu
extends CanvasLayer
## ビルドメニュー — タワー選択グリッド、コスト表示、カテゴリタブ
## EventBus.tower_selected_for_build を発火してタワーを選択する

@onready var tab_bar: TabContainer = $PanelContainer/TabContainer
@onready var defense_grid: GridContainer = $PanelContainer/TabContainer/Defense/ScrollContainer/GridContainer
@onready var attack_grid: GridContainer = $PanelContainer/TabContainer/Attack/ScrollContainer/GridContainer
@onready var support_grid: GridContainer = $PanelContainer/TabContainer/Support/ScrollContainer/GridContainer
@onready var special_grid: GridContainer = $PanelContainer/TabContainer/Special/ScrollContainer/GridContainer
@onready var detail_panel: PanelContainer = $DetailPanel
@onready var detail_name_label: Label = $DetailPanel/VBoxContainer/NameLabel
@onready var detail_desc_label: Label = $DetailPanel/VBoxContainer/DescLabel
@onready var detail_cost_label: Label = $DetailPanel/VBoxContainer/CostLabel
@onready var detail_stats_label: Label = $DetailPanel/VBoxContainer/StatsLabel
@onready var confirm_button: Button = $DetailPanel/VBoxContainer/ConfirmButton
@onready var cancel_button: Button = $DetailPanel/VBoxContainer/CancelButton
@onready var resource_label: Label = $ResourceHeader/MaterialLabel
@onready var gold_label: Label = $ResourceHeader/GoldLabel

const TOWER_DATA_DIR: String = "res://client/Data/Towers/"
const BUTTON_SCENE: String = "res://client/Scenes/UI/Widgets/TowerButton.tscn"

var _tower_db: Array[TowerData] = []
var _selected_tower: TowerData = null
var _current_build_material: int = 0
var _current_gold: int = 0

func _ready() -> void:
	_load_tower_data()
	_populate_grids()
	detail_panel.hide()
	confirm_button.pressed.connect(_on_confirm_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	EventBus.resources_changed.connect(_on_resources_changed)
	EventBus.build_mode_toggled.connect(_on_build_mode_toggled)
	EventBus.dialog_started.connect(_on_dialog_started)
	hide()

func _input(event: InputEvent) -> void:
	if event.is_action_just_pressed("open_build_menu") or event.is_action_just_pressed("ui_cancel"):
		if visible:
			_close()

## タワーデータをres://client/Data/Towers/ディレクトリからロード
func _load_tower_data() -> void:
	_tower_db.clear()
	var dir := DirAccess.open(TOWER_DATA_DIR)
	if dir == null:
		push_warning("BuildMenu: tower data directory not found at %s" % TOWER_DATA_DIR)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var res := load(TOWER_DATA_DIR + file_name)
			if res is TowerData:
				_tower_db.append(res as TowerData)
		file_name = dir.get_next()
	dir.list_dir_end()

## カテゴリ別にGridContainerへボタンを追加
func _populate_grids() -> void:
	_clear_grid(defense_grid)
	_clear_grid(attack_grid)
	_clear_grid(support_grid)
	_clear_grid(special_grid)

	for data in _tower_db:
		var grid := _get_grid_for_category(data.category)
		if grid == null:
			continue
		var btn := Button.new()
		btn.text = data.display_name
		btn.tooltip_text = "[Mat] %d  |  %s" % [data.build_cost, data.description]
		btn.custom_minimum_size = Vector2(100, 80)
		btn.pressed.connect(_on_tower_button_pressed.bind(data))
		grid.add_child(btn)

func _clear_grid(grid: GridContainer) -> void:
	for child in grid.get_children():
		child.queue_free()

func _get_grid_for_category(category: TowerData.TowerCategory) -> GridContainer:
	match category:
		TowerData.TowerCategory.DEFENSE: return defense_grid
		TowerData.TowerCategory.ATTACK:  return attack_grid
		TowerData.TowerCategory.SUPPORT: return support_grid
		TowerData.TowerCategory.SPECIAL: return special_grid
	return null

## タワーボタン押下 — 詳細パネル表示
func _on_tower_button_pressed(data: TowerData) -> void:
	_selected_tower = data
	_refresh_detail_panel()
	detail_panel.show()

func _refresh_detail_panel() -> void:
	if _selected_tower == null:
		detail_panel.hide()
		return
	detail_name_label.text = _selected_tower.display_name
	detail_desc_label.text = _selected_tower.description
	detail_cost_label.text = "[Mat] %d" % _selected_tower.build_cost

	var can_afford: bool = _current_build_material >= _selected_tower.build_cost
	confirm_button.disabled = not can_afford
	if not can_afford:
		detail_cost_label.modulate = Color(1.0, 0.3, 0.3)
	else:
		detail_cost_label.modulate = Color.WHITE

	var stats := ""
	if _selected_tower.attack_damage > 0.0:
		stats += "ATK: %.0f  Range: %.1f\n" % [_selected_tower.attack_damage, _selected_tower.attack_range]
	if _selected_tower.max_health > 0.0:
		stats += "HP: %.0f\n" % _selected_tower.max_health
	if _selected_tower.heal_per_tick > 0.0:
		stats += "Heal/tick: %.1f\n" % _selected_tower.heal_per_tick
	if _selected_tower.buff_type != &"":
		stats += "Buff: %s +%.0f\n" % [_selected_tower.buff_type, _selected_tower.buff_value]
	detail_stats_label.text = stats.strip_edges()

func _on_confirm_pressed() -> void:
	if _selected_tower == null:
		return
	EventBus.tower_selected_for_build.emit(_selected_tower)
	_close()

func _on_cancel_pressed() -> void:
	_selected_tower = null
	detail_panel.hide()

func _on_resources_changed(build_material: int, gold: int) -> void:
	_current_build_material = build_material
	_current_gold = gold
	resource_label.text = "[Mat] %d" % build_material
	gold_label.text = "[G] %d" % gold
	if _selected_tower != null:
		_refresh_detail_panel()

func _on_build_mode_toggled(active: bool) -> void:
	if active:
		_open()
	else:
		_close()

func _on_dialog_started(dialog_id: StringName) -> void:
	if dialog_id == &"build_menu":
		_open()

func _open() -> void:
	InputMapper.release_mouse()
	show()

func _close() -> void:
	InputMapper.capture_mouse()
	_selected_tower = null
	detail_panel.hide()
	hide()
