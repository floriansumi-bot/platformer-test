extends CanvasLayer
## Hearts (top-left) + score/death counters (top-right). Reads GameManager and
## reacts to its signals (no per-frame polling). Re-created with the level on
## respawn, so it shows full hearts, the reset score, and the persisted deaths.

const HEART_FULL := preload("res://assets/textures/heart_full.png")
const HEART_EMPTY := preload("res://assets/textures/heart_empty.png")

@onready var score_label: Label = $Margin/VBox/ScoreLabel
@onready var death_label: Label = $Margin/VBox/DeathLabel
@onready var hearts: HBoxContainer = $Hearts
@onready var powerups: HBoxContainer = $Powerups

var _heart_fills: Array[Control] = []   # per-heart clip controls (width = fill)


func _ready() -> void:
	var gm := get_node(^"/root/GameManager")
	_build_hearts(int(gm.MAX_HEALTH))
	_on_health(gm.health)
	_on_score(gm.score)
	_on_deaths(gm.deaths)
	gm.health_changed.connect(_on_health)
	gm.score_changed.connect(_on_score)
	gm.deaths_changed.connect(_on_deaths)
	EventBus.powerup_started.connect(_on_powerup_started)
	EventBus.powerup_ended.connect(_on_powerup_ended)
	$EquipButton.pressed.connect($Equipment.toggle)


## Show (or restart) a depleting-ring indicator for an active powerup.
func _on_powerup_started(kind: String, duration: float) -> void:
	for c in powerups.get_children():
		if c is PowerupTimer and (c as PowerupTimer).kind == kind:
			(c as PowerupTimer).restart(duration)
			return
	var t := PowerupTimer.new()
	powerups.add_child(t)
	t.setup(kind, duration)


func _on_powerup_ended(kind: String) -> void:
	for c in powerups.get_children():
		if c is PowerupTimer and (c as PowerupTimer).kind == kind:
			c.queue_free()
			return


func _build_hearts(count: int) -> void:
	var sz := HEART_FULL.get_size()
	for i in count:
		# An empty heart with a left-to-right clipped full heart on top, so the
		# fill width can show a fractional heart (e.g. 2/3 after a helmet-soaked hit).
		var cont := Control.new()
		cont.custom_minimum_size = sz
		var empty := TextureRect.new()
		empty.texture = HEART_EMPTY
		cont.add_child(empty)
		var clip := Control.new()
		clip.clip_contents = true
		clip.size = sz
		var full := TextureRect.new()
		full.texture = HEART_FULL
		clip.add_child(full)
		cont.add_child(clip)
		hearts.add_child(cont)
		_heart_fills.append(clip)


func _on_health(h: float) -> void:
	var w := HEART_FULL.get_size().x
	for i in _heart_fills.size():
		var fill := clampf(h - float(i), 0.0, 1.0)
		_heart_fills[i].size.x = w * fill


func _on_score(n: int) -> void:
	score_label.text = "Score: %d" % n


func _on_deaths(n: int) -> void:
	death_label.text = "Deaths: %d" % n
