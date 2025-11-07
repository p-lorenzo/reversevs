class_name HealthComponent
extends Node

@export var is_enemy: bool = false
@export var exp_granted: int = 0
@export var max_health: int = 100
var current_health: int = max_health

signal health_changed(current_health: int, max_health: int)
signal died()
signal healed(amount: int)
signal damaged(amount: int)

func _initialize(max_hp: int) -> void:
	max_health = max_hp
	current_health = max_health

func _ready() -> void:
	current_health = max_health
	
func take_damage(amount: int) -> void:
	if amount <= 0:
		return
	
	current_health = max(current_health - amount, 0)
	emit_signal("damaged", amount)
	emit_signal("health_changed", current_health, max_health)
	
	if current_health == 0:
		emit_signal("died")
		
func heal(amount: int) -> void:
	if amount <= 0:
		return
		
	current_health = min(current_health + amount, max_health)
	emit_signal("healed", amount)
	emit_signal("health_changed", current_health, max_health)
	
func is_alive() -> bool:
	return current_health > 0
	
func get_health_percentage() -> float:
	return float(current_health) / float(max_health) if max_health > 0 else 0.0
	
func get_exp_granted() -> int:
	return exp_granted
