class_name BuildSystem
extends Node
## ビルドシステム — グリッド配置・プレビューゴースト・コスト確認を管理
## PhaseManager の BUILD / WAVE_DEFENSE フェーズ中に使用可能
## EventBus.build_mode_toggled でアクティブ / 非アクティブを切り替える

@export var build_grid: BuildGrid
@export var placement_layer_mask: int = 0b0001  ## レイキャストで地面を検出するレイヤー

@onready var resource_system: ResourceSystem = $"../ResourceSystem"

# --- ランタイム状態 ---
var _selected_tower_data: TowerData = null
var _preview_instance: Node3D = null
var _build_mode_active: bool = false

## スナップ先のセルが占有済みかどうかを保持する: Vector3i → Node
var _placed_towers: Dictionary = {}

## 建設制限: プレイヤーごとの上限は GameConfig.MAX_TOWERS_PER_PLAYER
var _placed_count: int = 0

# プレビュー用のデフォルトマテリアル (ゴースト外観)
const _PREVIEW_VALID_COLOR   := Color(0.2, 0.9, 0.2, 0.45)
const _PREVIEW_INVALID_COLOR := Color(0.9, 0.2, 0.2, 0.45)

signal build_mode_changed(active: bool)
signal tower_preview_snapped(cell: Vector3i, world_pos: Vector3)

# ========================================================================== #
# ライフサイクル
# ========================================================================== #

func _ready() -> void:
	EventBus.build_mode_toggled.connect(_on_build_mode_toggled)
	EventBus.tower_selected_for_build.connect(_on_tower_selected_for_build)
	set_process(false)  # ビルドモードが有効な間だけ処理する

func _process(_delta: float) -> void:
	if not _build_mode_active or _preview_instance == null:
		return
	var world_pos := _get_cursor_world_position()
	if world_pos != Vector3.INF:
		_update_preview(world_pos)

# ========================================================================== #
# パブリック API
# ========================================================================== #

## ビルドモードを有効化する。select_tower() が呼ばれるまでプレビューは表示しない
func enable_build_mode() -> void:
	if _build_mode_active:
		return
	_build_mode_active = true
	set_process(true)
	build_mode_changed.emit(true)
	EventBus.build_mode_toggled.emit(true)

## ビルドモードを無効化してプレビューゴーストを破棄する
func disable_build_mode() -> void:
	if not _build_mode_active:
		return
	_build_mode_active = false
	set_process(false)
	_destroy_preview()
	_selected_tower_data = null
	build_mode_changed.emit(false)
	EventBus.build_mode_toggled.emit(false)

## 配置するタワーを選択し、プレビューメッシュを差し替える
func select_tower(data: TowerData) -> void:
	if data == null:
		return
	_selected_tower_data = data
	_rebuild_preview()

## カーソルが指すワールド座標にタワーを配置しようとする
## 成功時 true を返し EventBus.tower_placed を発火する
func try_place_tower(world_pos: Vector3) -> bool:
	if not _build_mode_active:
		return false
	if _selected_tower_data == null:
		return false
	if _placed_count >= GameConfig.MAX_TOWERS_PER_PLAYER:
		push_warning("BuildSystem: タワー上限に達しました (%d)" % GameConfig.MAX_TOWERS_PER_PLAYER)
		return false
	if not resource_system.can_afford_tower(_selected_tower_data):
		return false

	var cell := _world_to_cell(world_pos)
	if _placed_towers.has(cell):
		return false  # セルが使用済み

	if build_grid and not build_grid.is_cell_buildable(cell):
		return false

	# コスト消費
	if not resource_system.spend_build_material(_selected_tower_data.build_cost):
		return false

	# タワーのシーンをインスタンス化する
	var tower := _instantiate_tower(_selected_tower_data, _cell_to_world(cell))
	if tower == null:
		# ロール バック: リソースを返却する
		resource_system.add_build_material(_selected_tower_data.build_cost)
		return false

	_placed_towers[cell] = tower
	_placed_count += 1

	if build_grid:
		build_grid.mark_cell_occupied(cell, tower)

	EventBus.tower_placed.emit(tower, cell)
	return true

## タワーを売却してリソースを 70% 返還する
func try_sell_tower(tower: Node) -> bool:
	if tower == null or not is_instance_valid(tower):
		return false

	var cell := _find_cell_for_tower(tower)
	if cell == Vector3i.MAX:
		return false

	var data: TowerData = tower.get("tower_data") if tower.get("tower_data") != null else null
	var refund: int = 0
	if data:
		refund = int(data.build_cost * GameConfig.TOWER_SELL_REFUND_RATE)
	elif tower.get("sell_value") != null:
		refund = int(tower.sell_value * GameConfig.TOWER_SELL_REFUND_RATE)

	# タワーを除去する
	_placed_towers.erase(cell)
	_placed_count = maxi(0, _placed_count - 1)

	if build_grid:
		build_grid.mark_cell_free(cell)

	EventBus.tower_sold.emit(tower, refund)
	tower.queue_free()

	if refund > 0:
		resource_system.add_build_material(refund)

	return true

## 現在ビルドモードが有効かどうかを返す
func is_build_mode_active() -> bool:
	return _build_mode_active

## 指定セルのタワーを返す。なければ null
func get_tower_at_cell(cell: Vector3i) -> Node:
	return _placed_towers.get(cell, null)

## 配置済みタワー数を返す
func get_placed_count() -> int:
	return _placed_count

# ========================================================================== #
# プレビュー処理
# ========================================================================== #

## ゴーストプレビューを指定ワールド座標にグリッドスナップして移動する
func _update_preview(world_pos: Vector3) -> void:
	if _preview_instance == null:
		return

	var cell := _world_to_cell(world_pos)
	var snapped := _cell_to_world(cell)
	_preview_instance.global_position = snapped

	tower_preview_snapped.emit(cell, snapped)

	# セルが有効かどうかに応じてプレビューの色を変える
	var is_valid := _is_placement_valid(cell)
	_set_preview_color(is_valid)

func _rebuild_preview() -> void:
	_destroy_preview()
	if _selected_tower_data == null:
		return

	# タワーシーンを取得してゴーストインスタンスを作る
	var scene := _get_tower_scene(_selected_tower_data)
	if scene == null:
		# プレビュー用フォールバック: 半透明ボックス
		_preview_instance = _create_box_preview()
	else:
		_preview_instance = scene.instantiate()

	_preview_instance.set_meta(&"is_preview", true)
	_apply_preview_material(_preview_instance)

	# コリジョンを無効化してレイキャストの干渉を防ぐ
	for child in _preview_instance.get_children():
		if child is CollisionShape3D or child is CollisionPolygon3D:
			child.disabled = true
		elif child is Area3D or child is StaticBody3D or child is CharacterBody3D:
			child.collision_layer = 0
			child.collision_mask = 0

	get_tree().current_scene.add_child(_preview_instance)

func _destroy_preview() -> void:
	if is_instance_valid(_preview_instance):
		_preview_instance.queue_free()
	_preview_instance = null

func _set_preview_color(is_valid: bool) -> void:
	if _preview_instance == null:
		return
	var color := _PREVIEW_VALID_COLOR if is_valid else _PREVIEW_INVALID_COLOR
	_recursive_set_mesh_color(_preview_instance, color)

func _apply_preview_material(node: Node) -> void:
	_recursive_set_mesh_color(node, _PREVIEW_VALID_COLOR)

func _recursive_set_mesh_color(node: Node, color: Color) -> void:
	if node is MeshInstance3D:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.flags_transparent = true
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		for i in node.get_surface_override_material_count():
			node.set_surface_override_material(i, mat)
	for child in node.get_children():
		_recursive_set_mesh_color(child, color)

func _create_box_preview() -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(GameConfig.TOWER_GRID_SIZE * 0.9,
						2.0,
						GameConfig.TOWER_GRID_SIZE * 0.9)
	mi.mesh = mesh
	return mi

# ========================================================================== #
# 配置ロジック
# ========================================================================== #

func _is_placement_valid(cell: Vector3i) -> bool:
	if _placed_towers.has(cell):
		return false
	if _placed_count >= GameConfig.MAX_TOWERS_PER_PLAYER:
		return false
	if _selected_tower_data and not resource_system.can_afford_tower(_selected_tower_data):
		return false
	if build_grid and not build_grid.is_cell_buildable(cell):
		return false
	return true

func _instantiate_tower(data: TowerData, world_pos: Vector3) -> Node3D:
	var scene := _get_tower_scene(data)
	if scene == null:
		push_warning("BuildSystem: タワーシーンが見つかりません (id=%s)" % str(data.tower_id))
		return null

	var tower: Node3D = scene.instantiate()
	tower.global_position = world_pos

	# TowerData を注入する
	if tower.get("tower_data") == null:
		tower.set("tower_data", data)

	get_tree().current_scene.add_child(tower)
	return tower

func _get_tower_scene(data: TowerData) -> PackedScene:
	# TowerData が scene_path を持っていれば使う
	if data.get("scene_path") != null and data.scene_path != "":
		var scene: PackedScene = load(data.scene_path)
		if scene:
			return scene

	# フォールバック: tower_id からパスを推測する
	var fallback := "res://Scenes/Towers/%s.tscn" % str(data.tower_id)
	if ResourceLoader.exists(fallback):
		return load(fallback)

	return null

func _find_cell_for_tower(tower: Node) -> Vector3i:
	for cell in _placed_towers:
		if _placed_towers[cell] == tower:
			return cell
	return Vector3i.MAX

# ========================================================================== #
# グリッド変換
# ========================================================================== #

func _world_to_cell(world_pos: Vector3) -> Vector3i:
	var gs := GameConfig.TOWER_GRID_SIZE
	return Vector3i(
		int(floor(world_pos.x / gs)),
		0,
		int(floor(world_pos.z / gs))
	)

func _cell_to_world(cell: Vector3i) -> Vector3:
	var gs := GameConfig.TOWER_GRID_SIZE
	return Vector3(
		(float(cell.x) + 0.5) * gs,
		0.0,
		(float(cell.z) + 0.5) * gs
	)

# ========================================================================== #
# カーソル位置のレイキャスト
# ========================================================================== #

func _get_cursor_world_position() -> Vector3:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return Vector3.INF

	var mouse_pos := get_viewport().get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_dir    := camera.project_ray_normal(mouse_pos)
	var ray_end    := ray_origin + ray_dir * 200.0

	var space_state: PhysicsDirectSpaceState3D = (get_tree().current_scene as Node3D).get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(
		ray_origin, ray_end, placement_layer_mask
	)
	query.exclude = [_preview_instance] if is_instance_valid(_preview_instance) else []

	var result: Dictionary = space_state.intersect_ray(query)
	if result.is_empty():
		return Vector3.INF
	return result["position"]

# ========================================================================== #
# イベントハンドラ
# ========================================================================== #

func _on_build_mode_toggled(active: bool) -> void:
	# EventBus 側から受信した場合にのみ内部状態を同期する
	# (enable/disable_build_mode からの二重発火を防ぐため実際のトグルは行わない)
	if active and not _build_mode_active:
		_build_mode_active = true
		set_process(true)
	elif not active and _build_mode_active:
		_build_mode_active = false
		set_process(false)
		_destroy_preview()
		_selected_tower_data = null

func _on_tower_selected_for_build(tower_data: Resource) -> void:
	if tower_data is TowerData:
		select_tower(tower_data as TowerData)
