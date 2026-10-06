# Terrain examples

These scenes are intentionally small and independent of external demo assets.

## Visual checks

`terrain_material_layers.tscn` is the reference scene for the built-in layered
terrain material. It uses four tiny repeating textures:

```text
low elevation      sand
mid elevation      grass
steep/mid-high     rock
highest elevation  snow
```

The example uses **Top projection** and disables terrain shadows so the material
can be inspected on low-end integrated GPUs without making triplanar sampling or
shadow rendering part of the baseline cost.

Switch `NucleusTerrainMaterialProfile.projection_mode` to `Triplanar` when you
want to verify cliff projection quality.

## Performance notes

When the camera approaches a generated patch, Godot selects the base mesh
instead of the reduced LOD index buffers. More triangles near the camera are
therefore expected.

For weak integrated GPUs, start with:

```text
resolution = 48 to 64
lod_levels = 2
Top projection
2 to 4 small terrain layers
terrain shadows disabled while tuning
collision debug visualization disabled unless needed
```

Raise one cost at a time and profile the consuming game rather than the example.
