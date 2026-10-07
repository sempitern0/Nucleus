extends "res://tests/headless/test_case.gd"


func run() -> Dictionary:
	_test_transition_profile_builders()
	_test_presenter_immediate_compatibility()
	_test_visual_state_math()
	_test_progress_feedback_immediate()
	_test_interaction_selected_state()
	return finish()


func _test_transition_profile_builders() -> void:
	var fade := NucleusUITransitionProfile.fade_only(0.3)
	expect_true(fade.fade, "Fade transition keeps opacity animation enabled.")
	expect_false(fade.use_scale, "Fade-only transition disables scale.")
	expect_float(
		fade.get_motion().duration,
		0.3,
		"Fade builder preserves the requested duration.",
	)

	var slide := NucleusUITransitionProfile.slide(
		Vector2(24.0, -8.0),
		0.2,
		false,
	)
	expect_true(slide.use_offset, "Slide transition enables positional offset.")
	expect_false(slide.fade, "Slide builder can disable opacity animation.")
	expect_equal(
		slide.get_hidden_position(Vector2(10.0, 20.0)),
		Vector2(34.0, 12.0),
		"Slide hidden position is relative to authored position.",
	)

	var pop := NucleusUITransitionProfile.pop(
		0.15,
		Vector2(0.9, 0.8),
	)
	var hidden_scale := pop.get_hidden_scale(Vector2(2.0, 3.0))
	expect_float(
		hidden_scale.x,
		1.8,
		"Pop hidden X scale is relative to authored scale.",
	)
	expect_float(
		hidden_scale.y,
		2.4,
		"Pop hidden Y scale is relative to authored scale.",
	)
	expect_equal(
		pop.get_hidden_scale(Vector2(2.0, 3.0), 0.0),
		Vector2(2.0, 3.0),
		"Zero motion amplitude removes nonessential scale displacement.",
	)


func _test_presenter_immediate_compatibility() -> void:
	var root := Control.new()
	var panel := Control.new()
	var presenter := NucleusUIPresenter.new()

	panel.scale = Vector2(1.5, 1.25)
	panel.modulate.a = 0.8
	panel.position = Vector2(12.0, 18.0)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	presenter.target = panel
	presenter.transition = NucleusUITransitionProfile.slide(
		Vector2(0.0, 24.0)
	)

	root.add_child(panel)
	root.add_child(presenter)

	expect_true(
		attach_test_node(root),
		"Presenter fixture requires a live SceneTree.",
	)

	presenter.hide_immediately()
	expect_false(panel.visible, "Immediate hide hides the target.")
	expect_equal(
		panel.scale,
		Vector2(1.5, 1.25),
		"Immediate hide restores authored scale.",
	)

	presenter.show_immediately()
	expect_true(panel.visible, "Immediate show restores visibility.")
	expect_equal(
		panel.mouse_filter,
		Control.MOUSE_FILTER_STOP,
		"Immediate show restores authored mouse filtering.",
	)

	free_test_node(root)


func _test_visual_state_math() -> void:
	var state := NucleusUIVisualStateProfile.new()
	state.scale_multiplier = Vector2(1.1, 0.9)
	state.offset = Vector2(12.0, -4.0)
	state.rotation_degrees = 10.0
	state.alpha_multiplier = 0.5

	var scaled := state.get_scale(Vector2(2.0, 2.0))
	expect_float(
		scaled.x,
		2.2,
		"Visual state X scale is relative to authored scale.",
	)
	expect_float(
		scaled.y,
		1.8,
		"Visual state Y scale is relative to authored scale.",
	)
	expect_equal(
		state.get_position(Vector2(4.0, 5.0), 0.5),
		Vector2(10.0, 3.0),
		"Reduced amplitude attenuates visual-state offset.",
	)
	expect_float(
		state.get_alpha(0.8),
		0.4,
		"Visual state opacity is relative to authored alpha.",
	)


func _test_progress_feedback_immediate() -> void:
	var root := Control.new()
	var primary := ProgressBar.new()
	var trailing := ProgressBar.new()
	var feedback := NucleusUIProgressFeedback.new()

	primary.min_value = 0.0
	primary.max_value = 200.0
	primary.value = 100.0
	trailing.min_value = 0.0
	trailing.max_value = 1.0
	trailing.value = 0.5

	root.add_child(primary)
	root.add_child(trailing)
	feedback.primary_target = primary
	feedback.trailing_target = trailing
	feedback.sync_trailing_bounds = false
	root.add_child(feedback)

	expect_true(
		attach_test_node(root),
		"Progress feedback fixture requires a live SceneTree.",
	)

	expect_equal(
		feedback.snap_to(50.0),
		OK,
		"Progress feedback accepts immediate values.",
	)
	expect_float(
		primary.value,
		50.0,
		"Primary Range receives the requested value.",
	)
	expect_float(
		trailing.value,
		0.25,
		"Trailing Range maps through normalized progress.",
	)
	expect_float(
		feedback.get_ratio(),
		0.25,
		"Progress feedback exposes normalized ratio.",
	)

	free_test_node(root)


func _test_interaction_selected_state() -> void:
	var root := Control.new()
	var button := Button.new()
	var feedback := NucleusUIInteractionFeedback.new()
	var profile := NucleusUIFeedbackProfile.new()
	var selected := NucleusUIVisualStateProfile.new()
	var motion := NucleusUIMotionProfile.new()

	button.scale = Vector2(2.0, 2.0)
	motion.respect_reduced_motion = false
	profile.motion = motion
	selected.scale_multiplier = Vector2(1.1, 1.1)
	profile.selected_state = selected
	feedback.target = button
	feedback.profile = profile

	root.add_child(button)
	root.add_child(feedback)

	expect_true(
		attach_test_node(root),
		"Interaction feedback fixture requires a live SceneTree.",
	)

	feedback.set_selected(true, false)
	expect_true(
		feedback.is_selected(),
		"Interaction feedback exposes explicit selected state.",
	)
	expect_float(
		button.scale.x,
		2.2,
		"Selected visual state updates X scale.",
	)
	expect_float(
		button.scale.y,
		2.2,
		"Selected visual state updates Y scale.",
	)

	feedback.reset_immediately()
	expect_equal(
		button.scale,
		Vector2(2.0, 2.0),
		"Reset restores the authored scale.",
	)

	free_test_node(root)
