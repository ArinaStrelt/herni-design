extends Node3D

@onready var fade := $FadeLayer
@onready var level_root := $level_root
@onready var player := $Player
@onready var ui = $"/root/level_loader/UI"
@onready var shop_ui = $"/root/level_loader/UI/shop_ui"

var current_level: Node = null

var room_pool_1 := [
	"res://levels/dragon_forest/dragon_forest.tscn",
	"res://levels/ruins_forest/ruins_forest.tscn"
]

var room_pool_2 := [
	"res://levels/hrad_1/hrad_1.tscn",
	"res://levels/hrad_2/hrad_2.tscn"
]

var start_room := "res://levels/entrance_model/entrance.tscn"
var boss_room := "res://levels/boss_level/boss_level.tscn"

var room_count := 0
var max_rooms_before_boss := 7

func _ready():
	# Načti první level při spuštění
	randomize()
	load_level("res://levels/Base_model/base.tscn")

func clear_level_entities():
	for entity in get_tree().get_nodes_in_group("level_entities"):
		if is_instance_valid(entity):
			entity.queue_free()

func load_level(path: String):
	if current_level:
		current_level.queue_free()

	var scene = ResourceLoader.load(path, "PackedScene")

	current_level = scene.instantiate()
	level_root.add_child(current_level)

	# Hledání spawnu hráče
	var spawn_marker = current_level.get_node_or_null("player_spawn")
	if spawn_marker:
		player.global_transform.origin = spawn_marker.global_transform.origin
	else:
		print("⚠️ Varování: PlayerSpawn nebyl nalezen – hráč se nespawnul správně.")


func change_level(path := ""):
	var tween = fade.fade_out()
	await tween.finished
	if not path.ends_with("base.tscn"):
		room_count += 1
	else:
		room_count = 0
	print(room_count)
	if path == "":
		if room_count == 4:
			path = start_room
		elif room_count > max_rooms_before_boss:
			path = boss_room
		elif room_count < 4:
			path = room_pool_1.pick_random()
		else:
			path = room_pool_2.pick_random()
	print(path)
	
	load_level(path)
	clear_level_entities()
	spawn_enemies_in_level()

	var fade_in_tween = fade.fade_in()
	await fade_in_tween.finished

func get_scaled_enemy_pool():
	var tier1 = preload("res://scenes/enemies/enemy_knight.tscn")
	var tier2 = preload("res://scenes/enemies/enemy_cage_spider.tscn")
	var tier3 = preload("res://scenes/enemies/enemy_skeleton.tscn")
	var tier4 = preload("res://scenes/enemy_monster/enemy_monster.tscn")

	if room_count < 3:
		return [tier1, tier3]
	elif room_count == 4:
		return [tier2]
	elif room_count < 5:
		return [tier1, tier2, tier3]
	else:
		return [tier1, tier2, tier3, tier4]

func spawn_enemies_in_level():
	if not current_level:
		return

	var spawn_parent = current_level.get_node_or_null("enemy_spawns")
	if not spawn_parent:
		return

	var enemy_pool = get_scaled_enemy_pool()
	var total_spawn_points = spawn_parent.get_child_count()

	var tier3_scene = preload("res://scenes/enemies/enemy_skeleton.tscn")
	var max_tier3 = 3
	var tier3_count = 0

	var i = 0
	while i < total_spawn_points:
		var candidate = enemy_pool.pick_random()

		if candidate == tier3_scene and tier3_count >= max_tier3:
			continue
		else:
			if candidate == tier3_scene:
				tier3_count += 1

			var point = spawn_parent.get_child(i)
			var enemy_instance = candidate.instantiate()
			enemy_instance.transform.origin = point.global_transform.origin

			if enemy_instance.has_method("scale_difficulty"):
				enemy_instance.scale_difficulty(room_count)

			current_level.add_child(enemy_instance)

			i += 1


func reset_run():
	print("Resetuji běh…")

	# Odstranit aktuální mapu
	if current_level:
		current_level.queue_free()
		current_level = null

	player.reset_player()
	ui.update_health(player.current_health, player.max_health)
	ui.update_gold(player.gold)
	clear_level_entities()

	# Přesunout do základny
	change_level("res://levels/Base_model/base.tscn")
