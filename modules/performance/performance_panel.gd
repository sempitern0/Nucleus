class_name NucleusPerformancePanel
extends PanelContainer
## Optional development HUD for NucleusPerformanceSampler.

@export var sampler_path: NodePath = NodePath("Sampler")
@export var hide_in_release: bool = true
@export_range(1, 12, 1) var max_visible_diagnostics: int = 5

@onready var _target_label: Label = %Target
@onready var _metrics_label: Label = %Metrics
@onready var _diagnostics_label: Label = %Diagnostics
@onready var _hint_label: Label = %Hint

var _sampler: NucleusPerformanceSampler


func _ready() -> void:
	if hide_in_release and not OS.is_debug_build():
		queue_free()
		return

	_sampler = get_node_or_null(sampler_path) as NucleusPerformanceSampler
	if _sampler == null:
		_metrics_label.text = "No NucleusPerformanceSampler found."
		_diagnostics_label.text = "Assign sampler_path or add a Sampler child."
		return

	_sampler.snapshot_sampled.connect(_on_snapshot_sampled)
	_sampler.diagnostics_updated.connect(_on_diagnostics_updated)
	_update_target()
	_update_hint()

	var snapshot := _sampler.get_latest_snapshot()
	if snapshot != null:
		_on_snapshot_sampled(snapshot)
		_on_diagnostics_updated(_sampler.get_latest_diagnostics())


func _update_target() -> void:
	if _sampler.profile == null:
		_target_label.text = "Target: unconfigured"
		return

	_target_label.text = (
		"Target: %s · %d FPS · %.2f ms/frame"
		% [
			_sampler.profile.target_name,
			_sampler.profile.target_fps,
			_sampler.profile.frame_budget_ms(),
		]
	)


func _update_hint() -> void:
	_hint_label.text = (
		"Deep dive: Debugger > Profiler / Network Profiler / Video RAM. "
		+ "Use Nucleus diagnostics to choose where to look, not as a "
		+ "replacement for native profilers."
	)


func _on_snapshot_sampled(snapshot: NucleusPerformanceSnapshot) -> void:
	var fps := snapshot.get_metric(NucleusPerformanceMetricIds.FPS)
	var frame_ms := snapshot.get_metric(NucleusPerformanceMetricIds.PROCESS_MS)
	var physics_ms := snapshot.get_metric(
		NucleusPerformanceMetricIds.PHYSICS_MS
	)
	var navigation_ms := snapshot.get_metric(
		NucleusPerformanceMetricIds.NAVIGATION_MS
	)
	var draw_calls := int(
		snapshot.get_metric(NucleusPerformanceMetricIds.RENDER_DRAW_CALLS)
	)
	var render_objects := int(
		snapshot.get_metric(NucleusPerformanceMetricIds.RENDER_OBJECTS)
	)
	var primitives := int(
		snapshot.get_metric(NucleusPerformanceMetricIds.RENDER_PRIMITIVES)
	)
	var nodes := int(
		snapshot.get_metric(NucleusPerformanceMetricIds.NODE_COUNT)
	)
	var orphans := int(
		snapshot.get_metric(NucleusPerformanceMetricIds.ORPHAN_NODE_COUNT)
	)
	var video_memory := snapshot.get_metric(
		NucleusPerformanceMetricIds.VIDEO_MEMORY_BYTES
	)
	var bodies_3d := int(
		snapshot.get_metric(NucleusPerformanceMetricIds.PHYSICS_3D_ACTIVE)
	)
	var pairs_3d := int(
		snapshot.get_metric(NucleusPerformanceMetricIds.PHYSICS_3D_PAIRS)
	)
	var nav_agents_3d := int(
		snapshot.get_metric(NucleusPerformanceMetricIds.NAVIGATION_3D_AGENTS)
	)

	var lines := PackedStringArray([
		"FPS %.0f · Frame %.2f ms · Physics %.2f ms · Navigation %.2f ms"
			% [fps, frame_ms, physics_ms, navigation_ms],
		"Draws %d · Render objects %d · Primitives %d"
			% [draw_calls, render_objects, primitives],
		"Nodes %d · Orphans %d · VRAM %s"
			% [nodes, orphans, _format_bytes(video_memory)],
		"3D bodies %d · Collision pairs %d · Nav agents %d"
			% [bodies_3d, pairs_3d, nav_agents_3d],
	])
	_metrics_label.text = "\n".join(lines)


func _on_diagnostics_updated(
	diagnostics: Array[NucleusPerformanceDiagnostic],
) -> void:
	if diagnostics.is_empty():
		_diagnostics_label.text = "No current budget violations."
		return

	var lines: PackedStringArray = PackedStringArray()
	var visible_count: int = mini(diagnostics.size(), max_visible_diagnostics)

	for index: int in range(visible_count):
		var diagnostic := diagnostics[index]
		lines.append(
			"[%s] %s" % [diagnostic.severity_name(), diagnostic.title]
		)
		lines.append("  %s" % diagnostic.summary)

		if not diagnostic.suggestions.is_empty():
			lines.append("  Next: %s" % diagnostic.suggestions[0])

	if diagnostics.size() > visible_count:
		lines.append(
			"+ %d more diagnostic(s)"
			% (diagnostics.size() - visible_count)
		)

	_diagnostics_label.text = "\n".join(lines)


func _format_bytes(bytes: float) -> String:
	if bytes >= 1073741824.0:
		return "%.2f GiB" % (bytes / 1073741824.0)
	if bytes >= 1048576.0:
		return "%.1f MiB" % (bytes / 1048576.0)
	if bytes >= 1024.0:
		return "%.1f KiB" % (bytes / 1024.0)

	return "%d B" % int(bytes)
