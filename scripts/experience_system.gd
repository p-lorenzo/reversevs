extends Node

signal xp_changed(total_xp: int)
signal enemy_killed(xp_gained: int, total_xp: int)

var total_xp: int = 0

func _ready() -> void:
	_connect_existing_health_components()
	if not get_tree().is_connected("node_added", Callable(self, "_on_node_added")):
		get_tree().connect("node_added", _on_node_added)
	if not get_tree().is_connected("node_removed", Callable(self, "_on_node_removed")):
		get_tree().connect("node_removed", _on_node_removed)

func _connect_existing_health_components() -> void:
	_walk_and_connect(get_tree().root)

func _walk_and_connect(node: Node) -> void:
	_try_connect_health(node)
	for c in node.get_children():
		_walk_and_connect(c)

func _on_node_added(node: Node) -> void:
	_try_connect_health(node)

func _on_node_removed(node: Node) -> void:
	_try_disconnect_health(node)

func _try_connect_health(node: Node) -> void:
	if node is HealthComponent:
		var hc: HealthComponent = node
		if not hc.has_meta("__xp_connected"):
			hc.connect("died", Callable(self, "_on_health_died").bind(hc))
			hc.set_meta("__xp_connected", true)

func _try_disconnect_health(node: Node) -> void:
	if node is HealthComponent:
		var hc: HealthComponent = node
		if hc.has_meta("__xp_connected"):
			# Non è necessario disconnettere se il nodo viene rimosso/freed,
			# ma puliamo il meta per sicurezza.
			hc.remove_meta("__xp_connected")

func _on_health_died(hc: HealthComponent) -> void:
	if hc.is_enemy:
		var gain: int = max(0, hc.get_exp_granted())
		total_xp += gain
		enemy_killed.emit(gain, total_xp)
		xp_changed.emit(total_xp)
