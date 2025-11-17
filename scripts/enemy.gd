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
	if nav_agent:
		# Configurazione base del NavigationAgent2D per l'enemy
		nav_agent.avoidance_enabled = true
		# Vogliamo arrivare grossomodo alla distanza di attacco dall'eroe
		if not nav_agent.velocity_computed.is_connected(_on_nav_agent_velocity_computed):
			nav_agent.velocity_computed.connect(_on_nav_agent_velocity_computed)
	super._ready()

func _default_state() -> int:
	return States.CHASE if is_instance_valid(hero) else States.IDLE

func _physics_state(delta: float, current_state: int) -> void:
	if _attack_timer > 0.0:
		_attack_timer = max(0.0, _attack_timer - delta)

	# Se non abbiamo un NavigationAgent2D, manteniamo il comportamento originale
	if not nav_agent:
		match current_state:
			States.IDLE:
				velocity = Vector2.ZERO
				move_and_slide()
				if animated_sprite_2d:
					animated_sprite_2d.play("idle")

			States.CHASE:
				if not is_instance_valid(hero):
					velocity = Vector2.ZERO
					move_and_slide()
					if animated_sprite_2d:
						animated_sprite_2d.play("idle")
					return

				var to_hero := hero.global_position - global_position
				var dist := to_hero.length()

				if dist > 1.0:
					velocity = to_hero.normalized() * speed
				else:
					velocity = Vector2.ZERO

				move_and_slide()
				if animated_sprite_2d:
					animated_sprite_2d.play("walk")
					animated_sprite_2d.flip_h = velocity.x < 0

			States.ATTACK:
				velocity = Vector2.ZERO
				move_and_slide()
				if animated_sprite_2d:
					animated_sprite_2d.play("attack")

				if _attack_timer <= 0.0:
					_perform_attack()
					_attack_timer = attack_cooldown
		return

	# --- Comportamento con NavigationAgent2D (pathfinding + obstacle avoidance) ---
	match current_state:
		States.IDLE:
			velocity = Vector2.ZERO
			nav_agent.set_target_position(global_position)
			nav_agent.set_velocity(Vector2.ZERO)
			if animated_sprite_2d:
				animated_sprite_2d.play("idle")

		States.CHASE:
			if not is_instance_valid(hero):
				velocity = Vector2.ZERO
				nav_agent.set_target_position(global_position)
				nav_agent.set_velocity(Vector2.ZERO)
				if animated_sprite_2d:
					animated_sprite_2d.play("idle")
				return

			# Aggiorna la destinazione verso l'eroe: il NavigationServer si occupa del path
			nav_agent.set_target_position(hero.global_position)
			var next_pos := nav_agent.get_next_path_position()
			var to_next := next_pos - global_position

			if to_next.length() > 1.0:
				var desired_velocity := to_next.normalized() * speed
				nav_agent.set_velocity(desired_velocity)
			else:
				nav_agent.set_velocity(Vector2.ZERO)

		States.ATTACK:
			# Fermati e attacca, senza pathfinding
			velocity = Vector2.ZERO
			nav_agent.set_target_position(global_position)
			nav_agent.set_velocity(Vector2.ZERO)
			if animated_sprite_2d:
				animated_sprite_2d.play("attack")

			if _attack_timer <= 0.0:
				_perform_attack()
				_attack_timer = attack_cooldown

func _on_nav_agent_velocity_computed(safe_velocity: Vector2) -> void:
	# Applica la velocità calcolata dal NavigationAgent2D solo quando stiamo inseguendo
	if state == States.CHASE:
		velocity = safe_velocity
		move_and_slide()
		if animated_sprite_2d:
			animated_sprite_2d.play("walk")
			animated_sprite_2d.flip_h = velocity.x < 0

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
