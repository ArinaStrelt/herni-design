extends CharacterBody3D

@onready var animation_player: AnimationPlayer = $player_knight_model_new/AnimationPlayer

@onready var knight_model: Node3D = $player_knight_model_new
@onready var ui = $"/root/level_loader/UI"
@onready var loader = $"/root/level_loader"
@onready var hit_effect := $"/root/level_loader/UI/hit_effect"
@onready var playerWalkingAudioStream = $AudioStreamPlayer3D_walking
@onready var playerAttackAudioStream = $AudioStreamPlayer3D_attack
@onready var playerRollAudioStream = $AudioStreamPlayer3D_roll
@onready var playerCoinsAudioStream = $AudioStreamPlayer3D_coins
@onready var playerHitAudioStream = $AudioStreamPlayer3D_hit
@onready var playerOuchAudioStream = $AudioStreamPlayer3D_ouch
var SPEED := 2.5
var GRAVITY : float = ProjectSettings.get_setting("physics/3d/default_gravity")

var attacking = false
var is_dead = false
var is_flinching = false
var max_health = 10000000000000
var current_health = max_health
var interactables = []
var gold = 0
var damage = 20000000000
var is_rolling: bool = false
var roll_speed := 2
var roll_duration := 1.5

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
			playerAttackAudioStream.play()

		elif event.is_action_pressed("attack_2") and not attacking:
			start_attack("Spin_Attack")
			playerAttackAudioStream.play()

		elif event.is_action_pressed("restart") and not is_dead:
			die()
		
		elif event.is_action_pressed("roll"):
			start_roll()
			
		elif event.is_action_pressed("debug_damage_all"):
			damage_all_enemies()

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
	if is_dead:
		return
	
	is_rolling = true
	attacking = true
	knight_model.attack_hitbox_off()
	animation_player.play("Roll", -1, 1.2)
	playerRollAudioStream.play()

	var roll_direction := transform.basis.z.normalized()
	var timer = get_tree().create_timer(animation_player.get_animation("Roll").length * 0.8)

	while timer.time_left > 0:
		# Získáme nový směr podle vstupu
		var input_vector = Vector2(
			Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
			Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
		).normalized()

		if input_vector != Vector2.ZERO:
			var target_dir = Vector3(input_vector.x, 0, input_vector.y).normalized()
			# Plynulé přiblížení směru
			roll_direction = roll_direction.lerp(target_dir, 0.2)

			# Rotace modelu do směru pohybu
			var target_rotation = atan2(roll_direction.x, roll_direction.z)
			rotation.y = lerp_angle(rotation.y, target_rotation, 0.2)

		velocity = roll_direction.normalized() * roll_speed
		move_and_slide()
		await get_tree().process_frame

	# rollback
	velocity = Vector3.ZERO
	is_rolling = false
	attacking = false




func _physics_process(delta):
	if is_dead or is_flinching:
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
		if is_on_floor():
			if !playerWalkingAudioStream.playing:
				playerWalkingAudioStream.play()
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		animation_player.play("Idle_2")
		playerWalkingAudioStream.stop()


# -----------------------
# Tvoje pomocné funkce (beze změny):
func look_towards_mouse():
	var camera = get_viewport().get_camera_3d()
	if not camera:
		return

	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000

	var space_state = get_world_3d().direct_space_state
	var result = space_state.intersect_ray(
		PhysicsRayQueryParameters3D.create(from, to)
	)

	if result and result.has("position"):
		var target_pos = result.position
		var to_mouse = (target_pos - global_transform.origin).normalized()
		var angle = atan2(to_mouse.x, to_mouse.z)

		# Otoč pouze model, ne celý CharacterBody
		rotation.y = angle



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
		look_towards_mouse()
		attacking = true
		knight_model.current_attack_anim = anim_name
		animation_player.play(anim_name)
		await animation_player.animation_finished
		knight_model.attack_hitbox_off()
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
	if playerAttackAudioStream.playing:
		playerAttackAudioStream.stop()
	current_health -= amount
	playerHitAudioStream.play()
	playerOuchAudioStream.play()
	
	print("Hráč byl zasažen: ", current_health)
	ui.update_health(current_health, max_health)
	flash_red()

	if current_health <= 0:
		die()
	elif is_flinching:
		return
	else:
		is_flinching = true
		animation_player.play("Impact", -1, 1.3)
		await animation_player.animation_finished
		is_flinching = false
			

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
	playerCoinsAudioStream.play()
	gold += amount
	print("Získáno ", amount, " zlata. Máš celkem:", gold)
	
	if ui:
		ui.update_gold(gold)

func damage_all_enemies():
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.has_method("take_damage"):
			enemy.take_damage(1000)
			print("Damaged enemy:", enemy.name)
