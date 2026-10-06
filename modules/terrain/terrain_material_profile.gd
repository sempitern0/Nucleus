@tool
class_name NucleusTerrainMaterialProfile
extends Resource
## Reusable material policy for generated terrain patches.

enum DebugView {
	MATERIAL,
	HEIGHT_BANDS,
	SLOPE,
	NORMALS,
	LAYER_WEIGHTS,
	WORLD_GRID,
}

const DEFAULT_SHADER := preload(
	"res://modules/terrain/shaders/layered_terrain.gdshader"
)

@export_enum("Top projection", "Triplanar")
var projection_mode: int = 0
@export var base_color: Color = Color(0.24, 0.38, 0.18, 1.0)
@export var layers: Array[NucleusTerrainTextureLayer] = []
@export var custom_material: Material


func create_material(
	minimum_height: float,
	maximum_height: float,
	debug_view: int = DebugView.MATERIAL,
	debug_height_bands: int = 6,
	debug_grid_scale: float = 10.0,
) -> Material:
	if custom_material != null and debug_view == DebugView.MATERIAL:
		return custom_material

	var material := ShaderMaterial.new()
	material.shader = DEFAULT_SHADER
	material.set_shader_parameter("base_color", base_color)
	material.set_shader_parameter("height_min", minimum_height)
	material.set_shader_parameter("height_max", maximum_height)
	material.set_shader_parameter("use_triplanar", projection_mode == 1)
	material.set_shader_parameter("debug_view", debug_view)
	material.set_shader_parameter("debug_height_bands", maxi(2, debug_height_bands))
	material.set_shader_parameter("debug_grid_scale", maxf(0.1, debug_grid_scale))

	for index: int in range(4):
		_apply_layer(material, index)

	return material


func get_active_layer_count() -> int:
	var count := 0

	for layer: NucleusTerrainTextureLayer in layers:
		if layer != null and layer.enabled:
			count += 1

	return count


func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()

	if layers.size() > 4:
		errors.append("The built-in terrain material supports at most four layers.")

	for index: int in range(layers.size()):
		var layer := layers[index]

		if layer == null:
			errors.append("layers[%d] is null." % index)
			continue

		for error: String in layer.get_validation_errors():
			errors.append("layers[%d]: %s" % [index, error])

	return errors


func _apply_layer(material: ShaderMaterial, index: int) -> void:
	var prefix := "layer%d_" % index
	var layer: NucleusTerrainTextureLayer = (
		layers[index]
		if index < layers.size()
		else null
	)

	if layer == null or not layer.enabled:
		material.set_shader_parameter(prefix + "enabled", false)
		return

	material.set_shader_parameter(prefix + "enabled", true)
	material.set_shader_parameter(prefix + "use_texture", layer.albedo != null)
	material.set_shader_parameter(prefix + "albedo", layer.albedo)
	material.set_shader_parameter(prefix + "tint", layer.tint)
	material.set_shader_parameter(prefix + "uv_scale", layer.uv_scale)
	material.set_shader_parameter(prefix + "height_range", layer.height_range)
	material.set_shader_parameter(prefix + "slope_range", layer.slope_range)
	material.set_shader_parameter(prefix + "softness", layer.blend_softness)
	material.set_shader_parameter(prefix + "roughness", layer.roughness)
	material.set_shader_parameter(prefix + "metallic", layer.metallic)
