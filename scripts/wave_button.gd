extends Button

#connect to Threat.threat_changed to update button state

func _ready() -> void:
	if Threat and not Threat.threat_changed.is_connected(_on_threat_changed):
		Threat.threat_changed.connect(_on_threat_changed)

func _on_threat_changed(new_threat_level: int) -> void:
	text = "Start Wave \n %d/%d" % [new_threat_level, Threat.threat_needed_for_wave_round(Game.wave_round)]	
	pass

func update_button_state() -> void:
	text = "Start Wave \n %d/%d" % [Threat.threat_level, Threat.threat_needed_for_wave_round(Game.wave_round)]