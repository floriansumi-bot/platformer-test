extends Control
## Volume sliders (Master/Music/SFX → audio bus dB) + player name. Persists to
## user://settings.cfg; AudioManager applies the saved volumes at startup.

const SETTINGS_PATH := "user://settings.cfg"

@onready var master: HSlider = $Center/VBox/Master/Slider
@onready var music: HSlider = $Center/VBox/Music/Slider
@onready var sfx: HSlider = $Center/VBox/SFX/Slider
@onready var name_edit: LineEdit = $Center/VBox/NameRow/NameEdit


func _ready() -> void:
	_load()   # set slider positions BEFORE connecting, so loading doesn't re-save
	master.value_changed.connect(func(v): _apply("Master", v))
	music.value_changed.connect(func(v): _apply("Music", v))
	sfx.value_changed.connect(func(v): _apply("SFX", v))
	name_edit.text_changed.connect(func(t): Leaderboard.set_player_name(t))
	$Center/VBox/Back.pressed.connect(func(): SceneTransitioner.change_scene("res://src/ui/main_menu/main_menu.tscn"))
	$Center/VBox/Back.grab_focus()


func _apply(bus: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(linear))
	_save()


func _load() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	master.value = cfg.get_value("audio", "master", 1.0)
	music.value = cfg.get_value("audio", "music", 1.0)
	sfx.value = cfg.get_value("audio", "sfx", 1.0)
	name_edit.text = Leaderboard.player_name


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("audio", "master", master.value)
	cfg.set_value("audio", "music", music.value)
	cfg.set_value("audio", "sfx", sfx.value)
	cfg.save(SETTINGS_PATH)
