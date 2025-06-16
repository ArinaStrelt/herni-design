extends Control

@onready var exit_button = $Panel/close_button

func _ready():
	exit_button.pressed.connect(_on_exit_pressed)

func _on_exit_pressed():
	get_tree().quit()
