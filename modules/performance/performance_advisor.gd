class_name NucleusPerformanceAdvisor
extends RefCounted
## Converts sampled native metrics into bounded, evidence-backed suggestions.


static func evaluate(
	snapshot: NucleusPerformanceSnapshot,
	previous: NucleusPerformanceSnapshot,
	profile: NucleusPerformanceProfile,
	warmup_complete: bool,
) -> Array[NucleusPerformanceDiagnostic]:
	var diagnostics: Array[NucleusPerformanceDiagnostic] = []

	if snapshot == null or profile == null:
		return diagnostics

	_evaluate_frame(snapshot, profile, diagnostics)
	_evaluate_cpu_subsystems(snapshot, profile, diagnostics)
	_evaluate_rendering(snapshot, profile, diagnostics)
	_evaluate_scene_memory(snapshot, profile, diagnostics)
	_evaluate_physics(snapshot, profile, diagnostics)
	_evaluate_navigation(snapshot, profile, diagnostics)

	if warmup_complete:
		_evaluate_pipeline_compilation(
			snapshot,
			previous,
			profile,
			diagnostics,
		)

	return diagnostics


static func _evaluate_frame(
	snapshot: NucleusPerformanceSnapshot,
	profile: NucleusPerformanceProfile,
	out: Array[NucleusPerformanceDiagnostic],
) -> void:
	var frame_ms := snapshot.get_metric(NucleusPerformanceMetricIds.PROCESS_MS)
	var frame_budget_ms := profile.frame_budget_ms()
	var ratio := frame_ms / frame_budget_ms

	if ratio >= profile.frame_critical_ratio:
		out.append(
			NucleusPerformanceDiagnostic.build(
				NucleusPerformanceDiagnostic.Severity.CRITICAL,
				&"frame_budget_missed",
				"Frame budget missed",
				"The sampled frame time is above the configured target.",
				PackedStringArray([
					"Frame: %.2f ms" % frame_ms,
					"Target: %.2f ms (%d FPS)"
						% [frame_budget_ms, profile.target_fps],
				]),
				PackedStringArray([
					"Open Godot Debugger > Profiler and capture the same workload.",
					"Separate script/physics cost from rendering before optimizing.",
					"Re-test after every change; do not optimize from intuition alone.",
				]),
			)
		)
	elif ratio >= profile.frame_warning_ratio:
		out.append(
			NucleusPerformanceDiagnostic.build(
				NucleusPerformanceDiagnostic.Severity.WARNING,
				&"frame_budget_headroom",
				"Frame budget has little headroom",
				"The current workload is close to the configured frame budget.",
				PackedStringArray([
					"Frame: %.2f ms" % frame_ms,
					"Budget usage: %.0f%%" % (ratio * 100.0),
				]),
				PackedStringArray([
					"Capture a representative Profiler trace before adding features.",
					"Keep headroom for spikes, background work, and slower hardware.",
				]),
			)
		)

	var fps := snapshot.get_metric(NucleusPerformanceMetricIds.FPS)
	if fps <= 0.0 or fps >= float(profile.target_fps) * 0.9:
		return
	if ratio >= profile.frame_warning_ratio:
		return

	out.append(
		NucleusPerformanceDiagnostic.build(
			NucleusPerformanceDiagnostic.Severity.WARNING,
			&"fps_below_target_non_cpu",
			"FPS is below target without an obvious CPU frame overrun",
			"The sampled CPU/frame monitor still has headroom.",
			PackedStringArray([
				"FPS: %.0f / %d target" % [fps, profile.target_fps],
				"Frame: %.2f ms" % frame_ms,
			]),
			PackedStringArray([
				"Check VSync, FPS caps, window focus, and test conditions first.",
				"Inspect draw calls, primitives, VRAM, and the Video RAM panel.",
				"Use GPU/vendor profilers when the bottleneck remains GPU-bound.",
			]),
		)
	)


static func _evaluate_cpu_subsystems(
	snapshot: NucleusPerformanceSnapshot,
	profile: NucleusPerformanceProfile,
	out: Array[NucleusPerformanceDiagnostic],
) -> void:
	var physics_ms := snapshot.get_metric(NucleusPerformanceMetricIds.PHYSICS_MS)
	if profile.max_physics_ms > 0.0 and physics_ms > profile.max_physics_ms:
		out.append(
			NucleusPerformanceDiagnostic.build(
				NucleusPerformanceDiagnostic.Severity.WARNING,
				&"physics_time_budget",
				"Physics time exceeds its configured budget",
				"Physics is consuming more CPU time than this target allows.",
				PackedStringArray([
					"Physics: %.2f ms" % physics_ms,
					"Budget: %.2f ms" % profile.max_physics_ms,
				]),
				PackedStringArray([
					"Inspect active bodies and collision-pair growth.",
					"Prefer simple collision shapes and useful sleep behavior.",
					"Audit collision layers/masks before reducing physics quality.",
				]),
			)
		)

	var navigation_ms := snapshot.get_metric(
		NucleusPerformanceMetricIds.NAVIGATION_MS
	)
	if (
		profile.max_navigation_ms > 0.0
		and navigation_ms > profile.max_navigation_ms
	):
		out.append(
			NucleusPerformanceDiagnostic.build(
				NucleusPerformanceDiagnostic.Severity.WARNING,
				&"navigation_time_budget",
				"Navigation time exceeds its configured budget",
				"Navigation map updates or avoidance are using too much CPU time.",
				PackedStringArray([
					"Navigation: %.2f ms" % navigation_ms,
					"Budget: %.2f ms" % profile.max_navigation_ms,
				]),
				PackedStringArray([
					"Inspect active avoidance agents and path-request frequency.",
					"Do not request paths every frame unless the game requires it.",
					"Reduce avoidance participation before replacing NavigationServer.",
				]),
			)
		)


static func _evaluate_rendering(
	snapshot: NucleusPerformanceSnapshot,
	profile: NucleusPerformanceProfile,
	out: Array[NucleusPerformanceDiagnostic],
) -> void:
	_append_maximum_diagnostic(
		out,
		snapshot,
		NucleusPerformanceMetricIds.RENDER_DRAW_CALLS,
		float(profile.max_draw_calls),
		&"render_draw_calls",
		"Draw-call budget exceeded",
		"Draw calls",
		PackedStringArray([
			"Look for many unique materials or individually rendered repeated meshes.",
			"Consider MultiMesh, material sharing, visibility ranges, and LOD.",
			"Confirm the renderer is the bottleneck before restructuring scenes.",
		]),
	)
	_append_maximum_diagnostic(
		out,
		snapshot,
		NucleusPerformanceMetricIds.RENDER_OBJECTS,
		float(profile.max_render_objects),
		&"render_objects",
		"Rendered-object budget exceeded",
		"Rendered objects",
		PackedStringArray([
			"Inspect visibility ranges, frustum/occlusion behavior, and scene density.",
			"Batch repeated presentation only where it preserves gameplay ownership.",
		]),
	)
	_append_maximum_diagnostic(
		out,
		snapshot,
		NucleusPerformanceMetricIds.RENDER_PRIMITIVES,
		float(profile.max_primitives),
		&"render_primitives",
		"Primitive budget exceeded",
		"Rendered primitives",
		PackedStringArray([
			"Inspect mesh LOD and geometry that remains visible at long distance.",
			"Remember shadows/depth passes can multiply primitive work.",
		]),
	)

	var video_mb := _bytes_to_mb(
		snapshot.get_metric(NucleusPerformanceMetricIds.VIDEO_MEMORY_BYTES)
	)
	if (
		profile.max_video_memory_mb > 0.0
		and video_mb > profile.max_video_memory_mb
	):
		out.append(
			NucleusPerformanceDiagnostic.build(
				NucleusPerformanceDiagnostic.Severity.WARNING,
				&"video_memory",
				"Video-memory budget exceeded",
				"GPU resource memory is above the configured target.",
				PackedStringArray([
					"Video memory: %.1f MiB" % video_mb,
					"Budget: %.1f MiB" % profile.max_video_memory_mb,
				]),
				PackedStringArray([
					"Open Debugger > Video RAM and sort resources by memory.",
					"Review texture resolution/compression and oversized render targets.",
				]),
			)
		)


static func _evaluate_scene_memory(
	snapshot: NucleusPerformanceSnapshot,
	profile: NucleusPerformanceProfile,
	out: Array[NucleusPerformanceDiagnostic],
) -> void:
	var static_mb := _bytes_to_mb(
		snapshot.get_metric(NucleusPerformanceMetricIds.STATIC_MEMORY_BYTES)
	)
	if (
		profile.max_static_memory_mb > 0.0
		and static_mb > profile.max_static_memory_mb
	):
		out.append(
			NucleusPerformanceDiagnostic.build(
				NucleusPerformanceDiagnostic.Severity.WARNING,
				&"static_memory",
				"Static-memory budget exceeded",
				"Debug memory usage is above the configured target.",
				PackedStringArray([
					"Static memory: %.1f MiB" % static_mb,
					"Budget: %.1f MiB" % profile.max_static_memory_mb,
				]),
				PackedStringArray([
					"Compare resource/node counts before and after scene transitions.",
					"Look for retained resources and long-lived caches before trimming data.",
				]),
			)
		)

	_append_maximum_diagnostic(
		out,
		snapshot,
		NucleusPerformanceMetricIds.NODE_COUNT,
		float(profile.max_node_count),
		&"node_count",
		"Node-count budget exceeded",
		"Nodes",
		PackedStringArray([
			"Check whether repeated objects need pooling or a server-oriented path.",
			"Prefer measuring scene churn before flattening healthy scene structure.",
		]),
	)

	if profile.max_orphan_nodes < 0:
		return

	var orphan_count := int(
		snapshot.get_metric(NucleusPerformanceMetricIds.ORPHAN_NODE_COUNT)
	)
	if orphan_count <= profile.max_orphan_nodes:
		return

	out.append(
		NucleusPerformanceDiagnostic.build(
			NucleusPerformanceDiagnostic.Severity.WARNING,
			&"orphan_nodes",
			"Unexpected orphan nodes detected",
			"Debug mode reports more orphan nodes than the profile allows.",
			PackedStringArray([
				"Orphans: %d" % orphan_count,
				"Allowed: %d" % profile.max_orphan_nodes,
			]),
			PackedStringArray([
				"Audit node lifetime around scene replacement and deferred frees.",
				"Confirm intentional detached nodes before treating this as a leak.",
			]),
		)
	)


static func _evaluate_physics(
	snapshot: NucleusPerformanceSnapshot,
	profile: NucleusPerformanceProfile,
	out: Array[NucleusPerformanceDiagnostic],
) -> void:
	_append_maximum_diagnostic(
		out,
		snapshot,
		NucleusPerformanceMetricIds.PHYSICS_2D_ACTIVE,
		float(profile.max_physics_2d_active_objects),
		&"physics_2d_active",
		"2D active-body budget exceeded",
		"Active 2D physics objects",
		PackedStringArray([
			"Allow bodies to sleep and disable simulation outside useful scope.",
			"Pool short-lived bodies when churn is the actual bottleneck.",
		]),
	)
	_append_maximum_diagnostic(
		out,
		snapshot,
		NucleusPerformanceMetricIds.PHYSICS_2D_PAIRS,
		float(profile.max_physics_2d_collision_pairs),
		&"physics_2d_pairs",
		"2D collision-pair budget exceeded",
		"2D collision pairs",
		PackedStringArray([
			"Audit collision layers and masks for unnecessary pair generation.",
			"Reduce overlapping monitoring Areas that do not need continuous checks.",
		]),
	)
	_append_maximum_diagnostic(
		out,
		snapshot,
		NucleusPerformanceMetricIds.PHYSICS_3D_ACTIVE,
		float(profile.max_physics_3d_active_objects),
		&"physics_3d_active",
		"3D active-body budget exceeded",
		"Active 3D physics objects",
		PackedStringArray([
			"Allow bodies to sleep and avoid waking distant simulation needlessly.",
			"Prefer StaticBody3D for geometry that never needs rigid-body simulation.",
		]),
	)
	_append_maximum_diagnostic(
		out,
		snapshot,
		NucleusPerformanceMetricIds.PHYSICS_3D_PAIRS,
		float(profile.max_physics_3d_collision_pairs),
		&"physics_3d_pairs",
		"3D collision-pair budget exceeded",
		"3D collision pairs",
		PackedStringArray([
			"Audit collision layers/masks before lowering physics tick rate.",
			"Use simple collision geometry where detailed concavity is unnecessary.",
		]),
	)


static func _evaluate_navigation(
	snapshot: NucleusPerformanceSnapshot,
	profile: NucleusPerformanceProfile,
	out: Array[NucleusPerformanceDiagnostic],
) -> void:
	_append_maximum_diagnostic(
		out,
		snapshot,
		NucleusPerformanceMetricIds.NAVIGATION_2D_AGENTS,
		float(profile.max_navigation_2d_agents),
		&"navigation_2d_agents",
		"2D navigation-agent budget exceeded",
		"2D avoidance agents",
		PackedStringArray([
			"Only enable avoidance for agents that need local avoidance right now.",
			"Separate path following from avoidance participation.",
		]),
	)
	_append_maximum_diagnostic(
		out,
		snapshot,
		NucleusPerformanceMetricIds.NAVIGATION_3D_AGENTS,
		float(profile.max_navigation_3d_agents),
		&"navigation_3d_agents",
		"3D navigation-agent budget exceeded",
		"3D avoidance agents",
		PackedStringArray([
			"Only enable avoidance for agents that need local avoidance right now.",
			"Throttle game-owned path requests before replacing native navigation.",
		]),
	)


static func _evaluate_pipeline_compilation(
	snapshot: NucleusPerformanceSnapshot,
	previous: NucleusPerformanceSnapshot,
	profile: NucleusPerformanceProfile,
	out: Array[NucleusPerformanceDiagnostic],
) -> void:
	if not profile.warn_on_runtime_pipeline_compilation or previous == null:
		return

	var draw_delta := snapshot.delta_from(
		previous,
		NucleusPerformanceMetricIds.PIPELINE_DRAW,
	)
	var surface_delta := snapshot.delta_from(
		previous,
		NucleusPerformanceMetricIds.PIPELINE_SURFACE,
	)

	if draw_delta <= 0.0 and surface_delta <= 0.0:
		return

	out.append(
		NucleusPerformanceDiagnostic.build(
			NucleusPerformanceDiagnostic.Severity.WARNING,
			&"runtime_pipeline_compilation",
			"Rendering pipelines compiled during the measured workload",
			"First-use shader/material variants may be contributing to stutter.",
			PackedStringArray([
				"Draw compilations: +%d" % int(draw_delta),
				"Surface compilations: +%d" % int(surface_delta),
			]),
			PackedStringArray([
				"Reproduce the spike after a clean run and identify first-use content.",
				"Consider loading/warming representative materials before gameplay.",
				"Use Godot's pipeline-compilation guidance before adding custom caches.",
			]),
		)
	)


static func _append_maximum_diagnostic(
	out: Array[NucleusPerformanceDiagnostic],
	snapshot: NucleusPerformanceSnapshot,
	metric_id: StringName,
	maximum: float,
	code: StringName,
	title: String,
	label: String,
	suggestions: PackedStringArray,
) -> void:
	if maximum <= 0.0:
		return

	var value := snapshot.get_metric(metric_id)
	if value <= maximum:
		return

	out.append(
		NucleusPerformanceDiagnostic.build(
			NucleusPerformanceDiagnostic.Severity.WARNING,
			code,
			title,
			"%s is above the configured profile limit." % label,
			PackedStringArray([
				"%s: %d" % [label, int(value)],
				"Budget: %d" % int(maximum),
			]),
			suggestions,
		)
	)


static func _bytes_to_mb(value: float) -> float:
	return value / 1048576.0
