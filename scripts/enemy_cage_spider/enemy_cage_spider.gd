extends CharacterBody3D

@export var speed_patrol = 2.0
@export var speed_chase = 1.5
@export var aggro_distance = 8.0
@export var attack_distance = 1.5
@export var patrol_radius = 5.0
@export var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var rotation_speed = 5.0
@export var max_health := 100
@export var knockback_duration = 0.25
@export var knockback_force = 5.0
@export var attack_damage = 5
@export var attack_cooldown = 1.5

var current_health := 100
var is_dead := false
var player = null
var spawn_position: Vector3
var target_position: Vector3
var state = "patrol"
var wait_time = 0.0
var knockback_direction = Vector3.ZERO
var knockback_timer = 0.0
var attack_timer = 0.0

@onready var model_holder = $cage_spider
@onready var animation_player: AnimationPlayer = $cage_spider/AnimationPlayer

func _ready():
	spawn_position = global_position
	set_new_patrol_point()
	animation_player.play("Armature|ArmatureAction")

func _physics_process(delta):
	if is_dead:
		return

	attack_timer -= delta

	if knockback_timer > 0.0:
		knockback_timer -= delta
		velocity = knockback_direction * knockback_force
		move_and_slide()
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

	# Smooth rotation
	var look_dir: Vector3
	if velocity.length() > 0.1:
		look_dir = velocity.normalized()
	elif player and state == "chase" and global_position.distance_to(player.global_position) <= attack_distance:
		look_dir = (player.global_position - global_position).normalized()

	if look_dir:
		var target_angle = atan2(-look_dir.x, -look_dir.z)
		var current_angle = model_holder.rotation.y
		var corrected_target_angle = target_angle + deg_to_rad(90)
		model_holder.rotation.y = lerp_angle(current_angle, corrected_target_angle, delta * rotation_speed)

func set_new_patrol_point():
	var random_offset = Vector3(
		randf_range(-patrol_radius, patrol_radius),
		0,
		randf_range(-patrol_radius, patrol_radius)
	)
	target_position = spawn_position + random_offset
	wait_time = randf_range(1.0, 3.0)

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
	if attack_timer > 0.0:
		return

	attack_timer = attack_cooldown
	velocity = Vector3.ZERO

	if player and global_position.distance_to(player.global_position) <= attack_distance:
		if "take_damage" in player:
			player.take_damage(attack_damage)
			print("Enemy attacked player for", attack_damage)
		else:
			print("Player does not have take_damage() method!")

	# Optional attack animation
	if animation_player.has_animation("Attack"):
		animation_player.play("Attack")

func flash_red():
	var meshes = find_children("*", "MeshInstance3D", true, false)

	for mesh in meshes:
		var mat = mesh.get_active_material(0)
		if mat:
			var new_mat = mat.duplicate()
			mesh.set_surface_override_material(0, new_mat)
			new_mat.albedo_color = Color(1, 0, 0)

	await get_tree().create_timer(0.35).timeout

	for mesh in meshes:
		var mat = mesh.get_active_material(0)
		if mat:
			mat.albedo_color = Color(1, 1, 1)


func take_damage(amount: int):
	if is_dead:
		return

	current_health -= amount
	print("Enemy took damage:", amount)
	$health_bar.update_healthbar(current_health, max_health)
	flash_red()

	if player:
		var dir = (global_position - player.global_position)
		dir.y = 0
		knockback_direction = dir.normalized()
		knockback_timer = knockback_duration

	if current_health <= 0:
		die()

func die():
	is_dead = true
	print("Enemy died.")
	queue_free()
