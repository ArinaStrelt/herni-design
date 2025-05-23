extends CharacterBody3D

@export var speed_patrol = 2.0
@export var speed_chase = 1.5
@export var aggro_distance = 5.0
@export var attack_distance = 1.0
@export var patrol_radius = 4.0
@export var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var rotation_speed = 5.0
@export var max_health := 75
@export var knockback_duration = 1
@export var knockback_force = 0
@export var attack_damage = 10
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
var attack_animations = ["Attack", "Attack2"]
var attack_anim_duration = 1

@onready var model_holder = $cage_spider_animated_v3
@onready var animation_player: AnimationPlayer = model_holder.get_node("AnimationPlayer")
@onready var nav_agent: NavigationAgent3D = $NavAgent
@onready var collision_shape: CollisionShape3D = $CollisionShape3D


func _ready():
	spawn_position = global_position
	set_new_patrol_point()
	_play_animation("Idle")


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
		if distance_to_player <= aggro_distance and state != "attack":
			state = "chase"
		elif distance_to_player > aggro_distance * 1.2 and state != "attack":
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

	if state != "attack":
		if velocity.length() > 0.1:
			animation_player.speed_scale = 2.0 if state == "chase" else 1.0
			_play_animation("Walk")
		else:
			animation_player.speed_scale = 1.0
			_play_animation("Idle")

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


func attack() -> void:
	await _attack()

func _attack() -> void:
	if attack_timer > 0.0 or state == "attack":
		return

	attack_timer = attack_cooldown
	velocity = Vector3.ZERO
	state = "attack"

	if player and global_position.distance_to(player.global_position) <= attack_distance:
		if "take_damage" in player:
			player.take_damage(attack_damage)
			print("Enemy attacked player for", attack_damage)
		else:
			print("Player does not have take_damage() method!")

	var random_attack = attack_animations[randi() % attack_animations.size()]
	_play_animation(random_attack)

	await get_tree().create_timer(attack_anim_duration).timeout
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
	print("Enemy took damage:", amount)
	$health_bar.update_healthbar(current_health, max_health)
	flash_red()

	if player:
		var dir = (global_position - player.global_position)
		dir.y = 0
		knockback_direction = dir.normalized()
		knockback_timer = knockback_duration
		animation_player.play("Hit")

	if current_health <= 0:
		die()

func die():
	is_dead = true
	print("Enemy died.")

	collision_shape.set_deferred("disabled", true)

	animation_player.stop()
	animation_player.play("Death")

	set_physics_process(false)
	
	# Vytvoření mince
	var coin_scene = preload("res://scenes/coins/coins.tscn").instantiate()
	var coin = coin_scene.get_node("interact_area")

	# Případně nastav vlastní hodnotu (např. boss dropne 50)
	coin.value = randi_range(15, 25)  # nebo prostě coin.value = 5

	# Umístění na pozici nepřítele
	coin_scene.transform.origin = position

	# Přidání do scény
	get_tree().current_scene.add_child(coin_scene)
	
	await get_tree().create_timer(2.0).timeout
	
	queue_free()

func _play_animation(anim_name: String):
	if not animation_player.has_animation(anim_name):
		return
	if animation_player.current_animation != anim_name:
		animation_player.play(anim_name)
		
func scale_difficulty(level: int):
	if level > 1:
		max_health = max_health + ((level-1) * 25)
		attack_damage = attack_damage + ((level-1) * 10)

	else:
		return
