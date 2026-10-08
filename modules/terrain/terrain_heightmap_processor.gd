class_name NucleusTerrainHeightmapProcessor
extends RefCounted
## Deterministic preprocessing helpers for heightfield source images.
##
## Processing is explicit and non-destructive: every operation returns a new
## Image. Use this during world generation/loading, not as a per-frame effect.


static func transformed(
	source: Image,
	quarter_turns: int = 0,
	mirror_x: bool = false,
	mirror_y: bool = false,
) -> Image:
	var working := _editable_copy(source)

	if working == null:
		return null

	var turns := ((quarter_turns % 4) + 4) % 4

	for _turn: int in range(turns):
		working = _rotate_clockwise(working)

	if mirror_x:
		working.flip_x()

	if mirror_y:
		working.flip_y()

	return working


static func prefilter_for_resolution(
	source: Image,
	terrain_resolution: int,
	restore_source_dimensions: bool = true,
) -> Image:
	if source == null or source.is_empty():
		return null

	var sample_limit := maxi(2, terrain_resolution + 1)
	return prefilter_to_sample_limit(
		source,
		sample_limit,
		restore_source_dimensions,
	)


static func prefilter_to_sample_limit(
	source: Image,
	maximum_dimension: int,
	restore_source_dimensions: bool = true,
) -> Image:
	var working := _editable_copy(source)

	if working == null:
		return null

	var source_size := Vector2i(
		working.get_width(),
		working.get_height(),
	)
	var target_size := _fit_within(
		source_size,
		maxi(2, maximum_dimension),
	)

	if target_size == source_size:
		return working

	working.resize(
		target_size.x,
		target_size.y,
		Image.INTERPOLATE_LANCZOS,
	)

	if restore_source_dimensions:
		working.resize(
			source_size.x,
			source_size.y,
			Image.INTERPOLATE_CUBIC,
		)

	return working


static func texture_prefiltered_for_resolution(
	source: Texture2D,
	terrain_resolution: int,
	restore_source_dimensions: bool = true,
) -> ImageTexture:
	if source == null:
		return null

	var source_image := source.get_image()
	var processed := prefilter_for_resolution(
		source_image,
		terrain_resolution,
		restore_source_dimensions,
	)

	if processed == null:
		return null

	return ImageTexture.create_from_image(processed)


static func suggested_sample_limit(
	source_size: Vector2i,
	terrain_resolution: int,
) -> Vector2i:
	if source_size.x <= 0 or source_size.y <= 0:
		return Vector2i.ZERO

	return _fit_within(
		source_size,
		maxi(2, terrain_resolution + 1),
	)


static func _editable_copy(source: Image) -> Image:
	if source == null or source.is_empty():
		return null

	var working := source.duplicate()

	if working.is_compressed():
		var decompress_error: Error = working.decompress()

		if decompress_error != OK:
			return null

	return working


static func _fit_within(
	source_size: Vector2i,
	maximum_dimension: int,
) -> Vector2i:
	var largest := maxi(source_size.x, source_size.y)

	if largest <= maximum_dimension:
		return source_size

	var factor := float(maximum_dimension) / float(largest)
	return Vector2i(
		maxi(2, int(round(float(source_size.x) * factor))),
		maxi(2, int(round(float(source_size.y) * factor))),
	)


static func _rotate_clockwise(source: Image) -> Image:
	var target := Image.create_empty(
		source.get_height(),
		source.get_width(),
		false,
		source.get_format(),
	)

	for source_y: int in range(source.get_height()):
		for source_x: int in range(source.get_width()):
			target.set_pixel(
				source.get_height() - 1 - source_y,
				source_x,
				source.get_pixel(source_x, source_y),
			)

	return target
