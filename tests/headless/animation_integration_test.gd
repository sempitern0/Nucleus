extends "res://tests/headless/test_case.gd"


func run() -> Dictionary:
	_test_ragdoll_requires_simulator()
	_test_ragdoll_influence_clamps()
	_test_profile_suggests_common_clips()
	_test_rig_inspector()
	_test_starter_tree_builder()
	_test_setup_creates_tree_and_velocity_binding()
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


func _test_profile_suggests_common_clips() -> void:
	var player := _build_animation_player()
	var profile := NucleusAnimationStarterProfile3D.new()

	expect_equal(
		profile.suggest_common_clips(player),
		6,
		"Starter profile should identify the six conventional clip roles.",
	)
	expect_equal(
		profile.idle_animation,
		&"Humanoid_Idle",
		"Idle suggestion should retain the original AnimationPlayer key.",
	)
	expect_equal(
		profile.walk_animation,
		&"Humanoid_Walk",
		"Walk suggestion should retain the original AnimationPlayer key.",
	)
	expect_equal(
		profile.run_animation,
		&"Humanoid_Run",
		"Run suggestion should retain the original AnimationPlayer key.",
	)
	expect_true(
		profile.get_validation_errors(player).is_empty(),
		"Suggested starter profile should validate against its source player.",
	)

	player.free()


func _test_rig_inspector() -> void:
	var visual := Node3D.new()
	var skeleton := Skeleton3D.new()
	var player := _build_animation_player()
	visual.add_child(skeleton)
	visual.add_child(player)

	var report := NucleusAnimationRigInspector3D.inspect(visual)

	expect_true(
		report.get("skeleton") == skeleton,
		"Rig inspector should resolve the imported Skeleton3D.",
	)
	expect_true(
		report.get("animation_player") == player,
		"Rig inspector should resolve the imported AnimationPlayer.",
	)
	expect_equal(
		int(report.get("animation_player_count", 0)),
		1,
		"Rig inspector should count animation players.",
	)
	var animations: PackedStringArray = report.get(
		"animations",
		PackedStringArray(),
	)
	expect_equal(
		animations.size(),
		6,
		"Rig inspector should expose available animation keys.",
	)

	visual.free()


func _test_starter_tree_builder() -> void:
	var root := Node3D.new()
	var player := _build_animation_player()
	var tree := AnimationTree.new()
	root.add_child(player)
	root.add_child(tree)

	expect_true(
		attach_test_node(root),
		"AnimationTree builder test requires a live SceneTree.",
	)

	var profile := _configured_profile()

	expect_equal(
		NucleusAnimationTreeBuilder3D.build_starter_tree(
			tree,
			player,
			profile,
		),
		OK,
		"Starter builder should create a native AnimationTree graph.",
	)

	var state_machine := tree.tree_root as AnimationNodeStateMachine
	expect_true(
		state_machine != null,
		"Starter tree root should be an AnimationNodeStateMachine.",
	)

	var locomotion := (
		state_machine.get_node(
			NucleusAnimationTreeBuilder3D.LOCOMOTION_STATE
		)
		as AnimationNodeBlendSpace1D
	)
	expect_true(
		locomotion != null,
		"Starter state machine should contain Locomotion BlendSpace1D.",
	)
	expect_equal(
		locomotion.get_blend_point_count(),
		3,
		"Locomotion blend space should contain idle, walk and run.",
	)
	expect_true(
		state_machine.get_node(
			NucleusAnimationTreeBuilder3D.JUMP_STATE
		) is AnimationNodeAnimation,
		"Configured jump clip should become a native state.",
	)
	expect_equal(
		tree.anim_player,
		tree.get_path_to(player),
		"Builder should wire AnimationTree to the imported AnimationPlayer.",
	)
	expect_equal(
		NucleusAnimationTreeBuilder3D.build_starter_tree(
			tree,
			player,
			profile,
		),
		ERR_ALREADY_EXISTS,
		"Builder should protect an existing graph by default.",
	)

	free_test_node(root)


func _test_setup_creates_tree_and_velocity_binding() -> void:
	var body := CharacterBody3D.new()
	var visual := Node3D.new()
	var skeleton := Skeleton3D.new()
	var player := _build_animation_player()
	var setup := NucleusCharacterAnimationSetup3D.new()

	body.add_child(visual)
	visual.add_child(skeleton)
	visual.add_child(player)
	body.add_child(setup)
	setup.visual_root = visual
	setup.starter_profile = _configured_profile()

	expect_true(
		attach_test_node(body),
		"Animation setup test requires a live SceneTree.",
	)
	expect_equal(
		setup.build_starter_tree(),
		OK,
		"Setup helper should build the starter graph from resolved rig data.",
	)
	expect_true(
		setup.animation_tree != null,
		"Setup helper should create AnimationTree when requested.",
	)
	expect_true(
		setup.velocity_binding != null,
		"Setup helper should create a velocity binding for CharacterBody3D.",
	)
	expect_equal(
		setup.velocity_binding.speed_parameter,
		NucleusAnimationTreeBuilder3D.SPEED_PARAMETER,
		"Setup helper should wire the standard locomotion speed parameter.",
	)

	free_test_node(body)


func _configured_profile() -> NucleusAnimationStarterProfile3D:
	var profile := NucleusAnimationStarterProfile3D.new()
	profile.idle_animation = &"Humanoid_Idle"
	profile.walk_animation = &"Humanoid_Walk"
	profile.run_animation = &"Humanoid_Run"
	profile.jump_animation = &"Humanoid_Jump"
	profile.fall_animation = &"Humanoid_Fall"
	profile.land_animation = &"Humanoid_Land"
	profile.walk_speed = 2.0
	profile.run_speed = 5.0
	return profile


func _build_animation_player() -> AnimationPlayer:
	var player := AnimationPlayer.new()
	var library := AnimationLibrary.new()

	for animation_name: StringName in [
		&"Humanoid_Idle",
		&"Humanoid_Walk",
		&"Humanoid_Run",
		&"Humanoid_Jump",
		&"Humanoid_Fall",
		&"Humanoid_Land",
	]:
		var animation := Animation.new()
		animation.length = 1.0
		library.add_animation(animation_name, animation)

	player.add_animation_library(&"", library)
	return player
