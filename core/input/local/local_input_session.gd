class_name NucleusLocalInputSession
extends Node
## Optional scene-owned local multiplayer input router.
##
## Add this Node to a game/session scene when couch multiplayer is needed.
## It is deliberately not an Autoload.

signal player_joined(player: NucleusLocalPlayerInput)
signal player_left(player_index: int)
signal player_input(player: NucleusLocalPlayerInput, event: InputEvent)
signal player_device_disconnected(player: NucleusLocalPlayerInput)
signal player_device_reconnected(player: NucleusLocalPlayerInput)
signal join_requested(device_id: int)

@export_range(1, 16, 1, "or_greater")
var max_players: int = 4
@export var reserve_keyboard_mouse_player: bool = true
@export_range(0, 15, 1, "or_greater")
var keyboard_mouse_player_index: int = 0
@export var auto_join_gamepads: bool = true

var _players: Dictionary[int, NucleusLocalPlayerInput] = {}
var _gamepad_to_player: Dictionary[int, int] = {}


func _enter_tree() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	NucleusInput.gamepad_connected.connect(_on_gamepad_connected)
	NucleusInput.gamepad_disconnected.connect(_on_gamepad_disconnected)

	if reserve_keyboard_mouse_player:
		join_keyboard_mouse(keyboard_mouse_player_index)


func _input(event: InputEvent) -> void:
	if event.device == InputEvent.DEVICE_ID_EMULATION:
		return

	if event is InputEventJoypadButton:
		if event.pressed and not _gamepad_to_player.has(event.device):
			if auto_join_gamepads:
				join_gamepad(event.device)
			else:
				join_requested.emit(event.device)

		_route_gamepad_event(event)
		return

	if event is InputEventJoypadMotion:
		_route_gamepad_event(event)
		return

	if (
		event is InputEventKey
		or event is InputEventMouseButton
		or event is InputEventMouseMotion
	):
		_route_keyboard_mouse_event(event)


## Assigns the shared keyboard/mouse seat to one local player slot.
func join_keyboard_mouse(
	preferred_player_index: int = -1,
) -> NucleusLocalPlayerInput:
	for player: NucleusLocalPlayerInput in _players.values():
		if player.is_keyboard_mouse():
			return player

	var player_index: int = _resolve_player_index(preferred_player_index)

	if player_index == -1:
		return null

	var player := NucleusLocalPlayerInput.new(
		player_index,
		NucleusInputTypes.Source.KEYBOARD_MOUSE,
		InputEvent.DEVICE_ID_KEYBOARD,
	)
	player.device_name = "Keyboard & Mouse"

	_players[player_index] = player
	player_joined.emit(player)

	return player


## Assigns one connected gamepad to an available local player slot.
func join_gamepad(
	device_id: int,
	preferred_player_index: int = -1,
) -> NucleusLocalPlayerInput:
	if device_id not in Input.get_connected_joypads():
		return null

	if _gamepad_to_player.has(device_id):
		return get_player(_gamepad_to_player[device_id])

	var player_index: int = _resolve_player_index(preferred_player_index)

	if player_index == -1:
		return null

	var player := NucleusLocalPlayerInput.new(
		player_index,
		NucleusInputTypes.Source.GAMEPAD,
		device_id,
	)

	_players[player_index] = player
	_gamepad_to_player[device_id] = player_index

	player_joined.emit(player)

	return player


func leave_player(player_index: int) -> void:
	var player: NucleusLocalPlayerInput = _players.get(player_index)

	if player == null:
		return

	if player.is_gamepad() and player.device_id != -1:
		_gamepad_to_player.erase(player.device_id)
		player.stop_vibration()

	_players.erase(player_index)
	player_left.emit(player_index)


func clear_players() -> void:
	var player_indices: Array[int] = _players.keys()
	player_indices.sort()

	for player_index: int in player_indices:
		leave_player(player_index)


func get_player(player_index: int) -> NucleusLocalPlayerInput:
	return _players.get(player_index)


func get_players() -> Array[NucleusLocalPlayerInput]:
	var result: Array[NucleusLocalPlayerInput] = []
	var player_indices: Array[int] = _players.keys()
	player_indices.sort()

	for player_index: int in player_indices:
		result.append(_players[player_index])

	return result


func get_connected_players() -> Array[NucleusLocalPlayerInput]:
	return get_players().filter(
		func(player: NucleusLocalPlayerInput) -> bool:
			return player.connected
	)


func has_player(player_index: int) -> bool:
	return _players.has(player_index)


func get_player_for_gamepad(
	device_id: int,
) -> NucleusLocalPlayerInput:
	if not _gamepad_to_player.has(device_id):
		return null

	return get_player(_gamepad_to_player[device_id])


func _resolve_player_index(preferred_player_index: int) -> int:
	if (
		preferred_player_index >= 0
		and preferred_player_index < max_players
		and not _players.has(preferred_player_index)
	):
		return preferred_player_index

	for player_index: int in range(max_players):
		if not _players.has(player_index):
			return player_index

	return -1


func _route_keyboard_mouse_event(event: InputEvent) -> void:
	for player: NucleusLocalPlayerInput in _players.values():
		if player.is_keyboard_mouse() and player.connected:
			player._dispatch_input(event)
			player_input.emit(player, event)
			return


func _route_gamepad_event(event: InputEvent) -> void:
	var player: NucleusLocalPlayerInput = get_player_for_gamepad(
		event.device
	)

	if player == null or not player.connected:
		return

	player._dispatch_input(event)
	player_input.emit(player, event)


func _on_gamepad_disconnected(
	device_id: int,
	_device_name: String,
) -> void:
	var player: NucleusLocalPlayerInput = get_player_for_gamepad(
		device_id
	)

	if player == null:
		return

	_gamepad_to_player.erase(device_id)
	player._mark_disconnected()
	player_device_disconnected.emit(player)


func _on_gamepad_connected(
	device_id: int,
	_device_name: String,
) -> void:
	var guid: String = Input.get_joy_guid(device_id)

	for player: NucleusLocalPlayerInput in _players.values():
		if (
			player.is_gamepad()
			and not player.connected
			and not player.device_guid.is_empty()
			and player.device_guid == guid
		):
			player._set_gamepad_device(device_id)
			_gamepad_to_player[device_id] = player.player_index
			player_device_reconnected.emit(player)
			return
