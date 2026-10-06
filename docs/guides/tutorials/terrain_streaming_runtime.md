# Tutorial: run terrain streaming at runtime

This tutorial demonstrates `NucleusTerrainStreamer3D` as a moving linear terrain
window.

Runnable reference scene:

```text
res://examples/terrain/terrain_streaming.tscn
```

Run it with **F6**.

## What the example does

The scene contains:

```text
TerrainStreamingExample
├── TerrainStream : NucleusTerrainStreamer3D
├── TrackedTarget
│   ├── Marker
│   └── Camera3D
├── Sun
└── StreamingHUD
```

The orange marker moves automatically along +Z.

The streamer keeps a bounded range of chunks around that marker.

The HUD reports:

```text
current chunk
loaded chunk indices
loaded count
pending build count
world Z
```

## 1. Build the same ownership in your game

A production scene normally looks like:

```text
World
├── Player
└── TerrainStream : NucleusTerrainStreamer3D
```

Assign:

```text
tracked_node = Player
axis = Z
```

The streamer is scene-owned. It is not an Autoload.

## 2. Choose a patch profile

For a first runtime test, use:

```text
res://modules/terrain/presets/gentle_hills.tres
```

Then duplicate it into your project and tune it.

A streaming patch should usually be cheaper than a one-off hero landscape.

Start around:

```text
size = 200–320 m
resolution = 48–64
collision_resolution = 24–32
lod_levels = 2
```

## 3. Configure the active window

Example:

```text
chunks_behind = 1
chunks_ahead = 3
update_interval = 0.15–0.30
max_new_chunks_per_update = 1
```

This means the streamer does not attempt to build the complete window in one
frame.

If traversal speed is high enough to outrun generation, first increase the
window or reduce per-patch cost. Raising `max_new_chunks_per_update` can move the
spike rather than solve it.

## 4. Observe chunk lifecycle

The streamer exposes:

```gdscript
chunk_loaded(index: int, chunk: Node3D)
chunk_unloaded(index: int)

get_center_chunk_index()
get_loaded_chunk_count()
get_loaded_chunk_indices()
get_pending_chunk_count()
```

These are intended for development UI, telemetry, streaming coordination, or
project-specific systems that need to know when terrain becomes available.

Gameplay should not reach into the streamer's private chunk dictionary.

## 5. Understand continuity

Noise sampling uses patch world positions.

Adjacent chunks therefore sample the same noise field instead of restarting the
noise at each patch.

Keep:

```text
patch_gap = 0
```

for contiguous ground.

A non-zero gap is an explicit layout choice and will expose holes.

## 6. Understand what happens near the camera

The terrain `ArrayMesh` carries reduced index buffers as LODs.

Farther patches can render fewer triangles. As the camera approaches, Godot
returns to denser index buffers and ultimately the base mesh.

Therefore a rise in GPU work close to the terrain is expected.

On a low-end integrated GPU, profile these separately:

```text
terrain resolution
number of visible chunks
terrain shadows
Top versus Triplanar projection
number/size of active texture layers
```

Do not assume the mesh is the bottleneck until the material and shadows are
checked too.

## 7. Collision policy

The default profile uses `HeightMapShape3D`.

For a streamed route, collision normally needs to exist only inside the active
window.

Keep collision resolution lower than visual resolution unless gameplay requires
small terrain features to affect movement.

## 8. Fast movement and teleports

A teleport can change the center chunk by many indices at once.

The streamer will:

```text
remove chunks outside the new window
queue missing chunks in the new window
sort pending chunks nearest-first
build up to max_new_chunks_per_update each update
```

If the player must never see an empty landing area after teleporting, the game
should coordinate the teleport/loading presentation. The terrain streamer does
not block scene flow or freeze the player automatically.

## 9. When not to use the linear streamer

Do not use this component as a general infinite-world solution.

Use another ownership model when the game needs:

```text
omnidirectional open-world streaming
kilometres of clipmap terrain
persistent per-chunk authored edits
streamed foliage/object ecosystems
terrain deformation persistence
```

For a bounded Nautica archipelago, generating an `ISLANDS` layout once is often
simpler than streaming a linear window.

## Validation checklist

Run `terrain_streaming.tscn` and verify:

```text
the orange marker moves along +Z
new chunks appear ahead
old chunks disappear behind
HUD indices advance
loaded count remains bounded
pending count returns toward zero
there are no visible seams when patch_gap = 0
```
