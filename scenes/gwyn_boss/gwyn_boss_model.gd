extends Node3D

var already_hit := {}
var current_attack_anim := ""
var attack_damage := 0

func attack_hitbox_on():
	if current_attack_anim != "":
		$Sketchfab_model/root/GLTF_SceneRootNode/c5370_383/GLTF_created_0/Skeleton3D/Sword/hitbox.monitoring = true
		print("enemy hitbox on")
		already_hit.clear()

func attack_hitbox_off():
	$Sketchfab_model/root/GLTF_SceneRootNode/c5370_383/GLTF_created_0/Skeleton3D/Sword/hitbox.monitoring = false
	print("enemy hitbox off")
	current_attack_anim = ""

func _on_hitbox_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and not already_hit.has(body):
		already_hit[body] = true
		print("zásah hráče")
		body.take_damage(attack_damage)
