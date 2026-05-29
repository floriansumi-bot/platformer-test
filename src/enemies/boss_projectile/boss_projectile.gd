class_name BossProjectile
extends Area2D
## A fireball lobbed by the Dark Mage. Flies straight, damages the player's
## Hurtbox on contact, and frees itself on hit or after `lifetime`.

@export var damage: int = 1
@export var lifetime: float = 3.0

var velocity: Vector2 = Vector2.ZERO


func setup(v: Vector2) -> void:
	velocity = v


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	await get_tree().create_timer(lifetime).timeout
	if is_instance_valid(self):
		queue_free()


func _physics_process(delta: float) -> void:
	position += velocity * delta


func _on_area_entered(area: Area2D) -> void:
	if area is Hurtbox:
		(area as Hurtbox).take_hit(damage)
		queue_free()
