class_name NucleusSceneFlowService
extends Node
## Cross-scene loading and transition coordination.
##
## Scene Flow owns no gameplay state and no transition visuals. UI can observe
## its signals to display loading screens, fades, progress bars, or animations.

signal transition_started(from_scene: String, to_scene: String)
signal load_progress(scene_path: String, progress: float)
signal transition_completed(scene_path: String, scene: Node)
signal transition_failed(scene_path: String, error: Error)
signal busy_changed(is_busy: bool)

enum State {
	IDLE,
	LOADING,
	SWITCHING,
}

const LOG_CONTEXT: StringName = &"SceneFlow"

var state: State = State.IDLE

var _pending_scene_path: String = ""
var _progress: float = 0.0


func _enter_tree() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)


func _process(_delta: float) -> void:
	if state != State.LOADING or _pending_scene_path.is_empty():
		set_process(false)
		return

	var progress: Array = []
	var status: ResourceLoader.ThreadLoadStatus = (
		ResourceLoader.load_threaded_get_status(
			_pending_scene_path,
			progress,
		)
	)

	if not progress.is_empty():
		_set_progress(float(progress[0]))

	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			return

		ResourceLoader.THREAD_LOAD_LOADED:
			var resource: Resource = ResourceLoader.load_threaded_get(
				_pending_scene_path
			)

			if resource is PackedScene:
				_set_progress(1.0)
				_switch_to_packed_scene(
					resource as PackedScene,
					_pending_scene_path,
				)
			else:
				_fail_transition(ERR_FILE_UNRECOGNIZED)

		ResourceLoader.THREAD_LOAD_FAILED:
			_fail_transition(ERR_FILE_CANT_OPEN)

		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_fail_transition(ERR_FILE_UNRECOGNIZED)


## Changes to a PackedScene resource path.
##
## Background loading is used when thread support is available. On platforms
## without thread support, including threadless Web exports, loading falls back
## to a synchronous ResourceLoader call.
func change_scene(
	scene_path: String,
	background_loading: bool = true,
	use_sub_threads: bool = false,
) -> Error:
	if is_busy():
		return ERR_BUSY

	if not _is_valid_scene_path(scene_path):
		return ERR_INVALID_PARAMETER

	if not ResourceLoader.exists(scene_path):
		return ERR_FILE_NOT_FOUND

	_begin_transition(scene_path)

	if background_loading and NucleusPlatform.supports_threads():
		var request_error: Error = ResourceLoader.load_threaded_request(
			scene_path,
			"PackedScene",
			use_sub_threads,
		)

		if request_error != OK:
			_fail_transition(request_error)
			return request_error

		_set_state(State.LOADING)
		set_process(true)

		return OK

	var resource: Resource = ResourceLoader.load(
		scene_path,
		"PackedScene",
	)

	if not resource is PackedScene:
		_fail_transition(ERR_FILE_UNRECOGNIZED)
		return ERR_FILE_UNRECOGNIZED

	_set_progress(1.0)

	return _switch_to_packed_scene(
		resource as PackedScene,
		scene_path,
	)


## Changes to an already loaded PackedScene.
func change_scene_to_packed(
	scene: PackedScene,
	scene_path: String = "",
) -> Error:
	if is_busy():
		return ERR_BUSY

	if scene == null:
		return ERR_INVALID_PARAMETER

	var resolved_path: String = scene_path

	if resolved_path.is_empty():
		resolved_path = scene.resource_path

	_begin_transition(resolved_path)
	_set_progress(1.0)

	return _switch_to_packed_scene(scene, resolved_path)


## Reloads the current SceneTree scene while preserving Autoload services.
func reload_current_scene() -> Error:
	if is_busy():
		return ERR_BUSY

	var current_path: String = get_current_scene_path()

	_begin_transition(current_path)
	_set_progress(1.0)
	_set_state(State.SWITCHING)
	_connect_scene_changed()

	var error: Error = get_tree().reload_current_scene()

	if error != OK:
		_disconnect_scene_changed()
		_fail_transition(error)

	return error


func is_busy() -> bool:
	return state != State.IDLE


func get_progress() -> float:
	return _progress


func get_current_scene_path() -> String:
	var current_scene: Node = get_tree().current_scene

	if current_scene == null:
		return ""

	return current_scene.scene_file_path


func _begin_transition(scene_path: String) -> void:
	_pending_scene_path = scene_path
	_progress = 0.0

	transition_started.emit(
		get_current_scene_path(),
		_pending_scene_path,
	)
	_set_progress(0.0)


func _switch_to_packed_scene(
	scene: PackedScene,
	scene_path: String,
) -> Error:
	set_process(false)
	_pending_scene_path = scene_path
	_set_state(State.SWITCHING)
	_connect_scene_changed()

	var error: Error = get_tree().change_scene_to_packed(scene)

	if error != OK:
		_disconnect_scene_changed()
		_fail_transition(error)

	return error


func _connect_scene_changed() -> void:
	if get_tree().scene_changed.is_connected(_on_scene_changed):
		return

	get_tree().scene_changed.connect(
		_on_scene_changed,
		CONNECT_ONE_SHOT,
	)


func _disconnect_scene_changed() -> void:
	if get_tree().scene_changed.is_connected(_on_scene_changed):
		get_tree().scene_changed.disconnect(_on_scene_changed)


func _on_scene_changed() -> void:
	var completed_path: String = _pending_scene_path
	var current_scene: Node = get_tree().current_scene

	_pending_scene_path = ""
	_progress = 1.0
	_set_state(State.IDLE)

	transition_completed.emit(completed_path, current_scene)


func _fail_transition(error: Error) -> void:
	var failed_path: String = _pending_scene_path

	set_process(false)
	_pending_scene_path = ""
	_progress = 0.0
	_set_state(State.IDLE)

	NucleusLog.error(
		"Scene transition failed for '%s': %s"
		% [failed_path, error_string(error)],
		LOG_CONTEXT,
	)
	transition_failed.emit(failed_path, error)


func _set_progress(value: float) -> void:
	var normalized_progress: float = clampf(value, 0.0, 1.0)

	if is_equal_approx(normalized_progress, _progress) and value != 0.0:
		return

	_progress = normalized_progress
	load_progress.emit(_pending_scene_path, _progress)


func _set_state(new_state: State) -> void:
	var was_busy: bool = is_busy()

	state = new_state

	var now_busy: bool = is_busy()

	if was_busy != now_busy:
		busy_changed.emit(now_busy)


func _is_valid_scene_path(scene_path: String) -> bool:
	return (
		not scene_path.is_empty()
		and scene_path.begins_with("res://")
	)
