extends Control

@onready var close_button := $Panel/close_button

func _ready():
	close_button.pressed.connect(_on_exit_pressed)

func show_end_screen():
	visible = true
	fade_in()

func _on_exit_pressed():
	get_tree().quit()

func fade_in():
	self.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 1.5)
