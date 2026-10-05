extends "res://tests/headless/test_case.gd"


func run() -> Dictionary:
	_test_profile_defaults()
	_test_snapshot_delta()
	_test_frame_budget_diagnostic()
	_test_render_budget_diagnostic()
	_test_pipeline_compilation_diagnostic()
	_test_disabled_budget_stays_silent()
	return finish()


func _test_profile_defaults() -> void:
	var profile := NucleusPerformanceProfile.new()

	expect_true(
		absf(profile.frame_budget_ms() - 16.6666667) < 0.01,
		"60 FPS profile exposes a 16.67 ms frame budget.",
	)
	expect_true(
		profile.validate().is_empty(),
		"Default performance profile is valid.",
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


func _test_frame_budget_diagnostic() -> void:
	var profile := NucleusPerformanceProfile.new()
	profile.target_fps = 60
	profile.frame_warning_ratio = 0.85
	profile.frame_critical_ratio = 1.0

	var snapshot := NucleusPerformanceSnapshot.new()
	snapshot.set_metric(NucleusPerformanceMetricIds.PROCESS_MS, 18.0)
	snapshot.set_metric(NucleusPerformanceMetricIds.FPS, 55.0)

	var diagnostics := NucleusPerformanceAdvisor.evaluate(
		snapshot,
		null,
		profile,
		false,
	)

	expect_true(
		_has_code(diagnostics, &"frame_budget_missed"),
		"Advisor reports a missed configured frame budget.",
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


func _has_code(
	diagnostics: Array[NucleusPerformanceDiagnostic],
	code: StringName,
) -> bool:
	for diagnostic: NucleusPerformanceDiagnostic in diagnostics:
		if diagnostic.code == code:
			return true

	return false
