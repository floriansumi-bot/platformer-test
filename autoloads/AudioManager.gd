extends Node
## Music + SFX playback. Routes music to the Music bus and pooled one-shot SFX to
## the SFX bus, so the (future) options sliders can mix them. The single entry point
## for sound — gameplay calls play_music / play_sfx instead of spawning players.

const MUSIC_PATH := "res://assets/pixelart/medieval tutorial 2d pixelart/music/time_for_adventure.mp3"
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

	# Loop and start the 8-bit background track.
	var track: AudioStream = load(MUSIC_PATH)
	if track is AudioStreamMP3:
		(track as AudioStreamMP3).loop = true
	play_music(track)


func play_music(stream: AudioStream) -> void:
	if stream == null:
		return
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
