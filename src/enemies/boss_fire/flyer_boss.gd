extends BossBase
## Boss 2 — Fire Elemental. Hovers (no gravity), chases the player through the air
## with a bob, dipping toward the player's height. Set collision_mask = 0 (flies).

@export var hover_speed: float = 58.0
@export var bob_height: float = 9.0
@export var bob_speed: float = 2.6

var _t: float = 0.0


func _behaviour(delta: float) -> void:
	_t += delta
	if active and player != null:
		velocity.x = dir_to_player() * hover_speed
		var dy := signf(player.global_position.y - global_position.y)
		velocity.y = dy * hover_speed * 0.55 + cos(_t * bob_speed) * bob_height
	else:
		velocity.x = move_toward(velocity.x, 0.0, hover_speed * 3.0 * delta)
		velocity.y = cos(_t * bob_speed) * bob_height
	if not is_zero_approx(velocity.x):
		sprite.flip_h = velocity.x > 0.0
