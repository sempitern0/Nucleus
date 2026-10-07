extends Control
## Manual validation lab for reusable UI polish primitives.

var _presenter: NucleusUIPresenter
var _progress: NucleusUIProgressFeedback
var _typewriter: NucleusUITypewriter
var _shader_effect: NucleusUIShaderEffect
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

	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)

	var margin := MarginContainer.new()
	margin.custom_minimum_size.x = 720.0
	margin.add_theme_constant_override(&"margin_left", 32)
	margin.add_theme_constant_override(&"margin_top", 28)
	margin.add_theme_constant_override(&"margin_right", 32)
	margin.add_theme_constant_override(&"margin_bottom", 28)
	scroll.add_child(margin)

	var root_box := VBoxContainer.new()
	root_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	_build_glyph_demo(root_box)
	_build_shader_demo(root_box)
	_build_typewriter_demo(root_box)


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

	var feedback := NucleusUIInteractionFeedback.new()
	feedback.target = button
	feedback.profile = profile
	parent.add_child(feedback)


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


func _build_glyph_demo(parent: VBoxContainer) -> void:
	var heading := Label.new()
	heading.text = "Input glyph with automatic text fallback"
	parent.add_child(heading)

	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 10)
	parent.add_child(row)

	var glyph := TextureRect.new()
	glyph.custom_minimum_size = Vector2(32.0, 32.0)
	glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glyph.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(glyph)

	var fallback := Label.new()
	fallback.text = "Binding"
	row.add_child(fallback)

	var profile := NucleusInputGlyphProfile.new()
	_add_demo_glyphs(profile, NucleusInputTypes.Source.KEYBOARD_MOUSE)
	_add_demo_glyphs(profile, NucleusInputTypes.Source.GAMEPAD)

	var binding := NucleusInputGlyphBinding.new()
	binding.action = &"ui_accept"
	binding.profile = profile
	binding.glyph_target = glyph
	binding.fallback_label = fallback
	row.add_child(binding)


func _build_shader_demo(parent: VBoxContainer) -> void:
	var heading := Label.new()
	heading.text = "Game-owned shader parameter animation"
	parent.add_child(heading)

	var rect := ColorRect.new()
	rect.custom_minimum_size = Vector2(560.0, 46.0)
	parent.add_child(rect)

	var shader := Shader.new()
	shader.code = (
		"shader_type canvas_item;\n"
		+ "uniform float intensity : hint_range(0.0, 1.0) = 0.0;\n"
		+ "void fragment() {\n"
		+ "\tCOLOR = vec4(0.12 + intensity * 0.35, 0.28, 0.62, 1.0);\n"
		+ "}\n"
	)

	var shader_material := ShaderMaterial.new()
	shader_material.shader = shader
	rect.material = shader_material

	_shader_effect = NucleusUIShaderEffect.new()
	_shader_effect.target = rect
	rect.add_child(_shader_effect)

	var pulse := Button.new()
	pulse.text = "Animate shader intensity"
	pulse.pressed.connect(_pulse_shader)
	parent.add_child(pulse)


func _build_typewriter_demo(parent: VBoxContainer) -> void:
	var heading := Label.new()
	heading.text = "RichTextLabel reveal with punctuation cadence"
	parent.add_child(heading)

	var text := RichTextLabel.new()
	text.custom_minimum_size = Vector2(560.0, 78.0)
	text.bbcode_enabled = true
	text.text = (
		"[b]Nucleus[/b] reveals text, respects punctuation, "
		+ "and keeps dialogue ownership in the game. BBCode stays native."
	)
	parent.add_child(text)

	_typewriter = NucleusUITypewriter.new()
	_typewriter.target = text
	_typewriter.characters_per_second = 42.0
	_typewriter.minor_punctuation_delay = 0.08
	_typewriter.major_punctuation_delay = 0.2
	text.add_child(_typewriter)
	_typewriter.restart()

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override(&"separation", 10)
	parent.add_child(actions)

	var replay := Button.new()
	replay.text = "Replay text"
	replay.pressed.connect(_typewriter.restart)
	actions.add_child(replay)

	var skip := Button.new()
	skip.text = "Skip reveal"
	skip.pressed.connect(_typewriter.skip)
	actions.add_child(skip)


func _add_demo_glyphs(
	profile: NucleusInputGlyphProfile,
	source: int,
) -> void:
	var events: Array[InputEvent] = NucleusInput.get_action_events(
		&"ui_accept",
		source,
	)

	if events.is_empty():
		return

	var entry := NucleusInputGlyphEntry.new()
	entry.event_key = NucleusInputGlyphProfile.event_key(events[0])
	entry.texture = _make_demo_texture(
		Color(0.85, 0.9, 1.0, 1.0)
	)

	if source == NucleusInputTypes.Source.GAMEPAD:
		profile.generic_gamepad.append(entry)
	else:
		profile.keyboard_mouse.append(entry)


func _make_demo_texture(color: Color) -> Texture2D:
	var image := Image.create_empty(
		24,
		24,
		false,
		Image.FORMAT_RGBA8,
	)
	image.fill(color)
	return ImageTexture.create_from_image(image)


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


func _pulse_shader() -> void:
	var tween := _shader_effect.animate_parameter(
		&"intensity",
		1.0,
		0.65,
	)

	if tween:
		tween.finished.connect(_restore_shader_intensity)


func _restore_shader_intensity() -> void:
	_shader_effect.animate_parameter(
		&"intensity",
		0.0,
		1.0,
	)
