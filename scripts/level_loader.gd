extends Node3D

@onready var fade := $FadeLayer
@onready var level_root := $level_root
@onready var player := $Player
@onready var ui = $"/root/level_loader/UI"
@onready var shop_ui = $"/root/level_loader/UI/shop_ui"

var current_level: Node = null

func _ready():
	# Načti první level při spuštění
	randomize()
	load_level("res://levels/Base_model/base.tscn", Vector3(0, 0,-6.6))

func load_level(path: String, player_position: Vector3):
	if current_level:
		current_level.queue_free()

	var scene := load(path)
	current_level = scene.instantiate()
	level_root.add_child(current_level)

	player.global_transform.origin = player_position

func change_level(path: String, player_spawn_position: Vector3):
	var tween = fade.fade_out()
	await tween.finished

	load_level(path, player_spawn_position)
	for coin in get_tree().get_nodes_in_group("coins"):
		if coin and coin.is_inside_tree():
			coin.get_parent().queue_free()

	var fade_in_tween = fade.fade_in()
	await fade_in_tween.finished


func reset_run():
	print("Resetuji běh…")

	# Odstranit aktuální mapu
	if current_level:
		current_level.queue_free()
		current_level = null

	player.reset_player()
	ui.update_health(player.current_health, player.max_health)
	ui.update_gold(player.gold)
	shop_ui.update_ui()
	for coin in get_tree().get_nodes_in_group("coins"):
		if coin and coin.is_inside_tree():
			coin.get_parent().queue_free()

	# Přesunout do základny
	change_level("res://levels/Base_model/base.tscn", Vector3(0, 0, -6.6 ))
