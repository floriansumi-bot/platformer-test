extends CanvasLayer
## "YOU WIN!" overlay shown when the boss is defeated (EventBus.boss_defeated).
## Submits the winning run, then pauses the game and offers Retry / Main Menu.

@onready var panel: Control = $Panel
@onready var coins_label: Label = $Panel/Center/VBox/Coins


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.visible = false
	EventBus.boss_defeated.connect(_on_win)
	$Panel/Center/VBox/Retry.pressed.connect(_retry)
	$Panel/Center/VBox/MainMenu.pressed.connect(_to_menu)


func _on_win() -> void:
	Leaderboard.submit_run(GameManager.score)
	await get_tree().create_timer(0.6).timeout   # let the boss death animation play
	coins_label.text = "Score: %d" % GameManager.score
	get_tree().paused = true
	panel.visible = true
	$Panel/Center/VBox/Retry.grab_focus()


func _retry() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _to_menu() -> void:
	get_tree().paused = false
	SceneTransitioner.change_scene("res://src/ui/main_menu/main_menu.tscn")
