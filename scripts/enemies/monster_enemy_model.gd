extends Node3D

var already_hit := {}
var current_attack_anim := ""
var attack_damage := 0

func attack_hitbox_on():
	if current_attack_anim != "":
		$Armature/Skeleton3D/RightArm/hitbox.monitoring = true
		print("enemy hitbox on")
		already_hit.clear()

func attack_hitbox_off():
	$Armature/Skeleton3D/RightArm/hitbox.monitoring = false
	print("enemy hitbox off")
	current_attack_anim = ""


func _on_hitbox_body_entered(body: Node3D) -> void:
		if body.is_in_group("player") and not already_hit.has(body):
			already_hit[body] = true
			print("zásah hráče")
			body.take_damage(attack_damage)
