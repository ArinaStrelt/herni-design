extends CanvasLayer

@onready var fader := $Fader
@onready var transition_fx = preload("res://audio/transition.wav")

func fade_out() -> Tween:
	AudioPlayer.play_FX(transition_fx, -12)
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
