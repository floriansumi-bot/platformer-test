extends Control
## High Scores screen. Shows the leaderboard from the Leaderboard autoload (local
## cache, or SilentWolf once configured). Lets the player set the name used for runs.

@onready var list: VBoxContainer = $Center/VBox/List
@onready var status: Label = $Center/VBox/Status
@onready var name_edit: LineEdit = $Center/VBox/NameRow/NameEdit


func _ready() -> void:
	name_edit.text = Leaderboard.player_name
	name_edit.text_changed.connect(func(t): Leaderboard.set_player_name(t))
	$Center/VBox/Back.pressed.connect(func(): SceneTransitioner.change_scene("res://src/ui/main_menu/main_menu.tscn"))
	$Center/VBox/Back.grab_focus()
	Leaderboard.scores_received.connect(_on_scores)
	status.text = "Online leaderboard" if Leaderboard.is_online() else "Local scores"
	Leaderboard.request_scores()


func _on_scores(scores: Array) -> void:
	for c in list.get_children():
		c.queue_free()
	if scores.is_empty():
		var empty := Label.new()
		empty.text = "No runs yet — go play!"
		list.add_child(empty)
		return
	var rank := 1
	for s in scores:
		var row := Label.new()
		row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var pname := str(s.get("player_name", "?")).substr(0, 12)
		row.text = "%d. %s  -  %d" % [rank, pname, int(s.get("score", 0))]
		list.add_child(row)
		rank += 1
