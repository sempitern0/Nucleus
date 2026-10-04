extends "res://tests/headless/test_case.gd"


func run() -> Dictionary:
	_test_float_consideration()
	_test_bool_consideration()
	_test_option_multiplication()
	_test_brain_priority_tie_break()
	_test_brain_current_option_bonus()
	_test_repath_policy()
	_test_invalid_navigation_query_fallback()
	return finish()


func _test_float_consideration() -> void:
	var consideration := NucleusAIContextFloatConsideration.new()
	consideration.context_key = &"health"
	consideration.minimum_value = 0.0
	consideration.maximum_value = 100.0

	expect_float(
		consideration.evaluate({&"health": 25.0}),
		0.25,
		"Float consideration should normalize context into [0, 1].",
	)

	consideration.invert = true

	expect_float(
		consideration.evaluate({&"health": 25.0}),
		0.75,
		"Inverted consideration should flip normalized utility.",
	)


func _test_bool_consideration() -> void:
	var consideration := NucleusAIContextBoolConsideration.new()
	consideration.context_key = &"has_target"

	expect_float(
		consideration.evaluate({&"has_target": true}),
		1.0,
		"Boolean consideration should pass the expected value.",
	)
	expect_float(
		consideration.evaluate({&"has_target": false}),
		0.0,
		"Boolean consideration should reject the opposite value.",
	)


func _test_option_multiplication() -> void:
	var gate := NucleusAIContextBoolConsideration.new()
	gate.context_key = &"has_target"

	var distance := NucleusAIContextFloatConsideration.new()
	distance.context_key = &"range_score"

	var option := NucleusAIUtilityOption.new()
	option.option_id = &"attack"
	option.base_score = 0.8
	option.considerations.append(gate)
	option.considerations.append(distance)

	expect_float(
		option.evaluate(
			{
				&"has_target": true,
				&"range_score": 0.5,
			}
		),
		0.4,
		"Utility option should multiply normalized considerations.",
	)


func _test_brain_priority_tie_break() -> void:
	var low := NucleusAIUtilityOption.new()
	low.option_id = &"idle"
	low.base_score = 0.5
	low.priority = 0

	var high := NucleusAIUtilityOption.new()
	high.option_id = &"guard"
	high.base_score = 0.5
	high.priority = 10

	var brain := NucleusAIUtilityBrain.new()
	brain.options.append(low)
	brain.options.append(high)
	brain.current_option_bonus = 0.0

	expect_true(
		brain.evaluate() == high,
		"Equal utility should use priority as deterministic tie-break.",
	)

	brain.free()


func _test_brain_current_option_bonus() -> void:
	var first := NucleusAIUtilityOption.new()
	first.option_id = &"patrol"
	first.base_score = 0.55

	var second := NucleusAIUtilityOption.new()
	second.option_id = &"investigate"
	second.base_score = 0.56

	var brain := NucleusAIUtilityBrain.new()
	brain.options.append(first)
	brain.options.append(second)
	brain.current_option_bonus = 0.02
	brain.current_option = first

	expect_true(
		brain.evaluate() == first,
		"Current-option bonus should reduce decision thrashing near a tie.",
	)

	brain.free()


func _test_repath_policy() -> void:
	expect_true(
		NucleusNavigationPolicy.should_repath(
			0.0,
			1.0,
			0.0,
			0.25,
			false,
		),
		"First target assignment should always request a path.",
	)
	expect_false(
		NucleusNavigationPolicy.should_repath(
			10.0,
			1.0,
			0.1,
			0.25,
			true,
		),
		"Repath interval should throttle moving-target path resets.",
	)
	expect_true(
		NucleusNavigationPolicy.should_repath(
			2.0,
			1.0,
			0.25,
			0.25,
			true,
		),
		"Moved target should repath after interval and distance thresholds.",
	)


func _test_invalid_navigation_query_fallback() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5

	expect_true(
		NucleusNavigationQueries2D.random_point_in_radius(
			RID(),
			Vector2(3.0, 4.0),
			10.0,
			rng,
		).is_equal_approx(
			Vector2(3.0, 4.0)
		),
		"2D query should fail safely without a navigation map.",
	)

	expect_true(
		NucleusNavigationQueries3D.random_point_in_radius(
			RID(),
			Vector3(3.0, 2.0, 4.0),
			10.0,
			rng,
		).is_equal_approx(
			Vector3(3.0, 2.0, 4.0)
		),
		"3D query should fail safely without a navigation map.",
	)
