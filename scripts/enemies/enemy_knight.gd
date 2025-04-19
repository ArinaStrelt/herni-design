# EnemyKnight.gd  – připojit na root  CharacterBody3D
extends CharacterBody3D

@export var speed: float = 1     # běh přímo k hráči
@export var detect_range: float = 5    # kdy si hráče všimne
@export var attack_range: float = 1     # vzdálenost pro útok
@export var attack_cd: float = 0.25     # pauza mezi útoky
@export var max_health: int = 100

var current_health: int   = max_health
var player: Node3D
var can_attack: bool  = true
var is_attacking: bool  = false
var is_dead: bool  = false
var has_target: bool = false       #  NEW – pamatuje si, že hráče už zahlédl

@onready var model: Node3D = $enemy_knight_model
@onready var anim: AnimationPlayer = model.get_node("AnimationPlayer")

# ----------------------------------------------------------------------

func _physics_process(_delta):
	if is_dead:
		return

	# 1) získej hráče jen jednou
	if player == null:
		var list := get_tree().get_nodes_in_group("player")
		if list.size() > 0:
			player = list[0]

	if player == null:
		return

	var dist := global_position.distance_to(player.global_position)

	if is_attacking:
		return  # během seku se nehýbej

	if dist <= detect_range:
		has_target = true
		
	# 2) vidí hráče?
	if has_target:
		look_at(player.global_position, Vector3.UP)

		# 3) běh nebo útok
		if dist > attack_range:
			var dir := (player.global_position - global_position).normalized()
			velocity = dir * speed
			move_and_slide()
			anim.play("Run")
		else:
			velocity = Vector3.ZERO
			move_and_slide()
			attack()
	else:
		velocity = Vector3.ZERO
		move_and_slide()
		anim.play("Idle")

func flash_red():
	var meshes = $enemy_knight_model.find_children("*", "MeshInstance3D", true, false)

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



# ----------------------------------------------------------------------
# ÚTOK  (hitbox spouští AnimationPlayer sám přes Call‑Method Tracky)
func attack():
	if not can_attack:
		return

	is_attacking = true
	can_attack   = false
	model.current_attack_anim = "Slash"
	anim.play("Slash")            # AnimationPlayer uvnitř modelu
	await anim.animation_finished  # počká na konec seku

	is_attacking = false

	await get_tree().create_timer(attack_cd).timeout
	can_attack = true

# ----------------------------------------------------------------------
# DAMAGE  +  SMRT
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
	is_dead   = true
	velocity  = Vector3.ZERO
	move_and_slide()
	anim.play("A-pose")
	queue_free()          # jednoduchá „smrt“ – klidová póza
