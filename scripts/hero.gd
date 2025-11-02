extends CharacterBody2D

enum State { MOVE_TO_CASTLE, CHASE_ENEMY, ATTACK, IDLE }

@onready var target = $"../BossCastle"
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

@export var speed: float = 250.0
var aggro_range: float = 200.0
@export var attack_range: float = 20.0

var state: int = State.MOVE_TO_CASTLE
var enemy: Node2D = null

func _ready() -> void:
	if target and target.has_method("connect"):
		target.connect("body_entered", Callable(self, "_on_castle_body_entered"))

func _physics_process(delta: float) -> void:
	match state:
		State.MOVE_TO_CASTLE:
			# cerca nemici in aggro
			enemy = _get_nearest_enemy_in_range(aggro_range)
			if enemy:
				state = State.CHASE_ENEMY
				return

			var to_castle = target.global_position - global_position
			if to_castle.length() <= 8.0:
				velocity = Vector2.ZERO
				move_and_slide()
				state = State.IDLE
				animated_sprite_2d.play("idle")
				return

			velocity = to_castle.normalized() * speed
			move_and_slide()
			animated_sprite_2d.play("walk")

		State.CHASE_ENEMY:
			if not is_instance_valid(enemy):
				enemy = _get_nearest_enemy_in_range(aggro_range)
				if not enemy:
					state = State.MOVE_TO_CASTLE
					return

			var dist_enemy = global_position.distance_to(enemy.global_position)
			
			if dist_enemy <= attack_range:
				state = State.ATTACK
				velocity = Vector2.ZERO
				move_and_slide()
				animated_sprite_2d.play("attack")
				return

			velocity = (enemy.global_position - global_position).normalized() * speed
			move_and_slide()
			animated_sprite_2d.play("walk")

		State.ATTACK:
			if not is_instance_valid(enemy) or global_position.distance_to(enemy.global_position) > attack_range:
				state = State.CHASE_ENEMY
				return
			
			# semplice comportamento di attacco (da espandere con cooldown / danno)
			velocity = Vector2.ZERO
			move_and_slide()
			animated_sprite_2d.play("attack")

		State.IDLE:
			velocity = Vector2.ZERO
			move_and_slide()
			animated_sprite_2d.play("idle")
			# continua a cercare nemici anche in idle
			enemy = _get_nearest_enemy_in_range(aggro_range)
			if enemy:
				state = State.CHASE_ENEMY

func _get_nearest_enemy_in_range(range: float) -> Node2D:
	var nearest: Node2D = null
	var best_dist = range
	for e in get_tree().get_nodes_in_group("enemies"):
		if not (e is Node2D):
			continue
		var d = global_position.distance_to(e.global_position)
		if d <= best_dist:
			best_dist = d
			nearest = e
	return nearest

func _on_castle_body_entered(body: Node) -> void:
	if body == self:
		state = State.IDLE
		velocity = Vector2.ZERO
		move_and_slide()
		animated_sprite_2d.play("idle")
