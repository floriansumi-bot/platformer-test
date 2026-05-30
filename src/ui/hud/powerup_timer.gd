class_name PowerupTimer
extends Control
## A small powerup icon with a ring around it that depletes clockwise like a
## countdown pie, vanishing exactly when the powerup ends. One per active
## powerup; the HUD creates/removes these.

const SIZE := 26.0
const RADIUS := 12.0

var kind: String = ""

var _duration: float = 1.0
var _elapsed: float = 0.0
var _icon: TextureRect


func setup(k: String, duration: float) -> void:
	kind = k
	custom_minimum_size = Vector2(SIZE, SIZE)
	var tex: Texture2D = load("res://assets/textures/powerup_%s.png" % k)
	_icon = TextureRect.new()
	_icon.texture = tex
	_icon.position = Vector2((SIZE - 16.0) * 0.5, (SIZE - 16.0) * 0.5)
	_icon.size = Vector2(16, 16)
	_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_icon)
	restart(duration)


## (Re)start the countdown — used when the same powerup is picked up again.
func restart(duration: float) -> void:
	_duration = maxf(0.01, duration)
	_elapsed = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= _duration:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var frac := clampf(1.0 - _elapsed / _duration, 0.0, 1.0)
	if frac <= 0.0:
		return
	var c := Vector2(SIZE, SIZE) * 0.5
	# dim full ring for context, then the bright "time left" arc on top
	draw_arc(c, RADIUS, 0.0, TAU, 40, Color(0, 0, 0, 0.35), 3.0, true)
	var start := -PI / 2.0
	draw_arc(c, RADIUS, start, start + frac * TAU, 40, Color(1, 1, 1, 0.95), 2.5, true)
