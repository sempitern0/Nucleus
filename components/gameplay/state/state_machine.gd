class_name NucleusStateMachine
extends Node
## Scene-owned finite state machine.
##
## States are Nodes below [member state_root]. The machine forwards update and
## input callbacks only to the active state.

signal states_initialized(states: Dictionary)
signal transition_started(
	from_state: NucleusState,
	to_state: NucleusState,
	context: Dictionary,
)
signal state_changed(
	from_state: NucleusState,
	to_state: NucleusState,
	context: Dictionary,
)
signal transition_rejected(
	from_state: NucleusState,
	to_state: NucleusState,
	error: Error,
)

@export var state_root: Node
@export var initial_state: NucleusState
@export var allow_first_state_fallback: bool = true

@export_group("History")
@export_range(0, 128, 1) var history_capacity: int = 8

@export_group("Processing")
@export var active: bool = true

var current_state: NucleusState

var _states: Dictionary[StringName, NucleusState] = {}
var _history: Array[StringName] = []
var _transitioning: bool = false
var _initialized: bool = false


func _ready() -> void:
	if state_root == null:
		state_root = self

	_prepare_states()

	if _states.is_empty():
		NucleusLog.error(
			"%s has no NucleusState children." % get_path(),
			&"StateMachine",
		)
		_set_processing(false)
		return

	if initial_state == null and allow_first_state_fallback:
		initial_state = _states.values()[0]

	if initial_state == null:
		NucleusLog.error(
			"%s requires an initial state." % get_path(),
			&"StateMachine",
		)
		_set_processing(false)
		return

	if initial_state.get_state_id() not in _states:
		NucleusLog.error(
			"Initial state '%s' is not owned by %s."
			% [initial_state.name, get_path()],
			&"StateMachine",
		)
		_set_processing(false)
		return

	_initialized = true
	_set_processing(active)

	var error: Error = _enter_initial_state(initial_state)

	if error != OK:
		NucleusLog.error(
			"Could not enter initial state '%s': %s"
			% [initial_state.get_state_id(), error_string(error)],
			&"StateMachine",
		)

	states_initialized.emit(get_states())


func set_active(enabled: bool) -> void:
	active = enabled

	if _initialized:
		_set_processing(active)


func is_active() -> bool:
	return active and _initialized


func is_transitioning() -> bool:
	return _transitioning


func get_state(
	state_id: StringName,
) -> NucleusState:
	return _states.get(state_id)


func has_state(state_id: StringName) -> bool:
	return _states.has(state_id)


func get_states() -> Dictionary:
	return _states.duplicate()


func get_history() -> Array[StringName]:
	return _history.duplicate()


func get_previous_state_id() -> StringName:
	return _history.back() if not _history.is_empty() else &""


func change_state(
	next_state_id: StringName,
	context: Dictionary = {},
) -> Error:
	if not _initialized or not active:
		return ERR_UNAVAILABLE

	if _transitioning:
		return ERR_BUSY

	if not _states.has(next_state_id):
		return ERR_DOES_NOT_EXIST

	var next_state: NucleusState = _states[next_state_id]

	if next_state == current_state:
		return OK

	var previous_state: NucleusState = current_state
	var safe_context: Dictionary = context.duplicate(true)

	if (
		previous_state
		and not previous_state.can_exit(
			next_state,
			safe_context,
		)
	):
		transition_rejected.emit(
			previous_state,
			next_state,
			ERR_UNAVAILABLE,
		)
		return ERR_UNAVAILABLE

	if not next_state.can_enter(
		previous_state,
		safe_context,
	):
		transition_rejected.emit(
			previous_state,
			next_state,
			ERR_UNAVAILABLE,
		)
		return ERR_UNAVAILABLE

	_transitioning = true

	transition_started.emit(
		previous_state,
		next_state,
		safe_context,
	)

	if previous_state:
		_push_history(previous_state.get_state_id())
		previous_state.exit(next_state)
		previous_state.exited.emit(next_state)

	# Update ownership before enter() so state code observes the new state as
	# current if it queries the machine during its enter hook.
	current_state = next_state

	current_state.enter(
		previous_state,
		safe_context,
	)
	current_state.entered.emit(
		previous_state,
		safe_context,
	)

	_transitioning = false

	state_changed.emit(
		previous_state,
		current_state,
		safe_context,
	)

	return OK


func capture_state() -> Dictionary:
	return {
		"current_state": (
			String(current_state.get_state_id())
			if current_state
			else ""
		),
		"history": _history.duplicate(),
	}


func restore_state(data: Dictionary) -> Error:
	if not _initialized:
		return ERR_UNCONFIGURED

	var state_id := StringName(
		str(data.get("current_state", ""))
	)

	if state_id == &"" or not _states.has(state_id):
		return ERR_DOES_NOT_EXIST

	var restored_history: Array[StringName] = []

	for value: Variant in data.get("history", []):
		var history_id := StringName(str(value))

		if _states.has(history_id):
			restored_history.append(history_id)

	_history = restored_history
	_trim_history()

	if current_state == _states[state_id]:
		return OK

	return change_state(
		state_id,
		{"restored": true},
	)


func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)


func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)


func _input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)


func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_unhandled_input(event)


func _prepare_states() -> void:
	_states.clear()

	for node: Node in NucleusNodeUtils.descendants(
		state_root,
		true,
	):
		if not (node is NucleusState):
			continue

		if _belongs_to_nested_machine(node):
			continue

		var state := node as NucleusState
		var state_id: StringName = state.get_state_id()

		if state_id == &"":
			NucleusLog.error(
				"State %s has an empty state id." % state.get_path(),
				&"StateMachine",
			)
			continue

		if _states.has(state_id):
			NucleusLog.error(
				"Duplicate state id '%s' in %s."
				% [state_id, get_path()],
				&"StateMachine",
			)
			continue

		state.machine = self
		_states[state_id] = state
		state.state_ready()


func _belongs_to_nested_machine(node: Node) -> bool:
	var current: Node = node.get_parent()

	while current and current != state_root:
		if (
			current is NucleusStateMachine
			and current != self
		):
			return true

		current = current.get_parent()

	return false


func _enter_initial_state(state: NucleusState) -> Error:
	if not state.can_enter(null, {}):
		return ERR_UNAVAILABLE

	current_state = state
	current_state.enter(null, {})
	current_state.entered.emit(null, {})

	return OK


func _push_history(state_id: StringName) -> void:
	if history_capacity <= 0:
		return

	_history.append(state_id)
	_trim_history()


func _trim_history() -> void:
	while _history.size() > history_capacity:
		_history.pop_front()


func _set_processing(is_enabled: bool) -> void:
	set_process(is_enabled)
	set_physics_process(is_enabled)
	set_process_input(is_enabled)
	set_process_unhandled_input(is_enabled)
