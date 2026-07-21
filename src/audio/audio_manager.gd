extends Node
## Menedżer dźwięków (autoload "AudioManager").
## Pula AudioStreamPlayer3D do odtwarzania SFX w świecie gry.

const POOL_SIZE := 8

var _players: Array[AudioStreamPlayer3D] = []


func _ready() -> void:
	for i in POOL_SIZE:
		var player := AudioStreamPlayer3D.new()
		add_child(player)
		_players.append(player)
	EventBus.sfx_requested.connect(play_sfx)


func play_sfx(stream: AudioStream, position: Vector3) -> void:
	if stream == null:
		return
	for player in _players:
		if not player.playing:
			player.stream = stream
			player.global_position = position
			player.play()
			return
