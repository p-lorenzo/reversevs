extends Resource
class_name InventoryItem

@export var entity_scene: PackedScene
@export var icon: Texture2D

func _init(p_entity_scene: PackedScene = null, p_icon: Texture2D = null) -> void:
	entity_scene = p_entity_scene
	icon = p_icon
