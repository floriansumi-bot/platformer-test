class_name Hitbox
extends Area2D
## Deals damage to any Hurtbox it overlaps. Set `damage` and the collision mask
## (which layers it can hit) in the scene. Emits `hit` for owner-side reactions.

signal hit(hurtbox: Hurtbox)

@export var damage: int = 1


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	if area is Hurtbox:
		(area as Hurtbox).take_hit(damage)
		hit.emit(area)
