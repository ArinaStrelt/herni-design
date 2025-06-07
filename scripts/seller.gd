extends Node3D

@onready var animation_player = $seller/AnimationPlayer
@onready var interact_area = $interact_area
@onready var ui = get_node_or_null("/root/level_loader/UI")


func _ready():
	
	animation_player.play("standing")
	interact_area.add_to_group("interactable")

func interact(_player):
	
	print("Interakce s obchodníkem!")

	if ui:
		ui.open_shop()
		
