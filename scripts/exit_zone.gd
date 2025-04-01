extends Area3D

@export var next_level_path: String
@export var next_spawn_position: Vector3 = Vector3(0, 0, 0)

func _on_body_entered(body):
	if not body.is_in_group("player"):
		return

	# Zkontroluj, jestli ve scéně ještě jsou nepřátelé
	if get_tree().get_nodes_in_group("enemies").size() > 0:
		print("Jsou tu ještě nepřátelé!")
		return

	print("Přecházím na další mapu!")

	# Voláme přechod přes LevelLoader (který je v rootu)
	var loader = get_node("/root/level_loader")
	loader.change_level(next_level_path, next_spawn_position)
