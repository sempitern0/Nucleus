class_name NucleusAnimationVelocityBinding3D
extends Node
## Pushes CharacterBody3D locomotion state into AnimationTree parameters.

@export var body: CharacterBody3D
@export var animation_tree: AnimationTree
@export var orientation_source: Node3D

@export_group("Parameters")
@export var speed_parameter: StringName
@export var blend_parameter: StringName
@export var grounded_parameter: StringName
@export var vertical_speed_parameter: StringName
@export var moving_parameter: StringName

@export_group("Values")
@export var use_local_velocity: bool = true
@export var normalize_blend_direction: bool = true
## When > 0, writes direction with speed magnitude normalized to this reference.
## This takes precedence over normalize_blend_direction.
@export_range(0.0, 100000.0, 0.01, "or_greater")
var blend_magnitude_reference: float = 0.0
@export_range(0.0, 100000.0, 0.01, "or_greater")
var moving_threshold: float = 0.05


func _ready() -> void:
	_resolve_dependencies()

	if body == null or animation_tree == null:
		NucleusLog.error(
			"%s requires CharacterBody3D and AnimationTree." % get_path(),
			&"AnimationVelocity3D",
		)
		set_process(false)
		return

	if orientation_source == null:
		orientation_source = body


func _process(_delta: float) -> void:
	var velocity: Vector3 = body.velocity
	var local_velocity: Vector3 = velocity

	if use_local_velocity and orientation_source:
		local_velocity = (
			orientation_source.global_basis.inverse()
			* velocity
		)

	var horizontal := Vector2(
		local_velocity.x,
		-local_velocity.z,
	)
	var speed: float = Vector2(
		velocity.x,
		velocity.z,
	).length()

	if blend_magnitude_reference > 0.0:
		horizontal /= blend_magnitude_reference

		if horizontal.length_squared() > 1.0:
			horizontal = horizontal.normalized()
	elif normalize_blend_direction and not horizontal.is_zero_approx():
		horizontal = horizontal.normalized()

	if speed_parameter != &"":
		animation_tree.set(speed_parameter, speed)

	if blend_parameter != &"":
		animation_tree.set(blend_parameter, horizontal)

	if grounded_parameter != &"":
		animation_tree.set(
			grounded_parameter,
			body.is_on_floor(),
		)

	if vertical_speed_parameter != &"":
		animation_tree.set(
			vertical_speed_parameter,
			velocity.y,
		)

	if moving_parameter != &"":
		animation_tree.set(
			moving_parameter,
			speed > moving_threshold,
		)


func _resolve_dependencies() -> void:
	var root: Node = get_parent()

	while root and (body == null or animation_tree == null):
		if body == null and root is CharacterBody3D:
			body = root as CharacterBody3D

		if animation_tree == null and root is AnimationTree:
			animation_tree = root as AnimationTree

		for node: Node in NucleusNodeUtils.descendants(root):
			if body == null and node is CharacterBody3D:
				body = node as CharacterBody3D

			if animation_tree == null and node is AnimationTree:
				animation_tree = node as AnimationTree

		root = root.get_parent()
