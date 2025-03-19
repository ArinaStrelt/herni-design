extends Node3D

@onready var light: OmniLight3D = $OmniLight3D
var new_energy := 1.0

func _ready() -> void:
	randomize()
	
func _process(delta: float) -> void:
	light.light_energy = lerp(light.light_energy, new_energy, delta * 2.5)

func _on_timer_timeout() -> void:
	new_energy = randf_range(0.2, 1.0)
