class_name NucleusRenderAudit
extends RefCounted
## Development-time structural audit for common 3D rendering cost patterns.
##
## The audit never mutates scene state. It reports candidates that should be
## verified with NucleusPerformanceSampler and Godot's native rendering tools.


static func inspect(
	root: Node,
	repeated_instance_threshold: int = 8,
	shadow_caster_threshold: int = 64,
	unbounded_visibility_threshold: int = 96,
) -> Array[NucleusPerformanceDiagnostic]:
	var diagnostics: Array[NucleusPerformanceDiagnostic] = []
	if root == null:
		return diagnostics

	var mesh_groups: Dictionary[String, int] = {}
	var mesh_instances: int = 0
	var shadow_casters: int = 0
	var unbounded_visibility: int = 0

	for node: Node in NucleusNodeUtils.descendants(root, true):
		if not node is MeshInstance3D:
			continue

		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh == null:
			continue

		mesh_instances += 1
		var signature := _mesh_signature(mesh_instance)
		mesh_groups[signature] = int(mesh_groups.get(signature, 0)) + 1

		if (
			mesh_instance.cast_shadow
			!= GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		):
			shadow_casters += 1

		if mesh_instance.visibility_range_end <= 0.0:
			unbounded_visibility += 1

	var largest_group: int = 0
	for count_value: Variant in mesh_groups.values():
		largest_group = maxi(largest_group, int(count_value))

	if largest_group >= maxi(repeated_instance_threshold, 2):
		diagnostics.append(
			NucleusPerformanceDiagnostic.build(
				NucleusPerformanceDiagnostic.Severity.INFO,
				&"render_audit_repeated_instances",
				"Repeated mesh instances detected",
				"One mesh/material signature is rendered by many MeshInstance3D nodes.",
				PackedStringArray([
					"Largest repeated group: %d" % largest_group,
					"Audited mesh instances: %d" % mesh_instances,
				]),
				PackedStringArray([
					"Measure draw calls before changing scene structure.",
					"Consider MultiMesh only for presentation that can share draw state.",
					"Keep interactive or independently animated objects as normal nodes.",
				]),
			)
		)

	if shadow_casters >= maxi(shadow_caster_threshold, 1):
		diagnostics.append(
			NucleusPerformanceDiagnostic.build(
				NucleusPerformanceDiagnostic.Severity.INFO,
				&"render_audit_shadow_casters",
				"Many mesh instances cast shadows",
				"Shadow-capable geometry can multiply depth and lighting work.",
				PackedStringArray([
					"Shadow-casting mesh instances: %d" % shadow_casters,
					"Audited mesh instances: %d" % mesh_instances,
				]),
				PackedStringArray([
					"Inspect shadow cost with the target renderer and lights.",
					"Disable shadows only where they are not visually required.",
				]),
			)
		)

	if unbounded_visibility >= maxi(unbounded_visibility_threshold, 1):
		diagnostics.append(
			NucleusPerformanceDiagnostic.build(
				NucleusPerformanceDiagnostic.Severity.INFO,
				&"render_audit_unbounded_visibility",
				"Many mesh instances have no visibility range end",
				"Large scenes may benefit from authored visibility ranges or LOD policy.",
				PackedStringArray([
					"Unbounded mesh instances: %d" % unbounded_visibility,
					"Audited mesh instances: %d" % mesh_instances,
				]),
				PackedStringArray([
					"Use native visibility ranges only where distance culling is valid.",
					"Prefer native mesh LOD before introducing custom LOD infrastructure.",
				]),
			)
		)

	return diagnostics


static func _mesh_signature(instance: MeshInstance3D) -> String:
	var mesh_key := _resource_key(instance.mesh)
	var material_key := _resource_key(instance.material_override)
	return "%s|%s" % [mesh_key, material_key]


static func _resource_key(resource: Resource) -> String:
	if resource == null:
		return "none"
	if not resource.resource_path.is_empty():
		return resource.resource_path
	return "instance:%d" % resource.get_instance_id()
