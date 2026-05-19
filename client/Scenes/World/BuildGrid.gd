class_name BuildGrid
extends Node3D
## タワー配置グリッド管理
## セルの占有状態・配置可能範囲を管理

signal cell_occupied(cell: Vector3i, tower: Node)
signal cell_freed(cell: Vector3i)

var _occupied_cells: Dictionary = {}  # Vector3i → Node
var _build_zone_cells: Array[Vector3i] = []
var _grid_size: float = GameConfig.TOWER_GRID_SIZE

func _ready() -> void:
	EventBus.tower_destroyed.connect(_on_tower_destroyed)

func world_to_cell(world_pos: Vector3) -> Vector3i:
	return Vector3i(
		roundi(world_pos.x / _grid_size),
		0,
		roundi(world_pos.z / _grid_size)
	)

func cell_to_world(cell: Vector3i) -> Vector3:
	return Vector3(
		cell.x * _grid_size,
		0.0,
		cell.z * _grid_size
	)

func snap_to_grid(world_pos: Vector3) -> Vector3:
	return cell_to_world(world_to_cell(world_pos))

func is_cell_occupied(cell: Vector3i) -> bool:
	return _occupied_cells.has(cell)

func is_cell_in_build_zone(cell: Vector3i) -> bool:
	if _build_zone_cells.is_empty():
		return true
	return _build_zone_cells.has(cell)

func can_place_tower(world_pos: Vector3) -> bool:
	var cell := world_to_cell(world_pos)
	return not is_cell_occupied(cell) and is_cell_in_build_zone(cell)

func mark_occupied(cell: Vector3i, tower: Node) -> void:
	_occupied_cells[cell] = tower
	cell_occupied.emit(cell, tower)

func free_cell(cell: Vector3i) -> void:
	_occupied_cells.erase(cell)
	cell_freed.emit(cell)

func get_tower_at(cell: Vector3i) -> Node:
	return _occupied_cells.get(cell, null)

func get_tower_at_world_pos(world_pos: Vector3) -> Node:
	return get_tower_at(world_to_cell(world_pos))

func define_build_zone(cells: Array[Vector3i]) -> void:
	_build_zone_cells = cells.duplicate()

func define_build_zone_from_rect(center: Vector3, half_extents: Vector2) -> void:
	_build_zone_cells.clear()
	var center_cell := world_to_cell(center)
	var cells_x := int(half_extents.x / _grid_size) + 1
	var cells_z := int(half_extents.y / _grid_size) + 1
	for x in range(-cells_x, cells_x + 1):
		for z in range(-cells_z, cells_z + 1):
			_build_zone_cells.append(center_cell + Vector3i(x, 0, z))

func get_all_occupied_cells() -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	for key in _occupied_cells.keys():
		result.append(key)
	return result

func get_neighboring_cells(cell: Vector3i, radius: int = 1) -> Array[Vector3i]:
	var neighbors: Array[Vector3i] = []
	for x in range(-radius, radius + 1):
		for z in range(-radius, radius + 1):
			if x == 0 and z == 0:
				continue
			neighbors.append(cell + Vector3i(x, 0, z))
	return neighbors

func _on_tower_destroyed(tower: Node) -> void:
	for cell in _occupied_cells.keys():
		if _occupied_cells[cell] == tower:
			free_cell(cell)
			return
