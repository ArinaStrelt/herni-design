extends CharacterBody3D

@export var speed: float = 1       # běh přímo k hráči
@export var patrol_speed: float = 0.5  # pomalejší pohyb při patrolu
@export var detect_range: float = 5
@export var attack_range: float = 1
@export var attack_cd: float = 0.25
@export var max_health: int = 100
@export var attack_damage := 25
@export var patrol_radius: float = 4.0

var current_health: int = max_health
var player: Node3D
var can_attack: bool = true
var is_attacking: bool = false
var is_dead: bool = false
var has_target: bool = false
var state := "patrol"
var wait_time: float = 0.0
var spawn_position: Vector3

@onready var model: Node3D = $enemy_knight_model
@onready var anim: AnimationPlayer = model.get_node("AnimationPlayer")
@onready var nav_agent: NavigationAgent3D = $NavAgent
@onready var collision_shape: CollisionShape3D = $CollisionShape3D 

func _ready():
	spawn_position = global_position
	pick_new_patrol_point()

func _physics_process(_delta):
	if is_dead:
		return

	if player == null:
		var list := get_tree().get_nodes_in_group("player")
		if list.size() > 0:
			player = list[0]

	if player == null:
		return

	var dist := global_position.distance_to(player.global_position)

	if is_attacking:
		return

	if dist <= detect_range:
		has_target = true
		state = "chase"

	match state:
		"chase":
			look_at(player.global_position, Vector3.UP)
			if dist > attack_range:
				var dir := (player.global_position - global_position).normalized()
				velocity = dir * speed
				move_and_slide()
				if anim.current_animation != "Run":
					anim.play("Run")
			else:
				velocity = Vector3.ZERO
				move_and_slide()
				attack()
		"patrol":
			patrol(_delta)

func patrol(delta):
	if nav_agent == null:
		return

	if nav_agent.is_navigation_finished():
		velocity = Vector3.ZERO
		move_and_slide()
		if anim.current_animation != "Idle":
			anim.play("Idle")
		wait_time -= delta
		if wait_time <= 0:
			pick_new_patrol_point()
		return

	if anim.current_animation != "Run":
		anim.play("Run", -1, 0.5)

	var next_pos = nav_agent.get_next_path_position()
	var direction = (next_pos - global_position)
	direction.y = 0

	if direction.length() > 0.1:
		velocity = direction.normalized() * patrol_speed
	else:
		velocity = Vector3.ZERO

	move_and_slide()

	# Face direction of movement
	if velocity.length() > 0.1:
		var look_dir = velocity.normalized()
		look_at(global_position + look_dir, Vector3.UP)

func pick_new_patrol_point():
	if nav_agent == null:
		return  # Ensure nav_agent is ready before calling

	var offset = Vector3(
		randf_range(-1.0, 1.0),
		0,
		randf_range(-1.0, 1.0)
	).normalized() * patrol_radius

	var target = spawn_position + offset
	nav_agent.set_target_position(target)
	wait_time = randf_range(1.0, 2.5)

func flash_red():
	var meshes = $enemy_knight_model.find_children("*", "MeshInstance3D", true, false)

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

func attack():
	if not can_attack:
		return

	is_attacking = true
	can_attack = false
	model.attack_damage = attack_damage
	model.current_attack_anim = "Slash"
	anim.play("Slash")
	await anim.animation_finished

	is_attacking = false
	await get_tree().create_timer(attack_cd).timeout
	can_attack = true

func take_damage(amount:int):
	if is_dead:
		return
	current_health -= amount
	anim.play("Impact")
	$health_bar.update_healthbar(current_health, max_health)
	flash_red()

	if current_health <= 0:
		die()

func die():
	var death_position = global_transform.origin
	is_dead = true
	collision_shape.set_deferred("disabled", true)
	velocity = Vector3.ZERO
	move_and_slide()
	anim.play("A-pose")

	var coin_scene = preload("res://scenes/coins/coins.tscn").instantiate()
	var coin = coin_scene.get_node("interact_area")
	coin.value = randi_range(10, 20)
	coin_scene.transform.origin = death_position
	get_tree().current_scene.add_child(coin_scene)

	await get_tree().create_timer(2.0).timeout
	queue_free()

func scale_difficulty(level: int):
	if level > 1:
		max_health = max_health + ((level-1) * 75)
		attack_damage = attack_damage + ((level-1) * 15)
