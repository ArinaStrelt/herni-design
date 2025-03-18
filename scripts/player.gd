extends CharacterBody3D

@export var speed: float = 5.0
@export var acceleration: float = 10.0
@export var deceleration: float = 10.0
@export var jump_velocity: float = 5.0
@export var gravity: float = 9.8

func _physics_process(delta: float) -> void:
	var input_direction = Vector3.ZERO

	if Input.is_action_pressed("move_forward"):
		input_direction.z -= 1
	if Input.is_action_pressed("move_backward"):
		input_direction.z += 1
	if Input.is_action_pressed("move_left"):
		input_direction.x -= 1
	if Input.is_action_pressed("move_right"):
		input_direction.x += 1

	input_direction = input_direction.normalized()

	if input_direction != Vector3.ZERO:
		var target_velocity = input_direction * speed
		velocity.x = lerp(velocity.x, target_velocity.x, acceleration * delta)
		velocity.z = lerp(velocity.z, target_velocity.z, acceleration * delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, deceleration * delta)
		velocity.z = lerp(velocity.z, 0.0, deceleration * delta)

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity

	# Rotace hráče směrem k pozici kurzoru myši
	rotate_player_towards_mouse()

	move_and_slide()

func rotate_player_towards_mouse() -> void:
	var mouse_position = get_viewport().get_mouse_position()
	var camera = get_viewport().get_camera_3d()

	# Vytvoření paprsku z kamery skrze pozici kurzoru myši
	var ray_origin = camera.project_ray_origin(mouse_position)
	var ray_direction = camera.project_ray_normal(mouse_position)

	# Definování roviny XZ na úrovni hráče
	var player_position = global_transform.origin
	var plane = Plane(Vector3.UP, player_position.y)

	# Výpočet průsečíku paprsku s rovinou
	var intersection = plane.intersects_ray(ray_origin, ray_direction)
	if intersection:
		var look_at_position = intersection
		look_at_position.y = player_position.y  # Udržení aktuální výšky hráče
		look_at(look_at_position)
