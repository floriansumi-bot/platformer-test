extends BossBase
## Boss 1 — King Slime. Sits, then hops toward the player on a timer (ground).

@export var hop_speed: float = 70.0
@export var hop_jump: float = -320.0
@export var hop_interval: float = 1.3

var _timer: float = 0.0


func _behaviour(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.x = move_toward(velocity.x, 0.0, hop_speed * 4.0 * delta)
		if active:
			_timer += delta
			if _timer >= hop_interval:
				_timer = 0.0
				velocity.x = dir_to_player() * hop_speed
				velocity.y = hop_jump
	if not is_zero_approx(velocity.x):
		sprite.flip_h = velocity.x > 0.0
