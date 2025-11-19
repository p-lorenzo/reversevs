extends Node

class GridElement:
	var entity: Node
	var threat_modifier: int

const GRID_SIZE: int = 16
const HUD_EXCLUSION_HEIGHT: int = 48
var _occupied_cells: Dictionary = {}

func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		floori(world_pos.x / GRID_SIZE),
		floori(world_pos.y / GRID_SIZE)
	)

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(
		grid_pos.x * GRID_SIZE + GRID_SIZE / 2.0,
		grid_pos.y * GRID_SIZE + GRID_SIZE / 2.0
	)

func snap_to_grid(world_pos: Vector2) -> Vector2:
	var grid_pos := world_to_grid(world_pos)
	return grid_to_world(grid_pos)

func is_cell_occupied(grid_pos: Vector2i) -> bool:
	return _occupied_cells.has(grid_pos)

func _is_entity_static(entity: Node) -> bool:
	return entity.is_in_group("obstacles")

func occupy_cell(grid_pos: Vector2i, entity: Node2D, threat_modifier: int) -> bool:
	if is_cell_occupied(grid_pos):
		return false
	if not is_grid_position_spawnable(grid_pos):
		return false
	var grid_element := GridElement.new()
	grid_element.entity = entity
	grid_element.threat_modifier = threat_modifier
	_occupied_cells[grid_pos] = grid_element
	return true

func free_mobile_entities_cells() -> void:
	var cells_to_free: Array[Vector2i] = []
	for grid_pos in _occupied_cells.keys():
		var entity = _occupied_cells[grid_pos].entity
		if entity and not _is_entity_static(entity):
			cells_to_free.append(grid_pos)
	
	for grid_pos in cells_to_free:
		_occupied_cells.erase(grid_pos)

func is_world_position_spawnable(world_pos: Vector2) -> bool:
	return world_pos.y < _get_bottom_spawn_limit()

func is_grid_position_spawnable(grid_pos: Vector2i) -> bool:
	return is_world_position_spawnable(grid_to_world(grid_pos))

func _get_bottom_spawn_limit() -> float:
	var viewport_height := float(ProjectSettings.get_setting("display/window/size/viewport_height", 0))
	return viewport_height - HUD_EXCLUSION_HEIGHT
