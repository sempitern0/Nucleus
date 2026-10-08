# Rendering Quality and Asset Hygiene

Target engine: Godot 4.7.x.

Nucleus does not replace Godot's texture importer, materials, shaders, mesh LOD,
visibility ranges, or renderer.

This layer covers four recurring integration problems:

```text
texture import settings that deserve review
duplicated ShaderMaterial variants
per-instance scalar/vector material variation
runtime material / geometry presentation tiers
```

## Public types

Development / diagnostics:

```text
NucleusTextureBudgetProfile
NucleusTextureAudit
NucleusRenderAudit
```

Runtime presentation:

```text
NucleusMaterialInstanceBinding3D
NucleusMaterialQualityProfile3D
NucleusMaterialQualityController3D
NucleusGeometryQualityProfile3D
NucleusGeometryQualityController3D
```

## Texture audit

`NucleusTextureAudit` is explicit development tooling.

It never reimports or rewrites assets.

Use a narrow list when the project already knows which textures belong to a
feature:

```gdscript
var diagnostics := NucleusTextureAudit.inspect_paths(
	PackedStringArray([
		"res://characters/player/body_albedo.png",
		"res://characters/player/body_normal.png",
	]),
	budget,
	true,
)
```

Or scan a development directory explicitly:

```gdscript
var diagnostics := NucleusTextureAudit.inspect_directory(
	"res://assets/environment",
	budget,
	true,
)
```

The audit reviews:

```text
large dimensions
missing mipmaps for 3D usage
high-memory import compression modes
possible normal maps with normal-map detection disabled
```

### Dimension thresholds are review thresholds

A 4K texture is not automatically wrong.

Examples where high resolution may be valid:

```text
hero character close-up
large unique architectural surface
high-quality photo/reference presentation
UI or offline capture asset with different constraints
```

The diagnostic exists to force a texel-density decision, not to impose a
universal maximum.

`NucleusTextureAudit.estimate_rgba8_bytes()` reports an uncompressed RGBA8
baseline estimate. It is not a promise of actual GPU allocation because imported
compression, format, platform and streaming policy can change real VRAM use.

### Mipmaps

Mipmaps generally improve distant 3D texture sampling and reduce aliasing, at the
cost of additional texture memory.

Nucleus reports missing 3D mipmaps but does not enable them automatically because
some pixel-art, data, mask, or specialized shader assets may be intentional
exceptions.

### Compression

For ordinary 3D color/normal/material textures, GPU-friendly compression is
normally worth reviewing.

The audit treats these as the common low-memory 3D modes:

```text
VRAM Compressed
Basis Universal
```

It does not automatically convert:

```text
Lossless
Lossy
VRAM Uncompressed
```

because quality/platform requirements belong to the project.

## Per-instance shader parameters

If several objects share the same shader/material and only vary values such as:

```text
team color
wetness
damage amount
snow amount
wind phase
dissolve amount
highlight intensity
```

prefer a shader `instance uniform` where possible.

Example shader:

```glsl
shader_type spatial;

instance uniform vec4 damage_tint : source_color = vec4(1.0);

void fragment() {
	ALBEDO = damage_tint.rgb;
}
```

Scene/runtime code:

```gdscript
material_binding.set_parameter(
	&"damage_tint",
	Color(1.0, 0.3, 0.3),
)
```

`NucleusMaterialInstanceBinding3D` validates the parameter name by default and
accepts only the scalar/vector-style values supported by the intended instance
uniform contract:

```text
bool
int
float
Vector2
Vector3
Vector4
Color
```

Textures and arrays stay material-owned.

## Material quality

`NucleusMaterialQualityProfile3D` exposes:

```text
MINIMAL
REDUCED
FULL
```

Each tier can provide a `material_override`.

A null tier material means:

```text
restore the target's authored material_override
```

This makes a useful pattern:

```text
FULL
    null
    → authored production material

REDUCED
    cheaper shader/material

MINIMAL
    very cheap shader/material
```

The controller captures and restores the original override.

It does not mutate mesh surface materials.

### Good material-tier differences

Examples:

```text
FULL
    detail normal
    secondary procedural noise
    parallax
    expensive rim/subsurface/custom lighting

REDUCED
    base normal + ORM
    fewer procedural terms

MINIMAL
    albedo + roughness
    no expensive secondary effects
```

The actual shaders/materials remain project-owned art content.

## Geometry quality

`NucleusGeometryQualityProfile3D` uses native `GeometryInstance3D` controls.

It can:

```text
scale authored lod_bias
cap visibility_range_end
disable shadow casting in selected tiers
```

The controller always records the authored baseline first.

Example:

```text
FULL
    original state

REDUCED
    LOD bias × 0.75
    shadows preserved

MINIMAL
    LOD bias × 0.50
    optional distance cap
    shadows disabled
```

A zero visibility cap preserves the authored range.

If the authored range is unlimited and a tier supplies a cap, the cap becomes the
runtime end distance.

## Transparency audit

`NucleusRenderAudit` reports scenes with many known transparent mesh instances.

It detects:

```text
GeometryInstance3D.transparency > 0
BaseMaterial3D transparency modes
```

Custom ShaderMaterial transparency cannot be classified safely from arbitrary
shader code, so the audit does not pretend to know it.

Treat the diagnostic as an investigation trigger for:

```text
overdraw
sorting
alpha-blended foliage
large transparent surfaces
mostly opaque materials with small alpha regions
```

Prefer alpha scissor or opaque separation only where the art allows it.

## ShaderMaterial variant audit

The render audit also groups `ShaderMaterial` resources by their shared `Shader`.

If many distinct materials share one shader, Nucleus reports an opportunity to
review whether the variations could become per-instance uniforms.

This is not an automatic error.

Separate materials remain correct when they differ by:

```text
textures
render modes
feature branches
surface semantics
material-specific resources
```

## Low-end strategy

A low-quality product mode can compose:

```text
Texture import policy
    smaller authored/import-limited assets where appropriate

MaterialQuality
    simpler shading

GeometryQuality
    earlier native LOD
    shorter visibility
    fewer shadows

AnimationQuality
    fewer optional modifiers
    lower non-critical pose evaluation cadence

Rendering settings
    render scale
    shadow atlas/settings
    antialiasing
    renderer-specific features
```

Do not sacrifice gameplay simulation correctness to solve a presentation
bottleneck.

## Performance validation

The correct loop remains:

```text
representative workload
→ NucleusPerformanceSampler / Godot profiler
→ structural audit
→ one bounded quality/import change
→ repeat the same workload
→ compare
```

An audit finding is evidence to inspect, not proof that the asset is wrong.
