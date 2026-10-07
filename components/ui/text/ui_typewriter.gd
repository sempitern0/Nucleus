class_name NucleusUITypewriter
extends Node
## Reveals a RichTextLabel progressively without owning dialogue or text data.
##
## RichTextLabel remains authoritative for BBCode, shaping and localization.
## Reduced-motion users receive the full text immediately by default.

signal reveal_started(total_characters: int)
signal progress_changed(
	visible_characters: int,
	total_characters: int,
)
signal reveal_finished
signal skipped

const MICROSECONDS_PER_SECOND: float = 1_000_000.0

@export var target: RichTextLabel

@export_group("Reveal")
@export_range(1.0, 1000.0, 1.0, "or_greater")
var characters_per_second: float = 40.0
@export var start_on_ready: bool = false
@export var ignore_time_scale: bool = true

@export_group("Accessibility")
@export var respect_reduced_motion: bool = true
@export var reveal_immediately_with_reduced_motion: bool = true

var _revealing: bool = false
var _visible_float: float = 0.0
var _total_characters: int = 0
var _last_tick_usec: int = 0


func _enter_tree() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)


func _ready() -> void:
	if target == null:
		target = get_parent() as RichTextLabel

	if target == null:
		NucleusLog.error(
			"%s requires a RichTextLabel target or parent." % get_path(),
			&"UITypewriter",
		)
		return

	if start_on_ready:
		call_deferred("restart")


func _process(delta: float) -> void:
	if not _revealing or target == null:
		set_process(false)
		return

	var elapsed := delta

	if ignore_time_scale:
		var now := Time.get_ticks_usec()
		elapsed = float(now - _last_tick_usec) / MICROSECONDS_PER_SECOND
		_last_tick_usec = now

	_visible_float += characters_per_second * maxf(0.0, elapsed)

	var visible := mini(
		_total_characters,
		floori(_visible_float),
	)

	if visible != target.visible_characters:
		target.visible_characters = visible
		progress_changed.emit(visible, _total_characters)

	if visible >= _total_characters:
		_finish_reveal(false)


func restart() -> Error:
	if target == null:
		return ERR_UNCONFIGURED

	_total_characters = target.get_total_character_count()
	_visible_float = 0.0
	target.visible_characters = 0
	reveal_started.emit(_total_characters)

	if _total_characters <= 0:
		_finish_reveal(false)
		return OK

	if (
		respect_reduced_motion
		and reveal_immediately_with_reduced_motion
		and NucleusMotionPolicy.is_reduced_motion_enabled()
	):
		_finish_reveal(false)
		return OK

	_revealing = true
	_last_tick_usec = Time.get_ticks_usec()
	set_process(true)
	progress_changed.emit(0, _total_characters)
	return OK


func skip() -> void:
	if target == null or not _revealing:
		return

	_finish_reveal(true)


func reveal_immediately() -> Error:
	if target == null:
		return ERR_UNCONFIGURED

	_total_characters = target.get_total_character_count()
	_finish_reveal(false)
	return OK


func reset() -> Error:
	if target == null:
		return ERR_UNCONFIGURED

	_revealing = false
	set_process(false)
	_total_characters = target.get_total_character_count()
	_visible_float = 0.0
	target.visible_characters = 0
	progress_changed.emit(0, _total_characters)
	return OK


func is_revealing() -> bool:
	return _revealing


func get_progress() -> float:
	if _total_characters <= 0 or target == null:
		return 1.0

	return clampf(
		float(maxi(0, target.visible_characters))
		/ float(_total_characters),
		0.0,
		1.0,
	)


func _finish_reveal(was_skipped: bool) -> void:
	_revealing = false
	set_process(false)

	if target:
		target.visible_characters = _total_characters

	_visible_float = float(_total_characters)
	progress_changed.emit(
		_total_characters,
		_total_characters,
	)

	if was_skipped:
		skipped.emit()

	reveal_finished.emit()
