class_name NucleusCameraFov3D
extends Node
## Smooth target-FOV controller for a Camera3D.
##
## Sprint, aim, vehicle, and cutscene systems may all drive this component
## without camera code depending on those gameplay concepts.

signal target_fov_changed(fov: float)
signal fov_settled(fov: float)

@export var camera: Camera3D
@export_range(1.0, 179.0, 0.1)
var base_fov: float = 75.0
@export_range(0.0, 1000.0, 0.01, "or_greater")
var response: float = 8.0
@export var apply_base_fov_on_ready: bool = true

var target_fov: float = 75.0


func _ready() -> void:
	if camera == null:
		camera = get_parent() as Camera3D

	if camera == null:
		NucleusLog.error(
			"%s requires a Camera3D." % get_path(),
			&"CameraFov3D",
		)
		set_process(false)
		return

	target_fov = clampf(
		base_fov,
		1.0,
		179.0,
	)

	if apply_base_fov_on_ready:
		camera.fov = target_fov


func _process(delta: float) -> void:
	if camera == null:
		return

	if is_equal_approx(camera.fov, target_fov):
		return

	var weight: float = NucleusMotionMath.exponential_weight(
		response,
		delta,
	)
	camera.fov = lerpf(
		camera.fov,
		target_fov,
		weight,
	)

	if absf(camera.fov - target_fov) <= 0.01:
		camera.fov = target_fov
		fov_settled.emit(camera.fov)


func set_target_fov(
	fov: float,
	instant: bool = false,
) -> void:
	target_fov = clampf(
		fov,
		1.0,
		179.0,
	)

	if instant and camera:
		camera.fov = target_fov
		fov_settled.emit(camera.fov)

	target_fov_changed.emit(target_fov)


func reset_fov(instant: bool = false) -> void:
	set_target_fov(
		base_fov,
		instant,
	)
