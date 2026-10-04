class_name NucleusMovementFacing3D
extends Node
## Smoothly faces a unit-scale visual pivot toward motor movement.
##
## Use a dedicated Node3D pivot above imported/scaled art. This keeps model
## import transforms out of locomotion code.

## Prefer a dedicated unit-scale visual pivot, not the CharacterBody itself.
@export var target: Node3D
@export var motor: NucleusCharacterMotor3D
@export_range(0.0, 1000.0, 0.01, "or_greater")
var rotation_response: float = 12.0
@export var use_model_front: bool = false
@export var enabled: bool = true


func _ready() -> void:
	_resolve_dependencies()

	if motor:
		motor.movement_updated.connect(
			_on_movement_updated
		)


func _exit_tree() -> void:
	if (
		motor
		and motor.movement_updated.is_connected(
			_on_movement_updated
		)
	):
		motor.movement_updated.disconnect(
			_on_movement_updated
		)


func _on_movement_updated(
	direction: Vector3,
	_velocity: Vector3,
) -> void:
	if (
		not enabled
		or target == null
		or motor == null
		or motor.body == null
		or direction.is_zero_approx()
	):
		return

	var up: Vector3 = motor.body.up_direction.normalized()

	if up.is_zero_approx():
		up = Vector3.UP

	var target_scale: Vector3 = target.global_basis.get_scale()
	var desired_basis: Basis = Basis.looking_at(
		direction,
		up,
		use_model_front,
	)
	var current_basis: Basis = target.global_basis.orthonormalized()
	var weight: float = NucleusMotionMath.exponential_weight(
		rotation_response,
		get_physics_process_delta_time(),
	)
	var rotated_basis: Basis = current_basis.slerp(
		desired_basis,
		weight,
	)

	target.global_basis = rotated_basis.scaled(target_scale)


func _resolve_dependencies() -> void:
	if motor == null:
		var parent: Node = get_parent()

		if parent:
			for node: Node in NucleusNodeUtils.descendants(parent):
				if node is NucleusCharacterMotor3D:
					motor = node as NucleusCharacterMotor3D
					break

	if motor == null:
		NucleusLog.error(
			"%s requires a NucleusCharacterMotor3D." % get_path(),
			&"MovementFacing3D",
		)

	if target == null:
		NucleusLog.error(
			"%s requires a Node3D target." % get_path(),
			&"MovementFacing3D",
		)
