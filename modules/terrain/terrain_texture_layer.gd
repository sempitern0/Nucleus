@tool
class_name NucleusTerrainTextureLayer
extends Resource
## One procedural terrain material layer blended by height and surface slope.

@export var enabled: bool = true
@export var albedo: Texture2D
@export var tint: Color = Color.WHITE
@export_range(0.001, 1000.0, 0.001, "or_greater")
var uv_scale: float = 0.08
@export var height_range: Vector2 = Vector2(0.0, 1.0)
@export var slope_range: Vector2 = Vector2(0.0, 1.0)
@export_range(0.001, 0.5, 0.001)
var blend_softness: float = 0.08
@export_range(0.0, 1.0, 0.01)
var roughness: float = 0.9
@export_range(0.0, 1.0, 0.01)
var metallic: float = 0.0


func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()

	if height_range.x > height_range.y:
		errors.append("height_range minimum must not exceed its maximum.")

	if slope_range.x > slope_range.y:
		errors.append("slope_range minimum must not exceed its maximum.")

	return errors
