extends ProgressBar

var _hero: Node2D = null
var _health: Node = null
@onready var label: Label = $"../Label"
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
	min_value = 0
	max_value = _max_hp
	value = _cur_hp

func _bind_to_hero(hero: Node2D) -> void:
	_hero = hero
	_health = _hero.get_node_or_null("Health")
	if _health == null:
		_max_hp = 0
		_cur_hp = 0
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
	_update_health_bar()

func _on_health_changed(current_health: int, max_health: int) -> void:
	_cur_hp = current_health
	if max_health != _max_hp:
		_max_hp = max_health
	_update_health_bar()

func _on_healed(_amount: int) -> void:
	_update_health_bar()

func _on_damaged(_amount: int) -> void:
	_update_health_bar()
	
func _update_health_bar() -> void:
	value = _cur_hp
	label.text = str(_cur_hp) + "/" + str(_max_hp)
	
