extends Area3D

@export var speed := 4
@export var lifetime := 5.0
@export var attack_damage := 0
var direction: Vector3 = Vector3.ZERO

func _ready():
	# Timer pro životnost koule
	var life_timer = Timer.new()
	life_timer.wait_time = lifetime
	life_timer.one_shot = true
	life_timer.timeout.connect(queue_free)
	add_child(life_timer)
	life_timer.start()

func set_velocity(dir: Vector3):
	direction = dir.normalized()

func _physics_process(delta):
	global_position += direction * speed * delta

func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(attack_damage)
		queue_free()
