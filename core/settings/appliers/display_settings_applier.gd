class_name NucleusDisplaySettingsApplier
extends Node
## Applies built-in display and root-viewport settings to Godot runtime APIs.

const LOG_CONTEXT: StringName = &"DisplaySettings"
const EMBEDDED_WINDOW_WARNING: String = (
	"Window changes are unavailable while Godot game embedding is enabled. "
	+ "Disable 'Embed Game on Next Play' to validate this setting."
)

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
	_apply_borderless(_settings.get_bool(NucleusSettingIds.DISPLAY_BORDERLESS))
	_apply_vsync(
		_settings.get_int(
			NucleusSettingIds.DISPLAY_VSYNC_MODE,
			DisplayServer.VSYNC_ENABLED,
		)
	)
	_apply_max_fps(_settings.get_int(NucleusSettingIds.GRAPHICS_MAX_FPS))
	_apply_scaling_3d_mode(
		_settings.get_int(
			NucleusSettingIds.GRAPHICS_SCALING_3D_MODE,
			Viewport.SCALING_3D_MODE_BILINEAR,
		)
	)
	_apply_render_scale(
		_settings.get_float(NucleusSettingIds.GRAPHICS_RENDER_SCALE, 1.0)
	)
	_apply_screen_space_aa(
		_settings.get_int(
			NucleusSettingIds.GRAPHICS_SCREEN_SPACE_AA,
			Viewport.SCREEN_SPACE_AA_DISABLED,
		)
	)
	_apply_taa(_settings.get_bool(NucleusSettingIds.GRAPHICS_TAA_ENABLED))
	_apply_msaa_2d(
		_settings.get_int(
			NucleusSettingIds.GRAPHICS_MSAA_2D,
			Viewport.MSAA_DISABLED,
		)
	)
	_apply_msaa_3d(
		_settings.get_int(
			NucleusSettingIds.GRAPHICS_MSAA_3D,
			Viewport.MSAA_DISABLED,
		)
	)
	_apply_debanding(
		_settings.get_bool(NucleusSettingIds.GRAPHICS_DEBANDING_ENABLED)
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
		NucleusSettingIds.GRAPHICS_SCALING_3D_MODE:
			_apply_scaling_3d_mode(value)
		NucleusSettingIds.GRAPHICS_RENDER_SCALE:
			_apply_render_scale(value)
		NucleusSettingIds.GRAPHICS_SCREEN_SPACE_AA:
			_apply_screen_space_aa(value)
		NucleusSettingIds.GRAPHICS_TAA_ENABLED:
			_apply_taa(value)
		NucleusSettingIds.GRAPHICS_MSAA_2D:
			_apply_msaa_2d(value)
		NucleusSettingIds.GRAPHICS_MSAA_3D:
			_apply_msaa_3d(value)
		NucleusSettingIds.GRAPHICS_DEBANDING_ENABLED:
			_apply_debanding(value)


@warning_ignore("int_as_enum_without_cast")
func _apply_window_mode(value: int) -> void:
	if NucleusPlatform.uses_managed_window_mode():
		return
	if DisplayServer.window_get_mode() == value:
		return
	if Engine.is_embedded_in_editor():
		NucleusLog.warning(EMBEDDED_WINDOW_WARNING, LOG_CONTEXT)
		return
	DisplayServer.window_set_mode(value)


func _apply_borderless(value: bool) -> void:
	if NucleusPlatform.uses_managed_window_mode():
		return
	if DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_BORDERLESS) == value:
		return
	if Engine.is_embedded_in_editor():
		NucleusLog.warning(EMBEDDED_WINDOW_WARNING, LOG_CONTEXT)
		return
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, value)


@warning_ignore("int_as_enum_without_cast")
func _apply_vsync(value: int) -> void:
	DisplayServer.window_set_vsync_mode(value)


func _apply_max_fps(value: int) -> void:
	Engine.max_fps = maxi(0, value)


func _apply_render_scale(value: float) -> void:
	get_tree().root.scaling_3d_scale = clampf(value, 0.25, 2.0)



func _apply_scaling_3d_mode(value: int) -> void:
	@warning_ignore("int_as_enum_without_cast")
	get_tree().root.scaling_3d_mode = value



func _apply_screen_space_aa(value: int) -> void:
	@warning_ignore("int_as_enum_without_cast")
	get_tree().root.screen_space_aa = value


func _apply_taa(value: bool) -> void:
	get_tree().root.use_taa = value



func _apply_msaa_2d(value: int) -> void:
	@warning_ignore("int_as_enum_without_cast")
	get_tree().root.msaa_2d = value


func _apply_msaa_3d(value: int) -> void:
	@warning_ignore("int_as_enum_without_cast")
	get_tree().root.msaa_3d = value


func _apply_debanding(value: bool) -> void:
	get_tree().root.use_debanding = value
