extends CanvasLayer

var health_bar: ProgressBar

func _ready():
	health_bar = $MarginContainer/PlayerHealthBar
	var player = get_tree().get_root().find_child("Player", true, false)
	if player:
		update_health(player.current_health, player.max_health)


func update_health(current_health: int, max_health: int) -> void:
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
