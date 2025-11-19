extends Node2D
class_name SpawnerOnClick

@export var enemy_scene: PackedScene
@export var spawn_parent_path: Node
@export var enabled_in_plan_only := true
@export var inventory: Inventory

var _spawn_parent: Node = null
var _selected_scene: PackedScene = null
var _selected_sprite_texture: Texture2D = null
var _selected_threat_modifier: int = 0
var _last_spawned_entity: Node2D = null
var _last_occupied_cell: Vector2i = Vector2i.ZERO
var _last_threat_modifier: int = 0
var _hero: Hero = null
var _nav_region: NavigationRegion2D = null

func _ready() -> void:
	_spawn_parent = spawn_parent_path
	_find_inventory()
	_find_hero()
	_find_nav_region()
	
	if inventory:
		if not inventory.selection_changed.is_connected(_on_inventory_selection_changed):
			inventory.selection_changed.connect(_on_inventory_selection_changed)
		_selected_scene = inventory.get_selected_scene()
	elif enemy_scene:
		_selected_scene = enemy_scene

func _process(_delta: float) -> void:
	if !Game.is_plan_phase(): 
		hide_highlight()
		return	
	var mouse_pos := get_global_mouse_position()
	var grid_pos := Grid.world_to_grid(Grid.snap_to_grid(mouse_pos))
	highlight_cell(grid_pos)
	if !_hero.nav_agent.is_target_reachable() and Grid.is_cell_occupied(_last_occupied_cell) and is_instance_valid(_last_spawned_entity):
		_last_spawned_entity.queue_free()
		Grid._occupied_cells.erase(_last_occupied_cell)
		Threat.undo_spawn_entity(_last_threat_modifier)
	if !_hero.nav_agent.is_target_reachable():
		_nav_region.bake_navigation_polygon(false)

func _find_inventory() -> void:
	if inventory:
		return
	var invs := get_tree().get_nodes_in_group("inventory")
	if invs.size() > 0 and invs[0] is Inventory:
		inventory = invs[0]

func _find_hero() -> void:
	if _hero:
		return
	var heroes := get_tree().get_nodes_in_group("hero")
	if heroes.size() > 0 and heroes[0] is Hero:
		_hero = heroes[0]

func _find_nav_region() -> void:
	if _nav_region:
		return
	var nav_regions := get_tree().get_nodes_in_group("nav_region")
	if nav_regions.size() > 0 and nav_regions[0] is NavigationRegion2D:
		_nav_region = nav_regions[0]

func _on_inventory_selection_changed(_selected_index: int, selected_inventory_item: InventoryItem) -> void:
	_selected_scene = selected_inventory_item.entity_scene
	_selected_sprite_texture = selected_inventory_item.icon
	_selected_threat_modifier = selected_inventory_item.threat_modifier

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		Game.start_sim()

	if enabled_in_plan_only and (typeof(Game) != TYPE_NIL) and not Game.is_plan_phase():
		return

	if event is InputEventMouseButton and event.is_released() and event.button_index == MOUSE_BUTTON_LEFT:
		_spawn_at(get_global_mouse_position())
		
	if event is InputEventMouseButton and event.is_released() and event.button_index == MOUSE_BUTTON_RIGHT:
		_delete_at(get_global_mouse_position())

func _spawn_at(world_pos: Vector2) -> void:
	var scene_to_spawn := _selected_scene if _selected_scene else enemy_scene
	
	if scene_to_spawn == null:
		push_warning("Nessuna scena selezionata per lo spawn. Assegna enemy_scene o un inventario.")
		return
	var snapped_pos := Grid.snap_to_grid(world_pos)
	var grid_pos := Grid.world_to_grid(snapped_pos)

	if not Grid.is_world_position_spawnable(snapped_pos):
		print("Area HUD non disponibile per lo spawn: ", snapped_pos)
		return

	if Grid.is_cell_occupied(grid_pos):
		print("Cella già occupata: ", grid_pos)
		return
		
	var entity := scene_to_spawn.instantiate()
	if entity is Node2D:
		entity.global_position = snapped_pos
		if not Grid.occupy_cell(grid_pos, entity, _selected_threat_modifier):
			entity.queue_free()
			return
	
	if !Threat.try_spawn_entity(_selected_threat_modifier):
		return
	
	if is_instance_valid(_spawn_parent):
		_spawn_parent.add_child(entity)
	else:
		add_child(entity)
	_nav_region.bake_navigation_polygon(false)	
	_last_spawned_entity = entity
	_last_occupied_cell = grid_pos
	_last_threat_modifier = _selected_threat_modifier

func _delete_at(world_pos: Vector2) -> void:
	var snapped_pos := Grid.snap_to_grid(world_pos)
	var grid_pos := Grid.world_to_grid(snapped_pos)

	if not Grid.is_cell_occupied(grid_pos):
		print("Nessuna entità da eliminare nella cella: ", grid_pos)
		return

	var grid_element = Grid._occupied_cells[grid_pos]
	if grid_element and is_instance_valid(grid_element.entity):
		grid_element.entity.queue_free()
		Threat.undo_spawn_entity(grid_element.threat_modifier)
		Grid._occupied_cells.erase(grid_pos)
		

func _on_button_pressed() -> void:
	Game.start_sim()

func highlight_cell(grid_pos: Vector2i) -> void:
	var highlight_sprite: Sprite2D = get_node_or_null("HighlightSprite")
	if highlight_sprite == null:
		highlight_sprite = Sprite2D.new()
		highlight_sprite.name = "HighlightSprite"
		add_child(highlight_sprite)
	var cell_world_pos := Grid.grid_to_world(grid_pos)
	highlight_sprite.global_position = cell_world_pos
	highlight_sprite.texture = _selected_sprite_texture
	var can_spawn_here := Grid.is_world_position_spawnable(cell_world_pos) and !Grid.is_cell_occupied(grid_pos)
	highlight_sprite.modulate = Color(1, 1, 1, 0.5) if can_spawn_here else Color(1, 0, 0, 0.5)
	
func hide_highlight() -> void:
	var highlight_sprite: Sprite2D = get_node_or_null("HighlightSprite")
	if highlight_sprite != null:
		highlight_sprite.queue_free()
