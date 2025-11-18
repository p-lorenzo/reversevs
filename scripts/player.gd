# SpawnerOnClick.gd
extends Node2D
class_name SpawnerOnClick

@export var enemy_scene: PackedScene          # Fallback se non c'è inventario
@export var spawn_parent_path: Node
@export var add_to_enemies_group := true      # metti automaticamente i nuovi in "enemies"
@export var enabled_in_plan_only := true
@export var inventory: Inventory              # Riferimento all'inventario (opzionale)

var _spawn_parent: Node = null
var _selected_scene: PackedScene = null

func _ready() -> void:
	_spawn_parent = spawn_parent_path
	_find_inventory()
	
	# Se abbiamo un inventario, ascolta i cambi di selezione
	if inventory:
		if not inventory.selection_changed.is_connected(_on_inventory_selection_changed):
			inventory.selection_changed.connect(_on_inventory_selection_changed)
		# Imposta la scena iniziale
		_selected_scene = inventory.get_selected_scene()
	elif enemy_scene:
		# Fallback alla vecchia logica
		_selected_scene = enemy_scene

func _find_inventory() -> void:
	if inventory:
		return
	# Cerca l'inventario nella scena se non è stato assegnato
	var invs := get_tree().get_nodes_in_group("inventory")
	if invs.size() > 0 and invs[0] is Inventory:
		inventory = invs[0]

func _on_inventory_selection_changed(selected_index: int, selected_scene: PackedScene) -> void:
	_selected_scene = selected_scene

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		Game.start_sim()

	if enabled_in_plan_only and (typeof(Game) != TYPE_NIL) and not Game.is_plan_phase():
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_spawn_at(get_global_mouse_position())

func _spawn_at(world_pos: Vector2) -> void:
	# Usa la scena selezionata dall'inventario, altrimenti fallback a enemy_scene
	var scene_to_spawn := _selected_scene if _selected_scene else enemy_scene
	
	if scene_to_spawn == null:
		push_warning("Nessuna scena selezionata per lo spawn. Assegna enemy_scene o un inventario.")
		return

	var entity := scene_to_spawn.instantiate()
	# Se l'entità è un Node2D (o derivati), posizionalo
	if entity is Node2D:
		entity.global_position = world_pos
	# Attacca al parent designato, altrimenti al nodo corrente
	if is_instance_valid(_spawn_parent):
		_spawn_parent.add_child(entity)
	else:
		add_child(entity)

	# Aggiungi al gruppo enemies se è un nemico (controlla se ha Health.is_enemy)
	if add_to_enemies_group:
		var health := entity.get_node_or_null("Health")
		if health is HealthComponent and health.is_enemy:
			entity.add_to_group("enemies")


func _on_button_pressed() -> void:
	Game.start_sim()
