class_name Hurtbox
extends Area2D
## Receives damage from a Hitbox and reports it to its owner via `hurt`.
## The owner (player/enemy) decides what damage means — never mutate it from here.

signal hurt(amount: int)


## Called by an overlapping Hitbox. Just forwards the amount as a signal.
func take_hit(amount: int) -> void:
	hurt.emit(amount)
