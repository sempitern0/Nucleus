class_name NucleusAnimationTreeStateBinding
extends Node
## Drives an AnimationTree state machine from NucleusStateMachine transitions.

@export var state_machine: NucleusStateMachine
@export var animation_tree: AnimationTree
@export var playback_parameter: StringName = &"parameters/playback"
@export var mappings: Array[NucleusStateAnimationMapping] = []
@export var use_state_id_as_fallback: bool = true
@export var activate_tree_on_ready: bool = true
@export var reset_on_teleport: bool = true

var _map: Dictionary[StringName, StringName] = {}


func _ready() -> void:
	_resolve_dependencies()
	_build_map()

	if state_machine == null or animation_tree == null:
		NucleusLog.error(
			"%s requires StateMachine and AnimationTree." % get_path(),
			&"AnimationStateBinding",
		)
		return

	if activate_tree_on_ready:
		animation_tree.active = true

	state_machine.state_changed.connect(_on_state_changed)
	state_machine.states_initialized.connect(_on_states_initialized)

	_sync_current()


func _exit_tree() -> void:
	if state_machine == null:
		return

	if state_machine.state_changed.is_connected(_on_state_changed):
		state_machine.state_changed.disconnect(_on_state_changed)

	if state_machine.states_initialized.is_connected(_on_states_initialized):
		state_machine.states_initialized.disconnect(_on_states_initialized)


func refresh_mappings() -> void:
	_build_map()
	_sync_current()


func _sync_current() -> void:
	if state_machine and state_machine.current_state:
		_travel(
			state_machine.current_state.get_state_id()
		)


func _travel(state_id: StringName) -> void:
	if animation_tree == null:
		return

	var animation_state: StringName = _map.get(
		state_id,
		state_id if use_state_id_as_fallback else &"",
	)

	if animation_state == &"":
		return

	var playback: Variant = animation_tree.get(
		playback_parameter
	)

	if not playback is AnimationNodeStateMachinePlayback:
		NucleusLog.error(
			"AnimationTree parameter '%s' is not state-machine playback."
			% playback_parameter,
			&"AnimationStateBinding",
		)
		return

	(playback as AnimationNodeStateMachinePlayback).travel(
		animation_state,
		reset_on_teleport,
	)


func _build_map() -> void:
	_map.clear()

	for mapping: NucleusStateAnimationMapping in mappings:
		if (
			mapping == null
			or mapping.state_id == &""
			or mapping.animation_state == &""
		):
			continue

		_map[mapping.state_id] = mapping.animation_state


func _on_state_changed(
	_from_state: NucleusState,
	to_state: NucleusState,
	_context: Dictionary,
) -> void:
	if to_state:
		_travel(to_state.get_state_id())


func _on_states_initialized(_states: Dictionary) -> void:
	_sync_current()


func _resolve_dependencies() -> void:
	var root: Node = get_parent()

	while root and (state_machine == null or animation_tree == null):
		if state_machine == null and root is NucleusStateMachine:
			state_machine = root as NucleusStateMachine

		if animation_tree == null and root is AnimationTree:
			animation_tree = root as AnimationTree

		for node: Node in NucleusNodeUtils.descendants(root):
			if state_machine == null and node is NucleusStateMachine:
				state_machine = node as NucleusStateMachine

			if animation_tree == null and node is AnimationTree:
				animation_tree = node as AnimationTree

		root = root.get_parent()
