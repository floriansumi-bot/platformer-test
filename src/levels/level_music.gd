extends Node
## Drop into a scene to start its background track. AudioManager ignores the
## call if that track is already playing, so it won't restart on reload.

@export var track: AudioStream


func _ready() -> void:
	var am := get_node_or_null(^"/root/AudioManager")
	if am != null and track != null:
		am.play_music(track)
