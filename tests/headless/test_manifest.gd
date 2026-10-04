extends RefCounted

const SUITES: Array[Script] = [
	preload("res://tests/headless/semantic_version_test.gd"),
	preload("res://tests/headless/value_pool_test.gd"),
	preload("res://tests/headless/network_utils_test.gd"),
	preload("res://tests/headless/input_binding_codec_test.gd"),
	preload("res://tests/headless/smart_decal_test.gd"),
	preload("res://tests/headless/window_utils_test.gd"),
	preload("res://tests/headless/inventory_test.gd"),
	preload("res://tests/headless/equipment_test.gd"),
	preload("res://tests/headless/configuration_warnings_test.gd"),
]
