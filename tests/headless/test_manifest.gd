extends RefCounted

const SUITES: Array[Script] = [
	preload("res://tests/headless/semantic_version_test.gd"),
	preload("res://tests/headless/value_pool_test.gd"),
	preload("res://tests/headless/network_utils_test.gd"),
	preload("res://tests/headless/input_binding_codec_test.gd"),
	preload("res://tests/headless/input_defaults_test.gd"),
	preload("res://tests/headless/smart_decal_test.gd"),
	preload("res://tests/headless/window_utils_test.gd"),
	preload("res://tests/headless/inventory_test.gd"),
	preload("res://tests/headless/equipment_test.gd"),
	preload("res://tests/headless/loot_test.gd"),
	preload("res://tests/headless/world_state_test.gd"),
	preload("res://tests/headless/ai_navigation_test.gd"),
	preload("res://tests/headless/network_replication_test.gd"),
	preload("res://tests/headless/platform_services_test.gd"),
	preload("res://tests/headless/configuration_warnings_test.gd"),
]
