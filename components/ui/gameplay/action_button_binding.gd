class_name NucleusActionButtonBinding
extends Node
## Binds a regular BaseButton to one NucleusGameplayAction.
##
## The Button remains a normal Godot control. This component only coordinates
## availability and execution.

signal execution_finished(
	error: Error,
	action: NucleusGameplayAction,
)

@export var target: BaseButton
@export var gameplay_action: NucleusGameplayAction
@export var context_source: Node
@export var disable_when_unavailable: bool = true


func _ready() -> void:
	if target == null:
		target = get_parent() as BaseButton

	if target == null:
		NucleusLog.error(
			"%s requires a BaseButton." % get_path(),
			&"ActionButton",
		)
		return

	if gameplay_action == null:
		NucleusLog.error(
			"%s requires a NucleusGameplayAction." % get_path(),
			&"ActionButton",
		)
		return

	if context_source == null:
		context_source = target

	target.pressed.connect(_on_pressed)
	gameplay_action.availability_changed.connect(
		_on_availability_changed
	)

	_refresh()


func _exit_tree() -> void:
	if target and target.pressed.is_connected(_on_pressed):
		target.pressed.disconnect(_on_pressed)

	if (
		gameplay_action
		and gameplay_action.availability_changed.is_connected(
			_on_availability_changed
		)
	):
		gameplay_action.availability_changed.disconnect(
			_on_availability_changed
		)


func refresh() -> void:
	_refresh()


func _on_pressed() -> void:
	var context: Dictionary = {
		"source": context_source,
		"ui_source": target,
	}
	var error: Error = gameplay_action.try_execute(
		context
	)

	execution_finished.emit(
		error,
		gameplay_action,
	)

	_refresh()


func _on_availability_changed(
	_available: bool,
) -> void:
	_refresh()


func _refresh() -> void:
	if target == null or gameplay_action == null:
		return

	if disable_when_unavailable:
		target.disabled = not gameplay_action.can_execute()
