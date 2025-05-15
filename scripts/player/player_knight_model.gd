extends Node3D

@onready var player = get_node("/root/level_loader/Player")
var already_hit := {}
var current_attack_anim := ""

func attack_hitbox_on():
	if current_attack_anim != "":
		$Knight/Skeleton3D/K30_W01_REF_001/sword_hitbox.monitoring = true
		already_hit.clear()
		print("hit on")

func attack_hitbox_off():
	$Knight/Skeleton3D/K30_W01_REF_001/sword_hitbox.monitoring = false
	current_attack_anim = ""
	print("hit off")

func _on_sword_hitbox_body_entered(body):
	if body.is_in_group("enemies") and not already_hit.has(body):
		already_hit[body] = true
		print("zásah nepřítele")
		body.take_damage(player.damage)
