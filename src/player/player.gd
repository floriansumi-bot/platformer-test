# Player controller — CharacterBody2D root of player.tscn.
# Owns the tunables and the movement helpers the FSM states call.
# Physics ordering lives in the states (src/player/states/), not here.
class_name Player
extends CharacterBody2D

const DEATH_SFX: AudioStream = preload("res://assets/pixelart/medieval tutorial 2d pixelart/sounds/explosion.wav")

@export_group("Movement")
## Top horizontal speed in px/s.
@export var speed: float = 150.0
## How fast we reach `speed` (px/s²). Higher = snappier, lower = more momentum.
@export var acceleration: float = 1500.0
## How fast we stop when there's no input (px/s²). Low = ice.
@export var friction: float = 1500.0

@export_group("Jump")
## Initial upward velocity on jump (negative = up).
@export var jump_velocity: float = -400.0
## Downward acceleration in px/s². Higher than project gravity for a snappy, non-floaty arc.
@export var gravity: float = 1400.0
## Gravity is multiplied by this while falling, for a snappier descent.
@export var fall_gravity_multiplier: float = 1.8
## Fraction of upward velocity kept when the jump button is released early.
@export var jump_cut_factor: float = 0.4
## Extra mid-air jumps. 0 = single jump, 1 = double jump, 2 = triple, ...
@export var max_air_jumps: int = 1

@export_group("Combat")
## Upward velocity gained from stomping an enemy.
@export var stomp_bounce: float = -260.0
## Seconds of invulnerability after taking a hit.
@export var invuln_time: float = 0.8

var air_jumps_left: int = 0
var invincible: bool = false
var dying: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var jump_buffer_timer: Timer = $JumpBufferTimer
@onready var state_machine: StateMachine = $StateMachine
@onready var hurtbox: Hurtbox = $Hurtbox   # takes damage from enemy Hitboxes
@onready var feet: Area2D = $Feet          # detects stompable enemy tops


func _ready() -> void:
	add_to_group("player")
	air_jumps_left = max_air_jumps
	hurtbox.hurt.connect(_on_hurt)
	feet.area_entered.connect(_on_feet_area_entered)


func _process(_delta: float) -> void:
	# Fell into a pit — die (then respawn after a short pause).
	if global_position.y > 400.0:
		_die()


## Freeze, play the death sound, count the death, then reload after a short delay.
func _die() -> void:
	if dying:
		return
	dying = true
	invincible = true
	state_machine.set_physics_process(false)
	velocity = Vector2.ZERO
	AudioManager.play_sfx(DEATH_SFX)
	# Submit the run's score to the leaderboard before the reset.
	if GameManager.score > 0:
		Leaderboard.submit_run(GameManager.score)
	GameManager.register_death()
	await get_tree().create_timer(0.8).timeout
	get_tree().reload_current_scene()


# --- Movement helpers (called by the FSM states) ---------------------------

## Apply gravity for this frame, heavier while falling.
func apply_gravity(delta: float) -> void:
	var g := gravity
	if velocity.y > 0.0:
		g *= fall_gravity_multiplier
	velocity.y += g * delta


## Accelerate toward input direction, or decelerate with friction when idle.
func handle_horizontal(delta: float) -> void:
	var direction := get_move_direction()
	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
		sprite.flip_h = direction < 0.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)


## -1.0 (left), 0.0 (none), or 1.0 (right). Reads the Input Map, never raw keys.
func get_move_direction() -> float:
	return Input.get_axis("move_left", "move_right")


## Launch a jump and clear the coyote/buffer grace timers.
func jump() -> void:
	velocity.y = jump_velocity
	coyote_timer.stop()
	jump_buffer_timer.stop()


## Variable jump height: shorten the rise when the button is released early.
func jump_cut() -> void:
	if velocity.y < 0.0:
		velocity.y *= jump_cut_factor


## True while the coyote-time grace window is open.
func can_coyote_jump() -> bool:
	return not coyote_timer.is_stopped()


## True while a buffered jump is still pending.
func has_buffered_jump() -> bool:
	return not jump_buffer_timer.is_stopped()


## Start the coyote window — call when a grounded state leaves the floor.
func start_coyote() -> void:
	coyote_timer.start()


## Remember a jump press made just before landing.
func buffer_jump() -> void:
	jump_buffer_timer.start()


## Refill air jumps — call on landing (Idle/Run enter()).
func reset_air_jumps() -> void:
	air_jumps_left = max_air_jumps


## Play a SpriteFrames animation, unless it's already the one playing.
func play_anim(anim: StringName) -> void:
	if sprite.animation != anim or not sprite.is_playing():
		sprite.play(anim)


# --- Combat ----------------------------------------------------------------

## Feet overlapped something on the enemy-stomp layer. Only count it as a stomp
## while descending — side contact is handled by the enemy's Hitbox instead.
func _on_feet_area_entered(area: Area2D) -> void:
	if velocity.y > 0.0 and area is Hurtbox:
		(area as Hurtbox).take_hit(10)   # kill the stomped enemy
		velocity.y = stomp_bounce
		_grace(0.25)                      # brief i-frames so the dying enemy can't also hit us


## Enemy Hitbox struck our Hurtbox.
func _on_hurt(_amount: int) -> void:
	if invincible:
		return
	GameManager.apply_damage(1)
	if GameManager.health <= 0:
		_die()
		return
	velocity.y = -160.0   # small recoil pop
	_flash()
	_grace(invuln_time)


## Run invulnerability for `seconds`, unless a longer window is already active.
func _grace(seconds: float) -> void:
	if invincible:
		return
	invincible = true
	await get_tree().create_timer(seconds).timeout
	invincible = false
	sprite.modulate.a = 1.0


func _flash() -> void:
	var tw := create_tween().set_loops(4)
	tw.tween_property(sprite, "modulate:a", 0.25, 0.1)
	tw.tween_property(sprite, "modulate:a", 1.0, 0.1)
