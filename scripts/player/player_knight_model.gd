extends Node3D

var hit_enemies := {}
var current_attack_anim := ""

func attack_hitbox_on():
	if current_attack_anim != "":
		$Knight/Skeleton3D/K30_W01_REF_001/sword_hitbox.monitoring = true
		hit_enemies.clear()

func attack_hitbox_off():
	$Knight/Skeleton3D/K30_W01_REF_001/sword_hitbox.monitoring = false
	current_attack_anim = ""


func _on_sword_hitbox_body_entered(body):
	if body.is_in_group("enemies") and not hit_enemies.has(body):
		hit_enemies[body] = true
		print("zásah nepřítele")
		body.take_damage(10)
