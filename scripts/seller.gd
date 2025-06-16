extends Node3D

@onready var animation_player = $seller/AnimationPlayer
@onready var interact_area = $interact_area
@onready var exclamation_mark = $seller_visited  # tady přidej do scény node ExclamationMark
@onready var ui = get_node_or_null("/root/level_loader/UI")

@export var merchant_id: String = ""

var interacted = false

func _ready():
	animation_player.play("standing")
	interact_area.add_to_group("interactable")
	load_state()

func interact(_player):
	print("Interakce s obchodníkem!")

	if not interacted:
		interacted = true
		exclamation_mark.visible = false
		save_state()

	if ui:
		ui.open_shop()

func save_state():
	var key = "merchant_visited_%s" % merchant_id
	get_tree().root.set_meta(key, interacted)

func load_state():
	var key = "merchant_visited_%s" % merchant_id
	if get_tree().root.has_meta(key):
		interacted = get_tree().root.get_meta(key)
		exclamation_mark.visible = not interacted
	else:
		exclamation_mark.visible = true
