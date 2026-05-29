class_name Powerup
extends Area2D
## A timed powerup pickup. On touch it calls player.apply_powerup(kind) and
## vanishes. kind ∈ {"shield", "wand", "banana", "boots"}.
## Detects the player by collision mask (player = layer 2).

const PICKUP_SFX: AudioStream = preload("res://assets/pixelart/medieval tutorial 2d pixelart/sounds/power_up.wav")

@export_enum("shield", "wand", "banana", "boots") var kind: String = "shield"

@onready var sprite: Sprite2D = $Sprite2D

var taken: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var tex := load("res://assets/textures/powerup_%s.png" % kind)
	if tex != null:
		sprite.texture = tex
	# Gentle bob so it reads as a pickup.
	var t := create_tween().set_loops()
	t.tween_property(sprite, "position:y", -4.0, 0.6).set_trans(Tween.TRANS_SINE)
	t.tween_property(sprite, "position:y", 0.0, 0.6).set_trans(Tween.TRANS_SINE)


func _on_body_entered(body: Node2D) -> void:
	if taken or not (body is Player):
		return
	taken = true
	(body as Player).apply_powerup(kind)
	var am := get_node_or_null(^"/root/AudioManager")
	if am != null:
		am.play_sfx(PICKUP_SFX, -4.0)
	queue_free()
