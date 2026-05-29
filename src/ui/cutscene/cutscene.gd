extends Control
## Reusable between-levels cutscene: the knight delivers `lines` (typewriter reveal),
## then loads `next_scene`. Advance / skip-reveal with Jump, Enter, or click.
## Each cutscene_N.tscn inherits this scene and sets its own lines + next_scene.

@export var lines: Array[String] = ["..."]
@export_file("*.tscn") var next_scene: String = ""

const CHARS_PER_SEC := 28.0

@onready var text: Label = $Box/Text
@onready var prompt: Label = $Box/Prompt

var _line: int = 0
var _t: float = 0.0


func _ready() -> void:
	_show_line()


func _show_line() -> void:
	if lines.is_empty():
		_finish()
		return
	text.text = lines[_line]
	text.visible_ratio = 0.0
	_t = 0.0
	prompt.visible = false


func _process(delta: float) -> void:
	if text.visible_ratio < 1.0:
		_t += delta
		text.visible_ratio = minf(1.0, _t * CHARS_PER_SEC / maxf(1.0, float(text.text.length())))
		if text.visible_ratio >= 1.0:
			prompt.visible = true


func _unhandled_input(event: InputEvent) -> void:
	var adv := event.is_action_pressed("jump") or event.is_action_pressed("ui_accept")
	adv = adv or (event is InputEventMouseButton and event.pressed)
	if adv:
		_advance()


func _advance() -> void:
	if text.visible_ratio < 1.0:
		text.visible_ratio = 1.0
		prompt.visible = true
		return
	_line += 1
	if _line >= lines.size():
		_finish()
	else:
		_show_line()


func _finish() -> void:
	if not next_scene.is_empty():
		SceneTransitioner.change_scene(next_scene)
