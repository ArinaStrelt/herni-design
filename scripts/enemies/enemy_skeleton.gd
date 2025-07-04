extends CharacterBody3D

@export var speed := 1
@export var attack_range := 6.5
@export var detection_range := 8
@export var attack_cd: = 1.0
@export var magic_ball_scene := preload("res://scenes/enemies/magic_ball.tscn")
@export var max_health := 150
@export var attack_damage := 10

@onready var animation_player: AnimationPlayer = $skeleton/AnimationPlayer
@onready var magic_spawn_point: Marker3D = $skeleton/magic_point
@onready var player: Node3D = null
@onready var model: Node3D = $skeleton
@onready var health_bar = $health_bar
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var enemyHitAudioStream = $AudioStreamPlayer3D_hit
@onready var enemyFireballAudioStream = $AudioStreamPlayer3D_fireball
@onready var enemyVoiceAudioStream = $AudioStreamPlayer3D_voice
@onready var enemyWalkAudioStream = $AudioStreamPlayer3D_walk
@onready var enemyDeathAudioStream = $AudioStreamPlayer3D_death

var current_health = max_health
var is_attacking: bool = false
var can_attack: bool = true
var is_dead: bool  = false
var has_target: bool = false

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

	if dist <= detection_range:
		if !has_target:
			health_bar.show_aggro()
		has_target = true

	if has_target:
		look_at(player.global_position, Vector3.UP)

		if dist > attack_range:
			var dir := (player.global_position - global_position).normalized()
			velocity = dir * speed
			move_and_slide()
			animation_player.play("Run", -1, 0.75)
			
			if !enemyWalkAudioStream.playing:
				enemyWalkAudioStream.play()
		else:
			enemyWalkAudioStream.stop()
			velocity = Vector3.ZERO
			move_and_slide()
			attack()
	else:
		velocity = Vector3.ZERO
		move_and_slide()
		animation_player.play("Idle")

func attack():
	if not can_attack:
		return
	
	is_attacking = true
	can_attack = false

	animation_player.play("Attack")
	await animation_player.animation_finished

	if not is_instance_valid(player) or is_dead:
		return

	is_attacking = false
	await get_tree().create_timer(attack_cd).timeout
	can_attack = true

func cast_spell():
	
	var ball = magic_ball_scene.instantiate()
	get_tree().current_scene.add_child(ball)
	ball.global_transform.origin = magic_spawn_point.global_transform.origin
	ball.attack_damage = attack_damage
	var from = ball.global_position
	var to = player.global_position
	to.y = from.y  # let vodorovně

	var dir = (to - from).normalized()
	ball.set_velocity(dir)
	enemyFireballAudioStream.play()

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
	enemyHitAudioStream.play()
	enemyVoiceAudioStream.play()
	animation_player.play("Impact")

	health_bar.update_healthbar(current_health, max_health)
	flash_red()

	if current_health <= 0:
		die()


func die():
	var death_position = global_transform.origin
	is_dead   = true
	collision_shape.set_deferred("disabled", true)
	health_bar.visible = false
	velocity  = Vector3.ZERO
	move_and_slide()
	animation_player.play("Death")
	enemyDeathAudioStream.play()

	# Vytvoření mince
	var coin_scene = preload("res://scenes/coins/coins.tscn").instantiate()
	var coin = coin_scene.get_node("interact_area")

	# Případně nastav vlastní hodnotu (např. boss dropne 50)
	coin.value = randi_range(10, 20)  # nebo prostě coin.value = 5

	# Umístění na pozici nepřítele
	coin_scene.transform.origin = death_position

	# Přidání do scény
	get_tree().current_scene.add_child(coin_scene)
	await animation_player.animation_finished
	
	queue_free()

func scale_difficulty(level: int):
	if level > 1:
		max_health = max_health + ((level-1) * 60)
		attack_damage = attack_damage + ((level-1) * 10)
		current_health = max_health
	else:
		return
