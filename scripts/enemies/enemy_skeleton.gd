extends CharacterBody3D

@export var move_speed := 2.5
@export var attack_range := 10.0
@export var detection_range := 20.0
@export var magic_ball_scene: PackedScene
@export var max_health := 100

@onready var animation_player: AnimationPlayer = $skeleton/AnimationPlayer
@onready var magic_spawn_point: Marker3D = $skeleton/magic_point
@onready var player: Node3D = null
@onready var model: Node3D = $skeleton

var is_shooting := false
var is_casting := false
var is_flinching := false
var current_health = max_health
var is_dead: bool  = false

func _ready():
	animation_player.animation_finished.connect(_on_animation_finished)
	player = get_node("/root/level_loader/Player")  # nebo použij skupinu

func _physics_process(delta):
	if is_dead:
		return

	if not is_instance_valid(player):
		return

	var distance = global_position.distance_to(player.global_position)

	if distance > detection_range:
		velocity = Vector3.ZERO
		move_and_slide()
		if animation_player.current_animation != "Idle":
			animation_player.play("Idle")
		is_shooting = false
		return

	look_at(player.global_position)

	if distance > attack_range:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * move_speed
		move_and_slide()
		if animation_player.current_animation != "Run":
			animation_player.play("Run")
		is_shooting = false
	else:
		velocity = Vector3.ZERO
		move_and_slide()
		if not is_casting and not is_flinching:
			animation_player.play("Attack")
			is_casting = true
		is_shooting = true

func _on_animation_finished(anim_name: String):
	if anim_name == "Attack":
		is_casting = false
	elif anim_name == "Impact":
		is_flinching = false  # odteď může skeleton opět kouzlit


func cast_spell():
	var ball = magic_ball_scene.instantiate()
	get_tree().current_scene.add_child(ball)
	ball.global_transform.origin = magic_spawn_point.global_transform.origin

	var from = ball.global_position
	var to = player.global_position
	to.y = from.y  # let vodorovně

	var dir = (to - from).normalized()
	ball.set_velocity(dir)

func flash_red():
	var meshes = model.find_children("*", "MeshInstance3D", true, false)

	for mesh in meshes:
		var mat = mesh.get_active_material(0)
		if mat:
			# Zkopíruj materiál, aby nebyl sdílený
			var new_mat = mat.duplicate()
			mesh.set_surface_override_material(0, new_mat)
			new_mat.albedo_color = Color(1, 0, 0)

	await get_tree().create_timer(0.35).timeout

	for mesh in meshes:
		var mat = mesh.get_active_material(0)
		if mat:
			mat.albedo_color = Color(1, 1, 1)

# DAMAGE  +  SMRT
func take_damage(amount: int):
	if is_dead:
		return

	current_health -= amount

	# Přeruš kouzlení a začni flinch fázi
	is_casting = false
	is_flinching = true
	animation_player.play("Impact")

	$health_bar.update_healthbar(current_health, max_health)
	flash_red()

	if current_health <= 0:
		die()


func die():
	var position = global_transform.origin
	is_dead   = true
	velocity  = Vector3.ZERO
	move_and_slide()
	animation_player.play("A-pose")

	# Vytvoření mince
	var coin_scene = preload("res://scenes/coins/coins.tscn").instantiate()
	var coin = coin_scene.get_node("interact_area")

	# Případně nastav vlastní hodnotu (např. boss dropne 50)
	coin.value = randi_range(10, 20)  # nebo prostě coin.value = 5

	# Umístění na pozici nepřítele
	coin_scene.transform.origin = position

	# Přidání do scény
	get_tree().current_scene.add_child(coin_scene)
	await get_tree().create_timer(2.0).timeout
	
	queue_free()
