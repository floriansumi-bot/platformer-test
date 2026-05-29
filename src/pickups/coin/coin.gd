class_name Coin
extends Area2D
## Spinning collectible. When the player touches it, bump the coin count, play a
## blip through the AudioManager pool, and disappear. Detects the player by
## collision mask (player = layer 2).

signal collected

const PICKUP_SFX: AudioStream = preload("res://assets/pixelart/medieval tutorial 2d pixelart/sounds/coin.wav")

@export var value: int = 1

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var taken: bool = false


func _ready() -> void:
	sprite.play("spin")
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if taken or not (body is Player):
		return
	taken = true
	collected.emit()
	# Autoloads reached by path so the scene also builds in headless tooling.
	var gm := get_node_or_null(^"/root/GameManager")
	if gm != null:
		gm.add_score(value)
	var am := get_node_or_null(^"/root/AudioManager")
	if am != null:
		am.play_sfx(PICKUP_SFX)
	queue_free()
