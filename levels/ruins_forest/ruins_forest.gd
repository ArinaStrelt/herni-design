extends Node3D
@onready var atmoAudioStreamBG = $"AudioStreamPlayer3D-BG"
var backgroundAtmoOn = true

func _process(detla):
		update_music_status()
		
func update_music_status():
		if backgroundAtmoOn:
			if !atmoAudioStreamBG.playing:
				atmoAudioStreamBG.play()
		else:
				atmoAudioStreamBG.stop()
