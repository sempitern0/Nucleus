class_name NucleusUIMotionPolicy
extends RefCounted
## Resolves UI animation and flash accessibility preferences.
##
## Project preferences are combined with the operating-system accessibility
## preference when Godot can report it.


static func is_reduced_motion_enabled() -> bool:
	if DisplayServer.accessibility_should_reduce_animation() == 1:
		return true

	if not NucleusSettings.is_initialized():
		return false

	return NucleusSettings.get_bool(
		NucleusSettingIds.ACCESSIBILITY_REDUCED_MOTION,
		false,
	)


static func get_motion_scale() -> float:
	if not NucleusSettings.is_initialized():
		return 1.0

	return clampf(
		NucleusSettings.get_float(
			NucleusSettingIds.ACCESSIBILITY_UI_MOTION_SCALE,
			1.0,
		),
		0.0,
		2.0,
	)


static func get_effective_duration(
	duration: float,
	respect_reduced_motion: bool = true,
) -> float:
	var safe_duration: float = maxf(0.0, duration)

	if not respect_reduced_motion:
		return safe_duration

	if is_reduced_motion_enabled():
		return 0.0

	return safe_duration * get_motion_scale()


static func get_screen_flash_intensity() -> float:
	if DisplayServer.accessibility_should_reduce_animation() == 1:
		return 0.0

	if not NucleusSettings.is_initialized():
		return 1.0

	return clampf(
		NucleusSettings.get_float(
			NucleusSettingIds.ACCESSIBILITY_SCREEN_FLASH_INTENSITY,
			1.0,
		),
		0.0,
		1.0,
	)
