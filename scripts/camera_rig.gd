extends Node3D

@export var player: Node3D  # Reference na hráče
@export var follow_speed: float = 5.0  # Rychlost sledování
@export var camera_distance: float = 10.0  # Vzdálenost kamery od hráče
@export var camera_height: float = 7.0  # Výška kamery nad hráčem
@export var camera_angle: float = -45.0  # Úhel pohledu

func _ready():
	if not player:
		push_error("Player node is not assigned in CameraRig.")
		return

	# Natočení kamery tak, aby se dívala pod úhlem k podlaze
	rotation_degrees.x = camera_angle

func _process(delta):
	if not player:
		return

	# Cílová pozice kamery - za hráčem, ve výšce, podle nastavené vzdálenosti
	var target_position = player.global_transform.origin + Vector3(0, camera_height, -camera_distance)

	# Plynulé posunutí kamery směrem k cílové pozici
	position = position.lerp(target_position, follow_speed * delta)
