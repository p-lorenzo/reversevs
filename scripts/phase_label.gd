extends Label

func _ready() -> void:
	text = Game.get_phase_name()
	if not Game.phase_changed.is_connected(_on_phase_changed):
		Game.phase_changed.connect(_on_phase_changed)

func _on_phase_changed(new_phase: int) -> void:
	text = Game.get_phase_name(new_phase)
