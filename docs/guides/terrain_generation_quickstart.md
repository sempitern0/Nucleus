# Procedural Terrain Generation Quickstart

Use `modules/terrain` when the project needs fast generated 3D heightfield
terrain without adopting a manual terrain-painting workflow.

Technical contract:

[`../modules/terrain_generation.md`](../modules/terrain_generation.md)

## 1. Add a generator

Create:

```text
World
└── Terrain : NucleusTerrainGenerator3D
```

The node is scene-owned. Do not add it as an Autoload.

## 2. Create a terrain profile

Create a `NucleusTerrainProfile` resource.

For a noise prototype:

```text
height_source = FAST_NOISE
noise = FastNoiseLite
size = (256, 256)
resolution = 96
base_height = 0
height_scale = 45
collision_mode = HEIGHTMAP
collision_resolution = 48
lod_levels = 2
lod_distance_step = 120
```

The FastNoiseLite resource owns the actual frequency/fractal/seed settings.

## 3. Preview before committing geometry

Assign the profile to `Terrain` and press:

```text
Refresh Preview
```

Start with:

```text
preview_resolution = 20 to 32
```

The preview uses the same height sampler but skips collision and LOD data.

Do not use final 256+ resolution meshes merely to judge the shape while tuning
noise parameters.

## 4. Generate the final terrain

Press:

```text
Generate Terrain
```

The generated hierarchy is:

```text
Terrain
└── GeneratedTerrain
    └── TerrainPatch_000
        ├── TerrainMesh
        └── TerrainCollision
            └── CollisionShape3D
```

In the editor the generated nodes are owned by the edited scene and can be
saved normally.

## 5. Create a complete chunked area

Create `NucleusTerrainLayout`:

```text
mode = GRID
grid_size = (4, 4)
patch_gap = 0
```

Noise sampling uses patch world positions, so adjacent noise-generated patches
continue the same source field rather than restarting the noise on every chunk.

Splitting a large area into patches improves culling and gives runtime systems a
natural unit for loading/unloading.

If aggressive LOD produces visible borders between steep neighboring patches, use
larger patches or fewer LOD levels. The baseline intentionally does not hide those
tradeoffs behind a custom clipmap implementation.

## 6. Create an authored linear strip

For a road, river corridor, endless-runner prototype, or traversal test:

```text
mode = LINEAR
linear_count = 8
linear_axis = Z
linear_centered = true
```

This creates a fixed strip.

For continuous runtime generation, use `NucleusTerrainStreamer3D` instead.

## 7. Create islands

Create a layout:

```text
mode = ISLANDS
island_count = 8
island_spread = (2400, 2400)
island_scale_range = (0.6, 1.4)
island_min_separation = 100
seed = 42
```

Then tune the terrain profile:

```text
edge_floor_height = -18
island_inner_radius = 0.50
island_falloff = 0.35
island_power = 1.6
shoreline_noise = FastNoiseLite
shoreline_noise_strength = 0.10
```

The ISLANDS layout forces island masking even when the shared profile is left in
`RECTANGLE` mode.

This is useful when one profile is reused for a mainland/grid and for separate
ocean islands.

## 8. Add multiple procedural terrain textures

Create a `NucleusTerrainMaterialProfile` and add up to four
`NucleusTerrainTextureLayer` resources.

Example:

```text
Layer 0: sand
    height_range = (0.0, 0.25)
    slope_range = (0.0, 0.55)

Layer 1: grass
    height_range = (0.18, 0.70)
    slope_range = (0.0, 0.45)

Layer 2: rock
    height_range = (0.0, 1.0)
    slope_range = (0.35, 1.0)

Layer 3: high rock/snow
    height_range = (0.68, 1.0)
    slope_range = (0.0, 1.0)
```

Use `Top projection` on low-end targets when cliffs do not expose distracting
stretching. Use `Triplanar` when steep terrain quality matters more than the
extra texture samples.

## 9. Tune collision independently

A practical starting point for lower-end PCs:

```text
visual resolution = 96
collision resolution = 32 to 48
collision mode = HEIGHTMAP
collision_holes_below_height = false by default
```

For ocean islands that never need underwater ground collision, enable
`collision_holes_below_height` and place `collision_hole_height` below the water
surface.

Raise physics density only when gameplay actually needs smaller terrain detail.

Use `TRIMESH` only when a project-specific mesh requires it.

## 10. Stream a long route at runtime

Add:

```text
World
├── Player
└── TerrainStream : NucleusTerrainStreamer3D
```

Assign:

```text
profile
material_profile
tracked_node = Player
axis = Z
chunks_behind = 2
chunks_ahead = 4
max_new_chunks_per_update = 1
```

The streamer generates nearest missing chunks first and removes chunks outside
the requested window.

For an ocean archipelago that should exist as a bounded authored world, prefer
an ISLANDS layout generated once instead of the linear streamer.

## Example scenes

Ready-to-open examples live under:

```text
res://examples/terrain/
```

Use them as small regression fixtures as well as learning scenes:

```text
terrain_preview.tscn
    low-resolution editor/runtime preview without collision

terrain_single.tscn
    one complete noise-driven heightfield

terrain_grid.tscn
    chunked complete area with continuous noise sampling

terrain_linear.tscn
    fixed procedural strip along the Z axis

terrain_islands.tscn
    deterministic island layout over a native water plane

terrain_streaming.tscn
    runtime linear chunk streaming around a moving tracked node
```

The scenes intentionally use a built-in material profile and `FastNoiseLite`
resources, so they do not depend on external terrain textures or demo heightmaps.

## Performance checklist

Start here before increasing quality:

```text
patch size around 128–512 m depending on game scale
visual resolution 64–128 cells
collision resolution below visual resolution
LOD 1–3 levels
Top projection on weak GPUs
preview resolution below final resolution
small patches generated over several frames at runtime
```

Profile CPU generation, GPU draw cost, physics, memory, and traversal behavior on
the actual low-end target.
