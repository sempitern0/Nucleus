extends "res://tests/headless/test_case.gd"


func run() -> Dictionary:
	_test_profile_defaults()
	_test_snapshot_delta()
	_test_synced_process_time_stays_silent()
	_test_sustained_frame_target_diagnostic()
	_test_pacing_diagnostic()
	_test_render_budget_diagnostic()
	_test_pipeline_compilation_diagnostic()
	_test_disabled_budget_stays_silent()
	return finish()


func _test_profile_defaults() -> void:
	var profile := NucleusPerformanceProfile.new()

	expect_true(
		absf(profile.frame_budget_ms() - 16.6666667) < 0.01,
		"60 FPS profile exposes a 16.67 ms target cadence.",
	)
	expect_true(
		profile.validate().is_empty(),
		"Default performance profile is valid.",
	)
	expect_float(
		profile.fps_warning_ratio,
		0.95,
		"Default FPS warning tolerance leaves room for normal timing noise.",
	)
	expect_equal(
		profile.max_draw_calls,
		0,
		"Game-specific draw-call budgets are disabled by default.",
	)
	expect_equal(
		profile.max_orphan_nodes,
		-1,
		"Orphan-node diagnostics are opt-in by default.",
	)


func _test_snapshot_delta() -> void:
	var previous := NucleusPerformanceSnapshot.new()
	previous.set_metric(NucleusPerformanceMetricIds.PIPELINE_DRAW, 4.0)

	var current := NucleusPerformanceSnapshot.new()
	current.set_metric(NucleusPerformanceMetricIds.PIPELINE_DRAW, 7.0)

	expect_float(
		current.delta_from(
			previous,
			NucleusPerformanceMetricIds.PIPELINE_DRAW,
		),
		3.0,
		"Snapshots expose counter deltas for trend diagnostics.",
	)


func _test_synced_process_time_stays_silent() -> void:
	var profile := NucleusPerformanceProfile.new()
	var history := _frame_history(60.0, 17.0, 4)
	var snapshot := history.back()
	snapshot.set_metric(NucleusPerformanceMetricIds.PROCESS_MS, 18.0)

	var diagnostics := NucleusPerformanceAdvisor.evaluate(
		snapshot,
		null,
		profile,
		true,
		history,
	)

	expect_false(
		_has_code(diagnostics, &"frame_budget_missed"),
		"TIME_PROCESS above 16.67 ms does not create a false critical at 60 FPS.",
	)
	expect_false(
		_has_code(diagnostics, &"frame_budget_headroom"),
		"Synchronized 60 FPS does not create a false frame warning.",
	)


func _test_sustained_frame_target_diagnostic() -> void:
	var profile := NucleusPerformanceProfile.new()
	var history := _frame_history(45.0, 22.0, 4)
	var snapshot := history.back()
	snapshot.set_metric(NucleusPerformanceMetricIds.PROCESS_MS, 18.0)

	var diagnostics := NucleusPerformanceAdvisor.evaluate(
		snapshot,
		null,
		profile,
		true,
		history,
	)

	expect_true(
		_has_code(diagnostics, &"frame_budget_missed"),
		"Advisor reports a sustained critical miss of the FPS target.",
	)


func _test_pacing_diagnostic() -> void:
	var profile := NucleusPerformanceProfile.new()
	var history := _frame_history(60.0, 30.0, 4)
	var snapshot := history.back()

	var diagnostics := NucleusPerformanceAdvisor.evaluate(
		snapshot,
		null,
		profile,
		true,
		history,
	)

	expect_true(
		_has_code(diagnostics, &"frame_pacing_unstable"),
		"Advisor detects repeated high p95 frame intervals.",
	)


func _test_render_budget_diagnostic() -> void:
	var profile := NucleusPerformanceProfile.new()
	profile.max_draw_calls = 100

	var snapshot := NucleusPerformanceSnapshot.new()
	snapshot.set_metric(NucleusPerformanceMetricIds.PROCESS_MS, 4.0)
	snapshot.set_metric(NucleusPerformanceMetricIds.FPS, 60.0)
	snapshot.set_metric(NucleusPerformanceMetricIds.RENDER_DRAW_CALLS, 140.0)

	var diagnostics := NucleusPerformanceAdvisor.evaluate(
		snapshot,
		null,
		profile,
		false,
	)

	expect_true(
		_has_code(diagnostics, &"render_draw_calls"),
		"Advisor reports an enabled draw-call budget violation.",
	)


func _test_pipeline_compilation_diagnostic() -> void:
	var profile := NucleusPerformanceProfile.new()

	var previous := NucleusPerformanceSnapshot.new()
	previous.set_metric(NucleusPerformanceMetricIds.PIPELINE_DRAW, 2.0)
	previous.set_metric(NucleusPerformanceMetricIds.PIPELINE_SURFACE, 8.0)

	var snapshot := NucleusPerformanceSnapshot.new()
	snapshot.set_metric(NucleusPerformanceMetricIds.PROCESS_MS, 4.0)
	snapshot.set_metric(NucleusPerformanceMetricIds.FPS, 60.0)
	snapshot.set_metric(NucleusPerformanceMetricIds.PIPELINE_DRAW, 3.0)
	snapshot.set_metric(NucleusPerformanceMetricIds.PIPELINE_SURFACE, 10.0)

	var diagnostics := NucleusPerformanceAdvisor.evaluate(
		snapshot,
		previous,
		profile,
		true,
	)

	expect_true(
		_has_code(diagnostics, &"runtime_pipeline_compilation"),
		"Advisor detects pipeline compilation after warmup.",
	)


func _test_disabled_budget_stays_silent() -> void:
	var profile := NucleusPerformanceProfile.new()
	profile.max_physics_3d_collision_pairs = 0

	var snapshot := NucleusPerformanceSnapshot.new()
	snapshot.set_metric(NucleusPerformanceMetricIds.PROCESS_MS, 4.0)
	snapshot.set_metric(NucleusPerformanceMetricIds.FPS, 60.0)
	snapshot.set_metric(
		NucleusPerformanceMetricIds.PHYSICS_3D_PAIRS,
		100000.0,
	)

	var diagnostics := NucleusPerformanceAdvisor.evaluate(
		snapshot,
		null,
		profile,
		false,
	)

	expect_false(
		_has_code(diagnostics, &"physics_3d_pairs"),
		"Disabled project-specific budgets do not create false warnings.",
	)


func _frame_history(
	fps: float,
	p95_ms: float,
	count: int,
) -> Array[NucleusPerformanceSnapshot]:
	var history: Array[NucleusPerformanceSnapshot] = []
	for index: int in range(count):
		var snapshot := NucleusPerformanceSnapshot.new()
		snapshot.sequence = index + 1
		snapshot.set_metric(NucleusPerformanceMetricIds.WINDOW_FPS, fps)
		snapshot.set_metric(
			NucleusPerformanceMetricIds.FRAME_INTERVAL_P95_MS,
			p95_ms,
		)
		history.append(snapshot)
	return history


func _has_code(
	diagnostics: Array[NucleusPerformanceDiagnostic],
	code: StringName,
) -> bool:
	for diagnostic: NucleusPerformanceDiagnostic in diagnostics:
		if diagnostic.code == code:
			return true

	return false
