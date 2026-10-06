class_name NucleusTerrainStreamer3D
extends Node3D
## Lightweight linear runtime chunk streaming for long traversal games.

const PatchBuilder := preload(
	"res://modules/terrain/terrain_patch_builder.gd"
)

@export var profile: NucleusTerrainProfile
@export var material_profile: NucleusTerrainMaterialProfile
@export var tracked_node: Node3D
@export_enum("X", "Z")
var axis: int = NucleusTerrainLayout.Axis.Z
@export_range(0, 32, 1)
var chunks_behind: int = 2
@export_range(0, 32, 1)
var chunks_ahead: int = 4
@export_range(0.0, 10000.0, 0.1)
var patch_gap: float = 0.0
@export_range(0.02, 10.0, 0.01, "or_greater")
var update_interval: float = 0.25
@export_range(1, 8, 1)
var max_new_chunks_per_update: int = 1

var _chunks: Dictionary[int, Node3D] = {}
var _pending: Array[int] = []
var _elapsed: float = 0.0
var _last_center_index: int = 2147483647
var _material: Material


func _ready() -> void:
	if profile == null or tracked_node == null:
		set_process(false)
		NucleusLog.error(
			"Terrain streamer requires profile and tracked_node.",
			&"Terrain",
		)
		return

	_material = _create_material()
	_update_stream(true)


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed < update_interval:
		return
	_elapsed = 0.0
	_update_stream(false)


func clear_chunks() -> void:
	_pending.clear()
	for chunk: Node3D in _chunks.values():
		if is_instance_valid(chunk):
			chunk.queue_free()
	_chunks.clear()


func _update_stream(force: bool) -> void:
	var center: int = _get_chunk_index(tracked_node.global_position)

	if not force and center == _last_center_index and _pending.is_empty():
		return

	_last_center_index = center
	var minimum: int = center - chunks_behind
	var maximum: int = center + chunks_ahead
	var remove_indices: Array[int] = []

	for index: int in _chunks.keys():
		if index < minimum or index > maximum:
			remove_indices.append(index)

	for index: int in remove_indices:
		var chunk: Node3D = _chunks[index]
		_chunks.erase(index)
		if is_instance_valid(chunk):
			chunk.queue_free()

	for index: int in range(minimum, maximum + 1):
		if not _chunks.has(index) and not _pending.has(index):
			_pending.append(index)

	_pending.sort_custom(
		func(left: int, right: int) -> bool:
			return absi(left - center) < absi(right - center)
	)

	var build_count: int = mini(max_new_chunks_per_update, _pending.size())
	for _iteration: int in range(build_count):
		var index: int = _pending.pop_front()
		_build_chunk(index)


func _build_chunk(index: int) -> void:
	var position: Vector3 = _get_chunk_position(index)
	var result: Dictionary = PatchBuilder.build_patch(
		profile,
		_material,
		position,
		1.0,
		false,
		0,
		true,
		true,
	)

	if result.get("error", FAILED) != OK:
		NucleusLog.error(
			"Terrain streamer could not build chunk %d: %s"
			% [index, error_string(result.get("error", FAILED))],
			&"Terrain",
		)
		return

	var chunk: Node3D = result["node"]
	chunk.name = "TerrainChunk_%d" % index
	chunk.set_meta(&"terrain_chunk_index", index)
	add_child(chunk)
	_chunks[index] = chunk


func _get_chunk_index(world_position: Vector3) -> int:
	var length: float = (
		profile.size.x
		if axis == NucleusTerrainLayout.Axis.X
		else profile.size.y
	)
	length += patch_gap
	var coordinate: float = (
		world_position.x
		if axis == NucleusTerrainLayout.Axis.X
		else world_position.z
	)
	return int(floor(coordinate / maxf(length, 0.001)))


func _get_chunk_position(index: int) -> Vector3:
	var length: float = (
		profile.size.x
		if axis == NucleusTerrainLayout.Axis.X
		else profile.size.y
	)
	length += patch_gap
	var position: Vector3 = Vector3.ZERO

	if axis == NucleusTerrainLayout.Axis.X:
		position.x = float(index) * length
	else:
		position.z = float(index) * length

	return position


func _create_material() -> Material:
	if material_profile != null:
		return material_profile.create_material(
			profile.minimum_expected_height(),
			profile.maximum_expected_height(),
		)

	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.24, 0.38, 0.18)
	material.roughness = 1.0
	return material
