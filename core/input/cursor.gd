class_name NucleusCursor
extends RefCounted
## Stateless mouse cursor helpers salvaged from Barebone's Input helper.


static func is_visible() -> bool:
	return Input.mouse_mode == Input.MOUSE_MODE_VISIBLE


static func is_captured() -> bool:
	return Input.mouse_mode == Input.MOUSE_MODE_CAPTURED


static func is_confined() -> bool:
	return Input.mouse_mode == Input.MOUSE_MODE_CONFINED


static func show() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


static func hide() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN


static func capture() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


static func confine() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED


static func confine_hidden() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
