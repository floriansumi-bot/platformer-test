extends CanvasLayer
## Pause overlay toggled by the `pause` action. Keeps running while the tree is
## paused (process_mode = ALWAYS) so its buttons stay responsive.

@onready var panel: Control = $Panel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.visible = false
	$Panel/Center/VBox/Resume.pressed.connect(_resume)
	$Panel/Center/VBox/MainMenu.pressed.connect(_to_menu)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if get_tree().paused:
			_resume()
		else:
			_pause()


func _pause() -> void:
	get_tree().paused = true
	panel.visible = true
	$Panel/Center/VBox/Resume.grab_focus()


func _resume() -> void:
	get_tree().paused = false
	panel.visible = false


func _to_menu() -> void:
	get_tree().paused = false
	SceneTransitioner.change_scene("res://src/ui/main_menu/main_menu.tscn")
