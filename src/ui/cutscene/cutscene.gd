extends Control
## Between-levels cutscene: the knight delivers a few lines (typewriter reveal),
## then it loads the next level. Advance / skip-reveal with Jump, Enter, or click.

const NEXT_SCENE := "res://src/levels/level_02.tscn"
const CHARS_PER_SEC := 28.0
const LINES := [
	"Came to hell for the climate, stayed for the people.",
]

@onready var text: Label = $Box/Text
@onready var prompt: Label = $Box/Prompt

var _line: int = 0
var _t: float = 0.0


func _ready() -> void:
	_show_line()


func _show_line() -> void:
	text.text = LINES[_line]
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
	var advance := event.is_action_pressed("jump") or event.is_action_pressed("ui_accept")
	advance = advance or (event is InputEventMouseButton and event.pressed)
	if advance:
		_advance()


func _advance() -> void:
	if text.visible_ratio < 1.0:
		text.visible_ratio = 1.0   # reveal the rest instantly
		prompt.visible = true
		return
	_line += 1
	if _line >= LINES.size():
		SceneTransitioner.change_scene(NEXT_SCENE)
	else:
		_show_line()
