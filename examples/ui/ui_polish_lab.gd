extends Control
## Manual validation lab for reusable UI polish primitives.

var _presenter: NucleusUIPresenter
var _progress: NucleusUIProgressFeedback
var _demo_feedback: NucleusUIInteractionFeedback
var _panel_visible: bool = true
var _health: float = 100.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_lab()


func _build_lab() -> void:
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.055, 0.065, 0.08, 1.0)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override(&"margin_left", 32)
	margin.add_theme_constant_override(&"margin_top", 28)
	margin.add_theme_constant_override(&"margin_right", 32)
	margin.add_theme_constant_override(&"margin_bottom", 28)
	add_child(margin)

	var root_box := VBoxContainer.new()
	root_box.add_theme_constant_override(&"separation", 16)
	margin.add_child(root_box)

	var title := Label.new()
	title.text = "Nucleus UI Polish Lab"
	title.add_theme_font_size_override(&"font_size", 28)
	root_box.add_child(title)

	var instructions := Label.new()
	instructions.text = (
		"Try mouse, keyboard and controller focus. "
		+ "Toggle Reduce Motion in settings to compare behavior."
	)
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root_box.add_child(instructions)

	_build_presenter_demo(root_box)
	_build_interaction_demo(root_box)
	_build_progress_demo(root_box)


func _build_presenter_demo(parent: VBoxContainer) -> void:
	var heading := Label.new()
	heading.text = "Declarative panel transition"
	parent.add_child(heading)

	var slot := Control.new()
	slot.custom_minimum_size = Vector2(560.0, 150.0)
	parent.add_child(slot)

	var panel := PanelContainer.new()
	panel.position = Vector2(0.0, 8.0)
	panel.size = Vector2(540.0, 120.0)
	slot.add_child(panel)

	var content := MarginContainer.new()
	content.add_theme_constant_override(&"margin_left", 18)
	content.add_theme_constant_override(&"margin_top", 14)
	content.add_theme_constant_override(&"margin_right", 18)
	content.add_theme_constant_override(&"margin_bottom", 14)
	panel.add_child(content)

	var label := Label.new()
	label.text = (
		"This PresentationRoot owns panel enter/exit motion. "
		+ "Layout remains outside it."
	)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(label)

	_presenter = NucleusUIPresenter.new()
	_presenter.target = panel
	_presenter.transition = NucleusUITransitionProfile.slide(
		Vector2(0.0, 24.0),
		0.22,
		true,
	)
	slot.add_child(_presenter)

	var toggle := Button.new()
	toggle.text = "Hide / show panel"
	toggle.pressed.connect(_toggle_panel)
	parent.add_child(toggle)


func _build_interaction_demo(parent: VBoxContainer) -> void:
	var heading := Label.new()
	heading.text = "Interaction visual states"
	parent.add_child(heading)

	var button := Button.new()
	button.text = "Hover / focus / press / toggle"
	button.toggle_mode = true
	button.custom_minimum_size = Vector2(340.0, 48.0)
	parent.add_child(button)

	var profile := NucleusUIFeedbackProfile.new()
	profile.motion = NucleusUIMotionProfile.new()
	profile.motion.duration = 0.1
	profile.motion.reduced_motion_scale = 0.25

	var hover := NucleusUIVisualStateProfile.new()
	hover.scale_multiplier = Vector2(1.025, 1.025)

	var focus := NucleusUIVisualStateProfile.new()
	focus.scale_multiplier = Vector2(1.04, 1.04)

	var pressed := NucleusUIVisualStateProfile.new()
	pressed.scale_multiplier = Vector2(0.97, 0.97)

	var selected := NucleusUIVisualStateProfile.new()
	selected.scale_multiplier = Vector2(1.02, 1.02)
	selected.alpha_multiplier = 0.92

	profile.hover_state = hover
	profile.focus_state = focus
	profile.pressed_state = pressed
	profile.selected_state = selected

	_demo_feedback = NucleusUIInteractionFeedback.new()
	_demo_feedback.target = button
	_demo_feedback.profile = profile
	parent.add_child(_demo_feedback)


func _build_progress_demo(parent: VBoxContainer) -> void:
	var heading := Label.new()
	heading.text = "Progress feedback with delayed trailing value"
	parent.add_child(heading)

	var slot := Control.new()
	slot.custom_minimum_size = Vector2(560.0, 34.0)
	parent.add_child(slot)

	var trailing := ProgressBar.new()
	trailing.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	trailing.show_percentage = false
	trailing.value = _health
	trailing.modulate = Color(1.0, 0.45, 0.45, 0.55)
	slot.add_child(trailing)

	var primary := ProgressBar.new()
	primary.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	primary.show_percentage = true
	primary.value = _health
	slot.add_child(primary)

	_progress = NucleusUIProgressFeedback.new()
	_progress.primary_target = primary
	_progress.trailing_target = trailing
	_progress.feedback_target = slot
	_progress.decrease_trail_delay = 0.22
	_progress.pulse_on_decrease = true
	_progress.pulse_on_increase = false
	slot.add_child(_progress)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override(&"separation", 10)
	parent.add_child(actions)

	var damage := Button.new()
	damage.text = "Damage -25"
	damage.pressed.connect(_change_health.bind(-25.0))
	actions.add_child(damage)

	var heal := Button.new()
	heal.text = "Heal +15"
	heal.pressed.connect(_change_health.bind(15.0))
	actions.add_child(heal)

	var reset := Button.new()
	reset.text = "Reset"
	reset.pressed.connect(_reset_health)
	actions.add_child(reset)


func _toggle_panel() -> void:
	_panel_visible = not _panel_visible

	if _panel_visible:
		_presenter.show_animated()
	else:
		_presenter.hide_animated()


func _change_health(delta: float) -> void:
	_health = clampf(_health + delta, 0.0, 100.0)
	_progress.set_value(_health)


func _reset_health() -> void:
	_health = 100.0
	_progress.set_value(_health)
