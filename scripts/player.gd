extends Node2D
class_name SpawnerOnClick

@export var spawn_parent_path: Node
@export var inventory: Inventory

var _spawn_parent: Node = null
var _selected_scene: PackedScene = null
var _selected_sprite_texture: Texture2D = null
var _last_spawned_entity: Node2D = null
var _hero: Hero = null
var _nav_region: NavigationRegion2D = null
var _is_pressing := false
var _spawn_cooldown := 0.3
var _current_cooldown := 0.0

func _ready() -> void:
	_spawn_parent = spawn_parent_path
	_find_inventory()
	_find_hero()
	_find_nav_region()
	
	if inventory:
		if not inventory.selection_changed.is_connected(_on_inventory_selection_changed):
			inventory.selection_changed.connect(_on_inventory_selection_changed)
		_selected_scene = inventory.get_selected_scene()

func _process(delta: float) -> void:
	if !_hero: 
		return
	_handle_spawning(delta)
	

func _handle_spawning(delta: float) -> void:
	_current_cooldown -= delta;
	if _is_pressing and _current_cooldown <= 0:
		_spawn_at(get_global_mouse_position())
		_current_cooldown = _spawn_cooldown

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

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		_is_pressing = true
	
	if event is InputEventMouseButton and event.is_released() and event.button_index == MOUSE_BUTTON_LEFT:
		_is_pressing = false

func _spawn_at(world_pos: Vector2) -> void:
	if _selected_scene == null:
		push_warning("Nessuna scena selezionata per lo spawn. Assegna enemy_scene o un inventario.")
		return
		
	var entity := _selected_scene.instantiate()
	if entity is Node2D:
		entity.global_position = world_pos
	
	if is_instance_valid(_spawn_parent):
		_spawn_parent.add_child(entity)
	else:
		add_child(entity)
	_nav_region.bake_navigation_polygon(false)	
	_last_spawned_entity = entity
