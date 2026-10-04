# Nucleus Ecosystem — Future Plugin Horizon

These systems are intentionally planned as separate plugins/products.

They should be able to integrate with Nucleus, but Nucleus must not depend on
them.

---

# Day / Night + Environment Plugin

Barebone already contained a substantial day/night implementation with:

```text
time progression
day zones
day/hour/minute signals
sun configuration
sky configuration
multiple environment presets
sky shader resources
```

The future version should be re-audited rather than ported directly.

## Desired direction

Separate:

```text
simulation clock
celestial lighting
sky/environment presentation
weather hooks
gameplay time events
```

Potential integration with Nucleus:

```text
SaveSession
Settings
Localization for displayed time
optional EventBus
Attributes/Status only through game-owned adapters
```

The plugin should work without requiring Nucleus-specific gameplay systems.

---

# Planet Generator Plugin

Barebone contains procedural planet work under:

```text
components/3D/space/planets/
```

including a procedural planet body shader.

Treat this as a specialized rendering/procedural-content plugin.

## Reanalysis goals

Investigate:

```text
planet mesh topology
LOD strategy
seam handling
noise layering
biome/material generation
atmosphere
ocean/cloud layers
collision
editor preview
runtime generation cost
large-scale coordinate concerns
saveable seeds/configurations
```

Do not merge this into generic Nucleus world generation.

---

# Terrainy

Barebone Terrainy is already an editor plugin whose stated purpose is fast
natural-looking terrain generation without requiring manual painting.

That product direction should be preserved.

Terrainy should not try to become Terrain3D.

## Product goal

Terrainy should answer:

> I need a professional, attractive, optimized terrain quickly, and I do not
> need a full manual terrain-authoring suite.

Desired workflow:

```text
Add Terrainy
→ choose biome/preset
→ choose size/quality target
→ adjust a small set of meaningful controls
→ Generate
→ immediately obtain playable terrain
```

Advanced controls may exist, but quickstart quality is the primary product.

## Areas for a future deep audit

### Generation

```text
multi-octave height generation
domain warping
erosion approximations / optional erosion pass
plateau/ridge/valley controls
coast/island shaping
deterministic seeds
biome masks
```

### Surface quality

```text
slope/height-based material blending
triplanar options
macro variation
normal detail
distance detail strategy
texture-array workflow
```

### Optimization

```text
chunk generation
LOD
seam-safe chunk borders
collision LOD
visibility ranges
MultiMesh vegetation
background generation
editor bake versus runtime generation
Web/low-end quality presets
```

### Editor UX

```text
live preview with throttling
Generate / Regenerate controls
undo/redo
presets
seed lock
quality profiles
progress/cancel
non-destructive settings
clear diagnostics
```

### Environment composition

Terrainy may later expose optional hooks for:

```text
vegetation scattering
rocks/props
water placement
navigation preparation
spawn masks
Day/Night environment integration
```

These should remain adapters, not hard dependencies.

## Relationship to Terrain3D

Terrain3D and similar tools solve a broader authoring problem.

Terrainy's differentiator should be:

```text
speed
procedural defaults
few decisions to reach good quality
editor-first workflow
strong optimization presets
```

not matching every manual sculpt/paint feature.

---

# Plugin boundary rule

A plugin may depend on Godot and optionally integrate with Nucleus through
adapters.

Nucleus Core must never depend back on:

```text
Terrainy
Day/Night
Planet Generator
```

This keeps the base template small, directionally clean, and useful across
projects that never need those systems.
