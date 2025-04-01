extends CanvasLayer

@onready var fader := $Fader

func fade_out() -> Tween:
	fader.modulate.a = 0
	fader.visible = true
	var tween := create_tween()
	tween.tween_property(fader, "modulate:a", 1.0, 0.5)
	return tween

func fade_in() -> Tween:
	fader.modulate.a = 1
	fader.visible = true
	var tween := create_tween()
	tween.tween_property(fader, "modulate:a", 0.0, 0.5)
	return tween
