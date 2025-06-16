extends Control
	
@onready var label = $Panel  # uprav dle cesty k textu

func _ready():
	# Startujeme s neviditelností
	size = get_viewport().size
	label.modulate.a = 0.0
	fade_in()

func fade_in():
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 1.0)  # fade in za 1.5s
	tween.tween_callback(fade_hold)

func fade_hold():
	await get_tree().create_timer(3.0).timeout  # zůstane svítit 2 sekundy
	fade_out()

func fade_out():
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 0.0, 0.25)  # fade out za 1.5s
	tween.tween_callback(queue_free)
