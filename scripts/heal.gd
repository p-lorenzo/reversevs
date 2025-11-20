extends Area2D

@export var heal_amount: int = 1

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body == null:
		return
	
	if not body.is_in_group("hero"):
		return
	
	var health := body.get_node_or_null("Health")
	if health and health.has_method("heal"):
		health.heal(heal_amount)
	
	queue_free()
