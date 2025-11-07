extends Label

func _ready() -> void:
	text = "Phase: %s" % Game.get_phase_name()
	if not Game.phase_changed.is_connected(_on_phase_changed):
		Game.phase_changed.connect(_on_phase_changed)
	if not Game.wave_ended.is_connected(_on_wave_ended):
		Game.wave_ended.connect(_on_wave_ended)

func _on_phase_changed(new_phase: int) -> void:
	text = "Phase: %s" % Game.get_phase_name(new_phase)

func _on_wave_ended(reason: String) -> void:
	# Facoltativo: mostra un esito a fine ondata
	text = "Wave ended: %s" % reason
