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
## Initial upward velocity on jump (negative = up). Tuned to 2/3 of the old
## speed (with gravity scaled to match) so the arc rises/falls slower at the
## same height.
@export var jump_velocity: float = -267.0
## Downward acceleration in px/s². Scaled with jump_velocity to keep the jump
## height while making the whole arc 2/3 as fast.
@export var gravity: float = 622.0
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

## Damage the sword swing deals — same as a stomp (see _on_feet_area_entered).
const SWORD_DAMAGE := 10
const SUPERNOVA: PackedScene = preload("res://src/pickups/supernova/supernova.tscn")

var air_jumps_left: int = 0
var invincible: bool = false
var dying: bool = false

# --- Powerup runtime state (set by apply_powerup, auto-reverted by timers) ---
var speed_mult: float = 1.0   # banana slows to 0.5
var jump_mult: float = 1.0    # super boots raise to 1.7
var shield_hits: int = 0      # absorbs this many hits before real damage
var wand_active: bool = false   # wand powerup charged — the wand button casts a supernova
var attacking: bool = false     # a sword swing is in progress
var _wand_cooldown: float = 0.0 # min seconds between wand casts
var _boots_tween: Tween         # ramps the super-boots jump boost back to normal

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


func _process(delta: float) -> void:
	# Fell into a pit — die (then respawn after a short pause).
	if global_position.y > 400.0:
		_die()
	if dying:
		return
	# Sword swing on the attack button (X key / gamepad X).
	if not attacking and Input.is_action_just_pressed("attack"):
		_swing_sword()
	# Wand: while the powerup is charged, cast a supernova on the wand button
	# (Y key / gamepad Y), rate-limited by a short cooldown.
	_wand_cooldown = maxf(0.0, _wand_cooldown - delta)
	if wand_active and _wand_cooldown <= 0.0 and Input.is_action_just_pressed("wand"):
		_spawn_supernova()
		_wand_cooldown = 0.6


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
	SceneTransitioner.change_scene(_previous_level_path())


## On death, drop back to the previous level (level 1 just restarts).
func _previous_level_path() -> String:
	var path := get_tree().current_scene.scene_file_path if get_tree().current_scene else ""
	var idx := _level_index(path)
	if idx > 1:
		return "res://src/levels/level_%02d.tscn" % (idx - 1)
	return path if path != "" else "res://src/levels/level_01.tscn"


func _level_index(path: String) -> int:
	var n := path.get_file().trim_prefix("level_").trim_suffix(".tscn")
	return int(n) if n.is_valid_int() else 0


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
		velocity.x = move_toward(velocity.x, direction * speed * speed_mult, acceleration * delta)
		sprite.flip_h = direction < 0.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)


## -1.0 (left), 0.0 (none), or 1.0 (right). Reads the Input Map, never raw keys.
func get_move_direction() -> float:
	return Input.get_axis("move_left", "move_right")


## Launch a jump and clear the coyote/buffer grace timers.
func jump() -> void:
	velocity.y = jump_velocity * jump_mult
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
		# Bounce — but if you're holding jump as you land the stomp, spring much
		# higher (a timed stomp-jump).
		var boost := 1.7 if Input.is_action_pressed("jump") else 1.0
		velocity.y = stomp_bounce * boost
		_grace(0.25)                      # brief i-frames so the dying enemy can't also hit us


## Enemy Hitbox struck our Hurtbox.
func _on_hurt(_amount: int) -> void:
	if invincible:
		return
	# Shield powerup soaks hits before real health is touched.
	if shield_hits > 0:
		shield_hits -= 1
		if shield_hits == 0:
			EventBus.powerup_ended.emit("shield")   # used up before its timer
		velocity.y = -120.0
		_flash()
		_grace(0.5)
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


# --- Sword swing -----------------------------------------------------------

## Swing the sword: a short-lived hitbox in front of the knight plus a slash
## arc. Deals SWORD_DAMAGE (== a stomp) to any enemy Hurtbox it overlaps.
func _swing_sword() -> void:
	attacking = true
	var dir := -1.0 if sprite.flip_h else 1.0
	AudioManager.play_sfx(DEATH_SFX, -16.0)   # short "whoosh" reuse, quiet

	# Damage area (enemy layer = 4). Monitors so it reports overlapping Hurtboxes.
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 4
	area.position = Vector2(22.0 * dir, -4.0)
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(34, 30)
	cs.shape = shape
	area.add_child(cs)
	add_child(area)

	var slash := _make_slash(dir)
	add_child(slash)

	var hit := func(a: Area2D) -> void:
		if a is Hurtbox:
			(a as Hurtbox).take_hit(SWORD_DAMAGE)
	area.area_entered.connect(hit)
	# Catch enemies already overlapping when the swing appears.
	await get_tree().physics_frame
	for a in area.get_overlapping_areas():
		hit.call(a)

	await get_tree().create_timer(0.18).timeout
	area.queue_free()
	slash.queue_free()
	attacking = false


## A white crescent that sweeps an arc in front of the knight, then fades.
func _make_slash(dir: float) -> Node2D:
	var n := Node2D.new()
	n.position = Vector2(16.0 * dir, -2.0)
	n.scale.x = dir
	n.rotation = -0.8
	var poly := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 9:
		var a: float = lerpf(-1.0, 1.0, i / 8.0)
		pts.append(Vector2(cos(a), sin(a)) * 26.0)
	for i in 9:
		var a: float = lerpf(1.0, -1.0, i / 8.0)
		pts.append(Vector2(cos(a), sin(a)) * 17.0)
	poly.polygon = pts
	poly.color = Color(0.92, 0.97, 1.0, 0.95)
	n.add_child(poly)
	var t := create_tween()
	t.tween_property(n, "rotation", 0.8, 0.16).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(poly, "modulate:a", 0.0, 0.16)
	return n


# --- Powerups --------------------------------------------------------------

## Apply a timed powerup effect. Called by powerup pickups on touch.
func apply_powerup(kind: String) -> void:
	var duration := 0.0
	match kind:
		"shield":
			shield_hits = 2
			duration = 30.0
			_revert_after(func(): shield_hits = 0, duration, "shield")
		"wand":
			# Charge the wand for 12s; the player casts supernovas with the wand button.
			wand_active = true
			duration = 12.0
			_revert_after(func(): wand_active = false, duration, "wand")
		"banana":
			speed_mult = 0.5
			duration = 5.0
			_revert_after(func(): speed_mult = 1.0, duration, "banana")
		"boots":
			duration = 8.0
			_apply_boots(duration)
	if duration > 0.0:
		# HUD shows the icon + a depleting ring for this long.
		EventBus.powerup_started.emit(kind, duration)


## Super boots: full 1.7x jump for the first second, then ease back down to a
## normal jump (1.0x) by the end of `duration`.
func _apply_boots(duration: float) -> void:
	if _boots_tween != null and _boots_tween.is_valid():
		_boots_tween.kill()
	jump_mult = 1.7
	_boots_tween = create_tween()
	_boots_tween.tween_interval(1.0)
	_boots_tween.tween_property(self, "jump_mult", 1.0, maxf(0.1, duration - 1.0))
	_boots_tween.tween_callback(_end_boots)


func _end_boots() -> void:
	jump_mult = 1.0
	EventBus.powerup_ended.emit("boots")


## Run `revert` after `seconds`; if a kind is given, also tell the HUD it ended.
func _revert_after(revert: Callable, seconds: float, kind: String = "") -> void:
	await get_tree().create_timer(seconds).timeout
	if is_instance_valid(self):
		revert.call()
		if kind != "":
			EventBus.powerup_ended.emit(kind)


func _spawn_supernova() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var nova := SUPERNOVA.instantiate()
	scene.add_child(nova)
	nova.global_position = global_position
