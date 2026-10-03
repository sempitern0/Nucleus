class_name NucleusWindow
extends RefCounted
## Stateless helpers for viewport and desktop-window calculations.
##
## This replaces the pure portions of Barebone's WindowManager without adding
## another globally stateful Autoload.


## Returns the visible size of a viewport.
static func get_viewport_size(viewport: Viewport) -> Vector2:
	if viewport == null:
		return Vector2.ZERO

	return viewport.get_visible_rect().size


## Returns the center point of a viewport in viewport coordinates.
static func get_viewport_center(viewport: Viewport) -> Vector2:
	return get_viewport_size(viewport) * 0.5


## Returns the viewport width divided by its height.
static func get_viewport_aspect_ratio(viewport: Viewport) -> float:
	var viewport_size: Vector2 = get_viewport_size(viewport)

	if is_zero_approx(viewport_size.y):
		return 0.0

	return viewport_size.x / viewport_size.y


## Returns the viewport center transformed into the CanvasItem's local canvas.
static func get_viewport_center_in_canvas(canvas_item: CanvasItem) -> Vector2:
	if canvas_item == null:
		return Vector2.ZERO

	var viewport: Viewport = canvas_item.get_viewport()
	var viewport_center: Vector2 = get_viewport_center(viewport)

	return canvas_item.get_canvas_transform().affine_inverse() * viewport_center


## Returns mouse displacement from viewport center normalized to [-1, 1]-like
## screen-relative coordinates independent from the current resolution.
static func get_relative_mouse_position(viewport: Viewport) -> Vector2:
	if viewport == null:
		return Vector2.ZERO

	var viewport_size: Vector2 = get_viewport_size(viewport)
	var largest_dimension: float = maxf(viewport_size.x, viewport_size.y)

	if is_zero_approx(largest_dimension):
		return Vector2.ZERO

	var mouse_offset: Vector2 = viewport.get_mouse_position() - viewport_size * 0.5

	return mouse_offset / largest_dimension


## Returns the center of the usable area of a physical display.
static func get_display_center(
	screen: int = DisplayServer.SCREEN_OF_MAIN_WINDOW,
) -> Vector2i:
	var usable_rect: Rect2i = DisplayServer.screen_get_usable_rect(screen)

	@warning_ignore("integer_division")
	return usable_rect.position + usable_rect.size / 2


## Centers a desktop window inside the usable area of a display.
static func center_window(
	window: Window,
	screen: int = DisplayServer.SCREEN_OF_MAIN_WINDOW,
) -> void:
	if window == null:
		return

	var usable_rect: Rect2i = DisplayServer.screen_get_usable_rect(screen)
	var window_size: Vector2i = window.get_size_with_decorations()

	@warning_ignore("integer_division")
	window.position = usable_rect.position + (usable_rect.size - window_size) / 2
