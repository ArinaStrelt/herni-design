extends CharacterBody3D

@export var speed_patrol = 21
@export var speed_chase = 2
@export var aggro_distance = 8.0
@export var attack_distance = 1.5
@export var patrol_radius = 5.0
@export var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var rotation_speed = 5.0
@export var max_health := 250
@export var knockback_duration = 0.25
@export var knockback_force = 5.0
@export var attack_damage = 25
@export var attack_cooldown = 1

var current_health := max_health
var is_dead := false
var player = null
var spawn_position: Vector3
var target_position: Vector3
var state = "patrol"
var wait_time = 0.0
var knockback_direction = Vector3.ZERO
var knockback_timer = 0.0
var attack_timer = 0.0
var last_animation: String = ""

@onready var model_holder = $monster_enemy
@onready var animation_player: AnimationPlayer = $monster_enemy/AnimationPlayer
@onready var nav_agent: NavigationAgent3D = $NavAgent

func _ready():
	spawn_position = global_position
	animation_player.play("idle")
	animation_player.animation_finished.connect(on_animation_changed)

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
		else:
			state = "idle"

	match state:
		"idle":
			if not animation_player.is_playing():
				animation_player.play("idle")
		"chase":
			if player:
				if distance_to_player <= attack_distance:
					attack()
				else:
					chase_player(delta)

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
		var corrected_target_angle = target_angle + deg_to_rad(180)
		model_holder.rotation.y = lerp_angle(current_angle, corrected_target_angle, delta * rotation_speed)

func chase_player(delta):
	if animation_player.current_animation != "run":
		animation_player.play("run")

	# ✅ Always update the path
	nav_agent.set_target_position(player.global_position)

	# ✅ Wait until path is ready
	if nav_agent.is_navigation_finished():
		velocity = Vector3.ZERO
		return

	var next_pos = nav_agent.get_next_path_position()
	var direction = (next_pos - global_position)
	direction.y = 0

	if direction.length() > 0.1:
		velocity = direction.normalized() * speed_chase
	else:
		velocity = Vector3.ZERO

func attack():
	if attack_timer > 0.0:
		return

	attack_timer = attack_cooldown
	velocity = Vector3.ZERO

	if player and global_position.distance_to(player.global_position) <= attack_distance:
		animation_player.play("fight")

func on_animation_changed(anim_name: String):
	if last_animation == "fight":
		do_the_damage()
	last_animation = anim_name

# udělej damage až když se dokončí animace
func do_the_damage():
	if player and global_position.distance_to(player.global_position) <= attack_distance:
		if "take_damage" in player:
			player.take_damage(attack_damage)
			print("Enemy attacked player for", attack_damage)
		else:
			print("Player does not have take_damage() method!")

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

	# Vytvoření mince
	var coin_scene = preload("res://scenes/coins/coins.tscn").instantiate()
	var coin = coin_scene.get_node("interact_area")

	# Případně nastav vlastní hodnotu (např. boss dropne 50)
	coin.value = randi_range(20, 30)

	# Umístění na pozici nepřítele
	coin_scene.transform.origin = position

	# Přidání do scény
	get_tree().current_scene.add_child(coin_scene)

	await get_tree().create_timer(2.0).timeout

	queue_free()
