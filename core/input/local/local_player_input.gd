class_name NucleusLocalPlayerInput
extends RefCounted
## One local player's assigned input device.
##
## Held actions are polled per hardware device. Discrete events are routed by
## [NucleusLocalInputSession] through [signal input_received].

signal input_received(event: InputEvent)
signal device_changed(
	previous_source: int,
	previous_device_id: int,
)

var player_index: int = -1
var source: int = NucleusInputTypes.Source.ANY
var device_id: int = -1
var device_name: String = ""
var device_guid: String = ""
var gamepad_family: int = NucleusInputTypes.GamepadFamily.GENERIC
var connected: bool = false


func _init(
	local_player_index: int,
	input_source: int,
	input_device_id: int,
) -> void:
	player_index = local_player_index
	source = input_source
	device_id = input_device_id
	connected = true

	if source == NucleusInputTypes.Source.GAMEPAD:
		_refresh_gamepad_metadata()


func is_keyboard_mouse() -> bool:
	return source == NucleusInputTypes.Source.KEYBOARD_MOUSE


func is_gamepad() -> bool:
	return source == NucleusInputTypes.Source.GAMEPAD


func is_action_pressed(action: StringName) -> bool:
	if not connected:
		return false

	return NucleusLocalInputReader.is_action_pressed(
		source,
		device_id,
		action,
	)


func get_action_strength(action: StringName) -> float:
	if not connected:
		return 0.0

	return NucleusLocalInputReader.get_action_strength(
		source,
		device_id,
		action,
	)


func get_axis(
	negative_action: StringName,
	positive_action: StringName,
) -> float:
	if not connected:
		return 0.0

	return NucleusLocalInputReader.get_axis(
		source,
		device_id,
		negative_action,
		positive_action,
	)


func get_vector(
	negative_x: StringName,
	positive_x: StringName,
	negative_y: StringName,
	positive_y: StringName,
	deadzone: float = -1.0,
) -> Vector2:
	if not connected:
		return Vector2.ZERO

	return NucleusLocalInputReader.get_vector(
		source,
		device_id,
		negative_x,
		positive_x,
		negative_y,
		positive_y,
		deadzone,
	)


func get_binding_text(
	action: StringName,
	binding_index: int = 0,
) -> String:
	var events: Array[InputEvent] = NucleusInput.get_action_events(
		action,
		source,
	)

	if binding_index < 0 or binding_index >= events.size():
		return ""

	return NucleusInputLabels.event_to_text(
		events[binding_index],
		gamepad_family,
	)


func start_vibration(
	weak_strength: float = 0.5,
	strong_strength: float = 0.5,
	duration: float = 0.65,
) -> Error:
	if not is_gamepad() or not connected:
		return ERR_UNAVAILABLE

	return NucleusInput.start_vibration(
		weak_strength,
		strong_strength,
		duration,
		device_id,
	)


func stop_vibration() -> void:
	if is_gamepad() and connected:
		NucleusInput.stop_vibration(device_id)


func _set_input_device(
	new_source: int,
	new_device_id: int,
) -> bool:
	if new_source not in [
		NucleusInputTypes.Source.KEYBOARD_MOUSE,
		NucleusInputTypes.Source.GAMEPAD,
	]:
		return false

	if (
		new_source == NucleusInputTypes.Source.GAMEPAD
		and new_device_id not in Input.get_connected_joypads()
	):
		return false

	if new_source == NucleusInputTypes.Source.KEYBOARD_MOUSE:
		new_device_id = InputEvent.DEVICE_ID_KEYBOARD

	if source == new_source and device_id == new_device_id and connected:
		return false

	var previous_source: int = source
	var previous_device_id: int = device_id

	if is_gamepad() and connected:
		stop_vibration()

	source = new_source
	device_id = new_device_id
	connected = true

	if is_keyboard_mouse():
		device_name = "Keyboard & Mouse"
		device_guid = ""
		gamepad_family = NucleusInputTypes.GamepadFamily.GENERIC
	else:
		_refresh_gamepad_metadata()

	device_changed.emit(previous_source, previous_device_id)
	return true


func _set_gamepad_device(new_device_id: int) -> void:
	_set_input_device(
		NucleusInputTypes.Source.GAMEPAD,
		new_device_id,
	)


func _mark_disconnected() -> void:
	stop_vibration()
	connected = false
	device_id = -1


func _dispatch_input(event: InputEvent) -> void:
	input_received.emit(event)


func _refresh_gamepad_metadata() -> void:
	if device_id not in Input.get_connected_joypads():
		connected = false
		return

	device_name = Input.get_joy_name(device_id)
	device_guid = Input.get_joy_guid(device_id)
	gamepad_family = NucleusGamepad.detect_family(device_id)
