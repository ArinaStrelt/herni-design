extends Area3D

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
	loader.change_level()
