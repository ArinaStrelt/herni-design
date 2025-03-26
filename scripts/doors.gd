extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var _enemy_killed := false
var _player_close := false
var _opened := false

func _ready():
	animation_player.play("Idle")

func _process(delta: float) -> void:
	if !animation_player.is_playing() and _player_close and not _opened and _enemy_killed:
		animation_player.play("Open")
		_opened = true

# Zavolej mě přes signál, když enemy umře
func _on_enemy_killed():
	_enemy_killed = true

# Zavolej mě z area 3D když do něj hráč vejde
func _on_player_enter(body: Node3D):
	if !body.is_in_group("player"): return
	_player_close = true
	if _enemy_killed:
		animation_player.play("Open")
		_opened = true
		
# zavolej mě z Area 3D když odsud hráč odejde
func _on_player_leave(body: Node3D):
	if !body.is_in_group("player"): return
	_player_close = false
	if _enemy_killed:
		animation_player.play("Close")
		_opened = false
