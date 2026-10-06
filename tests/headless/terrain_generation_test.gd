extends "res://tests/headless/test_case.gd"

const MeshBuilder := preload(
	"res://modules/terrain/terrain_mesh_builder.gd"
)
const TerrainStreamerScript := preload(
	"res://modules/terrain/terrain_streamer_3d.gd"
)

const EXAMPLE_SCENES: Array[String] = [
	"res://examples/terrain/terrain_preview.tscn",
	"res://examples/terrain/terrain_single.tscn",
	"res://examples/terrain/terrain_grid.tscn",
	"res://examples/terrain/terrain_linear.tscn",
	"res://examples/terrain/terrain_islands.tscn",
	"res://examples/terrain/terrain_streaming.tscn",
]


func run() -> Dictionary:
	_test_profile_validation()
	_test_layouts_are_deterministic()
	_test_direct_array_mesh_generation()
	_test_heightmap_collision_generation()
	_test_heightmap_collision_holes()
	_test_streamer_contract()
	_test_example_scenes_load()
	return finish()


func _test_profile_validation() -> void:
	var profile := NucleusTerrainProfile.new()
	expect_true(
		not profile.get_validation_errors().is_empty(),
		"Noise terrain should require a FastNoiseLite source.",
	)

	profile.noise = FastNoiseLite.new()
	expect_true(
		profile.get_validation_errors().is_empty(),
		"A basic noise terrain profile should validate.",
	)


func _test_layouts_are_deterministic() -> void:
	var layout := NucleusTerrainLayout.new()
	layout.mode = NucleusTerrainLayout.Mode.ISLANDS
	layout.island_count = 4
	layout.island_spread = Vector2(1200.0, 1200.0)
	layout.island_min_separation = 10.0
	layout.seed = 90210
	var first := layout.build_descriptors(Vector2(128.0, 128.0))
	var second := layout.build_descriptors(Vector2(128.0, 128.0))

	expect_equal(first, second, "Island layouts should be deterministic by seed.")
	expect_equal(first.size(), 4, "The requested island count should fit this layout.")


func _test_direct_array_mesh_generation() -> void:
	var profile := _make_profile()
	profile.resolution = 8
	profile.lod_levels = 2
	var result := MeshBuilder.build_mesh(
		profile,
		Vector3.ZERO,
		1.0,
		0,
		false,
		true,
	)

	expect_equal(result.get("error"), OK, "Terrain mesh generation should succeed.")
	var mesh: ArrayMesh = result["mesh"]
	expect_equal(mesh.get_surface_count(), 1, "Terrain should use one mesh surface.")
	expect_equal(
		mesh.surface_get_array_len(0),
		81,
		"An 8-cell terrain should create a 9x9 vertex grid.",
	)
	expect_equal(
		mesh.surface_get_array_index_len(0),
		384,
		"An 8x8 cell grid should create two triangles per cell.",
	)


func _test_heightmap_collision_generation() -> void:
	var profile := _make_profile()
	profile.collision_resolution = 6
	var result := MeshBuilder.build_heightmap_shape(
		profile,
		Vector3.ZERO,
		1.0,
		false,
	)

	expect_equal(result.get("error"), OK, "Heightmap collision generation should succeed.")
	var shape: HeightMapShape3D = result["shape"]
	expect_equal(shape.map_width, 7, "Collision width should match resolution + 1.")
	expect_equal(shape.map_depth, 7, "Collision depth should match resolution + 1.")
	expect_equal(shape.map_data.size(), 49, "Collision should contain one height per sample.")


func _test_heightmap_collision_holes() -> void:
	var profile := _make_profile()
	profile.shape_mode = NucleusTerrainProfile.ShapeMode.ISLAND
	profile.edge_floor_height = -20.0
	profile.collision_resolution = 6
	profile.collision_holes_below_height = true
	profile.collision_hole_height = -10.0
	var result := MeshBuilder.build_heightmap_shape(
		profile,
		Vector3.ZERO,
		1.0,
		false,
	)

	expect_equal(result.get("error"), OK, "Collision-hole generation should succeed.")
	var shape: HeightMapShape3D = result["shape"]
	var has_hole := false

	for height: float in shape.map_data:
		if is_nan(height):
			has_hole = true
			break

	expect_true(has_hole, "Island collision can omit samples below the configured height.")


func _make_profile() -> NucleusTerrainProfile:
	var profile := NucleusTerrainProfile.new()
	var noise := FastNoiseLite.new()
	noise.seed = 7
	noise.frequency = 0.01
	profile.noise = noise
	profile.size = Vector2(64.0, 64.0)
	return profile


func _test_streamer_contract() -> void:
	var streamer: NucleusTerrainStreamer3D = TerrainStreamerScript.new()
	expect_equal(streamer.chunks_behind, 2, "Streamer keeps two chunks behind by default.")
	expect_equal(streamer.chunks_ahead, 4, "Streamer keeps four chunks ahead by default.")
	expect_equal(
		streamer.max_new_chunks_per_update,
		1,
		"Streamer builds one new chunk per update by default.",
	)
	streamer.free()


func _test_example_scenes_load() -> void:
	for scene_path: String in EXAMPLE_SCENES:
		var packed: PackedScene = load(scene_path) as PackedScene
		expect_true(
			packed != null,
			"Terrain example should load: %s" % scene_path,
		)
