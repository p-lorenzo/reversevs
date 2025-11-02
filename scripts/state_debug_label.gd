extends Node2D

@export var y_offset: float = 24.0
@export var x_offset: float = 0.0
@export var update_interval: float = 0.1
@export var auto_hide_when_missing: bool = true

var _label: Label
var _accum: float = 0.0

func _ready() -> void:
	_label = Label.new()
	_label.name = "StateDebugLabel"
	_label.z_index = 1000
	_label.modulate = Color(1, 1, 0)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_label.add_theme_constant_override("outline_size", 2)
	add_child(_label)
	_label.position = Vector2(x_offset, y_offset)
	_update_now()

func _process(delta: float) -> void:
	_accum += delta
	if _accum >= update_interval:
		_accum = 0.0
		_update_now()

func _update_now() -> void:
	var parent = get_parent()
	var state_text = _get_state_text(parent)
	if state_text == "":
		if auto_hide_when_missing:
			_label.visible = false
		else:
			_label.visible = true
			_label.text = "(no state)"
		return

	_label.visible = true
	_label.text = state_text
	_label.position = Vector2(x_offset, y_offset)

func _get_state_text(node: Object) -> String:
	if node == null:
		return ""

	# tenta di leggere una proprietà 'state' intera
	var state_value = node.get("state")

	# prova a leggere anche l'enum 'State'
	var enum_dict = node.get("State")

	if typeof(state_value) == TYPE_INT and enum_dict is Dictionary:
		# mappa int -> nome trovando chiave per valore
		for k in enum_dict.keys():
			if enum_dict[k] == state_value:
				return str(k)
		# fallback se non trovato
		return str(state_value)

	if state_value != null:
		return str(state_value)

	return ""
