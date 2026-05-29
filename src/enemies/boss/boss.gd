class_name Boss
extends CharacterBody2D
## King Slime — the end-of-level boss. Sleeps until the player enters its
## DetectionZone, then hops toward the player. Stomp it 5 times to win; it
## flashes and shrinks as it weakens. Touching its body hurts the player.
## Reports its fate via `died` and the global EventBus.boss_defeated signal.

signal died
signal damaged(amount: int)

@export var max_health: int = 50          # 5 stomps (player feet deal 10 each)
@export var gravity: float = 980.0
@export var hop_speed: float = 70.0
@export var hop_jump: float = -320.0
@export var hop_interval: float = 1.4

var health: int
var dead: bool = false
var active: bool = false
var player: Node2D
var _base_scale: Vector2

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hop_timer: Timer = $HopTimer
@onready var hitbox: Hitbox = $Hitbox
@onready var stompbox: Hurtbox = $StompBox
@onready var detection: Area2D = $DetectionZone


func _ready() -> void:
	health = max_health
	_base_scale = sprite.scale
	player = get_tree().get_first_node_in_group("player")
	stompbox.hurt.connect(_on_stomped)
	hop_timer.wait_time = hop_interval
	hop_timer.timeout.connect(_on_hop)
	hop_timer.start()
	detection.body_entered.connect(func(b): if b is Player: active = true)
	detection.body_exited.connect(func(b): if b is Player: active = false)
	sprite.play("walk")


func _physics_process(delta: float) -> void:
	if dead:
		return
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.x = move_toward(velocity.x, 0.0, hop_speed * 4.0 * delta)
	move_and_slide()


func _on_hop() -> void:
	if dead or not active or not is_on_floor():
		return
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	var dir := 1.0
	if player != null:
		dir = signf(player.global_position.x - global_position.x)
		sprite.flip_h = dir > 0.0
	velocity.x = dir * hop_speed
	velocity.y = hop_jump


func _on_stomped(amount: int) -> void:
	take_damage(amount)


func take_damage(amount: int) -> void:
	if dead:
		return
	health -= amount
	damaged.emit(amount)
	# Flash red and shrink toward half size as health drops.
	var hurt_tween := create_tween()
	hurt_tween.tween_property(sprite, "modulate", Color(1.0, 0.4, 0.4), 0.05)
	hurt_tween.tween_property(sprite, "modulate", Color.WHITE, 0.12)
	var t := clampf(float(health) / float(max_health), 0.0, 1.0)
	create_tween().tween_property(sprite, "scale", _base_scale * (0.5 + 0.5 * t), 0.12)
	if health <= 0:
		_die()


func _die() -> void:
	dead = true
	died.emit()
	EventBus.boss_defeated.emit()
	hitbox.set_deferred(&"monitoring", false)
	stompbox.set_deferred(&"monitoring", false)
	hop_timer.stop()
	velocity = Vector2.ZERO
	sprite.play("hit")
	var t := create_tween()
	t.tween_property(sprite, "scale", _base_scale * 0.05, 0.45)
	t.parallel().tween_property(self, "modulate:a", 0.0, 0.5)
	t.tween_callback(queue_free)
