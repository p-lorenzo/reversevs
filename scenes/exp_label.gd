extends Label

func _ready() -> void:
	if typeof(ExperienceSystem) != TYPE_NIL and not ExperienceSystem.xp_changed.is_connected(_on_xp_changed):
		ExperienceSystem.xp_changed.connect(_on_xp_changed)
	_on_xp_changed(ExperienceSystem.total_xp if typeof(ExperienceSystem) != TYPE_NIL else 0)

func _on_xp_changed(total: int) -> void:
	text = "XP: %d" % total
