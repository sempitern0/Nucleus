# Rendering Quality Quickstart

Use this guide for texture/material hygiene and reusable low-end 3D presentation
tiers.

Canonical contract:

```text
docs/components/rendering_quality.md
```

Hands-on:

```text
docs/guides/tutorials/material_texture_optimization_3d.md
```

## 1. Audit textures without mutating them

Create a `NucleusTextureBudgetProfile` appropriate for the project.

Example development thresholds:

```text
review at 2048
strong review at 4096
```

Then inspect a relevant directory or explicit path list.

Review diagnostics for:

```text
dimensions
mipmaps
compression
normal-map import intent
```

Do not bulk-reimport solely because an audit fired.

## 2. Share materials where possible

Before duplicating a `ShaderMaterial` to change one number/color, ask whether the
shader can use an `instance uniform`.

Use:

```text
NucleusMaterialInstanceBinding3D
```

for runtime values such as tint, wetness, damage, wind phase, dissolve, or other
scalar/vector presentation data.

## 3. Create material quality tiers

Create:

```text
NucleusMaterialQualityProfile3D
```

Typical policy:

```text
Full
    null → keep authored material

Reduced
    reduced-cost material

Minimal
    cheapest acceptable material
```

Add a `NucleusMaterialQualityController3D` to the
`GeometryInstance3D` that should switch tier.

## 4. Add native geometry quality

Create:

```text
NucleusGeometryQualityProfile3D
```

Tune:

```text
LOD bias scales
optional visibility caps
shadow disabling
```

Use a `NucleusGeometryQualityController3D` on the same or another
`GeometryInstance3D`.

Keep hero/local-player geometry more conservative than distant environment/crowd
geometry when product quality requires it.

## 5. Audit scene material patterns

Run:

```gdscript
var findings := NucleusRenderAudit.inspect(root)
```

The audit can now flag:

```text
repeated meshes
many shadow casters
unbounded visibility
many ShaderMaterial variants sharing one Shader
known transparent instances
```

Measure before restructuring scenes.

## 6. Map product presets

Nucleus does not introduce another global graphics manager.

A game can map its existing settings:

```text
Low
    Material MINIMAL
    Geometry MINIMAL

Medium
    Material REDUCED
    Geometry REDUCED

High / Ultra
    Material FULL
    Geometry FULL
```

Different actor categories can use different mappings.

## 7. Validate low quality as a real shipping mode

Test Low on representative weak hardware.

Check:

```text
material readability
LOD transitions
shadow readability
visibility popping
texture quality
VRAM
draw calls
GPU time
CPU frame time
```

The objective is not merely "lower settings". It is a version of the game that
remains readable, responsive and intentionally art-directed.
