extends Node

enum Phase { PLAN, SIM, CASTLE_REACHED, HERO_DIED }
signal phase_changed(new_phase: int)

var phase: int = Phase.PLAN
var hero: Node2D = null

var enemies_alive_at_sim_start: int = 0
var remaining_enemies: int = 0

var nav_region: NavigationRegion2D

func get_phase_name(p: int = phase) -> String:
	match p:
		Phase.PLAN:
			return "Planning Wave"
		Phase.SIM:
			return "Fighting Wave"
		Phase.CASTLE_REACHED:
			return "Castle Reached!"
		Phase.HERO_DIED:
			return "Hero Died!"
	return str(p)

func _ready() -> void:
	_refresh_nav_region()
	_refresh_hero()
	for c in get_tree().get_nodes_in_group("castle"):
		if c.has_signal("body_entered"):
			c.connect("body_entered", _on_castle_body_entered)

func is_plan_phase() -> bool:
	return phase == Phase.PLAN

func is_simulation_active() -> bool:
	return phase == Phase.SIM

func start_plan() -> void:
	if phase == Phase.PLAN:
		return
	phase = Phase.PLAN
	phase_changed.emit(phase)
	enemies_alive_at_sim_start = 0
	remaining_enemies = 0

func start_sim() -> void:
	if phase != Phase.PLAN:
		return
	nav_region.bake_navigation_polygon(false)
	_refresh_hero()
	Grid.free_mobile_entities_cells()
	enemies_alive_at_sim_start = 0
	remaining_enemies = 0
	for e in get_tree().get_nodes_in_group("enemies"):
		_connect_enemy_death(e)
		remaining_enemies += 1
	enemies_alive_at_sim_start = remaining_enemies

	phase = Phase.SIM
	phase_changed.emit(phase)

func _connect_enemy_death(e: Node) -> void:
	var hc := e.get_node_or_null("Health")
	if hc and hc.has_signal("died") and not hc.is_connected("died", Callable(self, "_on_enemy_died")):
		hc.connect("died", _on_enemy_died)

func _on_enemy_died() -> void:
	if phase != Phase.SIM:
		return
	remaining_enemies = max(remaining_enemies - 1, 0)
	if enemies_alive_at_sim_start > 0 and remaining_enemies == 0:
		_end_simulation("all_enemies_defeated")

func _end_simulation(reason: String) -> void:
	start_plan()

func _refresh_hero() -> void:
	var hs := get_tree().get_nodes_in_group("hero")
	if hs.size() > 0 and hs[0] is Node2D:
		hero = hs[0]
		var hc := hero.get_node_or_null("Health")
		if hc and not hc.is_connected("died", Callable(self, "_on_hero_died")):
			hc.connect("died", _on_hero_died)

func _refresh_nav_region() -> void:
	var nrs := get_tree().get_nodes_in_group("nav_region")
	if nrs.size() > 0 and nrs[0] is NavigationRegion2D:
		nav_region = nrs[0]

func _on_hero_died() -> void:
	if phase == Phase.SIM:
		phase = Phase.HERO_DIED
		phase_changed.emit(phase)

func _on_castle_body_entered(body: Node) -> void:
	if phase != Phase.SIM:
		return
	if body == hero:
		phase = Phase.CASTLE_REACHED
		phase_changed.emit(phase)
