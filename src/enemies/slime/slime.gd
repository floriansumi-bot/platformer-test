class_name Slime
extends CharacterBody2D
## Patrols a platform, turning around at ledges and walls (RayCast2D probes).
## Stomp it from above to kill it; touch it from the side and its Hitbox hurts you.
## Reports its fate with `died` / `damaged` — it never touches the player.

signal died
signal damaged(amount: int)

@export var speed: float = 32.0
@export var gravity: float = 980.0
@export var max_health: int = 1

var health: int
var direction: int = -1   # -1 = left, 1 = right
var dead: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ground_ray: RayCast2D = $GroundRay   # points down, offset ahead — ledge probe
@onready var wall_ray: RayCast2D = $WallRay       # points forward — wall probe
@onready var hitbox: Hitbox = $Hitbox             # contact damage to the player
@onready var stompbox: Hurtbox = $StompBox        # thin top hurtbox — stomp target


func _ready() -> void:
	health = max_health
	stompbox.hurt.connect(_on_stomped)
	_face(direction)
	sprite.play("walk")


func _physics_process(delta: float) -> void:
	if dead:
		return
	if not is_on_floor():
		velocity.y += gravity * delta
	elif not ground_ray.is_colliding() or wall_ray.is_colliding():
		_face(-direction)   # ledge ahead or wall ahead → turn
	velocity.x = float(direction) * speed
	move_and_slide()


## Point the probes in the travel direction and flip the sprite to match.
func _face(dir: int) -> void:
	direction = dir
	sprite.flip_h = dir > 0
	ground_ray.position.x = absf(ground_ray.position.x) * dir
	wall_ray.target_position.x = absf(wall_ray.target_position.x) * dir


func _on_stomped(amount: int) -> void:
	take_damage(amount)


func take_damage(amount: int) -> void:
	if dead:
		return
	health -= amount
	damaged.emit(amount)
	if health <= 0:
		_die()


func _die() -> void:
	dead = true
	died.emit()
	EventBus.enemy_killed.emit()   # +1 score
	hitbox.set_deferred(&"monitoring", false)
	stompbox.set_deferred(&"monitoring", false)
	velocity = Vector2.ZERO
	sprite.play("hit")
	var t := create_tween()
	t.tween_property(sprite, "scale:y", 0.15, 0.12)
	t.parallel().tween_property(self, "modulate:a", 0.0, 0.2)
	t.tween_callback(queue_free)
