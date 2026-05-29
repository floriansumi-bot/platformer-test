extends BossBase
## Boss 5 (finale) — Dark Mage. Keeps its distance and lobs fireball projectiles
## at the player on a timer. The projectile carries its own Hitbox.

const PROJECTILE := preload("res://src/enemies/boss_projectile/boss_projectile.tscn")

@export var fire_interval: float = 1.5
@export var projectile_speed: float = 130.0

var _timer: float = 0.0


func _behaviour(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.x = move_toward(velocity.x, 0.0, 220.0 * delta)
	if player != null:
		sprite.flip_h = dir_to_player() > 0.0
	if active:
		_timer += delta
		if _timer >= fire_interval:
			_timer = 0.0
			_shoot()


func _shoot() -> void:
	if player == null:
		return
	var p := PROJECTILE.instantiate() as BossProjectile
	get_parent().add_child(p)
	p.global_position = global_position + Vector2(0.0, -14.0)
	var aim := (player.global_position - p.global_position).normalized()
	p.setup(aim * projectile_speed)
