extends CharacterBody2D

enum State { IDLE, CHASE, ATTACK }

@onready var hero: Node2D = null
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var speed: float = 120.0
var attack_range: float = 40.0

var state: int = State.IDLE

# semplice cooldown per l'attacco
var attack_cooldown: float = 1.0
var attack_timer: float = 0.0

func _ready() -> void:
	_find_hero()
	state = State.CHASE if is_instance_valid(hero) else State.IDLE

func _physics_process(delta: float) -> void:
	if not is_instance_valid(hero):
		_find_hero()
		if not is_instance_valid(hero):
			state = State.IDLE

	# aggiorna timer attacco
	if attack_timer > 0.0:
		attack_timer = max(0.0, attack_timer - delta)

	match state:
		State.IDLE:
			velocity = Vector2.ZERO
			move_and_slide()
			if animated_sprite_2d:
				animated_sprite_2d.play("idle")
			if is_instance_valid(hero):
				state = State.CHASE

		State.CHASE:
			if not is_instance_valid(hero):
				state = State.IDLE
				return

			var to_hero = hero.global_position - global_position
			var dist = to_hero.length()

			if dist <= attack_range:
				state = State.ATTACK
				attack_timer = 0.0
				velocity = Vector2.ZERO
				move_and_slide()
				if animated_sprite_2d:
					animated_sprite_2d.play("attack")
				return

			velocity = to_hero.normalized() * speed
			move_and_slide()
			if animated_sprite_2d:
				animated_sprite_2d.play("walk")
				animated_sprite_2d.flip_h = velocity.x < 0

		State.ATTACK:
			if not is_instance_valid(hero):
				state = State.IDLE
				return

			var dist = global_position.distance_to(hero.global_position)
			if dist > attack_range:
				state = State.CHASE
				return

			# fermo e attacco (qui aggiungere logica danno)
			velocity = Vector2.ZERO
			move_and_slide()
			if animated_sprite_2d:
				animated_sprite_2d.play("attack")

			if attack_timer == 0.0:
				# placeholder: lancia l'attacco (emetti segnale o chiama funzione danno)
				attack_timer = attack_cooldown

func _find_hero() -> void:
	var list = get_tree().get_nodes_in_group("hero")
	if list.size() > 0 and list[0] is Node2D:
		hero = list[0]
