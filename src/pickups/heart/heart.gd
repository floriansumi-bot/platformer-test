class_name Heart
extends Area2D
## Healing pickup. When the player touches it, restore one heart (capped at max)
## and disappear. Detects the player by collision mask (player = layer 2).

const PICKUP_SFX: AudioStream = preload("res://assets/pixelart/medieval tutorial 2d pixelart/sounds/power_up.wav")

@onready var sprite: Sprite2D = $Sprite2D

var taken: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var t := create_tween().set_loops()
	t.tween_property(sprite, "scale", Vector2(1.15, 1.15), 0.5).set_trans(Tween.TRANS_SINE)
	t.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_SINE)


func _on_body_entered(body: Node2D) -> void:
	if taken or not (body is Player):
		return
	taken = true
	var gm := get_node_or_null(^"/root/GameManager")
	if gm != null:
		gm.heal(1)
	var am := get_node_or_null(^"/root/AudioManager")
	if am != null:
		am.play_sfx(PICKUP_SFX, -6.0)
	queue_free()
