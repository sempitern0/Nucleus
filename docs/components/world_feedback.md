# World Feedback History Contract

Target engine: Godot 4.7.x.

## Scope

```text
components/world/feedback
```

This subsystem provides a bounded world-space history for transient visual marks.
It is intended for effects whose visual state must remain where it was emitted
while the camera/player and the bounded texture window continue moving.

Public types:

```text
NucleusWorldStamp3D
NucleusWorldStampBuffer3D
NucleusWorldStampViewport3D
```

There is no global feedback manager or Autoload.

## Ownership boundary

The reusable mechanism is:

```text
world-space stamp data
        ↓
bounded history
        ↓
optional 2D history texture
        ↓
project shader / material / presentation
```

Nucleus does not decide whether the texture represents:

```text
boat wake coverage
snow footprints
mud tracks
tire marks
flattened vegetation
surface wetness
water ripples
scorch / disturbance masks
```

Those meanings remain game-owned.

The buffer is presentation history only. It never applies forces, changes
collision, edits terrain, or becomes authoritative gameplay state.

## NucleusWorldStamp3D

A stamp stores one transient world-space mark:

```text
world_position
dimensions
rotation
strength
lifetime
born_time
drift
growth
metadata
```

`dimensions` are world metres on the X/Z projection plane.

`drift` is world units per second. It is useful for presentation such as water
current, wind-blown ash coverage, or slowly moving foam. It does not imply a
physical velocity field.

`growth` is proportional growth across the stamp lifetime. `Vector2(1, 0)` means
the first dimension doubles by the end of life while the second stays unchanged.

Runtime query methods calculate age, normalized age, current world position, and
current dimensions without mutating the stored origin.

## NucleusWorldStampBuffer3D

The buffer owns:

```text
fixed stamp capacity
world-space center
coverage size
logical elapsed time
bounded motion-emitter history
```

It does not own a `SubViewport` or GPU resource. This makes the history usable in
headless tests and lets a game provide another renderer later without replacing
the storage contract.

### Bounded storage

`max_stamps` is a hard capacity. Once full, new stamps replace old slots instead
of growing memory indefinitely.

Expired stamps become inactive according to logical time and are eventually
replaced. The buffer therefore avoids node-per-stamp lifetime churn and does not
allocate a new scene object for every footprint or wake segment.

### Coverage and recentering

The history uses X/Z world coordinates. `coverage_size` is the full width/depth
of the represented region in metres.

```gdscript
buffer.set_center(player.global_position)
```

changes only the projection window. Existing stamp positions remain in world
space.

This is the critical recentering rule:

```text
move window
    ≠
move history
```

A wake or track therefore stays attached to its original world position when the
bounded texture follows the player.

`world_to_uv()` exposes the mapping used by the built-in viewport renderer. It is
also useful when a custom material needs the same center and extent.

`acceptance_margin` allows marks just outside the visible rectangle to enter the
buffer so they can remain continuous near the border while the window moves.

### Point stamps

Use `emit_stamp()` for isolated marks:

```gdscript
buffer.emit_stamp(
	impact_position,
	Vector2(1.2, 1.2),
	0.0,
	0.7,
	2.5,
)
```

A returned `null` means the mark was rejected, normally because it is outside the
bounded region or capacity is disabled.

### Motion stamps

`emit_motion()` is a generic distance-based trail helper.

The first sample initializes emitter history. Later samples emit one stamp per
configured `motion_spacing`, capped by `max_motion_stamps_per_call`.

This makes density dependent on world distance rather than FPS.

```gdscript
buffer.emit_motion(
	boat.get_instance_id(),
	boat.global_position,
	2.4,
	0.8,
)
```

The generic helper creates a central trail only. It intentionally does not add:

```text
wake side lobes
random breakup
vehicle tread patterns
left/right footsteps
snow compression rules
foam-specific turbulence
```

Those are higher-level emitters owned by the consuming project.

A movement jump larger than `coverage_size * motion_break_distance_ratio` resets
that emitter rather than drawing a stripe across the map. This handles teleport,
respawn, origin correction, and large discontinuities safely.

Emitter history itself is bounded by `max_emitters`. Stale emitters can be
reclaimed when a new emitter needs a slot.

## NucleusWorldStampViewport3D

This optional renderer converts active stamps into one transparent `SubViewport`
texture.

It owns:

```text
texture resolution
stamp mask texture
standard birth/fade envelope
world-space reprojection into the current buffer window
```

It does not own the consumer shader.

Retrieve the native texture through:

```gdscript
var history_texture := stamp_viewport.get_history_texture()
```

A water material might treat the texture as wake coverage. A snow material could
interpret exactly the same values as compression or displaced powder.

### Coverage, not final art

The output should normally be treated as a scalar coverage/history field, not as
the final visible effect.

For example, a wake shader can use it to reveal/break an authored foam texture
and perturb normals instead of displaying the stamp mask as a bright white blob.

This distinction is one of the lessons extracted from Nautica: history answers
**where/how strongly an interaction exists**; the receiving material decides
**how that interaction looks**.

### Default stamp texture

If `stamp_texture` is absent, the viewport builds a small radial
`GradientTexture2D` at runtime. It is a neutral fallback for development and
validation, not intended to impose art direction.

Projects should provide an authored repeat-safe/soft mask where the effect needs
a particular shape.

### Render cadence

The `SubViewport` uses `UPDATE_ONCE` rather than continuous rendering.

A redraw is requested when:

```text
a stamp is emitted
time advances while history is visible
the buffer center changes
the buffer is cleared
```

After the final visible stamps disappear, one last clear is rendered and the
viewport remains idle until history changes again.

There is no GPU-to-CPU readback.

## Typical Nautica-style integration

A project can replace a game-specific wake buffer with:

```text
Ocean / Boat code
    decides wake shape and strength
        ↓
NucleusWorldStampBuffer3D
    stores central/history stamps
        ↓
NucleusWorldStampViewport3D
    produces bounded coverage texture
        ↓
Ocean material
    samples coverage
        ↓
foam erosion + normal turbulence
```

Nucleus should not absorb the ocean material, analytical waves, hull disturbance,
foam textures, or boat-specific wake breakup.

## Quality and memory

Texture memory is determined mainly by viewport resolution and format, not by
world coverage in metres.

Increasing `coverage_size` with the same texture resolution shows more world but
reduces texel density. Increasing resolution improves detail but increases render
target cost.

A useful starting point from the proven Nautica workload is approximately:

```text
LOW      256 x 256
MEDIUM   384 x 384
HIGH     512 x 512
```

These are examples, not automatic Nucleus quality settings. The game chooses the
resolution appropriate for its material, camera distance, hardware target, and
quality options.

Keep `max_stamps` bounded independently of texture resolution.

## Headless and multiplayer

`NucleusWorldStampBuffer3D` can exist without rendering, which is useful for
unit tests and deterministic presentation feeds.

In normal multiplayer the history is client presentation. Replicate the
underlying authoritative event or actor state when necessary, then let clients
emit visual stamps locally.

Do not replicate render-target pixels or use a wake/footprint texture as gameplay
authority.

If tracks have gameplay meaning, such as AI scent or physically deep snow, that
simulation requires its own authoritative data model. The visual stamp buffer may
mirror it but must not become the source of truth.

## Persistence

Transient stamp history is not persisted by default.

Saving every wake, footprint, or rain disturbance usually creates large fragile
save data for presentation that should simply reconstruct or expire.

If a particular game needs durable marks, persist its semantic world state and
rebuild the presentation after load rather than serializing the viewport texture.

## Performance rules

The production constraints are deliberate:

```text
fixed stamp capacity
fixed emitter capacity
distance-based motion emission
per-call trail cap
bounded world coverage
one optional SubViewport
UPDATE_ONCE redraws
no GPU readback
no node-per-stamp scenes
```

The renderer still redraws every active stamp when the history changes. Very high
capacities or large textures must therefore be profiled on target hardware.

For effects with thousands of long-lived marks across a large persistent world,
use a chunked/terrain-specific solution rather than expanding this local buffer
without bound.

## What stays game-owned

```text
wake breakup and Kelvin-like patterns
snow/mud deformation semantics
vehicle tread/track layout
left/right foot placement
material/shader interpretation of coverage
surface-specific stamp selection
per-effect quality policy
persistent world decals/terrain modification
authoritative gameplay fields
```
