extends NPCStateMachineBody2D

enum States { IDLE, CHASE, ATTACK }

@onready var hero: Node2D = null
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

@export var speed: float = 120.0
@export var attack_range: float = 40.0
@export var attack_cooldown: float = 1.0

var attack_timer: float = 0.0

func _ready() -> void:
	_find_hero()
	super._ready() # inizializza la state machine base

func _default_state() -> int:
	return States.CHASE if is_instance_valid(hero) else States.IDLE

func _physics_state(delta: float, current_state: int) -> void:
	# cooldown attacco
	if attack_timer > 0.0:
		attack_timer = max(0.0, attack_timer - delta)

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

			# spara l'attacco solo a cooldown pronto
			if attack_timer == 0.0:
				_perform_attack()
				attack_timer = attack_cooldown

func _query_next_state(current_state: int, delta: float) -> int:
	# Gestione transizioni separata dalla logica
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
			if dist > attack_range:
				return States.CHASE
			return States.ATTACK

	return current_state

func _on_state_enter(new_state: int) -> void:
	# Se vuoi side-effect quando entri in uno stato
	if new_state == States.ATTACK:
		# reset opzionale per attaccare subito all'ingresso
		attack_timer = 0.0

func _perform_attack() -> void:
	# Qui metti segnale/danno effettivo.
	# Esempio: emit_signal("hit", hero) o chiamata a un HealthComponent
	# Per ora è un placeholder, come la dieta il 2 gennaio.
	pass

func _find_hero() -> void:
	var list := get_tree().get_nodes_in_group("hero")
	if list.size() > 0 and list[0] is Node2D:
		hero = list[0]
