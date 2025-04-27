extends CanvasLayer

@onready var gold_label = $container_gold/gold_label
@onready var health_bar: ProgressBar = $container_healthbar/player_health_bar

func _ready():
	var player = get_tree().get_root().find_child("Player", true, false)
	if player:
		update_health(player.current_health, player.max_health)


func update_health(current_health: int, max_health: int) -> void:
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health

func update_gold(gold_amount: int) -> void:
	gold_label.text = "Gold: %d" % gold_amount
