extends "res://tests/headless/test_case.gd"


func run() -> Dictionary:
	_test_key_roundtrip()
	_test_mouse_roundtrip()
	_test_joypad_button_roundtrip()
	_test_joypad_motion_roundtrip()
	return result()


func _test_key_roundtrip() -> void:
	var source := InputEventKey.new()
	source.physical_keycode = KEY_W
	source.location = KEY_LOCATION_STANDARD
	source.shift_pressed = true

	var decoded := NucleusInputBindingCodec.normalize(source) as InputEventKey
	check(decoded != null, "key event should round-trip")
	if decoded == null:
		return

	check(decoded.physical_keycode == KEY_W, "physical keycode should survive")
	check(decoded.location == KEY_LOCATION_STANDARD, "key location should survive")
	check(decoded.shift_pressed, "key modifiers should survive")


func _test_mouse_roundtrip() -> void:
	var source := InputEventMouseButton.new()
	source.button_index = MOUSE_BUTTON_RIGHT
	source.ctrl_pressed = true

	var decoded := NucleusInputBindingCodec.normalize(source) as InputEventMouseButton
	check(decoded != null, "mouse event should round-trip")
	if decoded == null:
		return

	check(decoded.button_index == MOUSE_BUTTON_RIGHT, "mouse button should survive")
	check(decoded.ctrl_pressed, "mouse modifiers should survive")


func _test_joypad_button_roundtrip() -> void:
	var source := InputEventJoypadButton.new()
	source.button_index = JOY_BUTTON_A

	var decoded := NucleusInputBindingCodec.normalize(source) as InputEventJoypadButton
	check(decoded != null, "joypad button should round-trip")
	if decoded == null:
		return

	check(decoded.button_index == JOY_BUTTON_A, "joypad button should survive")


func _test_joypad_motion_roundtrip() -> void:
	var source := InputEventJoypadMotion.new()
	source.axis = JOY_AXIS_TRIGGER_RIGHT
	source.axis_value = -0.75

	var decoded := NucleusInputBindingCodec.normalize(source) as InputEventJoypadMotion
	check(decoded != null, "joypad motion should round-trip")
	if decoded == null:
		return

	check(decoded.axis == JOY_AXIS_TRIGGER_RIGHT, "joypad axis should survive")
	check(is_equal_approx(decoded.axis_value, -1.0), "axis direction should normalize")
