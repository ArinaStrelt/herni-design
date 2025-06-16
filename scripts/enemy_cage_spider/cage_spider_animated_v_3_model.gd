extends Node3D

var already_hit := {}
var current_attack_anim := ""
var attack_damage := 0
var hitbox_enabled := false
var last_hit_time := {}

const HIT_COOLDOWN := 1.2  # v sekundách

func attack_hitbox_on():
	if current_attack_anim != "":
		var hitbox = $Armature/Skeleton3D/Arm_left/hitbox
		if hitbox:
			hitbox.monitoring = true
			hitbox_enabled = true
			already_hit.clear()
			last_hit_time.clear()
			print("enemy hitbox ON")


func attack_hitbox_off():
	var hitbox = $Armature/Skeleton3D/Arm_left/hitbox
	if hitbox:
		hitbox.monitoring = false
		hitbox_enabled = false
		print("enemy hitbox OFF")
	current_attack_anim = ""



func _on_hitbox_body_entered(body: Node3D) -> void:
	if not hitbox_enabled:
		return
	if body.is_in_group("player"):
		var now = Time.get_ticks_msec() / 1000.0
		if not last_hit_time.has(body) or now - last_hit_time[body] > HIT_COOLDOWN:
			last_hit_time[body] = now
			print("zásah hráče")
			print("Hitbox:", get_parent().name, "zasáhl:", body.name)
			if "take_damage" in body:
				body.take_damage(attack_damage)
		else:
			print("❌ Zásah ignorován kvůli cooldownu.")
