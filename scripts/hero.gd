extends NPCStateMachineBody2D

enum States { MOVE_TO_CASTLE, CHASE_ENEMY, ATTACK, IDLE }

@onready var target: Node2D = $"../BossCastle"
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var slash_particle: Node2D = $slash

@export var speed: float = 250.0
@export var aggro_range: float = 200.0
@export var attack_range: float = 20.0
@export var arrival_threshold: float = 8.0

@export var attack_cooldown: float = 0.7
var _attack_timer: float = 0.0

var enemy: Node2D = null

func _ready() -> void:
	if is_instance_valid(target) and target.has_signal("body_entered"):
		target.connect("body_entered", Callable(self, "_on_castle_body_entered"))
	super._ready()

func _default_state() -> int:
	return States.MOVE_TO_CASTLE

func _physics_state(delta: float, current_state: int) -> void:
	if _attack_timer > 0.0:
		_attack_timer = max(0.0, _attack_timer - delta)

	match current_state:
		States.MOVE_TO_CASTLE:
			enemy = _get_nearest_enemy_in_range(aggro_range)

			var to_castle := Vector2.ZERO
			if is_instance_valid(target):
				to_castle = target.global_position - global_position

			if to_castle.length() <= arrival_threshold:
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

func _query_next_state(current_state: int, delta: float) -> int:
	match current_state:
		States.MOVE_TO_CASTLE:
			if enemy:
				return States.CHASE_ENEMY
			if is_instance_valid(target):
				var to_castle := target.global_position - global_position
				if to_castle.length() <= arrival_threshold:
					return States.IDLE
			return States.MOVE_TO_CASTLE

		States.CHASE_ENEMY:
			if not is_instance_valid(enemy):
				enemy = _get_nearest_enemy_in_range(aggro_range)
				return States.MOVE_TO_CASTLE if not enemy else States.CHASE_ENEMY
			var dist_enemy := global_position.distance_to(enemy.global_position)
			if dist_enemy <= attack_range:
				return States.ATTACK
			return States.CHASE_ENEMY

		States.ATTACK:
			if not is_instance_valid(enemy):
				return States.MOVE_TO_CASTLE
			var dist_enemy := global_position.distance_to(enemy.global_position)
			if dist_enemy > attack_range + 4.0:
				return States.CHASE_ENEMY
			if dist_enemy <= attack_range:
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
	
	pass

func _get_nearest_enemy_in_range(range: float) -> Node2D:
	var nearest: Node2D = null
	var best_dist := range
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
		force_state(States.IDLE)
		velocity = Vector2.ZERO
		move_and_slide()
		if animated_sprite_2d: animated_sprite_2d.play("idle")


func _on_health_died() -> void:
	queue_free()
