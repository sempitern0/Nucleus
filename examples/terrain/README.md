# Terrain examples

These scenes are intentionally small and independent of external demo heightmaps.

## Preview scenes

Open these in the editor:

```text
terrain_preview.tscn
    one cheap island preview using the normal generator preview path

terrain_preview_presets.tscn
    four reusable profile presets shown side by side as low-resolution previews
```

Preview nodes are temporary and do not create collision or LOD data. Use them to
iterate on silhouette, noise frequency, height range, coastline, and material
bands before generating final terrain.

## Runnable scenes

Run with F6:

```text
terrain_single.tscn
terrain_grid.tscn
terrain_linear.tscn
terrain_islands.tscn
terrain_material_layers.tscn
terrain_streaming.tscn
```

`terrain_streaming.tscn` is the runtime streaming demo. An orange tracked marker
moves along +Z. The camera follows from behind and the HUD shows:

```text
current chunk index
loaded chunk indices/count
pending build count
tracked world Z
```

Chunks ahead appear incrementally and chunks left behind are freed.

## Visual material check

`terrain_material_layers.tscn` uses four tiny repeating textures:

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

## Presets

Reusable starting profiles live under:

```text
res://modules/terrain/presets/
```

The preview gallery uses:

```text
gentle_hills.tres
lowlands.tres
rugged_mountains.tres
archipelago_island.tres
```

Duplicate a preset into game-owned content before tuning it.

## Performance notes

When the camera approaches a generated patch, Godot selects the base mesh
instead of reduced LOD index buffers. More triangles near the camera are
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
