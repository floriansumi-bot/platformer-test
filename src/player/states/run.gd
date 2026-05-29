extends State


func enter() -> void:
	player.reset_air_jumps()
	player.play_anim(&"run")


func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.handle_horizontal(delta)
	player.move_and_slide()

	if Input.is_action_just_pressed("jump"):
		player.jump()
		transitioned.emit(&"jump")
	elif not player.is_on_floor():
		player.start_coyote()
		transitioned.emit(&"fall")
	elif player.get_move_direction() == 0.0 and is_zero_approx(player.velocity.x):
		transitioned.emit(&"idle")
