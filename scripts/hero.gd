extends NPCStateMachineBody2D
class_name Hero

enum States { MOVE_TO_CASTLE, CHASE_ENEMY, ATTACK, IDLE, CASTLE_REACHED }

@onready var default_target: Node2D = $"../BossCastle"
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var slash_particle: Node2D = $slash
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var hit_area: Area2D = $HitArea

@export var speed: float = 250.0
@export var aggro_range: float = 200.0
@export var attack_range: float = 20.0

@export var attack_cooldown: float = 0.7
var _attack_timer: float = 0.0

var enemy: Node2D = null

func _ready() -> void:
	if is_instance_valid(default_target) and default_target.has_signal("body_entered"):
		default_target.connect("body_entered", Callable(self, "_on_castle_body_entered"))
	if nav_agent:
		nav_agent.avoidance_enabled = true
		nav_agent.set_target_position(default_target.global_position)
		nav_agent.target_desired_distance = attack_range
	super._ready()

func _default_state() -> int:
	return States.MOVE_TO_CASTLE

func _update_facing() -> void:
	if not animated_sprite_2d:
		return
	if abs(velocity.x) > 0.0001:
		animated_sprite_2d.flip_h = velocity.x < 0
		return
	if is_instance_valid(enemy):
		animated_sprite_2d.flip_h = enemy.global_position.x < global_position.x

func _physics_state(delta: float, current_state: int) -> void:
	_update_facing()

	if _attack_timer > 0.0:
		_attack_timer = max(0.0, _attack_timer - delta)

	match current_state:
		States.MOVE_TO_CASTLE:
			enemy = _get_nearest_enemy_in_range(aggro_range)
			var to_castle := default_target.global_position - global_position
			if to_castle.length() <= nav_agent.target_desired_distance:
				_stay_put()
				if animated_sprite_2d: animated_sprite_2d.play("idle")
			else:
				_set_target(default_target)
	
		States.CHASE_ENEMY:
			if not is_instance_valid(enemy):
				enemy = _get_nearest_enemy_in_range(aggro_range)
				if not enemy:
					_stay_put()
					if animated_sprite_2d: animated_sprite_2d.play("idle")
					return
	
			_set_target(enemy)
			
	
		States.ATTACK:
			_stay_put()
			if animated_sprite_2d: animated_sprite_2d.play("attack")
	
			if _attack_timer <= 0.0 and is_instance_valid(enemy):
				_perform_attack(enemy)
				_attack_timer = attack_cooldown
	
		States.IDLE:
			_stay_put()
			enemy = _get_nearest_enemy_in_range(aggro_range)

		States.CASTLE_REACHED:
			_stay_put()
		
	move_and_slide()

func _stay_put() -> void:
	velocity = Vector2.ZERO
	nav_agent.set_target_position(global_position)
	nav_agent.set_velocity(Vector2.ZERO)
	if animated_sprite_2d: animated_sprite_2d.play("idle")
	
func _set_target(target: Node2D) -> void:
	var next_pos: Vector2 = global_position
	if is_instance_valid(target):
		nav_agent.set_target_position(target.global_position)
		next_pos = nav_agent.get_next_path_position()
	velocity = (next_pos - global_position).normalized() * speed
	if animated_sprite_2d:
		animated_sprite_2d.play("walk")

func _query_next_state(current_state: int, _delta: float) -> int:
	match current_state:
		States.MOVE_TO_CASTLE:
			if enemy:
				return States.CHASE_ENEMY
			return States.MOVE_TO_CASTLE
	
		States.CHASE_ENEMY:
			if not is_instance_valid(enemy):
				enemy = _get_nearest_enemy_in_range(aggro_range)
				return States.MOVE_TO_CASTLE if not enemy else States.CHASE_ENEMY
			var dist_enemy := global_position.distance_to(enemy.global_position)
			if dist_enemy <= nav_agent.target_desired_distance:
				return States.ATTACK
			return States.CHASE_ENEMY
	
		States.ATTACK:
			if not is_instance_valid(enemy):
				return States.MOVE_TO_CASTLE
			var dist_enemy := global_position.distance_to(enemy.global_position)
			if dist_enemy > nav_agent.target_desired_distance + 4.0:
				return States.CHASE_ENEMY
			if dist_enemy <= nav_agent.target_desired_distance:
				return States.ATTACK
	
		States.IDLE:
			if enemy:
				return States.CHASE_ENEMY
			return States.IDLE

	return current_state

func _perform_attack(target_enemy: Node2D) -> void:
	slash_particle.look_at(target_enemy.global_position)
	slash_particle.get_child(0).emitting = true
	for body in hit_area.get_overlapping_bodies():
		print(body)
		var hc := body.get_node_or_null("Health")
		if hc and hc.has_method("take_damage"):
			hc.take_damage(1)

func _get_nearest_enemy_in_range(search_range: float) -> Node2D:
	var nearest: Node2D = null
	var best_dist := search_range
	for e in get_tree().get_nodes_in_group("enemies"):
		if not (e is Node2D):
			continue
		var d := global_position.distance_to(e.global_position)
		if d <= best_dist:
			best_dist = d
			nearest = e
	return nearest

func _on_castle_body_entered(body: Node) -> void:
	if body == self:
		force_state(States.CASTLE_REACHED)

func _on_health_died() -> void:
	queue_free()
	
func reset_target() -> void:
	if is_instance_valid(default_target):
		nav_agent.set_target_position(default_target.global_position)
