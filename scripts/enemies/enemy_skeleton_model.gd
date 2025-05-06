extends Node3D

func cast_spell_proxy():
	if get_parent().has_method("cast_spell"):
		get_parent().cast_spell()
