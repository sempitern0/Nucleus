extends "res://tests/headless/test_case.gd"


func run() -> Dictionary:
	_test_sequence_tracker()
	_test_rate_limiter()
	_test_snapshot_buffer_2d()
	_test_snapshot_buffer_3d()
	return finish()


func _test_sequence_tracker() -> void:
	var tracker := NucleusNetworkSequenceTracker.new()

	expect_true(
		tracker.accept(
			7,
			&"movement",
			1,
		),
		"First positive sequence should be accepted.",
	)
	expect_false(
		tracker.accept(
			7,
			&"movement",
			1,
		),
		"Duplicate sequence should be rejected.",
	)
	expect_false(
		tracker.accept(
			7,
			&"movement",
			0,
		),
		"Older sequence should be rejected.",
	)
	expect_true(
		tracker.accept(
			7,
			&"movement",
			2,
		),
		"Newer sequence should be accepted.",
	)
	expect_true(
		tracker.accept(
			7,
			&"actions",
			1,
		),
		"Independent streams should maintain independent sequences.",
	)


func _test_rate_limiter() -> void:
	var limiter := NucleusNetworkRateLimiter.new()

	expect_true(
		limiter.allow(
			4,
			1000,
			2,
		),
		"First event in a rate window should pass.",
	)
	expect_true(
		limiter.allow(
			4,
			1100,
			2,
		),
		"Events up to the configured limit should pass.",
	)
	expect_false(
		limiter.allow(
			4,
			1200,
			2,
		),
		"Events beyond the configured limit should be rejected.",
	)
	expect_true(
		limiter.allow(
			4,
			2000,
			2,
		),
		"A new time window should reset admission.",
	)


func _test_snapshot_buffer_2d() -> void:
	var buffer := NucleusTransformSnapshotBuffer2D.new()

	expect_true(
		buffer.push(
			1,
			0.0,
			Vector2.ZERO,
			0.0,
		),
		"First 2D transform snapshot should be accepted.",
	)
	expect_true(
		buffer.push(
			2,
			1.0,
			Vector2(10.0, 0.0),
			1.0,
		),
		"Newer 2D transform snapshot should be accepted.",
	)
	expect_false(
		buffer.push(
			2,
			2.0,
			Vector2(20.0, 0.0),
			2.0,
		),
		"Duplicate 2D snapshot sequence should be rejected.",
	)

	var state: Dictionary = buffer.sample(0.5)
	var position: Vector2 = state["position"]

	expect_true(
		position.is_equal_approx(
			Vector2(5.0, 0.0)
		),
		"2D snapshot buffer should interpolate position.",
	)
	expect_float(
		float(state["rotation"]),
		0.5,
		"2D snapshot buffer should interpolate rotation.",
	)


func _test_snapshot_buffer_3d() -> void:
	var buffer := NucleusTransformSnapshotBuffer3D.new()
	var target_rotation := Quaternion(
		Vector3.UP,
		PI * 0.5,
	)

	buffer.push(
		1,
		0.0,
		Vector3.ZERO,
		Quaternion(),
	)
	buffer.push(
		2,
		1.0,
		Vector3(0.0, 0.0, 10.0),
		target_rotation,
	)

	var state: Dictionary = buffer.sample(0.5)
	var position: Vector3 = state["position"]
	var rotation: Quaternion = state["rotation"]

	expect_true(
		position.is_equal_approx(
			Vector3(0.0, 0.0, 5.0)
		),
		"3D snapshot buffer should interpolate position.",
	)
	expect_true(
		is_equal_approx(
			rotation.length(),
			1.0,
		),
		"Interpolated quaternion should remain normalized.",
	)
