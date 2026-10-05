class_name NucleusPerformanceSampler
extends Node
## Optional scene-owned performance sampling and lightweight trace capture.
##
## Native Godot Performance monitors remain the source of truth. This node adds
## history, target budgets, human-readable diagnostics, and custom game probes.

signal snapshot_sampled(snapshot: NucleusPerformanceSnapshot)
signal diagnostics_updated(
	diagnostics: Array[NucleusPerformanceDiagnostic],
)
signal trace_marked(trace: Dictionary)

const _SECONDS_TO_MS: float = 1000.0
const _NATIVE_MONITORS: Array[Dictionary] = [
	{
		"id": NucleusPerformanceMetricIds.FPS,
		"monitor": Performance.TIME_FPS,
		"scale": 1.0,
	},
	{
		"id": NucleusPerformanceMetricIds.PROCESS_MS,
		"monitor": Performance.TIME_PROCESS,
		"scale": _SECONDS_TO_MS,
	},
	{
		"id": NucleusPerformanceMetricIds.PHYSICS_MS,
		"monitor": Performance.TIME_PHYSICS_PROCESS,
		"scale": _SECONDS_TO_MS,
	},
	{
		"id": NucleusPerformanceMetricIds.NAVIGATION_MS,
		"monitor": Performance.TIME_NAVIGATION_PROCESS,
		"scale": _SECONDS_TO_MS,
	},
	{
		"id": NucleusPerformanceMetricIds.STATIC_MEMORY_BYTES,
		"monitor": Performance.MEMORY_STATIC,
		"scale": 1.0,
	},
	{
		"id": NucleusPerformanceMetricIds.MESSAGE_BUFFER_MAX_BYTES,
		"monitor": Performance.MEMORY_MESSAGE_BUFFER_MAX,
		"scale": 1.0,
	},
	{
		"id": NucleusPerformanceMetricIds.OBJECT_COUNT,
		"monitor": Performance.OBJECT_COUNT,
		"scale": 1.0,
	},
	{
		"id": NucleusPerformanceMetricIds.RESOURCE_COUNT,
		"monitor": Performance.OBJECT_RESOURCE_COUNT,
		"scale": 1.0,
	},
	{
		"id": NucleusPerformanceMetricIds.NODE_COUNT,
		"monitor": Performance.OBJECT_NODE_COUNT,
		"scale": 1.0,
	},
	{
		"id": NucleusPerformanceMetricIds.ORPHAN_NODE_COUNT,
		"monitor": Performance.OBJECT_ORPHAN_NODE_COUNT,
		"scale": 1.0,
	},
	{
		"id": NucleusPerformanceMetricIds.RENDER_OBJECTS,
		"monitor": Performance.RENDER_TOTAL_OBJECTS_IN_FRAME,
		"scale": 1.0,
	},
	{
		"id": NucleusPerformanceMetricIds.RENDER_PRIMITIVES,
		"monitor": Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME,
		"scale": 1.0,
	},
	{
		"id": NucleusPerformanceMetricIds.RENDER_DRAW_CALLS,
		"monitor": Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME,
		"scale": 1.0,
	},
	{
		"id": NucleusPerformanceMetricIds.VIDEO_MEMORY_BYTES,
		"monitor": Performance.RENDER_VIDEO_MEM_USED,
		"scale": 1.0,
	},
	{
		"id": NucleusPerformanceMetricIds.TEXTURE_MEMORY_BYTES,
		"monitor": Performance.RENDER_TEXTURE_MEM_USED,
		"scale": 1.0,
	},
	{
		"id": NucleusPerformanceMetricIds.BUFFER_MEMORY_BYTES,
		"monitor": Performance.RENDER_BUFFER_MEM_USED,
		"scale": 1.0,
	},
	{
		"id": NucleusPerformanceMetricIds.PHYSICS_2D_ACTIVE,
		"monitor": Performance.PHYSICS_2D_ACTIVE_OBJECTS,
		"scale": 1.0,
	},
	{
		"id": NucleusPerformanceMetricIds.PHYSICS_2D_PAIRS,
		"monitor": Performance.PHYSICS_2D_COLLISION_PAIRS,
		"scale": 1.0,
	},
	{
		"id": NucleusPerformanceMetricIds.PHYSICS_2D_ISLANDS,
		"monitor": Performance.PHYSICS_2D_ISLAND_COUNT,
		"scale": 1.0,
	},
	{
		"id": NucleusPerformanceMetricIds.PHYSICS_3D_ACTIVE,
		"monitor": Performance.PHYSICS_3D_ACTIVE_OBJECTS,
		"scale": 1.0,
	},
	{
		"id": NucleusPerformanceMetricIds.PHYSICS_3D_PAIRS,
		"monitor": Performance.PHYSICS_3D_COLLISION_PAIRS,
		"scale": 1.0,
	},
	{
		"id": NucleusPerformanceMetricIds.PHYSICS_3D_ISLANDS,
		"monitor": Performance.PHYSICS_3D_ISLAND_COUNT,
		"scale": 1.0,
	},
	{
		"id": NucleusPerformanceMetricIds.NAVIGATION_2D_REGIONS,
		"monitor": Performance.NAVIGATION_2D_REGION_COUNT,
		"scale": 1.0,
	},
	{
		"id": NucleusPerformanceMetricIds.NAVIGATION_2D_AGENTS,
		"monitor": Performance.NAVIGATION_2D_AGENT_COUNT,
		"scale": 1.0,
	},
	{
		"id": NucleusPerformanceMetricIds.NAVIGATION_2D_OBSTACLES,
		"monitor": Performance.NAVIGATION_2D_OBSTACLE_COUNT,
		"scale": 1.0,
	},
	{
		"id": NucleusPerformanceMetricIds.NAVIGATION_3D_REGIONS,
		"monitor": Performance.NAVIGATION_3D_REGION_COUNT,
		"scale": 1.0,
	},
	{
		"id": NucleusPerformanceMetricIds.NAVIGATION_3D_AGENTS,
		"monitor": Performance.NAVIGATION_3D_AGENT_COUNT,
		"scale": 1.0,
	},
	{
		"id": NucleusPerformanceMetricIds.NAVIGATION_3D_OBSTACLES,
		"monitor": Performance.NAVIGATION_3D_OBSTACLE_COUNT,
		"scale": 1.0,
	},
	{
		"id": NucleusPerformanceMetricIds.PIPELINE_CANVAS,
		"monitor": Performance.PIPELINE_COMPILATIONS_CANVAS,
		"scale": 1.0,
	},
	{
		"id": NucleusPerformanceMetricIds.PIPELINE_MESH,
		"monitor": Performance.PIPELINE_COMPILATIONS_MESH,
		"scale": 1.0,
	},
	{
		"id": NucleusPerformanceMetricIds.PIPELINE_SURFACE,
		"monitor": Performance.PIPELINE_COMPILATIONS_SURFACE,
		"scale": 1.0,
	},
	{
		"id": NucleusPerformanceMetricIds.PIPELINE_DRAW,
		"monitor": Performance.PIPELINE_COMPILATIONS_DRAW,
		"scale": 1.0,
	},
	{
		"id": NucleusPerformanceMetricIds.PIPELINE_SPECIALIZATION,
		"monitor": Performance.PIPELINE_COMPILATIONS_SPECIALIZATION,
		"scale": 1.0,
	},
]

@export_category("Sampling")
@export var start_enabled: bool = true
@export var debug_build_only: bool = true
@export_range(0.1, 10.0, 0.1) var sample_interval_seconds: float = 0.5
@export_range(1, 3600, 1) var history_capacity: int = 120
@export_range(1, 1000, 1) var trace_capacity: int = 128

@export_category("Target")
@export var profile: NucleusPerformanceProfile

@export_category("Diagnostics")
@export var evaluate_diagnostics: bool = true
@export_range(0.0, 30.0, 0.5) var warmup_seconds: float = 3.0

@export_category("Godot Debugger")
@export var publish_summary_monitors: bool = true

var _sampling: bool = false
var _elapsed: float = 0.0
var _started_usec: int = 0
var _sequence: int = 0
var _history: Array[NucleusPerformanceSnapshot] = []
var _traces: Array[Dictionary] = []
var _diagnostic_history: Array[Dictionary] = []
var _custom_probes: Dictionary = {}
var _published_probe_names: Dictionary = {}
var _registered_summary_names: Array[StringName] = []
var _latest_snapshot: NucleusPerformanceSnapshot
var _latest_diagnostics: Array[NucleusPerformanceDiagnostic] = []


func _ready() -> void:
	if profile == null:
		profile = NucleusPerformanceProfile.new()

	if debug_build_only and not OS.is_debug_build():
		set_process(false)
		return

	if publish_summary_monitors:
		_register_summary_monitors()

	if start_enabled:
		start_sampling()
	else:
		set_process(false)


func _exit_tree() -> void:
	_unregister_summary_monitors()

	for id: Variant in _published_probe_names.keys():
		_remove_custom_monitor(_published_probe_names[id])

	_published_probe_names.clear()


func _process(delta: float) -> void:
	if not _sampling:
		return

	_elapsed += delta
	if _elapsed < sample_interval_seconds:
		return

	_elapsed = 0.0
	sample_now()


func start_sampling() -> void:
	if debug_build_only and not OS.is_debug_build():
		return

	_sampling = true
	_elapsed = 0.0
	_started_usec = Time.get_ticks_usec()
	set_process(true)
	sample_now()


func stop_sampling() -> void:
	_sampling = false
	set_process(false)


func is_sampling() -> bool:
	return _sampling


func sample_now() -> NucleusPerformanceSnapshot:
	var previous := _latest_snapshot
	var snapshot := NucleusPerformanceSnapshot.new()
	_sequence += 1
	snapshot.sequence = _sequence
	snapshot.timestamp_usec = Time.get_ticks_usec()

	for entry: Dictionary in _NATIVE_MONITORS:
		var monitor: int = int(entry["monitor"])
		var scale: float = float(entry["scale"])
		var id: StringName = entry["id"]
		snapshot.set_metric(id, Performance.get_monitor(monitor) * scale)

	_sample_custom_probes(snapshot)
	_latest_snapshot = snapshot
	_push_history(snapshot)

	if evaluate_diagnostics:
		var warmup_complete := _warmup_complete()
		_latest_diagnostics = NucleusPerformanceAdvisor.evaluate(
			snapshot,
			previous,
			profile,
			warmup_complete,
		)
	else:
		_latest_diagnostics.clear()

	_record_diagnostics(snapshot)
	snapshot_sampled.emit(snapshot)
	diagnostics_updated.emit(_latest_diagnostics.duplicate())
	return snapshot


func register_probe(
	id: StringName,
	callable: Callable,
	publish_to_debugger: bool = false,
	monitor_type: int = Performance.MONITOR_TYPE_QUANTITY,
) -> Error:
	if id.is_empty() or not callable.is_valid():
		return ERR_INVALID_PARAMETER
	if _custom_probes.has(id):
		return ERR_ALREADY_EXISTS

	_custom_probes[id] = callable

	if publish_to_debugger:
		var monitor_name := _probe_monitor_name(id)
		if Performance.has_custom_monitor(monitor_name):
			_custom_probes.erase(id)
			return ERR_ALREADY_EXISTS

		Performance.add_custom_monitor(
			monitor_name,
			callable,
			[],
			monitor_type,
		)
		_published_probe_names[id] = monitor_name

	return OK


func unregister_probe(id: StringName) -> void:
	_custom_probes.erase(id)

	if not _published_probe_names.has(id):
		return

	_remove_custom_monitor(_published_probe_names[id])
	_published_probe_names.erase(id)


func mark_trace(
	label: StringName,
	metadata: Dictionary = {},
) -> void:
	var trace := {
		"label": str(label),
		"timestamp_usec": Time.get_ticks_usec(),
		"sample_sequence": _sequence,
		"metadata": metadata.duplicate(true),
	}
	_traces.append(trace)

	while _traces.size() > trace_capacity:
		_traces.pop_front()

	trace_marked.emit(trace.duplicate(true))


func get_latest_snapshot() -> NucleusPerformanceSnapshot:
	return _latest_snapshot


func get_latest_diagnostics() -> Array[NucleusPerformanceDiagnostic]:
	return _latest_diagnostics.duplicate()


func get_history() -> Array[NucleusPerformanceSnapshot]:
	return _history.duplicate()


func get_traces() -> Array[Dictionary]:
	return _traces.duplicate(true)


func get_diagnostic_history() -> Array[Dictionary]:
	return _diagnostic_history.duplicate(true)


func clear_history() -> void:
	_history.clear()
	_traces.clear()
	_diagnostic_history.clear()
	_latest_snapshot = null
	_latest_diagnostics.clear()
	_sequence = 0
	_elapsed = 0.0
	_started_usec = Time.get_ticks_usec()


func build_report() -> Dictionary:
	var samples: Array[Dictionary] = []
	for snapshot: NucleusPerformanceSnapshot in _history:
		samples.append(snapshot.to_dictionary())

	var diagnostics: Array[Dictionary] = []
	for diagnostic: NucleusPerformanceDiagnostic in _latest_diagnostics:
		diagnostics.append(diagnostic.to_dictionary())

	return {
		"schema_version": 1,
		"engine": Engine.get_version_info(),
		"os": OS.get_name(),
		"debug_build": OS.is_debug_build(),
		"renderer_method": ProjectSettings.get_setting(
			"rendering/renderer/rendering_method",
			"",
		),
		"profile": profile.to_dictionary() if profile != null else {},
		"samples": samples,
		"traces": get_traces(),
		"diagnostic_events": get_diagnostic_history(),
		"latest_diagnostics": diagnostics,
	}


func save_report(path: String) -> Error:
	if path.is_empty():
		return ERR_INVALID_PARAMETER

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()

	file.store_string(JSON.stringify(build_report(), "\t"))
	return OK


func _record_diagnostics(snapshot: NucleusPerformanceSnapshot) -> void:
	if _latest_diagnostics.is_empty():
		return

	var serialized: Array[Dictionary] = []
	for diagnostic: NucleusPerformanceDiagnostic in _latest_diagnostics:
		serialized.append(diagnostic.to_dictionary())

	_diagnostic_history.append(
		{
			"sample_sequence": snapshot.sequence,
			"timestamp_usec": snapshot.timestamp_usec,
			"diagnostics": serialized,
		}
	)

	while _diagnostic_history.size() > history_capacity:
		_diagnostic_history.pop_front()


func _sample_custom_probes(snapshot: NucleusPerformanceSnapshot) -> void:
	for id: Variant in _custom_probes:
		var callable: Callable = _custom_probes[id]
		if not callable.is_valid():
			continue

		var value: Variant = callable.call()
		if value is int or value is float:
			snapshot.set_metric(id, float(value))


func _push_history(snapshot: NucleusPerformanceSnapshot) -> void:
	_history.append(snapshot)

	while _history.size() > history_capacity:
		_history.pop_front()


func _warmup_complete() -> bool:
	if _started_usec <= 0:
		return true

	var elapsed_seconds := (
		float(Time.get_ticks_usec() - _started_usec)
		/ 1000000.0
	)
	return elapsed_seconds >= warmup_seconds


func _register_summary_monitors() -> void:
	_register_summary_monitor(
		&"Nucleus/FrameBudget",
		Callable(self, "_debugger_frame_budget_ratio"),
		Performance.MONITOR_TYPE_PERCENTAGE,
	)
	_register_summary_monitor(
		&"Nucleus/Warnings",
		Callable(self, "_debugger_warning_count"),
		Performance.MONITOR_TYPE_QUANTITY,
	)
	_register_summary_monitor(
		&"Nucleus/Criticals",
		Callable(self, "_debugger_critical_count"),
		Performance.MONITOR_TYPE_QUANTITY,
	)


func _register_summary_monitor(
	id: StringName,
	callable: Callable,
	monitor_type: int,
) -> void:
	if Performance.has_custom_monitor(id):
		return

	Performance.add_custom_monitor(id, callable, [], monitor_type)
	_registered_summary_names.append(id)


func _unregister_summary_monitors() -> void:
	for id: StringName in _registered_summary_names:
		_remove_custom_monitor(id)

	_registered_summary_names.clear()


func _remove_custom_monitor(id: StringName) -> void:
	if Performance.has_custom_monitor(id):
		Performance.remove_custom_monitor(id)


func _probe_monitor_name(id: StringName) -> StringName:
	return StringName(
		"NucleusGame/%s" % str(id).replace("/", ".")
	)


func _debugger_frame_budget_ratio() -> float:
	if _latest_snapshot == null or profile == null:
		return 0.0

	var budget_ms := profile.frame_budget_ms()
	if budget_ms <= 0.0:
		return 0.0

	return (
		_latest_snapshot.get_metric(NucleusPerformanceMetricIds.PROCESS_MS)
		/ budget_ms
	)


func _debugger_warning_count() -> float:
	var count: int = 0

	for diagnostic: NucleusPerformanceDiagnostic in _latest_diagnostics:
		if diagnostic.severity == NucleusPerformanceDiagnostic.Severity.WARNING:
			count += 1

	return float(count)


func _debugger_critical_count() -> float:
	var count: int = 0

	for diagnostic: NucleusPerformanceDiagnostic in _latest_diagnostics:
		if diagnostic.severity == NucleusPerformanceDiagnostic.Severity.CRITICAL:
			count += 1

	return float(count)
