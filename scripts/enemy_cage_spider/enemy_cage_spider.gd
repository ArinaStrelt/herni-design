extends CharacterBody3D

@export var speed_patrol = 2.0
@export var speed_chase = 4.5
@export var aggro_distance = 8.0
@export var attack_distance = 1.5
@export var patrol_radius = 5.0
@export var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var rotation_speed = 5.0
@export var max_health := 100

var current_health := 100
var is_dead := false
var player = null
var spawn_position: Vector3
var target_position: Vector3
var state = "patrol"
var wait_time = 0.0

@onready var model_holder = $cage_spider
@onready var animation_player: AnimationPlayer = $cage_spider/AnimationPlayer

func _ready():
	spawn_position = global_position
	set_new_patrol_point()
	animation_player.play("Armature|ArmatureAction")

func _physics_process(delta):
	if is_dead:
		return

	if not player:
		player = get_tree().get_first_node_in_group("player")

	var distance_to_player = INF
	if player:
		distance_to_player = global_position.distance_to(player.global_position)
		if distance_to_player <= aggro_distance:
			state = "chase"
		elif distance_to_player > aggro_distance * 1.2:
			state = "patrol"
	else:
		state = "patrol"

	match state:
		"patrol":
			patrol_move(delta)
		"chase":
			if player:
				chase_player(delta)
				if distance_to_player <= attack_distance:
					attack()

	if not is_on_floor():
		velocity.y -= gravity * delta

	move_and_slide()

	# Plynulá rotace bez změny velikosti
	var horizontal_velocity = Vector3(velocity.x, 0, velocity.z)
	if horizontal_velocity.length() > 0.1:
		var target_dir = horizontal_velocity.normalized()
		var target_angle = atan2(-target_dir.x, -target_dir.z)
		var current_angle = model_holder.rotation.y
		var corrected_target_angle = target_angle + deg_to_rad(90) # uprav podle orientace modelu
		model_holder.rotation.y = lerp_angle(current_angle, corrected_target_angle, delta * rotation_speed)

func set_new_patrol_point():
	var random_offset = Vector3(
		randf_range(-patrol_radius, patrol_radius),
		0,
		randf_range(-patrol_radius, patrol_radius)
	)
	target_position = spawn_position + random_offset
	wait_time = randf_range(1.0, 3.0) # Náhodné čekání mezi patrolováním

func patrol_move(delta):
	if wait_time > 0:
		wait_time -= delta
		velocity.x = move_toward(velocity.x, 0, speed_patrol)
		velocity.z = move_toward(velocity.z, 0, speed_patrol)
	else:
		var direction = (target_position - global_position)
		direction.y = 0

		if direction.length() < 0.2:
			set_new_patrol_point()
		else:
			velocity.x = direction.normalized().x * speed_patrol
			velocity.z = direction.normalized().z * speed_patrol

func chase_player(delta):
	var direction = (player.global_position - global_position)
	direction.y = 0
	velocity.x = direction.normalized().x * speed_chase
	velocity.z = direction.normalized().z * speed_chase

func attack():
	velocity = Vector3.ZERO
		# Sem přidej vlastní logiku útoku

func take_damage(amount: int):
	if is_dead:
		return

	current_health -= amount
	print("Enemy HP:", current_health)

	if current_health <= 0:
		die()

func die():
	is_dead = true
	print("Enemy died.")
	queue_free()
