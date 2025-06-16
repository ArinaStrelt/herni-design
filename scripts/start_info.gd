extends Control

@onready var player = get_node("/root/level_loader/Player")

func _on_close_button_pressed() -> void:
	var ui = get_node("/root/level_loader/UI")
	ui.close_start_info()
	if player:
		player.can_move = true
