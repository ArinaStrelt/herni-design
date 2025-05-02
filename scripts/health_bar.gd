extends Sprite3D

@onready var bar := $SubViewport/ProgressBar  # cesta ke 2D progress baru

func _ready():
	# Napojí Viewport jako texturu na tento sprite
	texture = $SubViewport.get_texture()
	bar.max_value = 100
	bar.value = 100
	show()

func update_healthbar(current_health: int, max_health: int) -> void:
	bar.max_value = max_health
	bar.value = current_health

	# Automaticky zobraz/skrývej podle stavu
	if current_health >= max_health:
		hide()
	else:
		show()
