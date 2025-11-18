extends NPCStateMachineBody2D

enum States { IDLE, CHASE, ATTACK }

@onready var hero: Node2D = null
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var slash_particle: Node2D = $slash
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

@export var speed: float = 120.0
@export var attack_cooldown: float = 1.0

var _attack_timer: float = 0.0

func _ready() -> void:
	_find_hero()
	super._ready()

func _default_state() -> int:
	return States.CHASE if is_instance_valid(hero) else States.IDLE

func _physics_state(delta: float, current_state: int) -> void:
	if _attack_timer > 0.0:
		_attack_timer = max(0.0, _attack_timer - delta)

	match current_state:
		States.IDLE:
			_stay_put()

		States.CHASE:
			if not is_instance_valid(hero):
				_stay_put()
				return

			_set_target(hero)

		States.ATTACK:
			_stay_put()

			if _attack_timer <= 0.0:
				_perform_attack()
				_attack_timer = attack_cooldown
	
	move_and_slide()
	
func _stay_put() -> void:
	velocity = Vector2.ZERO
	nav_agent.set_target_position(global_position)
	nav_agent.set_velocity(Vector2.ZERO)
	if animated_sprite_2d:
		animated_sprite_2d.play("idle")

func _set_target(target: Node2D) -> void:
	var next_pos: Vector2 = global_position
	if is_instance_valid(target):
		nav_agent.set_target_position(target.global_position)
		next_pos = nav_agent.get_next_path_position()
	velocity = (next_pos - global_position).normalized() * speed
	if animated_sprite_2d:
		animated_sprite_2d.play("walk")

func _query_next_state(current_state: int, delta: float) -> int:
	match current_state:
		States.IDLE:
			if is_instance_valid(hero):
				return States.CHASE
			return States.IDLE

		States.CHASE:
			if not is_instance_valid(hero):
				return States.IDLE
			var dist := global_position.distance_to(hero.global_position)
			if dist <= nav_agent.target_desired_distance:
				return States.ATTACK
			return States.CHASE

		States.ATTACK:
			if not is_instance_valid(hero):
				return States.IDLE
			var dist := global_position.distance_to(hero.global_position)
			if dist > nav_agent.target_desired_distance + 4.0:
				return States.CHASE
			if dist <= nav_agent.target_desired_distance:
				return States.ATTACK

	return current_state

func _perform_attack() -> void:
	if is_instance_valid(hero):
		slash_particle.look_at(hero.global_position)
		slash_particle.get_child(0).emitting = true
		if is_instance_valid(hero):
			var hc := hero.get_node_or_null("Health")
			if hc and hc.has_method("take_damage"):
				hc.take_damage(1)
	pass

func _find_hero() -> void:
	var list := get_tree().get_nodes_in_group("hero")
	if list.size() > 0 and list[0] is Node2D:
		hero = list[0]

func _on_health_died() -> void:
	queue_free()
