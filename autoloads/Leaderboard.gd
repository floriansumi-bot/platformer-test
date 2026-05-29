extends Node
## Leaderboard with a local cache and an optional SilentWolf online backend.
##
## A "run" is one life; its score (coins + kills + level bonuses) is submitted. Runs are
## always cached locally (so the High Scores screen works offline). They are ALSO
## posted to / fetched from SilentWolf once you go online.
##
## ── TO SEE FRIENDS' RUNS (go online) ──────────────────────────────────────
##   1. In Godot: AssetLib → search "SilentWolf" → download → enable the plugin
##      (Project ▸ Project Settings ▸ Plugins). It adds a "SilentWolf" autoload.
##   2. Make a free account at silentwolf.com, create a game, copy its API key + id.
##   3. Paste them into API_KEY / GAME_ID below.
##   Until then everything runs on the local cache — no errors, just solo scores.

signal scores_received(scores: Array)   # Array of { "player_name": String, "score": int }

const API_KEY := ""    # <-- paste your SilentWolf API key here
const GAME_ID := ""    # <-- paste your SilentWolf game id here
const MAX_SCORES := 10
const CACHE_PATH := "user://scores.json"
const SETTINGS_PATH := "user://settings.cfg"

var player_name: String = "Player"
var _cache: Array = []


func _ready() -> void:
	_load_cache()
	_load_name()
	_configure_silentwolf()


func _silentwolf() -> Node:
	return get_node_or_null(^"/root/SilentWolf")


## True when the SilentWolf addon is installed AND credentials are filled in.
func is_online() -> bool:
	return _silentwolf() != null and API_KEY != "" and GAME_ID != ""


func _configure_silentwolf() -> void:
	if is_online():
		_silentwolf().configure({"api_key": API_KEY, "game_id": GAME_ID, "log_level": 0})


## Submit a finished run. Always cached locally; also posted online if configured.
func submit_run(score: int) -> void:
	_cache.append({"player_name": player_name, "score": score})
	_cache.sort_custom(func(a, b): return int(a["score"]) > int(b["score"]))
	if _cache.size() > 50:
		_cache.resize(50)
	_save_cache()
	if is_online():
		_silentwolf().Scores.save_score(player_name, score)


## Request the leaderboard; emits scores_received with an Array of {player_name, score}.
func request_scores() -> void:
	if is_online():
		var sw := _silentwolf()
		sw.Scores.get_scores()
		await sw.Scores.sw_scores_received
		scores_received.emit(sw.Scores.scores)
	else:
		scores_received.emit(_cache.slice(0, MAX_SCORES))


func set_player_name(value: String) -> void:
	player_name = value.strip_edges()
	if player_name.is_empty():
		player_name = "Player"
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("player", "name", player_name)
	cfg.save(SETTINGS_PATH)


func _load_name() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		player_name = cfg.get_value("player", "name", "Player")


func _load_cache() -> void:
	if not FileAccess.file_exists(CACHE_PATH):
		return
	var f := FileAccess.open(CACHE_PATH, FileAccess.READ)
	if f == null:
		return
	var data: Variant = JSON.parse_string(f.get_as_text())
	if data is Array:
		_cache = data


func _save_cache() -> void:
	var f := FileAccess.open(CACHE_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(_cache))
