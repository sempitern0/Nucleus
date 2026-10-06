# Procedural Terrain Generation Quickstart

Use `modules/terrain` when the project needs fast generated 3D heightfield
terrain without adopting a manual terrain-painting workflow.

Technical contract:

[`../modules/terrain_generation.md`](../modules/terrain_generation.md)

Focused tutorials:

- [`tutorials/terrain_preview_and_presets.md`](tutorials/terrain_preview_and_presets.md)
- [`tutorials/procedural_terrain_3d.md`](tutorials/procedural_terrain_3d.md)
- [`tutorials/terrain_streaming_runtime.md`](tutorials/terrain_streaming_runtime.md)

## 1. Add a generator

Create:

```text
World
└── Terrain : NucleusTerrainGenerator3D
```

The node is scene-owned. Do not add it as an Autoload.

## 2. Start from a profile or preset

Create a `NucleusTerrainProfile`, or duplicate one of:

```text
res://modules/terrain/presets/gentle_hills.tres
res://modules/terrain/presets/lowlands.tres
res://modules/terrain/presets/rugged_mountains.tres
res://modules/terrain/presets/archipelago_island.tres
```

The presets are ordinary Resources. They are starting values, not a second API.

For a custom noise prototype:

```text
height_source = FAST_NOISE
noise = FastNoiseLite
size = (256, 256)
resolution = 64
base_height = 0
height_scale = 45
collision_mode = HEIGHTMAP
collision_resolution = 32
lod_levels = 2
lod_distance_step = 120
```

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

Open this scene to compare four presets at once:

```text
res://examples/terrain/terrain_preview_presets.tscn
```

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
continue the same source field rather than restarting on every chunk.

## 6. Create a fixed linear strip

For a road, river corridor, endless-runner prototype, or traversal test:

```text
mode = LINEAR
linear_count = 8
linear_axis = Z
linear_centered = true
```

For continuous runtime generation, use `NucleusTerrainStreamer3D`.

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
edge_floor_height = -24
island_inner_radius = 0.50
island_falloff = 0.35
island_power = 1.6
shoreline_noise = FastNoiseLite
shoreline_noise_strength = 0.10
```

For less-flat underwater terrain:

```text
edge_floor_noise = FastNoiseLite
edge_floor_noise_strength = 4–10
```

This varies the submerged floor but intentionally keeps the efficient rectangular
heightfield topology. Make the patch larger/deeper when transparent water could
otherwise reveal the outer rectangle.

## 8. Add multiple terrain textures

Create a `NucleusTerrainMaterialProfile` and add up to four
`NucleusTerrainTextureLayer` resources.

A ready example is:

```text
res://examples/terrain/materials/terrain_height_layers.tres
```

It demonstrates sand, grass, rock, and snow/high-altitude bands.

Use **Top projection** on low-end targets. Use Triplanar when steep terrain
quality matters more than extra texture sampling.

## 9. Tune collision independently

A practical starting point for lower-end PCs:

```text
visual resolution = 48–80
collision resolution = 24–40
collision mode = HEIGHTMAP
```

For ocean islands that never need underwater ground collision, enable
`collision_holes_below_height`.

Use `TRIMESH` only when a project-specific mesh requires it.

## 10. Run the streaming demo

Open and run with F6:

```text
res://examples/terrain/terrain_streaming.tscn
```

The orange marker moves automatically. The HUD shows the current chunk, loaded
chunk indices, and pending builds while terrain is created ahead and recycled
behind.

For your own scene:

```text
World
├── Player
└── TerrainStream : NucleusTerrainStreamer3D
```

Assign:

```text
tracked_node = Player
axis = Z
chunks_behind = 1–2
chunks_ahead = 3–4
max_new_chunks_per_update = 1
```

Detailed tutorial:

[`tutorials/terrain_streaming_runtime.md`](tutorials/terrain_streaming_runtime.md)

## Example scenes

```text
terrain_preview.tscn
terrain_preview_presets.tscn
terrain_single.tscn
terrain_grid.tscn
terrain_linear.tscn
terrain_islands.tscn
terrain_material_layers.tscn
terrain_streaming.tscn
```

See `res://examples/terrain/README.md` for what each scene demonstrates.

## Performance checklist

Start here before increasing quality:

```text
patch size around 128–512 m depending on game scale
visual resolution 48–96 cells
collision resolution below visual resolution
LOD 1–3 levels
Top projection on weak GPUs
terrain shadows disabled while tuning on weak GPUs
preview resolution below final resolution
one new streamed patch per update
```

Profile CPU generation, GPU draw cost, physics, memory, and traversal behavior on
the actual target.
