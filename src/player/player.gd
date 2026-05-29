# Player controller — CharacterBody2D root of player.tscn.
# Owns the tunables and the movement helpers the FSM states call.
# Physics ordering lives in the states (src/player/states/), not here.
class_name Player
extends CharacterBody2D

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

var air_jumps_left: int = 0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var jump_buffer_timer: Timer = $JumpBufferTimer
@onready var state_machine: StateMachine = $StateMachine


func _ready() -> void:
	air_jumps_left = max_air_jumps


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
