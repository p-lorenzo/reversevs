extends NPCStateMachineBody2D

enum States { MOVE_TO_CASTLE, CHASE_ENEMY, ATTACK, IDLE, CASTLE_REACHED }

@onready var target: Node2D = $"../BossCastle"
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var slash_particle: Node2D = $slash
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

@export var speed: float = 250.0
@export var aggro_range: float = 200.0

@export var attack_cooldown: float = 0.7
var _attack_timer: float = 0.0

var enemy: Node2D = null

func _ready() -> void:
	if is_instance_valid(target) and target.has_signal("body_entered"):
		target.connect("body_entered", Callable(self, "_on_castle_body_entered"))
	if nav_agent:
		# Configurazione base del NavigationAgent2D per Godot 4.5
		nav_agent.avoidance_enabled = true
		nav_agent.set_target_position(global_position)
		if not nav_agent.velocity_computed.is_connected(_on_nav_agent_velocity_computed):
			nav_agent.velocity_computed.connect(_on_nav_agent_velocity_computed)
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

	# default stop nav target if needed
	if not nav_agent:
		# fallback comportamentale originale se non c'è NavigationAgent2D
		_physics_without_nav(delta, current_state)
		return

	match current_state:
		States.MOVE_TO_CASTLE:
			enemy = _get_nearest_enemy_in_range(aggro_range)
	
			var to_castle := Vector2.ZERO
			if is_instance_valid(target):
				to_castle = target.global_position - global_position
	
			if to_castle.length() <= nav_agent.target_desired_distance:
				velocity = Vector2.ZERO
				nav_agent.set_target_position(global_position)
				nav_agent.set_velocity(Vector2.ZERO)
				if animated_sprite_2d: animated_sprite_2d.play("idle")
			else:
				if is_instance_valid(target):
					nav_agent.set_target_position(target.global_position)
				var next_pos := nav_agent.get_next_path_position()
				var to_next := next_pos - global_position

				if to_next.length() > 0.1:
					var desired_velocity := to_next.normalized() * speed
					# Dici al NavigationAgent qual è la tua velocità ideale, l'avoidance calcolerà quella sicura
					nav_agent.set_velocity(desired_velocity)
				else:
					nav_agent.set_velocity(Vector2.ZERO)

				if animated_sprite_2d:
					animated_sprite_2d.play("walk")
	
		States.CHASE_ENEMY:
			if not is_instance_valid(enemy):
				enemy = _get_nearest_enemy_in_range(aggro_range)
				if not enemy:
					velocity = Vector2.ZERO
					nav_agent.set_target_position(global_position)
					nav_agent.set_velocity(Vector2.ZERO)
					if animated_sprite_2d: animated_sprite_2d.play("idle")
					return
	
			# aggiorna destinazione del navigation agent al nemico (recomputes path automaticamente)
			nav_agent.set_target_position(enemy.global_position)
			var next_pos := nav_agent.get_next_path_position()
			var to_next := next_pos - global_position

			if to_next.length() > 1.0:
				var desired_velocity := to_next.normalized() * speed
				nav_agent.set_velocity(desired_velocity)
			else:
				nav_agent.set_velocity(Vector2.ZERO)
			if animated_sprite_2d:
				animated_sprite_2d.play("walk")
	
		States.ATTACK:
			# fermati e attacca
			velocity = Vector2.ZERO
			nav_agent.set_target_position(global_position)
			nav_agent.set_velocity(Vector2.ZERO)
			if animated_sprite_2d: animated_sprite_2d.play("attack")
	
			if _attack_timer <= 0.0 and is_instance_valid(enemy):
				_perform_attack(enemy)
				_attack_timer = attack_cooldown
	
		States.IDLE:
			velocity = Vector2.ZERO
			nav_agent.set_target_position(global_position)
			nav_agent.set_velocity(Vector2.ZERO)
			if animated_sprite_2d: animated_sprite_2d.play("idle")
			enemy = _get_nearest_enemy_in_range(aggro_range)

		States.CASTLE_REACHED:
			velocity = Vector2.ZERO
			nav_agent.set_target_position(global_position)
			nav_agent.set_velocity(Vector2.ZERO)
			if animated_sprite_2d: animated_sprite_2d.play("idle")

func _on_nav_agent_velocity_computed(safe_velocity: Vector2) -> void:
	# Chiamato dal NavigationAgent2D quando ha calcolato una velocità sicura che tiene conto dell'avoidance.
	# Applica il movimento solo negli stati in cui l'eroe deve effettivamente muoversi.
	match state:
		States.MOVE_TO_CASTLE, States.CHASE_ENEMY:
			velocity = safe_velocity
			move_and_slide()
		_:
			# In ATTACK, IDLE, CASTLE_REACHED (o altri stati futuri) ignoriamo la velocità dell'agente
			velocity = Vector2.ZERO

func _physics_without_nav(_delta: float, current_state: int) -> void:
	# fallback se non esiste NavigationAgent2D (mantiene comportamento originale)
	match current_state:
		States.MOVE_TO_CASTLE:
			enemy = _get_nearest_enemy_in_range(aggro_range)
			var to_castle := Vector2.ZERO
			if is_instance_valid(target):
				to_castle = target.global_position - global_position
			if to_castle.length() <= nav_agent.target_desired_distance:
				velocity = Vector2.ZERO
				move_and_slide()
				if animated_sprite_2d: animated_sprite_2d.play("idle")
			else:
				velocity = to_castle.normalized() * speed
				move_and_slide()
				if animated_sprite_2d: animated_sprite_2d.play("walk")
		States.CHASE_ENEMY:
			if not is_instance_valid(enemy):
				enemy = _get_nearest_enemy_in_range(aggro_range)
				if not enemy:
					velocity = Vector2.ZERO
					move_and_slide()
					if animated_sprite_2d: animated_sprite_2d.play("idle")
					return
			var dir := (enemy.global_position - global_position)
			var dist_enemy := dir.length()
			if dist_enemy > 1.0:
				velocity = dir.normalized() * speed
			else:
				velocity = Vector2.ZERO
			move_and_slide()
			if animated_sprite_2d: animated_sprite_2d.play("walk")
		States.ATTACK:
			velocity = Vector2.ZERO
			move_and_slide()
			if animated_sprite_2d: animated_sprite_2d.play("attack")
			if _attack_timer <= 0.0 and is_instance_valid(enemy):
				_perform_attack(enemy)
				_attack_timer = attack_cooldown
		States.IDLE:
			velocity = Vector2.ZERO
			move_and_slide()
			if animated_sprite_2d: animated_sprite_2d.play("idle")
			enemy = _get_nearest_enemy_in_range(aggro_range)
		States.CASTLE_REACHED:
			velocity = Vector2.ZERO
			move_and_slide()
			if animated_sprite_2d: animated_sprite_2d.play("idle")

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
	var hc := target_enemy.get_node_or_null("Health")
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
