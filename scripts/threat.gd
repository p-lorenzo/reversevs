extends Node

signal threat_changed(new_threat_level: int)

var threat_level: int = 0

func try_spawn_entity(threat_modifier: int) -> bool:
	threat_level += threat_modifier
	threat_changed.emit(threat_level)
	return true

func undo_spawn_entity(threat_modifier: int) -> void:
	threat_level -= threat_modifier
	if threat_level < 0:
		threat_level = 0
	threat_changed.emit(threat_level)

func threat_needed_for_wave_round(wave_round: int) -> int:
	return (5 + (wave_round - 1) * 3)
	
func is_threat_high_enough_to_start_wave(wave_round: int) -> bool:
	return threat_level >= threat_needed_for_wave_round(wave_round)
	
func reset_threat() -> void:
	threat_level = 0
	threat_changed.emit(threat_level)