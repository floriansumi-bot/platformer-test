class_name MovingPlatform
extends AnimatableBody2D
## Moves between its start and start+travel and back, forever. sync_to_physics
## (set in the scene) makes it carry the player smoothly. On the world layer.

@export var travel: Vector2 = Vector2(64, 0)
@export var duration: float = 2.0


func _ready() -> void:
	var start := position
	# Move during the physics step so sync_to_physics carries the player.
	var t := create_tween().set_loops().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	t = t.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(self, "position", start + travel, duration)
	t.tween_property(self, "position", start, duration)
