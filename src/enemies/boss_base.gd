class_name BossBase
extends CharacterBody2D
## Shared boss logic: health, stomp-to-damage, flash + shrink feedback, death
## (emits died + EventBus.boss_defeated), DetectionZone aggro, and a player ref.
## Each boss subclasses this and overrides _behaviour(delta) for its movement.
## Required child nodes: AnimatedSprite2D, Hitbox, StompBox, DetectionZone.

signal died

@export var max_health: int = 50   # 5 stomps (the player's feet deal 10)
@export var gravity: float = 980.0

var health: int
var dead: bool = false
var active: bool = false
var player: Node2D
var _base_scale: Vector2

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Hitbox = $Hitbox
@onready var stompbox: Hurtbox = $StompBox
@onready var detection: Area2D = $DetectionZone


func _ready() -> void:
	health = max_health
	_base_scale = sprite.scale
	player = get_tree().get_first_node_in_group("player")
	stompbox.hurt.connect(func(amount: int): take_damage(amount))
	detection.body_entered.connect(func(b): if b is Player: active = true)
	detection.body_exited.connect(func(b): if b is Player: active = false)
	if sprite.sprite_frames.has_animation("walk"):
		sprite.play("walk")
	_on_ready()


func _physics_process(delta: float) -> void:
	if dead:
		return
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	_behaviour(delta)
	move_and_slide()


# --- Overridable hooks ---
func _on_ready() -> void:
	pass

func _behaviour(_delta: float) -> void:
	pass


func dir_to_player() -> float:
	if player == null:
		return 0.0
	return signf(player.global_position.x - global_position.x)


func take_damage(amount: int) -> void:
	if dead:
		return
	health -= amount
	var flash := create_tween()
	flash.tween_property(sprite, "modulate", Color(1.0, 0.4, 0.4), 0.05)
	flash.tween_property(sprite, "modulate", Color.WHITE, 0.12)
	var r := clampf(float(health) / float(max_health), 0.0, 1.0)
	create_tween().tween_property(sprite, "scale", _base_scale * (0.55 + 0.45 * r), 0.12)
	if health <= 0:
		_die()


func _die() -> void:
	dead = true
	died.emit()
	EventBus.boss_defeated.emit()
	hitbox.set_deferred(&"monitoring", false)
	stompbox.set_deferred(&"monitoring", false)
	velocity = Vector2.ZERO
	if sprite.sprite_frames.has_animation("hit"):
		sprite.play("hit")
	var t := create_tween()
	t.tween_property(sprite, "scale", _base_scale * 0.05, 0.45)
	t.parallel().tween_property(self, "modulate:a", 0.0, 0.5)
	t.tween_callback(queue_free)
