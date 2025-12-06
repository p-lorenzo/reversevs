extends Node

var hero: Node2D = null
var nav_region: NavigationRegion2D

func _ready() -> void:
	_refresh_nav_region()
	_refresh_hero()
	for c in get_tree().get_nodes_in_group("castle"):
		if c.has_signal("body_entered"):
			c.connect("body_entered", _on_castle_body_entered)

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
	pass

func _on_castle_body_entered(body: Node) -> void:
	if body == hero:
		pass
