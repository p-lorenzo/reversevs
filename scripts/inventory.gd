extends HBoxContainer
class_name Inventory

signal selection_changed(selected_index: int, selected_inventory_item: InventoryItem)

# Export variables
@export var empty_slot_texture: Texture2D
@export var selected_slot_modulate: Color = Color(1.2, 1.2, 1.2, 1.0)  # Evidenziazione slot selezionato
@export var normal_slot_modulate: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var slot_size: Vector2i = Vector2i(48, 48)
@export var inventory_items: Array[InventoryItem] = []  # Array di item inventario (contiene scena, icona, costo)

var selected_index: int = 0
var _slots: Array[Control] = []

func _ready() -> void:
	rebuild_inventory()
	# Connetti input per scroll
	set_process_input(true)

func _input(event: InputEvent) -> void:
	if not visible:
		return
	
	# Scroll del mouse per cambiare selezione
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				select_previous()
				get_viewport().set_input_as_handled()
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				select_next()
				get_viewport().set_input_as_handled()
			elif event.button_index == MOUSE_BUTTON_LEFT:
				# Click su uno slot per selezionarlo
				_handle_slot_click(event.position)

func rebuild_inventory() -> void:
	_clear_slots()
	
	if inventory_items.is_empty():
		return
	
	for i in range(inventory_items.size()):
		var slot := _create_slot(i)
		add_child(slot)
		_slots.append(slot)
	
	# Seleziona il primo slot di default
	if _slots.size() > 0:
		select_slot(0)

func _create_slot(index: int) -> Control:
	var container := PanelContainer.new()
	container.custom_minimum_size = slot_size
	container.mouse_filter = Control.MOUSE_FILTER_STOP  # Permette click
	
	# Stile base per lo slot
	var style_box := StyleBoxFlat.new()
	style_box.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color(0.5, 0.5, 0.5, 1.0)
	style_box.corner_radius_top_left = 4
	style_box.corner_radius_top_right = 4
	style_box.corner_radius_bottom_left = 4
	style_box.corner_radius_bottom_right = 4
	container.add_theme_stylebox_override("panel", style_box)
	
	# Container interno per centrare l'icona
	var inner := CenterContainer.new()
	container.add_child(inner)
	
	# TextureRect per l'icona
	var icon_rect := TextureRect.new()
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon_rect.custom_minimum_size = slot_size - Vector2i(8, 8)  # Padding interno
	
	var overlay := Control.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.add_child(overlay)
	
	var threat_bg := ColorRect.new()
	threat_bg.name = "ThreatBackground"
	threat_bg.color = Color(0.1, 0.1, 0.1, 0.55)
	threat_bg.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT, true)
	threat_bg.offset_left = -20
	threat_bg.offset_top = -20
	threat_bg.offset_right = -2
	threat_bg.offset_bottom = -2
	threat_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	threat_bg.visible = false
	overlay.add_child(threat_bg)
	
	var threat_label := Label.new()
	threat_label.name = "ThreatLabel"
	threat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	threat_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	threat_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT, true)
	threat_label.offset_left = -26
	threat_label.offset_top = -20
	threat_label.offset_right = -4
	threat_label.offset_bottom = -4
	threat_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	threat_label.add_theme_font_size_override("font_size", 12)
	overlay.add_child(threat_label)
	
	# Imposta l'icona dall'InventoryItem se disponibile, altrimenti slot vuoto
	if index < inventory_items.size() and inventory_items[index] != null:
		var item: InventoryItem = inventory_items[index]
		if item.icon:
			icon_rect.texture = item.icon
		elif empty_slot_texture:
			icon_rect.texture = empty_slot_texture
		
		_update_threat_label(threat_label, threat_bg, item.threat_modifier)
	else:
		# Slot vuoto
		if empty_slot_texture:
			icon_rect.texture = empty_slot_texture
		threat_bg.visible = false
		threat_label.visible = false
	
	inner.add_child(icon_rect)
	
	# Salva l'indice come metadata per il click
	container.set_meta("slot_index", index)
	
	return container

func _update_threat_label(label: Label, bg: ColorRect, modifier: int) -> void:
	if modifier == 0:
		label.visible = false
		bg.visible = false
		return
	
	label.visible = true
	bg.visible = true
	var prefix := "+" if modifier > 0 else ""
	label.text = "%s%d" % [prefix, modifier]
	
	var positive_color := Color(0.3, 0.9, 0.3, 1.0)
	var negative_color := Color(1.0, 0.3, 0.3, 1.0)
	label.add_theme_color_override("font_color", positive_color if modifier > 0 else negative_color)

func _clear_slots() -> void:
	for slot in _slots:
		if is_instance_valid(slot):
			remove_child(slot)
			slot.queue_free()
	_slots.clear()

func _handle_slot_click(_mouse_pos: Vector2) -> void:
	# Converti posizione mouse in coordinate locali del container
	var local_pos := get_global_mouse_position() - global_position
	
	for i in range(_slots.size()):
		var slot := _slots[i]
		if slot.get_rect().has_point(local_pos):
			select_slot(i)
			get_viewport().set_input_as_handled()
			break

func select_slot(index: int) -> void:
	if index < 0 or index >= _slots.size():
		return
	
	selected_index = index
	
	# Aggiorna evidenziazione
	for i in range(_slots.size()):
		var slot := _slots[i]
		if i == selected_index:
			slot.modulate = selected_slot_modulate
			# Aggiungi bordo più evidente per lo slot selezionato
			var style_box := slot.get_theme_stylebox("panel") as StyleBoxFlat
			if style_box:
				style_box.border_color = Color(1.0, 1.0, 0.0, 1.0)  # Bordo giallo
		else:
			slot.modulate = normal_slot_modulate
			var style_box := slot.get_theme_stylebox("panel") as StyleBoxFlat
			if style_box:
				style_box.border_color = Color(0.5, 0.5, 0.5, 1.0)  # Bordo grigio
	
	# Emetti segnale
	var selected_inventory_item: InventoryItem = null
	if selected_index >= 0 and selected_index < inventory_items.size():
		var item: InventoryItem = inventory_items[selected_index]
		if item:
			selected_inventory_item = item
	selection_changed.emit(selected_index, selected_inventory_item)

func select_next() -> void:
	if _slots.is_empty():
		return
	var next := (selected_index + 1) % _slots.size()
	select_slot(next)

func select_previous() -> void:
	if _slots.is_empty():
		return
	var prev := (selected_index - 1 + _slots.size()) % _slots.size()
	select_slot(prev)

func get_selected_scene() -> PackedScene:
	if selected_index >= 0 and selected_index < inventory_items.size():
		var item: InventoryItem = inventory_items[selected_index]
		if item:
			return item.entity_scene
	return null

func get_selected_item() -> InventoryItem:
	if selected_index >= 0 and selected_index < inventory_items.size():
		return inventory_items[selected_index]
	return null

func set_inventory_items(items: Array[InventoryItem]) -> void:
	inventory_items = items
	rebuild_inventory()
