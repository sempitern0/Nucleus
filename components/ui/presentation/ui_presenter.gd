class_name NucleusUIPresenter
extends Node
## Reusable animated show/hide behavior for panels, dialogs, and HUD groups.

signal transition_started(showing: bool)
signal shown
signal hidden

@export var target: Control
@export var motion: NucleusUIMotionProfile

@export_group("Effects")
@export var fade: bool = true
@export var scale: bool = true
@export var hidden_scale: Vector2 = Vector2(0.96, 0.96)

@export_group("Lifecycle")
@export var hide_on_ready: bool = false

var _base_scale: Vector2
var _base_alpha: float
var _base_mouse_filter: Control.MouseFilter
var _tween: Tween


func _ready() -> void:
	if not _resolve_target():
		return

	if motion == null:
		motion = NucleusUIMotionProfile.new()

	_base_scale = target.scale
	_base_alpha = target.modulate.a
	_base_mouse_filter = target.mouse_filter

	_update_pivot()
	target.resized.connect(_update_pivot)

	if hide_on_ready:
		hide_immediately()


func show_animated() -> Tween:
	_kill_tween()

	target.show()
	target.mouse_filter = _base_mouse_filter
	transition_started.emit(true)

	if fade:
		target.modulate.a = 0.0

	if scale:
		target.scale = _base_scale * hidden_scale

	var duration: float = NucleusUIMotion.get_duration(motion)
	_tween = NucleusUIMotion.create_tween(
		target,
		motion,
	).set_parallel(true)

	if fade:
		_tween.tween_property(
			target,
			"modulate:a",
			_base_alpha,
			duration,
		)

	if scale:
		_tween.tween_property(
			target,
			"scale",
			_base_scale,
			duration,
		)

	if not fade and not scale:
		_tween.tween_interval(0.0)

	_tween.finished.connect(
		_on_show_finished,
		CONNECT_ONE_SHOT,
	)

	return _tween


func hide_animated() -> Tween:
	_kill_tween()

	transition_started.emit(false)
	target.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var duration: float = NucleusUIMotion.get_duration(motion)
	_tween = NucleusUIMotion.create_tween(
		target,
		motion,
	).set_parallel(true)

	if fade:
		_tween.tween_property(
			target,
			"modulate:a",
			0.0,
			duration,
		)

	if scale:
		_tween.tween_property(
			target,
			"scale",
			_base_scale * hidden_scale,
			duration,
		)

	if not fade and not scale:
		_tween.tween_interval(0.0)

	_tween.finished.connect(
		_on_hide_finished,
		CONNECT_ONE_SHOT,
	)

	return _tween


func show_immediately() -> void:
	_kill_tween()

	target.show()
	target.mouse_filter = _base_mouse_filter
	target.modulate.a = _base_alpha
	target.scale = _base_scale

	shown.emit()


func hide_immediately() -> void:
	_kill_tween()

	target.hide()
	target.mouse_filter = Control.MOUSE_FILTER_IGNORE
	target.modulate.a = _base_alpha
	target.scale = _base_scale

	hidden.emit()


func _update_pivot() -> void:
	if target:
		NucleusUIMotion.set_pivot_ratio(
			target,
			Vector2(0.5, 0.5),
		)


func _resolve_target() -> bool:
	if target == null:
		target = get_parent() as Control

	if target:
		return true

	NucleusLog.error(
		"%s requires a Control target or parent." % get_path(),
		&"UIPresenter",
	)

	return false


func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()

	_tween = null


func _on_show_finished() -> void:
	_tween = null
	shown.emit()


func _on_hide_finished() -> void:
	_tween = null
	target.hide()
	target.modulate.a = _base_alpha
	target.scale = _base_scale

	hidden.emit()
