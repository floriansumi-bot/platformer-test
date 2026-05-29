class_name Bee
extends CharacterBody2D
## Flying enemy (Kenney pack). Drifts back and forth in the air with a gentle bob,
## ignoring terrain. Stomp it from above to kill (player bounces); its body hurts
## you on contact. Reports kills via the global EventBus.

signal died

@export var speed: float = 42.0
@export var range_px: float = 56.0   # how far it drifts from its start before turning
@export var bob_height: float = 8.0
@export var bob_speed: float = 3.0

var dead: bool = false
var _origin_x: float = 0.0
var _dir: int = 1
var _t: float = 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Hitbox = $Hitbox
@onready var stompbox: Hurtbox = $StompBox


func _ready() -> void:
	_origin_x = global_position.x
	stompbox.hurt.connect(_on_stomped)
	sprite.play("fly")


func _physics_process(delta: float) -> void:
	if dead:
		return
	_t += delta
	if global_position.x > _origin_x + range_px:
		_dir = -1
	elif global_position.x < _origin_x - range_px:
		_dir = 1
	sprite.flip_h = _dir > 0
	velocity.x = float(_dir) * speed
	velocity.y = cos(_t * bob_speed) * bob_height
	move_and_slide()


func _on_stomped(_amount: int) -> void:
	_die()


func _die() -> void:
	dead = true
	died.emit()
	EventBus.enemy_killed.emit()
	hitbox.set_deferred(&"monitoring", false)
	stompbox.set_deferred(&"monitoring", false)
	velocity = Vector2.ZERO
	var t := create_tween()
	t.tween_property(self, "position:y", position.y + 24.0, 0.35)   # tumble downward
	t.parallel().tween_property(self, "modulate:a", 0.0, 0.35)
	t.tween_callback(queue_free)
