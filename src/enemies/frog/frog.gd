class_name Frog
extends CharacterBody2D
## Hopping enemy (Kenney pack). Sits, then hops forward on a timer; turns around
## at walls. Stomp it from above to kill (player bounces); its body hurts you on
## contact. Reports kills via the global EventBus. Same damage model as the slime.

signal died
signal damaged(amount: int)

@export var gravity: float = 980.0
@export var hop_vx: float = 46.0
@export var hop_vy: float = -250.0
@export var hop_interval: float = 1.3
@export var max_health: int = 1

var health: int
var dead: bool = false
var _dir: int = -1
var _t: float = 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ground_ray: RayCast2D = $GroundRay   # down-ahead ledge probe
@onready var hitbox: Hitbox = $Hitbox
@onready var stompbox: Hurtbox = $StompBox


func _ready() -> void:
	health = max_health
	stompbox.hurt.connect(_on_stomped)
	sprite.play("idle")


func _physics_process(delta: float) -> void:
	if dead:
		return
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
		_t += delta
		if _t >= hop_interval:
			_t = 0.0
			# Don't leap over a ledge or into a wall — turn instead.
			_ground_probe()
			if not ground_ray.is_colliding() or is_on_wall():
				_dir = -_dir
			velocity.y = hop_vy
			velocity.x = float(_dir) * hop_vx
			sprite.play("jump")
	sprite.flip_h = _dir > 0
	move_and_slide()
	if is_on_floor() and velocity.y >= 0.0 and sprite.animation == &"jump":
		sprite.play("idle")


func _ground_probe() -> void:
	ground_ray.position.x = absf(ground_ray.position.x) * _dir


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
	EventBus.enemy_killed.emit()
	hitbox.set_deferred(&"monitoring", false)
	stompbox.set_deferred(&"monitoring", false)
	velocity = Vector2.ZERO
	var t := create_tween()
	t.tween_property(sprite, "scale:y", sprite.scale.y * 0.2, 0.12)
	t.parallel().tween_property(self, "modulate:a", 0.0, 0.2)
	t.tween_callback(queue_free)
