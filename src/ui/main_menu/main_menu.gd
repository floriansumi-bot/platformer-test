extends Control
## Title screen: Play / Options / High Scores / Quit. The game's first scene.

func _ready() -> void:
	AudioManager.play_music(preload("res://assets/audio/theme1.wav"))
	$Center/VBox/Play.pressed.connect(func(): SceneTransitioner.change_scene("res://src/levels/level_01.tscn"))
	$Center/VBox/Options.pressed.connect(func(): SceneTransitioner.change_scene("res://src/ui/options/options_menu.tscn"))
	$Center/VBox/HighScores.pressed.connect(func(): SceneTransitioner.change_scene("res://src/ui/high_scores/high_scores.tscn"))
	$Center/VBox/Quit.pressed.connect(func(): get_tree().quit())
	$Center/VBox/Play.grab_focus()
