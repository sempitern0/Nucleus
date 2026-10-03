class_name NucleusUIInteractionFeedback
extends Node
## Adds polished hover, focus, press, and optional audio feedback to a Control.
##
## The component is intentionally presentation-only. It never handles the
## control's business action.

@export var target: Control
@export var profile: NucleusUIFeedbackProfile

var _base_scale: Vector2
var _base_alpha: float
var _hovered: bool = false
var _focused: bool = false
var _pressed: bool = false
var _tween: Tween


func _ready() -> void:
	if not _resolve_dependencies():
		return

	if profile == null:
		profile = NucleusUIFeedbackProfile.new()

	if profile.motion == null:
		profile.motion = NucleusUIMotionProfile.new()
		profile.motion.duration = 0.1

	_base_scale = target.scale
	_base_alpha = target.modulate.a

	_update_pivot()

	target.resized.connect(_update_pivot)
	target.mouse_entered.connect(_on_mouse_entered)
	target.mouse_exited.connect(_on_mouse_exited)
	target.focus_entered.connect(_on_focus_entered)
	target.focus_exited.connect(_on_focus_exited)

	if target is BaseButton:
		var button := target as BaseButton
		button.button_down.connect(_on_button_down)
		button.button_up.connect(_on_button_up)


func reset_immediately() -> void:
	_kill_tween()

	_hovered = false
	_focused = false
	_pressed = false

	target.scale = _base_scale
	target.modulate.a = _base_alpha


func _resolve_dependencies() -> bool:
	if target == null:
		target = get_parent() as Control

	if target:
		return true

	NucleusLog.error(
		"%s requires a Control target or parent." % get_path(),
		&"UIFeedback",
	)

	return false


func _refresh_visual_state() -> void:
	_kill_tween()

	var scale_multiplier: float = 1.0
	var alpha: float = profile.idle_alpha

	if _pressed:
		scale_multiplier = profile.pressed_scale
		alpha = profile.pressed_alpha
	elif _focused:
		scale_multiplier = profile.focus_scale
		alpha = profile.active_alpha
	elif _hovered:
		scale_multiplier = profile.hover_scale
		alpha = profile.active_alpha

	if (
		profile.disable_scale_with_reduced_motion
		and NucleusUIMotionPolicy.is_reduced_motion_enabled()
	):
		scale_multiplier = 1.0

	var duration: float = NucleusUIMotion.get_duration(profile.motion)
	_tween = NucleusUIMotion.create_tween(
		target,
		profile.motion,
	).set_parallel(true)

	if profile.use_scale:
		_tween.tween_property(
			target,
			"scale",
			_base_scale * scale_multiplier,
			duration,
		)

	if profile.use_opacity:
		_tween.tween_property(
			target,
			"modulate:a",
			_base_alpha * alpha,
			duration,
		)

	if not profile.use_scale and not profile.use_opacity:
		_tween.tween_interval(0.0)


func _update_pivot() -> void:
	if target:
		NucleusUIMotion.set_pivot_ratio(
			target,
			Vector2(0.5, 0.5),
		)


func _play_cue(cue: NucleusAudioCue) -> void:
	if cue:
		NucleusAudio.play_cue(cue)


func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()

	_tween = null


func _on_mouse_entered() -> void:
	_hovered = true
	_play_cue(profile.hover_cue)
	_refresh_visual_state()


func _on_mouse_exited() -> void:
	_hovered = false
	_refresh_visual_state()


func _on_focus_entered() -> void:
	_focused = true
	_play_cue(profile.focus_cue)
	_refresh_visual_state()


func _on_focus_exited() -> void:
	_focused = false
	_pressed = false
	_refresh_visual_state()


func _on_button_down() -> void:
	_pressed = true
	_play_cue(profile.pressed_cue)
	_refresh_visual_state()


func _on_button_up() -> void:
	_pressed = false
	_refresh_visual_state()
