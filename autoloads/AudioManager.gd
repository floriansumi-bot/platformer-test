extends Node
## Music + SFX playback. Routes music to the Music bus and pooled one-shot SFX to
## the SFX bus, so the (future) options sliders can mix them. The single entry point
## for sound — gameplay calls play_music / play_sfx instead of spawning players.

const SFX_POOL_SIZE := 8

var _music: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _next: int = 0


func _ready() -> void:
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	_music.volume_db = -6.0
	add_child(_music)

	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_pool.append(p)

	_load_volumes()
	# Music is started per-scene (menu + each level) via play_music().


## Play a looping music track. Ignores the call if that track is already playing
## (so reloading/re-entering a level with the same song doesn't restart it).
func play_music(stream: AudioStream) -> void:
	if stream == null or (_music.stream == stream and _music.playing):
		return
	if stream is AudioStreamWAV:
		var w := stream as AudioStreamWAV
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = w.data.size() / 2   # frames (16-bit mono)
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	_music.stream = stream
	_music.play()


## Play a one-shot sound from the pool (grabs a free player, else steals the next).
func play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	if stream == null:
		return
	var player: AudioStreamPlayer = null
	for p in _sfx_pool:
		if not p.playing:
			player = p
			break
	if player == null:
		player = _sfx_pool[_next]
		_next = (_next + 1) % SFX_POOL_SIZE
	player.stream = stream
	player.volume_db = volume_db
	player.play()


## Apply persisted volumes (set in the Options menu) to the audio buses at startup.
func _load_volumes() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://settings.cfg") != OK:
		return
	for bus in ["Master", "Music", "SFX"]:
		var idx := AudioServer.get_bus_index(bus)
		if idx >= 0:
			var linear: float = cfg.get_value("audio", bus.to_lower(), 1.0)
			AudioServer.set_bus_volume_db(idx, linear_to_db(linear))
