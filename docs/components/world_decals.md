# World Decals Contract

## Scope

This document covers:

```text
components/gameplay/decals
```

The subsystem currently exposes:

```text
NucleusSmartDecal3D
```

It is a scene-owned presentation component built on Godot's native `Decal`.

## Why this belongs in Nucleus

Runtime surface marks recur across many 3D game genres:

```text
bullet impacts
blood / slime
footprints
scorch marks
paint
damage marks
temporary interaction markers
environmental dirt
```

The reusable problem is not decal art or impact gameplay. It is reliable
placement against an arbitrary world-space point/normal, optional variation,
lifetime, and pooling behavior.

## Native Godot ownership

`NucleusSmartDecal3D` does not generate geometry.

Godot `Decal` projects textures inside its own AABB. This naturally allows one
projector to affect curved or irregular mesh geometry intersecting that volume.

The native projector travels from local `+Y` toward local `-Y`.

Nucleus therefore aligns:

```text
decal local +Y
        =
outward surface normal
```

so projection points into the hit surface.

## Placement

Use:

```gdscript
var error := decal.place_on_surface(
	hit_position,
	hit_normal,
)
```

A zero normal is rejected with `ERR_INVALID_PARAMETER`.

`surface_offset` moves the projector a small distance outward along the normal.
Keep this small; projection depth is controlled by native `Decal.size.y`.

## Surface semantics integration

SmartDecal deliberately does not choose its own texture from collision material.
When project presentation depends on semantic surface type, resolve that first:

```gdscript
var surface := NucleusSurfaceResolver3D.resolve_raycast(impact_ray)
var decal_scene := choose_impact_decal(surface)
var decal := decal_scene.instantiate() as NucleusSmartDecal3D

get_tree().current_scene.add_child(decal)
decal.place_on_surface(
	impact_ray.get_collision_point(),
	impact_ray.get_collision_normal(),
)
```

This keeps two reusable responsibilities independent:

```text
World Surfaces
    classify what was hit

SmartDecal
    align/display one already-selected mark
```

See [`world_surfaces.md`](world_surfaces.md) for the semantic surface contract.

## Tangent / roll control

For decals whose planar orientation matters, pass a world-space tangent hint:

```gdscript
decal.place_on_surface(
	hit_position,
	hit_normal,
	projectile_direction,
)
```

The tangent is projected onto the surface plane before building the decal basis.

With no tangent hint, Nucleus chooses a stable fallback axis that works for
floor, ceiling, wall, slope, and arbitrary curved-surface normals.

Optional random roll is applied around decal-local `Y`, so it does not disturb
surface alignment.

## Size variation

Random size variation intentionally changes only:

```text
Decal.size.x
Decal.size.z
```

It never randomizes:

```text
Decal.size.y
```

because `Y` is projection depth rather than visible planar decal size.

This is a deliberate improvement over Barebone's original SmartDecal behavior.

## Projection depth and angle rejection

For hard-surface impact marks:

- keep `size.y` only as deep as required to intersect the receiving surface;
- consider `normal_fade > 0` to reject surfaces facing too far away;
- consider low/zero `upper_fade` and `lower_fade` for tight hard-surface marks;
- use `cull_mask` to prevent a world decal from projecting onto nearby actors.

These are native Godot `Decal` controls and remain visible in the Inspector.

Nucleus does not wrap them in duplicate properties.

## Renderer limitations

Godot decals are supported by Forward+ and Mobile, not Compatibility.

The default Nucleus project uses Forward+.

Mobile also has tighter per-mesh decal limits, so projects targeting Mobile
should use shorter lifetimes/pooling and conservative decal density.

## Lifetime

`fade_after == 0` means no automatic expiration.

When enabled:

```text
visible delay
→ alpha fade
→ emission energy fade when present
→ expired signal
```

The emission fade matters because native `Decal.modulate.a` does not fade the
emission contribution.

## Pooling integration

A SmartDecal can contain or reference a `NucleusPoolable`.

When:

```text
release_poolable_on_expire = true
```

expiration asks the poolable to release its target instead of destroying the
scene.

`NucleusPoolable.acquired` resets SmartDecal visual state automatically.

If no active poolable accepts release, `free_on_expire` controls whether the
decal is freed or merely hidden.

This keeps pooling optional and local; there is no global decal manager.

## Baseline/reset behavior

SmartDecal captures its configured:

```text
size
modulate
emission_energy
```

as a reusable visual baseline.

`reset_visual_state()` restores that baseline.

`recapture_visual_baseline()` is available when a project intentionally changes
runtime defaults before reuse.

## What SmartDecal does not own

Not included:

```text
physics raycasts
surface classification rules
damage rules
impact audio
particle spawning
decal texture selection
global decal limits
global decal manager
```

`NucleusSurfaceResolver3D` can provide optional semantic classification. The
project still decides which decal/content corresponds to that semantic profile.
