extends CharacterBody3D

@onready var animation_player: AnimationPlayer = $player_knight_model_new/AnimationPlayer

@onready var knight_model: Node3D = $player_knight_model_new
@onready var ui = $"/root/level_loader/UI"
@onready var loader = $"/root/level_loader"
@onready var hit_effect := $"/root/level_loader/UI/hit_effect"

var SPEED := 2.5
var GRAVITY : float = ProjectSettings.get_setting("physics/3d/default_gravity")

var attacking = false
var is_dead = false
var max_health = 100
var current_health = max_health
var interactables = []
var gold = 0
var damage = 15

var is_rolling: bool = false
var roll_speed := 1.75
var roll_duration := 1

var can_move = true  # nová proměnná

func _ready():
	$interact_area.connect("area_entered", _on_area_entered)
	$interact_area.connect("area_exited", _on_area_exited)
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event):
	if is_dead or is_rolling:
		return

	# E klávesa (interact)
	if event.is_action_pressed("interact"):
		if ui and ui.shop_opened:
			ui.close_shop()
			can_move = true
		else:
			try_interact()

	# Útoky
	if can_move:
		if event.is_action_pressed("attack") and not attacking:
			start_attack("Attack")

		elif event.is_action_pressed("attack_2") and not attacking:
			start_attack("Spin_Attack")

		elif event.is_action_pressed("restart") and not is_dead:
			die()
		
		elif event.is_action_pressed("roll"):
			start_roll()

func try_interact():
	if interactables.size() == 0:
		return

	var closest = get_closest_interactable()
	if closest:
		var target = closest

		while target and not target.has_method("interact"):
			if target.get_parent():
				target = target.get_parent()
			else:
				break

		if target and target.has_method("interact"):
			target.interact(self)

			# Pokud interact otevřel obchod
			if ui and ui.shop_opened:
				can_move = false  # zakáže pohyb

func start_roll():
	if is_dead or attacking:
		return
	
	is_rolling = true
	attacking = true  # volitelně, aby nemohl útočit během skoku
	animation_player.play("Roll", -1, 1.2)

	var direction = transform.basis.z.normalized()
	var timer = get_tree().create_timer(roll_duration)

	while timer.time_left > 0:
		velocity = direction * roll_speed
		move_and_slide()
		await get_tree().process_frame

	# rollback na normální stav
	velocity = Vector3.ZERO
	is_rolling = false
	attacking = false


func _physics_process(delta):
	if is_dead:
		return

	if not can_move:
		# když je zakázaný pohyb, tak jen resetuj rychlost
		velocity.x = 0.0
		velocity.z = 0.0
		animation_player.play("Idle_2")
	else:
		handle_movement(delta)

	# Gravitace pořád běží
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0

	move_and_slide()

func handle_movement(delta):
	if attacking:
		velocity.x = 0.0
		velocity.z = 0.0
		return

	var input_vector = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	).normalized()

	if input_vector != Vector2.ZERO:
		var direction = Vector3(input_vector.x, 0, input_vector.y).normalized()
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED

		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, delta * 10.0)

		animation_player.play("Run")
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		animation_player.play("Idle_2")

# -----------------------
# Tvoje pomocné funkce (beze změny):

func get_closest_interactable():
	var closest = null
	var shortest_distance = INF

	for obj in interactables:
		if not obj or not obj.is_inside_tree():
			continue

		var distance = global_transform.origin.distance_to(obj.global_transform.origin)
		if distance < shortest_distance:
			closest = obj
			shortest_distance = distance

	return closest

func _on_area_entered(area):
	if area.is_in_group("interactable") and not interactables.has(area):
		interactables.append(area)

func _on_area_exited(area):
	if area.is_in_group("interactable") and interactables.has(area):
		interactables.erase(area)

func start_attack(anim_name: String):
	if animation_player.has_animation(anim_name):
		attacking = true
		knight_model.current_attack_anim = anim_name
		animation_player.play(anim_name)
		await animation_player.animation_finished
		attacking = false

func flash_red():
	var meshes = find_children("*", "MeshInstance3D", true, false)

	# Mapujeme původní barvy pro reset
	var original_colors := {}

	for mesh in meshes:
		var _surface_count = mesh.get_surface_override_material_count()
		for i in mesh.mesh.get_surface_count():
			var mat = mesh.get_active_material(i)
			if mat:
				var new_mat = mat.duplicate()
				original_colors[mesh.name + "_" + str(i)] = mat.albedo_color
				mesh.set_surface_override_material(i, new_mat)
				new_mat.albedo_color = Color(1, 0, 0)

	await get_tree().create_timer(0.35).timeout

	# Obnovení barev
	reset_colors()

func reset_colors():
	var meshes = knight_model.find_children("*", "MeshInstance3D", true, false)

	for mesh in meshes:
		for i in mesh.mesh.get_surface_count():
			var mat = mesh.get_active_material(i)
			if mat:
				mat.albedo_color = Color(1, 1, 1)


func take_damage(amount: int):
	if is_dead or is_rolling:
		return

	current_health -= amount
	print("Hráč byl zasažen: ", current_health)
	ui.update_health(current_health, max_health)
	flash_red()

	if current_health <= 0:
		die()
	else:
		if animation_player.has_animation("Impact"):
			animation_player.play("Impact")
			

func die():
	is_dead = true
	current_health = 0
	ui.update_health(current_health, max_health)
	animation_player.play("Death_2")
	velocity = Vector3.ZERO
	await animation_player.animation_finished
	loader.reset_run()

func reset_player():
	current_health = max_health
	is_dead = false
	reset_colors()
	animation_player.stop()
	animation_player.play("Idle_2")
  # Reset pohybu
	velocity = Vector3.ZERO

	
func add_gold(amount: int):
	gold += amount
	print("Získáno ", amount, " zlata. Máš celkem:", gold)
	
	if ui:
		ui.update_gold(gold)
