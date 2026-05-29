extends BossBase
## Boss 3 — Goblin. Stands still, then dashes fast across the ground toward the
## player for a short burst, then recovers. Telegraphed by the pause before each charge.

@export var charge_speed: float = 230.0
@export var charge_interval: float = 1.8
@export var charge_time: float = 0.55

var _timer: float = 0.0
var _charge_left: float = 0.0
var _face: int = -1


func _behaviour(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
		return
	if _charge_left > 0.0:
		_charge_left -= delta
		velocity.x = float(_face) * charge_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, charge_speed * 6.0 * delta)
		if active:
			_timer += delta
			if _timer >= charge_interval:
				_timer = 0.0
				_charge_left = charge_time
				_face = int(dir_to_player())
				if _face == 0:
					_face = -1
	if not is_zero_approx(velocity.x):
		sprite.flip_h = velocity.x > 0.0
