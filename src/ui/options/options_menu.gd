extends Control
## Volume sliders (Master/Music/SFX → audio bus dB) + player name.
## Changes preview live so you can hear them, but are only written to disk on
## Confirm. Cancel restores the audio buses + name to how they were on entry.

const SETTINGS_PATH := "user://settings.cfg"

@onready var master: HSlider = $Center/VBox/Master/Slider
@onready var music: HSlider = $Center/VBox/Music/Slider
@onready var sfx: HSlider = $Center/VBox/SFX/Slider
@onready var name_edit: LineEdit = $Center/VBox/NameRow/NameEdit

# Snapshot of the settings as they were when this screen opened (for Cancel).
var _entry: Dictionary = {}


func _ready() -> void:
	_load()   # set slider positions BEFORE connecting, so loading doesn't re-preview
	_entry = {
		"master": master.value,
		"music": music.value,
		"sfx": sfx.value,
		"name": Leaderboard.player_name,
	}
	# Live preview only — no disk writes until Confirm.
	master.value_changed.connect(func(v): _preview("Master", v))
	music.value_changed.connect(func(v): _preview("Music", v))
	sfx.value_changed.connect(func(v): _preview("SFX", v))
	$Center/VBox/Confirm.pressed.connect(_on_confirm)
	$Center/VBox/Back.pressed.connect(_on_cancel)
	$Center/VBox/Confirm.grab_focus()


## Apply a bus volume immediately so the change is audible, without saving.
func _preview(bus: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(linear))


## Persist the current settings, then return to the menu.
func _on_confirm() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("audio", "master", master.value)
	cfg.set_value("audio", "music", music.value)
	cfg.set_value("audio", "sfx", sfx.value)
	cfg.save(SETTINGS_PATH)
	Leaderboard.set_player_name(name_edit.text)   # persists the name itself
	SceneTransitioner.change_scene("res://src/ui/main_menu/main_menu.tscn")


## Discard changes: restore the buses to the entry snapshot, leave the name
## untouched (it was never committed), and return without saving.
func _on_cancel() -> void:
	_preview("Master", _entry["master"])
	_preview("Music", _entry["music"])
	_preview("SFX", _entry["sfx"])
	SceneTransitioner.change_scene("res://src/ui/main_menu/main_menu.tscn")


func _load() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	master.value = cfg.get_value("audio", "master", 1.0)
	music.value = cfg.get_value("audio", "music", 1.0)
	sfx.value = cfg.get_value("audio", "sfx", 1.0)
	name_edit.text = Leaderboard.player_name
