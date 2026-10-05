class_name NucleusPerformanceProfile
extends Resource
## Game-owned performance target and optional subsystem budgets.
##
## Zero means "not budgeted" for optional maxima. Nucleus only diagnoses
## thresholds the consuming game intentionally enables.

@export_category("Target")
@export var target_name: String = "Development 60 FPS"
@export_range(1, 360, 1) var target_fps: int = 60
@export_range(0.1, 1.0, 0.05) var frame_warning_ratio: float = 0.85
@export_range(1.0, 4.0, 0.05) var frame_critical_ratio: float = 1.0

@export_category("CPU")
@export_range(0.0, 100.0, 0.1, "or_greater")
var max_physics_ms: float = 0.0
@export_range(0.0, 100.0, 0.1, "or_greater")
var max_navigation_ms: float = 0.0

@export_category("Rendering")
@export_range(0, 100000, 1, "or_greater") var max_draw_calls: int = 0
@export_range(0, 1000000, 1, "or_greater") var max_render_objects: int = 0
@export_range(0, 1000000000, 1, "or_greater") var max_primitives: int = 0
@export_range(0.0, 65536.0, 1.0, "or_greater")
var max_video_memory_mb: float = 0.0
@export var warn_on_runtime_pipeline_compilation: bool = true

@export_category("Scene / Memory")
@export_range(0.0, 65536.0, 1.0, "or_greater")
var max_static_memory_mb: float = 0.0
@export_range(0, 1000000, 1, "or_greater") var max_node_count: int = 0
@export_range(-1, 100000, 1, "or_greater") var max_orphan_nodes: int = -1

@export_category("Physics 2D")
@export_range(0, 1000000, 1, "or_greater")
var max_physics_2d_active_objects: int = 0
@export_range(0, 1000000, 1, "or_greater")
var max_physics_2d_collision_pairs: int = 0

@export_category("Physics 3D")
@export_range(0, 1000000, 1, "or_greater")
var max_physics_3d_active_objects: int = 0
@export_range(0, 1000000, 1, "or_greater")
var max_physics_3d_collision_pairs: int = 0

@export_category("Navigation")
@export_range(0, 1000000, 1, "or_greater")
var max_navigation_2d_agents: int = 0
@export_range(0, 1000000, 1, "or_greater")
var max_navigation_3d_agents: int = 0


func frame_budget_ms() -> float:
	return 1000.0 / float(max(target_fps, 1))


func validate() -> PackedStringArray:
	var errors := PackedStringArray()

	if target_fps <= 0:
		errors.append("target_fps must be greater than zero.")
	if frame_warning_ratio <= 0.0:
		errors.append("frame_warning_ratio must be greater than zero.")
	if frame_critical_ratio < frame_warning_ratio:
		errors.append(
			"frame_critical_ratio must be greater than or equal to "
			+ "frame_warning_ratio."
		)
	if max_orphan_nodes < -1:
		errors.append("max_orphan_nodes must be -1 or greater.")

	return errors


func to_dictionary() -> Dictionary:
	return {
		"target_name": target_name,
		"target_fps": target_fps,
		"frame_budget_ms": frame_budget_ms(),
		"frame_warning_ratio": frame_warning_ratio,
		"frame_critical_ratio": frame_critical_ratio,
		"max_physics_ms": max_physics_ms,
		"max_navigation_ms": max_navigation_ms,
		"max_draw_calls": max_draw_calls,
		"max_render_objects": max_render_objects,
		"max_primitives": max_primitives,
		"max_video_memory_mb": max_video_memory_mb,
		"max_static_memory_mb": max_static_memory_mb,
		"max_node_count": max_node_count,
		"max_orphan_nodes": max_orphan_nodes,
		"max_physics_2d_active_objects": max_physics_2d_active_objects,
		"max_physics_2d_collision_pairs": max_physics_2d_collision_pairs,
		"max_physics_3d_active_objects": max_physics_3d_active_objects,
		"max_physics_3d_collision_pairs": max_physics_3d_collision_pairs,
		"max_navigation_2d_agents": max_navigation_2d_agents,
		"max_navigation_3d_agents": max_navigation_3d_agents,
		"warn_on_runtime_pipeline_compilation":
			warn_on_runtime_pipeline_compilation,
	}
