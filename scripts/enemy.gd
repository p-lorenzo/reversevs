extends NPCStateMachineBody2D

enum States { IDLE, CHASE, ATTACK }

@onready var hero: Node2D = null
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

@export var speed: float = 120.0
@export var attack_range: float = 40.0
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
			if dist <= attack_range:
				return States.ATTACK
			return States.CHASE

		States.ATTACK:
			if not is_instance_valid(hero):
				return States.IDLE
			var dist := global_position.distance_to(hero.global_position)
			if dist > attack_range + 4.0:
				return States.CHASE
			if dist <= attack_range:
				return States.ATTACK

	return current_state

func _perform_attack() -> void:
	print_debug("enemy " + str(self) + " attacks hero " + str(hero) + "for 1 damage")
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
