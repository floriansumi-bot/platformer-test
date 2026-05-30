extends Control
## Title screen: Play / Options / High Scores / Quit. The game's first scene.
## A looping vignette plays behind the menu: the knight charges a big slime,
## slashes it, and it squishes into goo — then resets and does it again.

@onready var knight: AnimatedSprite2D = $Knight
@onready var slime: AnimatedSprite2D = $Slime

var _knight_home: Vector2
var _slime_home: Vector2


func _ready() -> void:
	AudioManager.play_music(preload("res://assets/audio/theme1.wav"))
	# Play runs the intro story cards first, which then load level 1. Death sends
	# the player to the previous level (never back through the intro).
	$Center/VBox/Play.pressed.connect(func(): GameManager.new_game(); SceneTransitioner.change_scene("res://src/ui/cutscene/cutscene_intro.tscn"))
	$Center/VBox/Options.pressed.connect(func(): SceneTransitioner.change_scene("res://src/ui/options/options_menu.tscn"))
	$Center/VBox/HighScores.pressed.connect(func(): SceneTransitioner.change_scene("res://src/ui/high_scores/high_scores.tscn"))
	$Center/VBox/Quit.pressed.connect(func(): get_tree().quit())
	$Center/VBox/Play.grab_focus()

	_knight_home = knight.position
	_slime_home = slime.position
	_play_vignette()


## Loops forever: reset → charge → slash → slime dies → pause → repeat.
func _play_vignette() -> void:
	while is_inside_tree():
		# Reset the scene.
		knight.position = _knight_home
		knight.flip_h = false
		knight.play("idle")
		slime.position = _slime_home
		slime.scale = Vector2(2.8, 2.8)
		slime.modulate = Color.WHITE
		slime.visible = true
		slime.play("walk")
		await get_tree().create_timer(1.1).timeout

		# Charge the slime.
		knight.play("run")
		var charge := create_tween()
		charge.tween_property(knight, "position", slime.position - Vector2(34, 0), 0.45).set_trans(Tween.TRANS_QUAD)
		await charge.finished

		# Slash + the slime recoils.
		_spawn_slash()
		slime.play("hit")
		slime.modulate = Color(1.0, 0.5, 0.5)
		knight.play("idle")
		await get_tree().create_timer(0.18).timeout

		# Slime squishes flat into goo and fades.
		var death := create_tween()
		death.tween_property(slime, "scale", Vector2(3.4, 0.5), 0.14).set_trans(Tween.TRANS_BACK)
		death.parallel().tween_property(slime, "position:y", _slime_home.y + 14.0, 0.14)
		death.tween_property(slime, "modulate:a", 0.0, 0.4)
		await death.finished

		await get_tree().create_timer(0.9).timeout
		# Knight strides back to his mark.
		knight.flip_h = true
		knight.play("run")
		var back := create_tween()
		back.tween_property(knight, "position", _knight_home, 0.5)
		await back.finished
		await get_tree().create_timer(0.5).timeout


## A white crescent slash arc in front of the knight that sweeps and fades.
func _spawn_slash() -> void:
	var n := Node2D.new()
	n.position = knight.position + Vector2(34.0, -6.0)
	add_child(n)
	var poly := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 9:
		var a: float = lerpf(-1.0, 1.0, i / 8.0)
		pts.append(Vector2(cos(a), sin(a)) * 30.0)
	for i in 9:
		var a: float = lerpf(1.0, -1.0, i / 8.0)
		pts.append(Vector2(cos(a), sin(a)) * 19.0)
	poly.polygon = pts
	poly.color = Color(0.95, 0.98, 1.0, 0.95)
	n.add_child(poly)
	n.rotation = -0.8
	var t := create_tween()
	t.tween_property(n, "rotation", 0.8, 0.18).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(poly, "modulate:a", 0.0, 0.22)
	t.tween_callback(n.queue_free)
