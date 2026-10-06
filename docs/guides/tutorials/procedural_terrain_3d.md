# Tutorial: build a procedural island chain and streaming route

This tutorial turns the Terrainy-style workflow into a reusable Nucleus setup.

You will build:

```text
one reusable height profile
one four-layer procedural material
an editor preview
an eight-island archipelago
an optional linear runtime streamer
heightmap collisions cheaper than the visual mesh
```

## 1. Create the scene shell

```text
OceanWorld : Node3D
├── Terrain : NucleusTerrainGenerator3D
├── Ocean : MeshInstance3D
└── Player : CharacterBody3D
```

Keep ocean/water policy outside the terrain module. Nucleus terrain only needs
to know where its coastline descends.

Place the ocean surface at:

```text
Y = 0
```

## 2. Build the island height profile

Create `island_profile.tres` as `NucleusTerrainProfile`.

Recommended first values:

```text
size = (320, 320)
resolution = 96
base_height = -2
height_scale = 70
edge_floor_height = -24
collision_mode = HEIGHTMAP
collision_resolution = 40
collision_holes_below_height = true
collision_hole_height = -2
lod_levels = 2
lod_distance_step = 140
```

Create a FastNoiseLite resource:

```text
noise_type = Simplex Smooth
frequency ≈ 0.004–0.012
fractal_octaves = 4–6
```

Assign it to:

```text
height_source = FAST_NOISE
noise = <resource>
```

The exact frequency depends on your world scale. Large islands generally need a
lower frequency than small hills.

## 3. Make the coastline irregular

Create a second FastNoiseLite with a somewhat higher frequency and assign:

```text
shoreline_noise
shoreline_noise_strength = 0.08–0.16
```

Then set:

```text
island_inner_radius = 0.50
island_falloff = 0.35
island_power = 1.5
```

The shoreline noise changes the radial boundary, not the mountain noise itself.
This makes it easier to tune coast shape separately from inland relief.

## 4. Preview cheaply

Assign the profile to `Terrain`.

Set:

```text
preview_resolution = 24
```

Press **Refresh Preview**.

Change noise frequency, height scale, elevation curve, shoreline settings, and
refresh the preview until the silhouette is useful.

Do not generate final collision while exploring shape.

## 5. Build a procedural material

Create `island_material.tres` as `NucleusTerrainMaterialProfile`.

Set:

```text
projection_mode = Triplanar
```

Create four `NucleusTerrainTextureLayer` resources:

### Sand

```text
height_range = (0.0, 0.25)
slope_range = (0.0, 0.50)
roughness = 0.85
```

### Grass

```text
height_range = (0.15, 0.70)
slope_range = (0.0, 0.45)
roughness = 0.95
```

### Cliff rock

```text
height_range = (0.0, 1.0)
slope_range = (0.30, 1.0)
roughness = 0.90
```

### High rock / snow

```text
height_range = (0.68, 1.0)
slope_range = (0.0, 1.0)
roughness = 0.80
```

Assign albedo textures if available. Tint-only layers also work while
prototyping.

If target hardware struggles, switch the material to **Top projection** before
reducing terrain geometry. Pixel shader cost and vertex cost are different
budgets.

## 6. Scatter an archipelago

Create `archipelago_layout.tres` as `NucleusTerrainLayout`:

```text
mode = ISLANDS
island_count = 8
island_spread = (2600, 2600)
island_scale_range = (0.55, 1.35)
island_min_separation = 120
seed = 2026
```

Assign it to `Terrain` and refresh preview.

The same seed produces the same placement.

If fewer islands appear than requested, the placement constraints do not fit in
the configured spread. Increase `island_spread`, lower separation, or reduce
island size/count.

## 7. Generate the final archipelago

Press **Generate Terrain**.

The module creates one MeshInstance3D per island. This gives Godot separate AABBs
for frustum culling instead of forcing the whole world into one render object.

Each island also receives a `HeightMapShape3D` collision grid at the lower
collision resolution.

Walk or sail around the result and inspect:

```text
Profiler frame time
Rendering draw calls / primitives
Physics 3D activity
Video RAM
```

Then tune the profile for the actual target hardware.

## 8. Use a heightmap instead of noise

To preserve a known landform:

```text
height_source = HEIGHTMAP
image = <heightmap Texture2D>
normalize_heightmap = true
image_mapping = STRETCH_TO_PATCH
```

The same layout, collision, LOD, preview, and material pipeline remains valid.

For generic grayscale noise textures use:

```text
height_source = IMAGE
```

Use `WORLD_REPEAT` only when a texture should tile continuously across multiple
patches.

## 9. Add a linear runtime route

For a project that moves continuously along one axis, disable/remove the static
generator and add:

```text
TerrainStream : NucleusTerrainStreamer3D
```

Assign the same profile and material, then:

```text
tracked_node = Player
axis = Z
chunks_behind = 2
chunks_ahead = 4
max_new_chunks_per_update = 1
update_interval = 0.25
```

This is appropriate for long traversal, runners, rail-like routes, or tests
where only a moving strip must exist.

It is not a general infinite-world clipmap. If the project proves it needs a
huge omnidirectional open world, that is evidence for a more specialized
terrain system.

## 10. Low-PC configuration pass

Try this before replacing the module:

```text
visual resolution: 64–96
collision resolution: 24–40
LOD levels: 2
patch size: 256–384
projection: Top
cast shadows: disable on terrain if art direction allows
runtime builds: 1 patch per frame/update
```

Then increase one budget at a time.

Do not assume a 256-cell patch is acceptable merely because generation succeeds
on the development PC.

## Terrainy differences

The Nucleus version deliberately changes several behaviors:

```text
Terrainy threads + deferred SurfaceTool pipeline
    → direct ArrayMesh build + frame-budgeted multi-patch generation

trimesh collision by default
    → HeightMapShape3D by default

node dictionary of MeshInstance -> config
    → reusable profile + layout resources

radial flag mixed into terrain config
    → explicit island shaping + island world layout

single terrain material reference
    → optional procedural four-layer material profile or custom material

procedural renderer owns Terrainy node
    → independent scene-owned linear streamer
```

The goal is not to preserve Terrainy's API. The goal is to preserve its useful
workflow while fitting Nucleus ownership and performance rules.

## What remains game-specific

Keep these outside the generic module until a real game proves a reusable
contract:

```text
ocean rendering and buoyancy
biome simulation
foliage/object distribution
roads and rivers
erosion simulation
save format for generated worlds
network replication of procedural seeds
navigation bake policy
runtime terrain deformation
```

For Nautica, the natural next layer is to consume terrain height/coast data from
the generated profile when placing vegetation, settlements, reefs, or gameplay
POIs, rather than adding manual paint infrastructure to the terrain core.

## Reference scenes

The repository includes small executable examples for each layout and preview
workflow described in this tutorial:

```text
res://examples/terrain/terrain_preview.tscn
res://examples/terrain/terrain_single.tscn
res://examples/terrain/terrain_grid.tscn
res://examples/terrain/terrain_linear.tscn
res://examples/terrain/terrain_islands.tscn
res://examples/terrain/terrain_streaming.tscn
```

Open the preview scene in the editor to inspect the cheap preview path. Run the
other scenes with F6 to exercise generated collision, LOD data, island masking,
or streaming without requiring project-specific assets.
