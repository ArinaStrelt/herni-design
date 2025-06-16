extends CharacterBody3D

@export var speed_patrol = 1.0
@export var speed_chase = 1.5
@export var aggro_distance = 6.0
@export var attack_distance = 6.0
@export var patrol_radius = 4.0
@export var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var rotation_speed = 5.0
@export var max_health := 1000
@export var knockback_duration = 1
@export var knockback_force = 0
@export var attack_damage = 110
@export var attack_cooldown = 2

var current_health = max_health
var is_dead := false
var player = null
var spawn_position: Vector3
var target_position: Vector3
var state = "patrol"
var wait_time = 0.0
var knockback_direction = Vector3.ZERO
var knockback_timer = 0.0
var attack_timer = 0.0
var attack_anim_duration = 1.5
var is_attacking = false
var jump_attack_cooldown = 30.0
var jump_attack_timer = 0.0
var stab_attack_cooldown = 15.0
var stab_attack_timer = 0.0

@onready var model_holder = $gwyn_boss
@onready var animation_player: AnimationPlayer = model_holder.get_node("AnimationPlayer")
@onready var nav_agent: NavigationAgent3D = $NavAgent
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var health_bar = $health_bar
@onready var enemyWalkAudioStream = $AudioStreamPlayer3D_walk
@onready var enemyDeathAudioStream = $AudioStreamPlayer3D_death
@onready var enemyAttackAudioStream = $AudioStreamPlayer3D_attack
@onready var enemyHitAudioStream = $AudioStreamPlayer3D_hit

func _ready():
	spawn_position = global_position
	set_new_patrol_point()
	_play_animation("idle")

func _physics_process(delta):
	if is_dead:
		return

	attack_timer -= delta
	stab_attack_timer -= delta
	jump_attack_timer -= delta

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
		if distance_to_player <= aggro_distance and state != "attack":
			state = "chase"
		elif distance_to_player > aggro_distance * 1.2 and state != "attack":
			state = "patrol"
	else:
		animation_player.speed_scale = 1.0
		state = "patrol"

	match state:
		"patrol":
			patrol_move(delta)
		"chase":
			if player:
				chase_player(delta)
				if distance_to_player <= attack_distance:
					call_deferred("attack")

	if not is_on_floor():
		velocity.y -= gravity * delta

	move_and_slide()

	if velocity.length() > 0.1:
		animation_player.speed_scale = 1.0
		var look_dir = velocity.normalized()
		var target_angle = atan2(look_dir.x, look_dir.z)
		model_holder.rotation.y = lerp_angle(model_holder.rotation.y, target_angle, delta * rotation_speed)

	if state != "attack":
		if velocity.length() > 0.1:
			animation_player.speed_scale = 1.0
			_play_animation("run" if current_health <= max_health / 2 else "walk")
			if not enemyWalkAudioStream.playing:
				enemyWalkAudioStream.play()
			# Apply increased chase speed when below half HP
			if state == "chase" and current_health <= max_health / 2:
				speed_chase = 2.5
			else:
				speed_chase = 1.5
		else:
			if enemyWalkAudioStream.playing:
				enemyWalkAudioStream.stop()
			animation_player.speed_scale = 1.0
			_play_animation("idle")

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
		nav_agent.set_target_position(target_position)
		var next_pos = nav_agent.get_next_path_position()
		var direction = (next_pos - global_position)
		direction.y = 0

		if direction.length() < 0.2:
			set_new_patrol_point()
		else:
			velocity = direction.normalized() * speed_patrol

func chase_player(_delta):
	if not player:
		return
	nav_agent.set_target_position(player.global_position)
	var next_pos = nav_agent.get_next_path_position()
	var direction = (next_pos - global_position)
	direction.y = 0
	if direction.length() > 0.1:
		velocity = direction.normalized() * speed_chase
	else:
		velocity = Vector3.ZERO

func attack():
	if attack_timer > 0.0 or state == "attack" or is_attacking:
		return

	var distance_to_player = global_position.distance_to(player.global_position)

	# Ensure stab is used only below 2/3 health and above 1/3 health
	if current_health < max_health * (2.0 / 3.0) and current_health >= max_health * (1.0 / 3.0) and distance_to_player >= 3.0 and distance_to_player <= 5.0 and stab_attack_timer <= 0.0:
		stab_attack_timer = stab_attack_cooldown
		call_deferred("execute_attack", "attack_stab")
		return
	elif current_health < max_health * (1.0 / 3.0) and jump_attack_timer <= 0.0 and distance_to_player >= 4.0 and distance_to_player <= 6.0:
		jump_attack_timer = jump_attack_cooldown
		execute_attack("attack_jump")
	elif distance_to_player <= 2.0:
		var roll = randi_range(0, 2)
		if roll == 0:
			execute_attack("attack_slash")
		elif roll == 1 and current_health < max_health * (2.0 / 3.0) and current_health >= max_health * (1.0 / 3.0) and stab_attack_timer <= 0.0:
			stab_attack_timer = stab_attack_cooldown
			execute_attack("attack_stab")
		else:
			execute_attack("attack_spinning")

func execute_attack(anim_name: String):
	# Rotate towards player before attacking
	if player:
		var dir = (player.global_position - global_position).normalized()
		dir.y = 0
		if dir.length() > 0.01:
			var target_angle = atan2(dir.x, dir.z)
			model_holder.rotation.y = target_angle
	attack_timer = attack_cooldown
	velocity = Vector3.ZERO
	state = "attack"
	is_attacking = true

	enemyAttackAudioStream.play()
	model_holder.attack_damage = attack_damage
	model_holder.current_attack_anim = anim_name

	# Apply lunge forward if it's a stab attack
	if anim_name == "attack_stab" and player:
		var stab_dir = (player.global_position - global_position).normalized()
		stab_dir.y = 0
		velocity = stab_dir * 6.0

	# Apply hop forward for spinning attack
	_play_animation(anim_name)

	if anim_name == "attack_spinning" and player:
		await get_tree().create_timer(0.9).timeout
		var spin_dir = (player.global_position - global_position).normalized()
		spin_dir.y = 0
		velocity = spin_dir * 2.5
		await get_tree().create_timer(0.6).timeout
		velocity = Vector3.ZERO

	if anim_name == "attack_jump" and player:
		await get_tree().create_timer(0.3).timeout
		var jump_dir = (player.global_position - global_position).normalized()
		jump_dir.y = 0
		velocity = jump_dir * 6
		await get_tree().create_timer(0.95).timeout
		velocity = Vector3.ZERO

	_play_animation(anim_name)

	# Wait until hit moment
	await get_tree().create_timer(0.4).timeout
	model_holder.attack_hitbox_on()

	# Stop movement on stab only
	if anim_name == "attack_stab":
		await get_tree().create_timer(0.42).timeout
		velocity = Vector3.ZERO

	await get_tree().create_timer(attack_anim_duration).timeout

	model_holder.attack_hitbox_off()
	is_attacking = false
	state = "chase"

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
	enemyHitAudioStream.play()
	print("Enemy took damage:", amount)
	health_bar.update_healthbar(current_health, max_health)
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

	collision_shape.set_deferred("disabled", true)
	health_bar.visible = false
	animation_player.stop()
	animation_player.play("death")
	enemyDeathAudioStream.play()

	set_physics_process(false)

	var coin_scene = preload("res://scenes/coins/coins.tscn").instantiate()
	var coin = coin_scene.get_node("interact_area")
	coin.value = randi_range(15, 25)
	coin_scene.transform.origin = position

	get_tree().current_scene.add_child(coin_scene)

	await get_tree().create_timer(2.0).timeout
	queue_free()

func _play_animation(anim_name: String):
	if not animation_player.has_animation(anim_name):
		print("❌ Missing animation:", anim_name)
		return
	if animation_player.current_animation != anim_name:
		animation_player.play(anim_name)

func scale_difficulty(level: int):
	if level > 1:
		max_health = max_health + ((level-1) * 25)
		attack_damage = attack_damage + ((level-1) * 10)
