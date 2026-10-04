extends SceneTree

const TEST_MANIFEST := preload("res://tests/headless/test_manifest.gd")


func _initialize() -> void:
	call_deferred("_run_all")


func _run_all() -> void:
	var result: Dictionary = _execute_suites()
	var failures: PackedStringArray = result["failures"]
	var total_checks: int = result["checks"]
	var suite_count: int = TEST_MANIFEST.SUITES.size()

	if failures.is_empty():
		print(
			"Nucleus headless tests: PASS (%d checks, %d suites)."
			% [total_checks, suite_count]
		)
		quit(0)
		return

	push_error(
		"Nucleus headless tests: FAIL (%d failures / %d checks)."
		% [failures.size(), total_checks]
	)

	for failure: String in failures:
		push_error("  - " + failure)

	quit(1)


func _execute_suites() -> Dictionary:
	var total_checks: int = 0
	var failures := PackedStringArray()

	for suite_script: Script in TEST_MANIFEST.SUITES:
		var suite: Variant = suite_script.new()
		var result: Dictionary = suite.run()
		total_checks += int(result.get("checks", 0))

		for failure: String in result.get("failures", PackedStringArray()):
			failures.append(
				"%s: %s"
				% [suite_script.resource_path.get_file(), failure]
			)

	return {
		"checks": total_checks,
		"failures": failures,
	}
