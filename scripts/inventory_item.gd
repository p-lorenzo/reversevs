extends Resource
class_name InventoryItem

@export var entity_scene: PackedScene
@export var icon: Texture2D
@export var cost: int = 0  # Costo per spawnare/comprare l'entità (per uso futuro)

func _init(p_entity_scene: PackedScene = null, p_icon: Texture2D = null, p_cost: int = 0) -> void:
	entity_scene = p_entity_scene
	icon = p_icon
	cost = p_cost
