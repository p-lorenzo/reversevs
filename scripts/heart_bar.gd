extends HBoxContainer

@export var full_heart: Texture2D
@export var empty_heart: Texture2D
@export var hp_per_heart: int = 10  # quanta HP vale 1 cuore (es. 100 HP -> 10 cuori)
@export var heart_size: Vector2i = Vector2i(16, 16)

var _hero: Node2D = null
var _health: Node = null
var _max_hp: int = 0
var _cur_hp: int = 0

func _ready() -> void:
	# Trova hero dal singleton Game o dal gruppo "hero"
	if typeof(Game) != TYPE_NIL and Game.hero:
		_bind_to_hero(Game.hero)
	else:
		var hs := get_tree().get_nodes_in_group("hero")
		if hs.size() > 0 and hs[0] is Node2D:
			_bind_to_hero(hs[0])

	# Se Game cambia eroe (respawn), potresti voler ricollegare:
	if typeof(Game) != TYPE_NIL and not Game.phase_changed.is_connected(_on_phase_changed):
		Game.phase_changed.connect(_on_phase_changed)

func _on_phase_changed(_p: int) -> void:
	# Ricontrolla l'eroe quando si entra in SIM (o esci), nel dubbio ricollega
	if typeof(Game) != TYPE_NIL and Game.hero and Game.hero != _hero:
		_bind_to_hero(Game.hero)

func _bind_to_hero(hero: Node2D) -> void:
	_hero = hero
	_health = _hero.get_node_or_null("Health")
	if _health == null:
		_clear_hearts()
		return

	# Disconnetti eventuali connessioni precedenti
	if _health.is_connected("health_changed", Callable(self, "_on_health_changed")):
		_health.disconnect("health_changed", _on_health_changed)
	if _health.is_connected("healed", Callable(self, "_on_healed")):
		_health.disconnect("healed", _on_healed)
	if _health.is_connected("damaged", Callable(self, "_on_damaged")):
		_health.disconnect("damaged", _on_damaged)

	# Connetti ai segnali dell'health component
	_health.connect("health_changed", _on_health_changed)
	_health.connect("healed", _on_healed)
	_health.connect("damaged", _on_damaged)

	# Inizializza valori e UI
	_max_hp = _health.max_health if "max_health" in _health else 0
	_cur_hp = _health.current_health if "current_health" in _health else 0
	_rebuild_hearts()
	_update_hearts_fill()

func _on_health_changed(current_health: int, max_health: int) -> void:
	_cur_hp = current_health
	if max_health != _max_hp:
		_max_hp = max_health
		_rebuild_hearts()
	_update_hearts_fill()

func _on_healed(_amount: int) -> void:
	# Il dettaglio esatto arriva anche via health_changed; qui basta aggiornare safe
	_update_hearts_fill()

func _on_damaged(_amount: int) -> void:
	_update_hearts_fill()

func _rebuild_hearts() -> void:
	_clear_hearts()
	if hp_per_heart <= 0:
		hp_per_heart = 1
	var hearts := int(ceil(float(_max_hp) / float(hp_per_heart)))
	for i in hearts:
		var tr := TextureRect.new()
		tr.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		tr.texture = empty_heart
		tr.custom_minimum_size = heart_size
		add_child(tr)

func _update_hearts_fill() -> void:
	if hp_per_heart <= 0:
		hp_per_heart = 1
	var filled := int(ceil(float(_cur_hp) / float(hp_per_heart)))
	var total := get_child_count()
	for i in total:
		var tr := get_child(i)
		if tr is TextureRect:
			tr.texture = full_heart if i < filled else empty_heart

func _clear_hearts() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
