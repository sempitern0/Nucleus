extends Control
## Visual acceptance lab for the project-wide native Theme baseline.
## Changing the preview does not mutate the shared project Theme Resources.

const HIGH_CONTRAST_THEME: Theme = preload(
	"res://components/ui/theme/nucleus_high_contrast_theme.tres"
)

var _result: Label


func _ready() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.075, 0.095, 0.115)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	scroll.add_child(center)

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(0, 560)
	center.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 15)
	panel.add_child(column)

	var title := Label.new()
	title.text = "Nucleus — Default UI Theme"
	title.add_theme_font_size_override(&"font_size", 26)
	column.add_child(title)

	var description := Label.new()
	description.text = "Native Godot controls. No fonts or artwork dependencies."
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(description)

	var separator := HSeparator.new()
	column.add_child(separator)

	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override(&"separation", 12)
	column.add_child(action_row)
	_add_button(action_row, "Default button", false)
	_add_button(action_row, "Disabled button", true)

	var edit := LineEdit.new()
	edit.placeholder_text = "Text field — type here"
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(edit)

	var dropdown := OptionButton.new()
	dropdown.add_item("Difficulty: Normal")
	dropdown.add_item("Difficulty: Accessible")
	dropdown.add_item("Difficulty: Custom")
	column.add_child(dropdown)

	var checks := HBoxContainer.new()
	column.add_child(checks)
	var checkbox := CheckBox.new()
	checkbox.text = "Remember choice"
	checkbox.button_pressed = true
	checks.add_child(checkbox)

	var contrast := CheckButton.new()
	contrast.text = "High-contrast preview"
	checks.add_child(contrast)
	contrast.toggled.connect(_toggle_contrast)

	var slider_text := Label.new()
	slider_text.text = "Volume example (50%)"
	column.add_child(slider_text)
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.value = 50
	column.add_child(slider)
	slider.value_changed.connect(func(value: float) -> void:
		slider_text.text = "Volume example (%d%%)" % roundi(value)
	)

	var progress := ProgressBar.new()
	progress.value = 64
	column.add_child(progress)

	var tabs := TabContainer.new()
	tabs.custom_minimum_size = Vector2(0, 130)
	column.add_child(tabs)
	for item: String in ["Overview", "Keyboard", "Gamepad"]:
		var page := MarginContainer.new()
		page.name = item
		tabs.add_child(page)
		var label := Label.new()
		label.text = "Focus and contrast must remain clear with %s." % item.to_lower()
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		page.add_child(label)

	_result = Label.new()
	_result.text = "Tab to test focus; Enter/Space to activate."
	_result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_result)


func _add_button(parent: Node, caption: String, is_disabled: bool) -> void:
	var button := Button.new()
	button.text = caption
	button.disabled = is_disabled
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(button)
	if not is_disabled:
		button.pressed.connect(func() -> void:
			_result.text = "Button activated by pointer or keyboard."
		)


func _toggle_contrast(enabled: bool) -> void:
	# Null restores the project-wide baseline; the alternative is local to this lab.
	theme = HIGH_CONTRAST_THEME if enabled else null
	_result.text = (
		"High-contrast preview enabled."
		if enabled else "Project-wide default theme restored."
	)
