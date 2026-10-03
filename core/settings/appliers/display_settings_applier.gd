class_name NucleusDisplaySettingsApplier
extends Node
## Applies built-in display and rendering settings to Godot runtime APIs.

const LOG_CONTEXT: StringName = &"DisplaySettings"

var _settings: NucleusSettingsService


func _ready() -> void:
	_settings = get_parent() as NucleusSettingsService

	if _settings == null:
		NucleusLog.error(
			"Display settings applier requires NucleusSettingsService as parent.",
			LOG_CONTEXT,
		)
		return

	_settings.setting_changed.connect(_on_setting_changed)
	_settings.settings_loaded.connect(_apply_all)

	if _settings.is_initialized():
		_apply_all()


func _apply_all() -> void:
	_apply_window_mode(
		_settings.get_int(
			NucleusSettingIds.DISPLAY_WINDOW_MODE,
			DisplayServer.WINDOW_MODE_WINDOWED,
		)
	)
	_apply_borderless(
		_settings.get_bool(NucleusSettingIds.DISPLAY_BORDERLESS)
	)
	_apply_vsync(
		_settings.get_int(
			NucleusSettingIds.DISPLAY_VSYNC_MODE,
			DisplayServer.VSYNC_ENABLED,
		)
	)
	_apply_max_fps(
		_settings.get_int(NucleusSettingIds.GRAPHICS_MAX_FPS)
	)
	_apply_msaa_3d(
		_settings.get_int(
			NucleusSettingIds.GRAPHICS_MSAA_3D,
			Viewport.MSAA_DISABLED,
		)
	)


func _on_setting_changed(
	setting_id: StringName,
	value: Variant,
	_previous_value: Variant,
) -> void:
	match setting_id:
		NucleusSettingIds.DISPLAY_WINDOW_MODE:
			_apply_window_mode(value)

		NucleusSettingIds.DISPLAY_BORDERLESS:
			_apply_borderless(value)

		NucleusSettingIds.DISPLAY_VSYNC_MODE:
			_apply_vsync(value)

		NucleusSettingIds.GRAPHICS_MAX_FPS:
			_apply_max_fps(value)

		NucleusSettingIds.GRAPHICS_MSAA_3D:
			_apply_msaa_3d(value)


@warning_ignore("int_as_enum_without_cast")
func _apply_window_mode(value: int) -> void:
	if NucleusPlatform.uses_managed_window_mode():
		return

	DisplayServer.window_set_mode(value)


func _apply_borderless(value: bool) -> void:
	if NucleusPlatform.uses_managed_window_mode():
		return

	DisplayServer.window_set_flag(
		DisplayServer.WINDOW_FLAG_BORDERLESS,
		value,
	)


@warning_ignore("int_as_enum_without_cast")
func _apply_vsync(value: int) -> void:
	DisplayServer.window_set_vsync_mode(value)


func _apply_max_fps(value: int) -> void:
	Engine.max_fps = maxi(0, value)


@warning_ignore("int_as_enum_without_cast")
func _apply_msaa_3d(value: int) -> void:
	get_tree().root.msaa_3d = value
