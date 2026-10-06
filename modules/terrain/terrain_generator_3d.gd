@tool
class_name NucleusTerrainGenerator3D
extends Node3D
## Scene-owned editor/runtime terrain generation with cheap 3D previews.

signal generation_started
signal patch_generated(index: int, patch: Node3D)
signal generation_completed(patch_count: int)
signal generation_failed(error: Error, message: String)

const PatchBuilder := preload(
	"res://modules/terrain/terrain_patch_builder.gd"
)

const GENERATED_ROOT: StringName = &"GeneratedTerrain"
const PREVIEW_ROOT: StringName = &"__TerrainPreview"

@export var profile: NucleusTerrainProfile:
	set(value):
		_disconnect_resource(profile)
		profile = value
		_connect_resource(profile)
		update_configuration_warnings()
		_request_auto_preview()

@export var layout: NucleusTerrainLayout:
	set(value):
		_disconnect_resource(layout)
		layout = value
		_connect_resource(layout)
		update_configuration_warnings()
		_request_auto_preview()

@export var material_profile: NucleusTerrainMaterialProfile:
	set(value):
		_disconnect_resource(material_profile)
		material_profile = value
		_connect_resource(material_profile)
		_request_auto_preview()

@export_group("Editor preview")
@export var auto_preview_on_change: bool = false
@export_range(4, 128, 1)
var preview_resolution: int = 24
@export var preview_uses_material: bool = true

@export_group("Runtime generation")
@export_range(1, 32, 1)
var patches_per_frame: int = 1

@export_tool_button("Refresh Preview")
var refresh_preview_action: Callable = refresh_preview
@export_tool_button("Generate Terrain")
var generate_terrain_action: Callable = generate_terrain
@export_tool_button("Clear Generated Terrain")
var clear_generated_action: Callable = clear_generated

var _is_generating: bool = false
var _auto_preview_queued: bool = false


func _ready() -> void:
	_connect_resource(profile)
	_connect_resource(layout)
	_connect_resource(material_profile)


func _exit_tree() -> void:
	_disconnect_resource(profile)
	_disconnect_resource(layout)
	_disconnect_resource(material_profile)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	if profile == null:
		warnings.append("Assign a NucleusTerrainProfile before generating terrain.")
	elif not profile.get_validation_errors().is_empty():
		warnings.append("Terrain profile contains validation errors.")

	if layout != null and not layout.get_validation_errors().is_empty():
		warnings.append("Terrain layout contains validation errors.")

	return warnings


func is_generating() -> bool:
	return _is_generating


func refresh_preview() -> Error:
	if profile == null:
		return ERR_UNCONFIGURED

	var validation_error := _first_validation_error()
	if validation_error != "":
		return _emit_failure(ERR_INVALID_DATA, validation_error)

	_clear_named_child(PREVIEW_ROOT)
	var root := Node3D.new()
	root.name = PREVIEW_ROOT
	add_child(root)
	var descriptors := _get_descriptors()
	var material := _build_preview_material()

	for index: int in range(descriptors.size()):
		var descriptor: Dictionary = descriptors[index]
		var result := PatchBuilder.build_patch(
			profile,
			material,
			descriptor["position"],
			descriptor["scale"],
			descriptor["force_island"],
			mini(preview_resolution, profile.resolution),
			false,
			false,
		)

		if result.get("error", FAILED) != OK:
			_clear_named_child(PREVIEW_ROOT)
			return _emit_failure(
				result.get("error", FAILED),
				"Terrain preview patch %d could not be built." % index,
			)

		var patch: Node3D = result["node"]
		patch.name = "PreviewPatch_%03d" % index
		root.add_child(patch)

	return OK


func generate_terrain() -> Error:
	if _is_generating:
		return ERR_BUSY

	if profile == null:
		return ERR_UNCONFIGURED

	var validation_error := _first_validation_error()
	if validation_error != "":
		return _emit_failure(ERR_INVALID_DATA, validation_error)

	_is_generating = true
	generation_started.emit()
	clear_generated()
	var root := Node3D.new()
	root.name = GENERATED_ROOT
	add_child(root)
	var descriptors := _get_descriptors()
	var material := _build_material()

	if descriptors.is_empty():
		_is_generating = false
		_clear_named_child(GENERATED_ROOT)
		return _emit_failure(
			ERR_CANT_CREATE,
			"Terrain layout produced no patches. Check island separation/spread.",
		)

	for index: int in range(descriptors.size()):
		var result := _build_descriptor_patch(descriptors[index], material, index)
		if result != OK:
			_is_generating = false
			_clear_named_child(GENERATED_ROOT)
			return result

	_set_generated_owners(root)
	_is_generating = false
	generation_completed.emit(descriptors.size())
	return OK


func generate_terrain_async() -> void:
	if _is_generating or profile == null:
		return

	var validation_error := _first_validation_error()
	if validation_error != "":
		_emit_failure(ERR_INVALID_DATA, validation_error)
		return

	_is_generating = true
	generation_started.emit()
	clear_generated()
	var root := Node3D.new()
	root.name = GENERATED_ROOT
	add_child(root)
	var descriptors := _get_descriptors()
	var material := _build_material()

	if descriptors.is_empty():
		_is_generating = false
		_clear_named_child(GENERATED_ROOT)
		_emit_failure(
			ERR_CANT_CREATE,
			"Terrain layout produced no patches. Check island separation/spread.",
		)
		return

	var built_this_frame := 0

	for index: int in range(descriptors.size()):
		var result := _build_descriptor_patch(descriptors[index], material, index)
		if result != OK:
			_is_generating = false
			_clear_named_child(GENERATED_ROOT)
			return

		built_this_frame += 1
		if built_this_frame >= patches_per_frame and index < descriptors.size() - 1:
			built_this_frame = 0
			await get_tree().process_frame

	_set_generated_owners(root)
	_is_generating = false
	generation_completed.emit(descriptors.size())


func clear_preview() -> void:
	_clear_named_child(PREVIEW_ROOT)


func clear_generated() -> void:
	_clear_named_child(GENERATED_ROOT)


func _build_descriptor_patch(
	descriptor: Dictionary,
	material: Material,
	index: int,
) -> Error:
	var root := get_node_or_null(NodePath(String(GENERATED_ROOT))) as Node3D
	if root == null:
		return _emit_failure(ERR_UNCONFIGURED, "Generated terrain root disappeared.")

	var result := PatchBuilder.build_patch(
		profile,
		material,
		descriptor["position"],
		descriptor["scale"],
		descriptor["force_island"],
		0,
		true,
		true,
	)

	if result.get("error", FAILED) != OK:
		return _emit_failure(
			result.get("error", FAILED),
			"Terrain patch %d could not be built." % index,
		)

	var patch: Node3D = result["node"]
	patch.name = "TerrainPatch_%03d" % index
	patch.set_meta(&"terrain_patch_index", index)
	root.add_child(patch)
	patch_generated.emit(index, patch)
	return OK


func _get_descriptors() -> Array[Dictionary]:
	if layout == null:
		return [
			{
				"position": Vector3.ZERO,
				"scale": 1.0,
				"force_island": false,
			}
		]

	return layout.build_descriptors(profile.size)


func _build_material() -> Material:
	if material_profile != null:
		return material_profile.create_material(
			profile.minimum_expected_height(),
			profile.maximum_expected_height(),
		)

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.24, 0.38, 0.18)
	material.roughness = 1.0
	return material


func _build_preview_material() -> Material:
	if preview_uses_material:
		return _build_material()

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.33, 0.52, 0.24)
	material.roughness = 1.0
	return material


func _first_validation_error() -> String:
	for error: String in profile.get_validation_errors():
		return "Terrain profile: %s" % error

	if layout != null:
		for error: String in layout.get_validation_errors():
			return "Terrain layout: %s" % error

	if material_profile != null:
		for error: String in material_profile.get_validation_errors():
			return "Terrain material: %s" % error

	return ""


func _emit_failure(error: Error, message: String) -> Error:
	generation_failed.emit(error, message)
	NucleusLog.error(
		"%s (%s)" % [message, error_string(error)],
		&"Terrain",
	)
	return error


func _clear_named_child(child_name: StringName) -> void:
	var child := get_node_or_null(NodePath(String(child_name)))
	if child == null:
		return
	remove_child(child)
	child.queue_free()


func _set_generated_owners(root: Node) -> void:
	if not Engine.is_editor_hint() or get_tree().edited_scene_root == null:
		return

	_set_owner_recursive(root, get_tree().edited_scene_root)


func _set_owner_recursive(node: Node, owner: Node) -> void:
	node.owner = owner
	for child: Node in node.get_children():
		_set_owner_recursive(child, owner)


func _connect_resource(resource: Resource) -> void:
	if resource == null or resource.changed.is_connected(_on_resource_changed):
		return
	resource.changed.connect(_on_resource_changed)


func _disconnect_resource(resource: Resource) -> void:
	if resource == null or not resource.changed.is_connected(_on_resource_changed):
		return
	resource.changed.disconnect(_on_resource_changed)


func _on_resource_changed() -> void:
	update_configuration_warnings()
	_request_auto_preview()


func _request_auto_preview() -> void:
	if not Engine.is_editor_hint() or not auto_preview_on_change:
		return
	if _auto_preview_queued or not is_inside_tree():
		return
	_auto_preview_queued = true
	call_deferred("_run_auto_preview")


func _run_auto_preview() -> void:
	_auto_preview_queued = false
	refresh_preview()
