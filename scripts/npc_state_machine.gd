class_name NPCStateMachineBody2D
extends CharacterBody2D

signal state_changed(old_state: int, new_state: int)

enum DebugLabelMode { AUTO, ON, OFF }
@export var state_label_mode: DebugLabelMode = DebugLabelMode.AUTO
@export var state_label_offset: Vector2 = Vector2(0, -24)
@export var state_label_font_size: int = 14
@export var state_label_bg: bool = true

var _state_label: Label = null

@export var initial_state: int = -1

var state: int = -1
var state_time: float = 0.0

func _ready() -> void:
	state = initial_state if initial_state >= 0 else _default_state()
	_setup_state_label_if_needed()
	_on_state_enter(state)
	_update_state_label()

func _physics_process(delta: float) -> void:
	state_time += delta

	_physics_state(delta, state)

	var next := _query_next_state(state, delta)
	if next != state:
		_on_state_exit(state)
		var old := state
		state = next
		state_time = 0.0
		_on_state_enter(state)
		state_changed.emit(old, state)
		_update_state_label()

	_update_state_label_position()

func _default_state() -> int:
	push_error("Implementa _default_state() nella sottoclasse.")
	return 0

func _physics_state(delta: float, current_state: int) -> void:
	pass

func _query_next_state(current_state: int, delta: float) -> int:
	return current_state

func _on_state_enter(new_state: int) -> void:
	pass

func _on_state_exit(old_state: int) -> void:
	pass

func _state_name(s: int) -> String:
	# Se la sottoclasse ha una costante "State" o "States", cerca lì
	if has_meta("enum_name_map"):
		var map = get_meta("enum_name_map")
		if map.has(s):
			return map[s]

	if "State" in self:
		var dict = self.State
		for k in dict.keys():
			if dict[k] == s:
				return k
	elif "States" in self:
		var dict = self.States
		for k in dict.keys():
			if dict[k] == s:
				return k

	return str(s)

func force_state(new_state: int) -> void:
	if new_state == state:
		return
	_on_state_exit(state)
	var old := state
	state = new_state
	state_time = 0.0
	_on_state_enter(state)
	state_changed.emit(old, state)
	_update_state_label()

func _should_show_state_label() -> bool:
	match state_label_mode:
		DebugLabelMode.ON:
			return true
		DebugLabelMode.OFF:
			return false
		DebugLabelMode.AUTO:
			return Engine.is_editor_hint() or OS.is_debug_build()
	return false

func _setup_state_label_if_needed() -> void:
	if not _should_show_state_label():
		if is_instance_valid(_state_label):
			_state_label.queue_free()
			_state_label = null
		return

	if is_instance_valid(_state_label):
		return

	_state_label = Label.new()
	_state_label.name = "__StateLabel"
	_state_label.z_index = 1000
	_state_label.top_level = false
	_state_label.position = state_label_offset
	_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Stile minimale
	if state_label_font_size > 0:
		_state_label.add_theme_font_size_override("font_size", state_label_font_size)
	if state_label_bg:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0, 0, 0, 0.6)
		sb.corner_radius_top_left = 4
		sb.corner_radius_top_right = 4
		sb.corner_radius_bottom_left = 4
		sb.corner_radius_bottom_right = 4
		sb.content_margin_left = 4
		sb.content_margin_right = 4
		sb.content_margin_top = 2
		sb.content_margin_bottom = 2
		_state_label.add_theme_stylebox_override("normal", sb)
	_state_label.self_modulate = Color(1, 1, 1, 0.95)

	add_child(_state_label)

func _update_state_label() -> void:
	if not is_instance_valid(_state_label):
		_setup_state_label_if_needed()
	if not is_instance_valid(_state_label):
		return

	_state_label.text = _state_name(state)
	_state_label.reset_size()
	_state_label.size = _state_label.get_minimum_size()

func _update_state_label_position() -> void:
	if not is_instance_valid(_state_label):
		return
	_state_label.position = state_label_offset
