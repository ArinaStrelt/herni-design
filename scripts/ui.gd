extends CanvasLayer

@onready var gold_label = $container_gold/gold_label
@onready var health_bar: ProgressBar = $container_healthbar/player_health_bar
@onready var health_bar_label = $container_healthbar/player_health_label
@onready var shop_ui = $shop_ui
@onready var start_info = $start_info
@onready var storeEnteringAudioStream = $AudioStreamPlayer3D_enter
var shop_opened := false

func _ready():
	var player = get_tree().get_root().find_child("Player", true, false)
	if player:
		update_health(player.current_health, player.max_health)
		update_gold(player.gold)


func update_health(current_health: int, max_health: int) -> void:
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
		health_bar_label.text = "%d HP" % current_health

func update_gold(gold_amount: int) -> void:
	gold_label.text = "Gold: %d" % gold_amount

func open_shop():
	storeEnteringAudioStream.play()
	shop_ui.update_ui()
	shop_ui.visible = true
	shop_opened = true
	get_tree().paused = true  # pauzne hru, pokud chceš
	
func close_shop():
	shop_ui.visible = false
	shop_opened = false
	get_tree().paused = false

func close_start_info():
	start_info.visible = false
