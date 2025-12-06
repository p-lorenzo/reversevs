extends Node

signal threat_changed(new_threat_level: int)

var threat_level: int = 0

func try_spawn_entity(threat_modifier: int) -> bool:
	print("current threat: " + str(threat_level) + "\n")
	print("spawn cost: " + str(threat_modifier) + "\n")
	print("resulting threat: " + str(threat_level + threat_modifier) + "\n")

	if threat_level + threat_modifier < 0:
		return false
	threat_level += threat_modifier
	threat_changed.emit(threat_level)
	return true

func undo_spawn_entity(threat_modifier: int) -> void:
	threat_level -= threat_modifier
	if threat_level < 0:
		threat_level = 0
	threat_changed.emit(threat_level)

func reset_threat() -> void:
	threat_level = 0
	threat_changed.emit(threat_level)