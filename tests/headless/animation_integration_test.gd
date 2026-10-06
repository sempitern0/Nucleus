extends "res://tests/headless/test_case.gd"


func run() -> Dictionary:
	_test_ragdoll_requires_simulator()
	_test_ragdoll_influence_clamps()
	return finish()


func _test_ragdoll_requires_simulator() -> void:
	var controller := NucleusRagdollController3D.new()

	expect_true(
		not controller._get_configuration_warnings().is_empty(),
		"Ragdoll controller warns when no simulator is assigned.",
	)
	controller.free()


func _test_ragdoll_influence_clamps() -> void:
	var skeleton := Skeleton3D.new()
	var simulator := PhysicalBoneSimulator3D.new()
	var controller := NucleusRagdollController3D.new()

	skeleton.add_child(simulator)
	skeleton.add_child(controller)
	controller.simulator = simulator

	controller.set_ragdoll_influence(0.35)
	expect_float(
		simulator.influence,
		0.35,
		"Ragdoll controller forwards influence to the native simulator.",
	)

	controller.set_ragdoll_influence(2.0)
	expect_float(
		simulator.influence,
		1.0,
		"Ragdoll influence is clamped to the native modifier range.",
	)

	skeleton.free()
