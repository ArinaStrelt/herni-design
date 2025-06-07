extends CharacterBody3D

var health := 20

func take_damage(amount: int):
	health -= amount

	
	print("Nepřítel zasažen! HP:", health)
	if health <= 0:
		queue_free()
