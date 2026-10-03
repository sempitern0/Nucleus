class_name NucleusLog
extends RefCounted
## Stateless logging facade for Nucleus and game code.
##
## Messages are emitted through Godot's normal output API. If
## [NucleusFileLogger] is installed, Godot forwards the same output to it.


## Emits a development-only diagnostic message.
static func debug(message: String, context: StringName = &"") -> void:
	if not OS.is_debug_build():
		return

	print("[DEBUG] %s" % _with_context(message, context))


## Emits a regular informational message.
static func info(message: String, context: StringName = &"") -> void:
	print(_with_context(message, context))


## Emits a Godot warning.
static func warning(message: String, context: StringName = &"") -> void:
	push_warning(_with_context(message, context))


## Emits a Godot error.
static func error(message: String, context: StringName = &"") -> void:
	push_error(_with_context(message, context))


static func _with_context(message: String, context: StringName) -> String:
	if context == &"":
		return message

	return "[%s] %s" % [context, message]
