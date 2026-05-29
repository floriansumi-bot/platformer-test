extends State


func enter() -> void:
	player.play_anim(&"jump")


func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.handle_horizontal(delta)

	# Variable jump height: release early to cut the rise short.
	if Input.is_action_just_released("jump"):
		player.jump_cut()

	# Double jump (only if max_air_jumps > 0).
	if Input.is_action_just_pressed("jump") and player.air_jumps_left > 0:
		player.air_jumps_left -= 1
		player.jump()

	player.move_and_slide()

	if player.velocity.y >= 0.0:
		transitioned.emit(&"fall")
