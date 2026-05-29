class_name Door
extends StaticBody2D
## A solid gate that blocks the path until a LevelButton opens it (slides up out
## of the way and stops colliding).

func open() -> void:
	var t := create_tween()
	t.tween_property(self, "position:y", position.y - 48.0, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(self, "modulate:a", 0.35, 0.55)
	t.tween_callback(func(): collision_layer = 0)
