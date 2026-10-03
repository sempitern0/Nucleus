class_name NucleusInputRebindButtonBinding
extends Node
## Turns a regular Button into a runtime input-rebinding control by composition.

signal rebind_started(action: StringName)
signal rebind_finished(action: StringName, event: InputEvent)
signal conflict_detected(
	action: StringName,
	event: InputEvent,
	conflicts: Array[StringName],
)

@export var action: StringName
@export_enum("Keyboard & Mouse:1", "Gamepad:2")
var source: int = NucleusInputTypes.Source.KEYBOARD_MOUSE
@export_range(0, 8, 1, "or_greater") var binding_index: int = 0

@export_group("Behavior")
@export var allow_conflicts: bool = true
@export_range(0.1, 1.0, 0.05)
var joypad_axis_capture_threshold: float = 0.7

@export_group("Presentation")
@export var target: Button
@export var listening_text: String = "Press an input..."
@export var unbound_text: String = "Unbound"

var _listening: bool = false


func _ready() -> void:
	set_process_input(false)

	if target == null:
		target = get_parent() as Button

	if target == null:
		NucleusLog.error(
			"%s requires a Button target or parent." % get_path(),
			&"InputBinding",
		)
		return

	if action == &"":
		NucleusLog.error(
			"%s has no input action assigned." % get_path(),
			&"InputBinding",
		)
		return

	target.pressed.connect(begin_rebind)
	NucleusInput.action_binding_changed.connect(
		_on_action_binding_changed
	)
	NucleusInput.active_gamepad_changed.connect(
		_on_active_gamepad_changed
	)

	_update_text()


func _input(event: InputEvent) -> void:
	if not _listening:
		return

	if not NucleusInputBindingCodec.is_capture_candidate(
		event,
		joypad_axis_capture_threshold,
	):
		return

	var event_source: int = NucleusInputBindingCodec.get_source(event)

	if event_source != source:
		return

	var normalized_event: InputEvent = (
		NucleusInputBindingCodec.normalize(event)
	)

	if normalized_event == null:
		return

	var conflicts: Array[StringName] = NucleusInput.find_conflicts(
		normalized_event,
		action,
	)

	if not conflicts.is_empty() and not allow_conflicts:
		conflict_detected.emit(
			action,
			normalized_event,
			conflicts,
		)
		return

	var error: Error = NucleusInput.set_binding(
		action,
		source,
		binding_index,
		normalized_event,
	)

	if error != OK:
		return

	get_viewport().set_input_as_handled()
	_listening = false
	set_process_input(false)

	_update_text()
	rebind_finished.emit(action, normalized_event)


## Starts listening for a replacement hardware event.
func begin_rebind() -> void:
	if _listening:
		return

	_listening = true
	target.text = listening_text
	set_process_input(true)

	rebind_started.emit(action)


## Cancels an active capture without modifying the binding.
func cancel_rebind() -> void:
	if not _listening:
		return

	_listening = false
	set_process_input(false)
	_update_text()


func _update_text() -> void:
	if target == null:
		return

	var binding_text: String = NucleusInput.get_binding_text(
		action,
		source,
		binding_index,
	)

	target.text = unbound_text if binding_text.is_empty() else binding_text


func _on_action_binding_changed(changed_action: StringName) -> void:
	if changed_action == action and not _listening:
		_update_text()


func _on_active_gamepad_changed(
	_device_id: int,
	_family: int,
) -> void:
	if source == NucleusInputTypes.Source.GAMEPAD and not _listening:
		_update_text()
