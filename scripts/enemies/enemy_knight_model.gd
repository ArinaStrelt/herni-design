extends Node3D

var already_hit := {}
var current_attack_anim := ""
var attack_damage := 10

func attack_hitbox_on():
	if current_attack_anim != "":
		$Armature/Skeleton3D/Cube_sword_0/sword_hitbox.monitoring = true
		print("enemy hitbox on")
		already_hit.clear()

func attack_hitbox_off():
	$Armature/Skeleton3D/Cube_sword_0/sword_hitbox.monitoring = false
	print("enemy hitbox off")
	current_attack_anim = ""

func _on_sword_hitbox_body_entered(body):
	if body.is_in_group("player") and not already_hit.has(body):
		already_hit[body] = true
		print("zásah hráče")
		body.take_damage(attack_damage)
