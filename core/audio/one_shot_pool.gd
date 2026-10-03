class_name NucleusAudioOneShotPool
extends Node
## Dynamic pool for arbitrary non-positional one-shot sounds.
##
## The pool grows on demand up to [member max_players]. If every player is
## busy at the limit, the oldest playback is recycled.

const LOG_CONTEXT: StringName = &"Audio"

@export_range(1, 128, 1, "or_greater")
var initial_players: int = 8
@export_range(1, 256, 1, "or_greater")
var max_players: int = 32

var _players: Array[AudioStreamPlayer] = []
var _started_at_usec: Dictionary[AudioStreamPlayer, int] = {}


func _ready() -> void:
	max_players = maxi(max_players, initial_players)

	for _index: int in range(initial_players):
		_create_player()


## Plays an arbitrary AudioStream through one pooled player.
func play(
	stream: AudioStream,
	bus: StringName = NucleusAudioBuses.SFX,
	volume_linear: float = 1.0,
	pitch_scale: float = 1.0,
	from_position: float = 0.0,
) -> AudioStreamPlayer:
	if stream == null:
		return null

	var player: AudioStreamPlayer = _acquire_player()

	if player == null:
		return null

	_reset_player(player)

	player.stream = stream
	player.bus = _validated_bus(bus)
	player.volume_linear = maxf(0.0, volume_linear)
	player.pitch_scale = clampf(pitch_scale, 0.01, 4.0)

	_started_at_usec[player] = Time.get_ticks_usec()
	player.play(maxf(0.0, from_position))

	return player


## Plays a reusable cue Resource.
func play_cue(cue: NucleusAudioCue) -> AudioStreamPlayer:
	if cue == null:
		return null

	return play(
		cue.stream,
		cue.bus,
		cue.volume_linear,
		cue.pitch_scale,
		cue.from_position,
	)


## Stops every currently active pooled sound.
func stop_all() -> void:
	for player: AudioStreamPlayer in _players:
		player.stop()
		_reset_player(player)


## Stops pooled sounds routed to one bus.
func stop_bus(bus: StringName) -> void:
	for player: AudioStreamPlayer in _players:
		if player.playing and player.bus == bus:
			player.stop()
			_reset_player(player)


func _create_player() -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = "OneShot%d" % _players.size()
	player.bus = NucleusAudioBuses.SFX
	player.finished.connect(_on_player_finished.bind(player))

	add_child(player)
	_players.append(player)
	_started_at_usec[player] = 0

	return player


func _acquire_player() -> AudioStreamPlayer:
	for player: AudioStreamPlayer in _players:
		if not player.playing:
			return player

	if _players.size() < max_players:
		return _create_player()

	var oldest_player: AudioStreamPlayer
	var oldest_time: int = 9223372036854775807

	for player: AudioStreamPlayer in _players:
		var started_at: int = _started_at_usec.get(player, 0)

		if started_at < oldest_time:
			oldest_time = started_at
			oldest_player = player

	if oldest_player:
		oldest_player.stop()

	return oldest_player


func _reset_player(player: AudioStreamPlayer) -> void:
	player.stream = null
	player.bus = NucleusAudioBuses.SFX
	player.volume_linear = 1.0
	player.pitch_scale = 1.0
	player.stream_paused = false
	_started_at_usec[player] = 0


func _validated_bus(bus: StringName) -> StringName:
	if AudioServer.get_bus_index(bus) != -1:
		return bus

	NucleusLog.warning(
		"Unknown audio bus '%s'; falling back to SFX." % bus,
		LOG_CONTEXT,
	)

	return NucleusAudioBuses.SFX


func _on_player_finished(player: AudioStreamPlayer) -> void:
	_reset_player(player)
