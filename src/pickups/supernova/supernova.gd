extends Area2D
## Expanding shockwave spawned by the wand powerup. Grows outward, killing any
## enemy Hurtbox it sweeps over (enemy layer = 4), then frees itself.

func _ready() -> void:
	collision_mask = 4
	area_entered.connect(_on_area_entered)

	# Glowing disc, built in code so the scene stays tiny.
	var poly := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		pts.append(Vector2(cos(a), sin(a)) * 16.0)
	poly.polygon = pts
	poly.color = Color(0.55, 0.85, 1.0, 0.7)
	add_child(poly)

	scale = Vector2(0.25, 0.25)
	var t := create_tween()
	t.tween_property(self, "scale", Vector2(4.5, 4.5), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(self, "modulate:a", 0.0, 0.5)
	t.tween_callback(queue_free)


func _on_area_entered(a: Area2D) -> void:
	if a is Hurtbox:
		(a as Hurtbox).take_hit(100)   # enough to kill any enemy
