extends CharacterBody3D

@onready var animation_player: AnimationPlayer = $player_knight_model/AnimationPlayer
@onready var knight_model: Node3D = $player_knight_model/Knight

var SPEED := 2.5
var GRAVITY : float = ProjectSettings.get_setting("physics/3d/default_gravity")

var attacking = false
var is_dead = false
var max_health = 100
var current_health = 100

func _physics_process(delta):
	if is_dead:
		return

	if not attacking:
		var input_vector = Vector2(
			Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
			Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
		).normalized()

		if input_vector != Vector2.ZERO:
			var direction = Vector3(input_vector.x, 0, input_vector.y).normalized()
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED

			var target_rotation = atan2(direction.x, direction.z)
			rotation.y = lerp_angle(rotation.y, target_rotation, delta * 10.0)

			animation_player.play("Run")
		else:
			velocity.x = 0.0
			velocity.z = 0.0
			animation_player.play("Idle")
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	# Gravitace
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0

	move_and_slide()


func _input(event):
	if is_dead:
		return

	if event.is_action_pressed("attack") and not attacking:
		start_attack("Slash")

	elif event.is_action_pressed("attack_2") and not attacking:
		start_attack("Spin_slash")

	elif event.is_action_pressed("restart") and not is_dead:
		die()


func start_attack(anim_name: String):
	if animation_player.has_animation(anim_name):
		attacking = true
		$player_knight_model.current_attack_anim = anim_name
		animation_player.play(anim_name)
		await animation_player.animation_finished
		attacking = false

func take_damage(amount: int):
	if is_dead:
		return
	
	current_health -= amount
	print("Hráč byl zasažen: ", current_health)
	
	if current_health <= 0:
		die()
	else:
		# Optional: play a hurt animation if available
		if animation_player.has_animation("Hurt"):
			animation_player.play("Hurt")

func die():
	is_dead = true
	print("Hráč zemřel!")
	animation_player.play("Death")

	# Zakázat pohyb a útok
	velocity = Vector3.ZERO
	await animation_player.animation_finished

	# Nebo restartneš scénu:
	var loader = get_node("/root/level_loader")
	loader.reset_run()

func reset_player():
	current_health = 100
	is_dead = false

	# Reset animace
	animation_player.stop()
	animation_player.play("Idle")

	# Reset pohybu
	velocity = Vector3.ZERO