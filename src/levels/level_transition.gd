extends Node
## Drop into a level to make beating its boss advance to the next scene
## (instead of showing the final victory screen). Set `next_scene` in the inspector.

@export_file("*.tscn") var next_scene: String
@export var delay: float = 0.8


func _ready() -> void:
	EventBus.boss_defeated.connect(_on_boss_defeated)


func _on_boss_defeated() -> void:
	await get_tree().create_timer(delay).timeout   # let the boss death animation play
	if not next_scene.is_empty():
		SceneTransitioner.change_scene(next_scene)
