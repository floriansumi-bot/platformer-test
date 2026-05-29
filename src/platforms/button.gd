class_name LevelButton
extends Area2D
## A pressure plate. When the player steps on it, it opens the linked door so the
## path ahead can be passed. One-shot.

@export var door_path: NodePath

@onready var visual: Polygon2D = $Visual

var done: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if done or not (body is Player):
		return
	done = true
	visual.color = Color(0.4, 1.0, 0.5)   # lit
	var door := get_node_or_null(door_path)
	if door != null and door.has_method("open"):
		door.open()
