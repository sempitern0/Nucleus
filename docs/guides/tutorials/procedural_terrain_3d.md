# Tutorial: build a procedural island chain

This tutorial builds a bounded procedural archipelago using the optional Nucleus
terrain module.

For editor iteration first, read:

[`terrain_preview_and_presets.md`](terrain_preview_and_presets.md)

For moving runtime terrain windows, read:

[`terrain_streaming_runtime.md`](terrain_streaming_runtime.md)

## What you will build

```text
one reusable island height profile
one four-layer terrain material
cheap editor preview
an eight-island deterministic layout
heightmap collision cheaper than the visual mesh
an ocean plane owned by the game
```

## 1. Create the scene shell

```text
OceanWorld : Node3D
├── Terrain : NucleusTerrainGenerator3D
├── Ocean : MeshInstance3D
└── Player : CharacterBody3D
```

Keep ocean rendering, buoyancy, and wave policy outside the terrain module.

Place the ocean surface at:

```text
Y = 0
```

## 2. Start from the island preset

Duplicate:

```text
res://modules/terrain/presets/archipelago_island.tres
```

into your game's content folder.

Assign the duplicate to `Terrain.profile`.

This gives you a working baseline for:

```text
noise relief
shoreline perturbation
submerged floor variation
LOD
heightmap collision
underwater collision holes
```

## 3. Understand the island controls

The main landform still comes from:

```text
noise
base_height
height_scale
```

The coastline comes from:

```text
island_inner_radius
island_falloff
island_power
shoreline_noise
shoreline_noise_strength
```

The submerged area comes from:

```text
edge_floor_height
edge_floor_noise
edge_floor_noise_strength
```

`shoreline_noise` changes the horizontal coastline.

`edge_floor_noise` changes the Y value that fully faded terrain approaches.

That second noise is useful because a perfectly constant deep floor reads as an
obvious square plate through very clear water.

It does not remove the rectangular mesh boundary. A heightfield remains a
regular grid by design.

For deep/transparent water, combine:

```text
larger patch footprint
deep edge_floor_height
low-frequency edge_floor_noise
water fog/absorption owned by the water material
```

## 4. Preview cheaply

Set:

```text
preview_resolution = 20–32
```

Press **Refresh Preview**.

Tune shape here before final geometry.

Open:

```text
res://examples/terrain/terrain_preview_presets.tscn
```

to compare the supplied terrain families side by side.

## 5. Tune the noise for natural scale

Do not start by increasing resolution.

Tune:

```text
FastNoiseLite.frequency
fractal_octaves
fractal_lacunarity
fractal_gain
```

A lower frequency produces broader landforms. Extra octaves add smaller detail.

Mesh resolution only decides how densely that field is sampled.

## 6. Build a procedural material

Use:

```text
res://examples/terrain/materials/terrain_height_layers.tres
```

as a readable starting point.

It demonstrates:

```text
sand
grass
rock
snow/high-altitude
```

The default projection is **Top** for lower fragment cost.

Switch to Triplanar only when cliff stretching matters enough to justify the
additional sampling cost.

## 7. Scatter an archipelago

Create `NucleusTerrainLayout`:

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

If fewer islands appear than requested, increase spread, lower separation, or
reduce island size/count.

## 8. Generate the final archipelago

Press **Generate Terrain**.

The module creates one terrain patch per island.

That gives Godot separate AABBs for culling rather than forcing the complete
archipelago into one mesh.

Each island receives its configured `HeightMapShape3D` collision grid.

## 9. Validate underwater collision policy

For a boat game, decide whether submerged land should collide.

If not:

```text
collision_holes_below_height = true
collision_hole_height ≈ just below water level
```

The visual seabed can continue under the water while unnecessary collision
samples become holes.

## 10. Profile on the target class

For a weak integrated GPU, start with:

```text
resolution = 48–64
collision_resolution = 24–32
lod_levels = 2
projection = Top
terrain shadows = off while tuning
```

When moving close to a patch, the renderer returns toward the base mesh, so
triangle cost increases by design.

Material projection and shadows can also dominate a low-end GPU, so reduce them
before assuming geometry is the only bottleneck.

## Heightmap/image sources

To preserve a known landform:

```text
height_source = HEIGHTMAP
image = <Texture2D>
normalize_heightmap = true
image_mapping = STRETCH_TO_PATCH
```

For generic grayscale source images:

```text
height_source = IMAGE
```

The preview, layout, material, LOD, and collision pipeline remains the same.

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

For Nautica, the natural next layer is to consume generated height/coast data for
POI, vegetation, settlement, reef, and navigation placement rather than adding
manual paint infrastructure to the terrain core.
