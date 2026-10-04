extends RefCounted

var _checks: int = 0
var _failures := PackedStringArray()


func expect_true(value: bool, message: String) -> void:
	_checks += 1

	if not value:
		_failures.append(message)


func expect_false(value: bool, message: String) -> void:
	expect_true(not value, message)


func expect_equal(
	actual: Variant,
	expected: Variant,
	message: String,
) -> void:
	_checks += 1

	if actual != expected:
		_failures.append(
			"%s (expected=%s actual=%s)"
			% [message, str(expected), str(actual)]
		)


func expect_float(
	actual: float,
	expected: float,
	message: String,
) -> void:
	_checks += 1

	if not is_equal_approx(actual, expected):
		_failures.append(
			"%s (expected=%s actual=%s)"
			% [message, str(expected), str(actual)]
		)


func finish() -> Dictionary:
	return {
		"checks": _checks,
		"failures": _failures,
	}
