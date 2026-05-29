extends BossBase
## Boss 4 — Troll. Leaps high toward the player and slams down with heavy gravity.
## Big arcs, hard landings — give it room.

@export var jump_force: float = -470.0
@export var leap_speed: float = 95.0
@export var slam_gravity: float = 1.6
@export var interval: float = 1.7

var _timer: float = 0.0
var _air_vx: float = 0.0


func _behaviour(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * slam_gravity * delta   # heavy slam
		velocity.x = _air_vx
	else:
		velocity.x = move_toward(velocity.x, 0.0, leap_speed * 5.0 * delta)
		_air_vx = 0.0
		if active:
			_timer += delta
			if _timer >= interval:
				_timer = 0.0
				velocity.y = jump_force
				_air_vx = dir_to_player() * leap_speed
				sprite.flip_h = _air_vx > 0.0
