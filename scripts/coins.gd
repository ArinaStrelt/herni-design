extends Area3D

@export var min_value := 1
@export var max_value := 5
var value := 0

func _ready():
	add_to_group("coins")
	if value <= 0:
		randomize()
		value = randi_range(min_value, max_value)

func interact(player):
	if player.has_method("add_gold"):
		player.add_gold(value)
	get_parent().queue_free()
