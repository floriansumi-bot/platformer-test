extends State


func enter() -> void:
	player.play_anim(&"fall")


func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.handle_horizontal(delta)

	if Input.is_action_just_pressed("jump"):
		player.buffer_jump()
		if player.can_coyote_jump():
			player.jump()
			transitioned.emit(&"jump")
			return
		elif player.air_jumps_left > 0:
			player.air_jumps_left -= 1
			player.jump()
			transitioned.emit(&"jump")
			return

	player.move_and_slide()

	if player.is_on_floor():
		if player.has_buffered_jump():          # buffered jump fires on landing
			player.jump()
			transitioned.emit(&"jump")
		elif player.get_move_direction() != 0.0:
			transitioned.emit(&"run")
		else:
			transitioned.emit(&"idle")
