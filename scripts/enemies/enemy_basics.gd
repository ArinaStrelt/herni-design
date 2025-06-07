extends CharacterBody3D
@onready var playerHitAudioStream = $AudioStreamPlayer3D_hit
var health := 20

func take_damage(amount: int):
	health -= amount
	playerHitAudioStream.play()
	
	print("Nepřítel zasažen! HP:", health)
	if health <= 0:
		queue_free()
