extends "res://tests/headless/test_case.gd"

var _scheduler_hits: int = 0
var _prewarm_progress_calls: int = 0
var _last_prewarm_total: int = 0


func run() -> Dictionary:
	_test_scheduler_budget_and_skip_catchup()
	_test_scheduler_auto_phase()
	_test_activity_gate_restores_baseline()
	_test_pool_prewarm_progress()
	_test_ai_uses_scheduler()
	return finish()


func _test_scheduler_budget_and_skip_catchup() -> void:
	_scheduler_hits = 0
	var scheduler := NucleusUpdateScheduler.new()
	scheduler.max_callbacks_per_frame = 2
	scheduler.frame_budget_usec = 0

	for _index: int in range(3):
		scheduler.register_task(
			Callable(self, "_on_scheduler_tick"),
			0.1,
			0.0,
		)

	expect_equal(
		scheduler._advance(1.0),
		2,
		"Scheduler caps callback count per frame.",
	)
	expect_equal(
		_scheduler_hits,
		2,
		"Only budgeted scheduler callbacks execute in the first frame.",
	)
	expect_equal(
		scheduler._advance(0.0),
		1,
		"Deferred due work continues on the next scheduler dispatch.",
	)
	expect_equal(
		scheduler._advance(0.0),
		0,
		"Executed tasks do not replay missed intervals as catch-up work.",
	)

	scheduler.free()


func _test_scheduler_auto_phase() -> void:
	_scheduler_hits = 0
	var scheduler := NucleusUpdateScheduler.new()
	scheduler.frame_budget_usec = 0
	scheduler.max_callbacks_per_frame = 8

	scheduler.register_task(
		Callable(self, "_on_scheduler_tick"),
		1.0,
		-1.0,
	)
	scheduler.register_task(
		Callable(self, "_on_scheduler_tick"),
		1.0,
		-1.0,
	)

	scheduler._advance(0.0)
	expect_equal(
		_scheduler_hits,
		1,
		"Automatic phase prevents identical registration times from aligning.",
	)

	scheduler.free()


func _test_activity_gate_restores_baseline() -> void:
	var root := Node.new()
	var target := Node2D.new()
	var gate := NucleusActivityGate.new()

	target.visible = true
	target.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	gate.target = target
	gate.manage_visibility = true

	root.add_child(target)
	root.add_child(gate)

	expect_true(
		attach_test_node(root),
		"Activity-gate fixture requires a live SceneTree.",
	)

	gate.set_active(false)
	expect_false(target.visible, "Inactive gate hides its managed target.")
	expect_equal(
		target.process_mode,
		Node.PROCESS_MODE_DISABLED,
		"Inactive gate disables target processing.",
	)

	gate.set_active(true)
	expect_true(target.visible, "Reactivation restores authored visibility.")
	expect_equal(
		target.process_mode,
		Node.PROCESS_MODE_WHEN_PAUSED,
		"Reactivation restores authored process mode.",
	)

	free_test_node(root)


func _test_pool_prewarm_progress() -> void:
	_prewarm_progress_calls = 0
	_last_prewarm_total = 0

	var template := Node.new()
	var poolable := NucleusPoolable.new()
	poolable.name = "Poolable"
	template.add_child(poolable)
	poolable.owner = template

	var packed := PackedScene.new()
	expect_equal(
		packed.pack(template),
		OK,
		"Pool optimization test can pack a reusable fixture.",
	)
	template.free()

	var pool := NucleusObjectPool.new()
	pool.packed_scene = packed
	pool.auto_prewarm = false
	pool.prewarm_progress.connect(_on_prewarm_progress)

	expect_true(
		attach_test_node(pool),
		"Object-pool fixture requires a live SceneTree.",
	)
	expect_equal(pool.prewarm(3), 3, "Synchronous prewarm behavior is preserved.")
	expect_equal(pool.get_total_count(), 3, "Prewarm creates the requested capacity.")
	expect_equal(
		_prewarm_progress_calls,
		1,
		"Prewarm reports progress through the shared progress signal.",
	)
	expect_equal(
		_last_prewarm_total,
		3,
		"Prewarm progress reports the requested target total.",
	)

	free_test_node(pool)


func _test_ai_uses_scheduler() -> void:
	var root := Node.new()
	var scheduler := NucleusUpdateScheduler.new()
	var brain := NucleusAIUtilityBrain.new()
	var option := NucleusAIUtilityOption.new()

	option.option_id = &"idle"
	option.base_score = 1.0
	brain.options.append(option)
	brain.update_scheduler = scheduler
	brain.evaluation_interval = 1.0
	brain.evaluation_phase = 0.0

	root.add_child(scheduler)
	root.add_child(brain)

	expect_true(
		attach_test_node(root),
		"Scheduled-AI fixture requires a live SceneTree.",
	)
	expect_false(
		brain.is_physics_processing(),
		"Scheduled AI disables its fallback per-physics-frame polling.",
	)

	scheduler._advance(0.0)
	expect_true(
		brain.current_option == option,
		"Scheduler dispatch performs the utility evaluation.",
	)

	free_test_node(root)


func _on_scheduler_tick(_elapsed: float) -> void:
	_scheduler_hits += 1


func _on_prewarm_progress(
	_created_count: int,
	_total_count: int,
	target_total: int,
) -> void:
	_prewarm_progress_calls += 1
	_last_prewarm_total = target_total
