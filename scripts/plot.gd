extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var doorOpenAudioStream = $AudioStreamPlayer3D_open
var _opened := false

func _ready():
	animation_player.play("Idle")

func _process(_delta: float) -> void:
	check_enemies_and_open()

func check_enemies_and_open():
	if _opened:
		return

	if get_tree().get_nodes_in_group("enemies").is_empty():
		animation_player.play("Open")
		doorOpenAudioStream.play()
		_opened = true
