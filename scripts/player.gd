# SpawnerOnClick.gd
extends Node2D
class_name SpawnerOnClick

@export var enemy_scene: PackedScene          # assegna qui la scena dell'enemy (PackedScene)
@export var spawn_parent_path: Node
@export var add_to_enemies_group := true      # metti automaticamente i nuovi in "enemies"

var _spawn_parent: Node = null

func _ready() -> void:
	_spawn_parent = spawn_parent_path

func _unhandled_input(event: InputEvent) -> void:
	# Mouse sinistro
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_spawn_at(get_global_mouse_position())
	# Touch (mobile)
	elif event is InputEventScreenTouch and event.pressed:
		var pos = event.position
		var world_pos = pos
		var cam := get_viewport().get_camera_2d()
		if cam:
			world_pos = cam.screen_to_world(pos)
		_spawn_at(world_pos)

func _spawn_at(world_pos: Vector2) -> void:
	if enemy_scene == null:
		push_warning("enemy_scene non assegnata. Niente spawn, niente party.")
		return

	var enemy := enemy_scene.instantiate()
	# Se l'enemy è un Node2D (o derivati), posizionalo
	if enemy is Node2D:
		enemy.global_position = world_pos
	# Attacca al parent designato, altrimenti al nodo corrente
	if is_instance_valid(_spawn_parent):
		_spawn_parent.add_child(enemy)
	else:
		add_child(enemy)

	if add_to_enemies_group:
		enemy.add_to_group("enemies")
