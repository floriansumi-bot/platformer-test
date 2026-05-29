extends CanvasLayer
## Hearts (top-left) + coin/death counters (top-right). Reads GameManager and
## reacts to its signals (no per-frame polling). Re-created with the level on
## respawn, so it shows full hearts, the reset coins, and the persisted deaths.

const HEART_FULL := preload("res://assets/textures/heart_full.png")
const HEART_EMPTY := preload("res://assets/textures/heart_empty.png")

@onready var coin_label: Label = $Margin/VBox/CoinLabel
@onready var death_label: Label = $Margin/VBox/DeathLabel
@onready var hearts: HBoxContainer = $Hearts

var _icons: Array[TextureRect] = []


func _ready() -> void:
	var gm := get_node(^"/root/GameManager")
	_build_hearts(gm.MAX_HEALTH)
	_on_health(gm.health)
	_on_coins(gm.coins)
	_on_deaths(gm.deaths)
	gm.health_changed.connect(_on_health)
	gm.coins_changed.connect(_on_coins)
	gm.deaths_changed.connect(_on_deaths)


func _build_hearts(count: int) -> void:
	for i in count:
		var tr := TextureRect.new()
		tr.texture = HEART_FULL
		tr.stretch_mode = TextureRect.STRETCH_KEEP
		hearts.add_child(tr)
		_icons.append(tr)


func _on_health(n: int) -> void:
	for i in _icons.size():
		_icons[i].texture = HEART_FULL if i < n else HEART_EMPTY


func _on_coins(n: int) -> void:
	coin_label.text = "Coins: %d" % n


func _on_deaths(n: int) -> void:
	death_label.text = "Deaths: %d" % n
