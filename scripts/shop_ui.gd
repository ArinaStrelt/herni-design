extends Control

@onready var player = get_node("/root/level_loader/Player")

# HP sekce
@onready var hp_current_label = $panel/HBoxContainer/hp_section/current_hp
@onready var hp_price_label = $panel/HBoxContainer/hp_section/upgrade_hp_price
@onready var hp_bonus_label = $panel/HBoxContainer/hp_section/upgrade_hp_info
@onready var hp_button = $panel/HBoxContainer/hp_section/upgrade_hp_button

# Damage sekce
@onready var dmg_current_label = $panel/HBoxContainer/dmg_section/current_dmg
@onready var dmg_price_label = $panel/HBoxContainer/dmg_section/upgrade_dmg_price
@onready var dmg_bonus_label = $panel/HBoxContainer/dmg_section/upgrade_dmg_info
@onready var dmg_button = $panel/HBoxContainer/dmg_section/upgrade_dmg_button

# Zavírací tlačítko
@onready var close_button = $panel/close_button

# Parametry upgradů
var hp_upgrade_amount = 20
var hp_upgrade_cost = 25

var dmg_upgrade_amount = 5
var dmg_upgrade_cost = 25

func _ready():
	close_button.pressed.connect(_on_close_pressed)
	hp_button.pressed.connect(_on_hp_upgrade)
	dmg_button.pressed.connect(_on_dmg_upgrade)
	update_ui()

func update_ui():
	# Aktualizace HP sekce
	hp_current_label.text = "HP: %d / %d" % [player.current_health, player.max_health]
	hp_price_label.text = "Cena: %d zlata" % hp_upgrade_cost
	hp_bonus_label.text = "Bonus: +%d HP" % hp_upgrade_amount
	hp_button.disabled = player.gold < hp_upgrade_cost

	# Aktualizace Damage sekce
	dmg_current_label.text = "Damage: %d" % player.damage
	dmg_price_label.text = "Cena: %d zlata" % dmg_upgrade_cost
	dmg_bonus_label.text = "Bonus: +%d Damage" % dmg_upgrade_amount
	dmg_button.disabled = player.gold < dmg_upgrade_cost

func _on_hp_upgrade():
	if player.gold >= hp_upgrade_cost:
		player.gold -= hp_upgrade_cost
		player.max_health += hp_upgrade_amount
		player.current_health += hp_upgrade_amount  # volitelné
		player.ui.update_health(player.current_health, player.max_health)
		player.ui.update_gold(player.gold)
		hp_upgrade_cost += 25
		update_ui()

func _on_dmg_upgrade():
	if player.gold >= dmg_upgrade_cost:
		player.gold -= dmg_upgrade_cost
		player.damage += dmg_upgrade_amount
		player.ui.update_gold(player.gold)
		dmg_upgrade_cost += 25
		update_ui()

func _on_close_pressed():
	var ui = get_node("/root/level_loader/UI")
	ui.close_shop()
	if player:
		player.can_move = true
