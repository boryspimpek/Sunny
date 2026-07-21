extends Node
## Menedżer dźwięków (autoload "AudioManager").
## Pula AudioStreamPlayer3D do odtwarzania SFX w świecie gry.

const POOL_SIZE := 8
const DUPLICATE_INTERVAL_MS := 80

var _players: Array[AudioStreamPlayer3D] = []
var _last_played_ms: Dictionary = {}


func _ready() -> void:
	for i in POOL_SIZE:
		var player := AudioStreamPlayer3D.new()
		add_child(player)
		_players.append(player)
	EventBus.sfx_requested.connect(play_sfx)


func play_sfx(stream: AudioStream, position: Vector3) -> void:
	if stream == null:
		return
	var now := Time.get_ticks_msec()
	if _last_played_ms.has(stream) and now - _last_played_ms[stream] < DUPLICATE_INTERVAL_MS:
		return
	for player in _players:
		if not player.playing:
			player.stream = stream
			player.global_position = position
			player.play()
			_last_played_ms[stream] = now
			return
