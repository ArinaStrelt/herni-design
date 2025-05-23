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
var is_flinching = false
var max_health = 1000
var current_health = max_health
var interactables = []
var gold = 0
var damage = 150
var is_rolling: bool = false
var roll_speed := 2
var can_move = true

func _ready():
	$interact_area.connect("area_entered", _on_area_entered)
	$interact_area.connect("area_exited", _on_area_exited)
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event):
	if is_dead or is_rolling:
		return

	if event.is_action_pressed("interact"):
		if ui and ui.shop_opened:
			ui.close_shop()
			can_move = true
		else:
			try_interact()

	if can_move:
		if event.is_action_pressed("attack") and not attacking:
			start_attack("Attack")
		elif event.is_action_pressed("attack_2") and not attacking:
			start_attack("Spin_Attack")
		elif event.is_action_pressed("restart") and not is_dead:
			die()
		elif event.is_action_pressed("roll"):
			start_roll()

func _physics_process(delta):
	if is_dead or is_flinching:
		return

	if not can_move:
		velocity = Vector3.ZERO
		animation_player.play("Idle_2")
	elif is_rolling:
		handle_roll()
	else:
		handle_movement(delta)

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

	# Otáčení celé postavy směrem k myši
	var mouse_pos = get_mouse_world_position()
	if mouse_pos:
		var dir = (mouse_pos - global_position)
		dir.y = 0
		if dir.length() > 0.1:
			look_at(mouse_pos, Vector3.UP)
			rotate_y(deg_to_rad(180))

	var input_vector = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	).normalized()

	if input_vector != Vector2.ZERO:
		var forward = -transform.basis.z
		var right = -transform.basis.x
		var move_direction = (forward * input_vector.y + right * input_vector.x).normalized()

		velocity.x = move_direction.x * SPEED
		velocity.z = move_direction.z * SPEED
		animation_player.play("Run")
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		animation_player.play("Idle_2")

func handle_roll():
	# Otáčení k myši
	var mouse_pos = get_mouse_world_position()
	if mouse_pos:
		var dir = (mouse_pos - global_position)
		dir.y = 0
		if dir.length() > 0.1:
			look_at(mouse_pos, Vector3.UP)
			rotate_y(deg_to_rad(180))

	# Pohyb podle WSAD nebo myši
	var input_vector = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	).normalized()

	var move_direction = Vector3.ZERO

	if input_vector != Vector2.ZERO:
		var forward = -transform.basis.z
		var right = -transform.basis.x
		move_direction = (forward * input_vector.y + right * input_vector.x).normalized()
	else:
		# Pokud nedrží WSAD → jdi směrem k myši
		if mouse_pos:
			move_direction = (mouse_pos - global_position).normalized()
			move_direction.y = 0  # zabránit skákání

	velocity.x = move_direction.x * roll_speed
	velocity.z = move_direction.z * roll_speed


func start_roll():
	if is_dead:
		return
	is_rolling = true
	attacking = true
	knight_model.attack_hitbox_off()
	animation_player.play("Roll", -1, 1.2)

	var duration = animation_player.get_animation("Roll").length / 1.2
	await get_tree().create_timer(duration * 0.8).timeout

	is_rolling = false
	attacking = false

func get_mouse_world_position():
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return null

	var mouse_pos := get_viewport().get_mouse_position()
	var from := camera.project_ray_origin(mouse_pos)
	var to := from + camera.project_ray_normal(mouse_pos) * 1000

	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]

	var result := space_state.intersect_ray(query)
	if result:
		var position : Vector3 = result.position
		position.y = global_transform.origin.y
		return position

	return null

func try_interact():
	if interactables.size() == 0:
		return
	var closest = get_closest_interactable()
	if closest:
		var target = closest
		while target and not target.has_method("interact"):
			target = target.get_parent()
		if target and target.has_method("interact"):
			target.interact(self)
			if ui and ui.shop_opened:
				can_move = false

func get_closest_interactable():
	var closest = null
	var shortest = INF
	for obj in interactables:
		if not obj or not obj.is_inside_tree():
			continue
		var dist = global_transform.origin.distance_to(obj.global_transform.origin)
		if dist < shortest:
			closest = obj
			shortest = dist
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
		knight_model.attack_hitbox_off()
		attacking = false

func flash_red():
	var meshes = find_children("*", "MeshInstance3D", true, false)
	var original_colors := {}
	for mesh in meshes:
		for i in mesh.mesh.get_surface_count():
			var mat = mesh.get_active_material(i)
			if mat:
				var new_mat = mat.duplicate()
				original_colors[mesh.name + "_" + str(i)] = mat.albedo_color
				mesh.set_surface_override_material(i, new_mat)
				new_mat.albedo_color = Color(1, 0, 0)

	await get_tree().create_timer(0.35).timeout
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
	velocity = Vector3.ZERO

func add_gold(amount: int):
	gold += amount
	if ui:
		ui.update_gold(gold)
