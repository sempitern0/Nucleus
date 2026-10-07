# World Surfaces Contract

Target engine: Godot 4.7.x.

## Scope

```text
components/world/surfaces
```

This subsystem contains two deliberately separate surface contracts:

```text
semantic classification
    what kind of surface was hit?

spatial sampling
    where is a continuous surface and how is it moving?
```

Public types:

```text
NucleusSurfaceProfile
NucleusSurfaceQuery3D
NucleusSurfaceSource3D
NucleusSurfaceProvider3D
NucleusSurfaceResolver3D

NucleusSurfaceSample3D
NucleusSurfaceSampler3D
NucleusPlaneSurfaceSampler3D
```

There is no surface manager or Autoload.

## Ownership boundary

Semantic classification and spatial sampling solve different problems.

A collision surface flow is:

```text
Godot physics collision
        ↓
NucleusSurfaceResolver3D
        ↓
NucleusSurfaceProfile
        ↓
project-owned response mapping
```

An analytical surface flow is:

```text
world position + optional time
        ↓
NucleusSurfaceSampler3D
        ↓
NucleusSurfaceSample3D
        ↓
project-owned simulation / presentation
```

Do not require a semantic profile merely to sample terrain height, and do not
require an analytical sampler merely to choose a footstep sound from a collider.
A project may compose both when it actually needs both.

Neither contract owns:

```text
audio assets
particle assets
decal assets
PhysicsMaterial
fluid density
buoyancy coefficients
damage rules
weather state
```

## Semantic surface profiles

`NucleusSurfaceProfile` is a reusable Resource containing:

```text
surface_id
semantic tags
```

Example identities:

```text
wood
metal
stone
sand
grass
mud
water
snow
```

Tags allow broader responses without replacing the stable id:

```text
metal
    tags = hard, manufactured, conductive

wet_sand
    tags = soft, granular, wet
```

Use ids for exact project mappings and tags for families of behavior.

Profiles validate that `surface_id` is present and that tags are non-empty and
unique. Nucleus does not enforce global uniqueness across all project resources;
that remains a content-authoring responsibility.

## Static semantic providers

For one semantic surface on an entire collider:

```text
Wall : StaticBody3D
├── CollisionShape3D
└── Surface : NucleusSurfaceProvider3D
        profile = stone
```

For different semantics on shapes owned by the same collider, place the provider
under the corresponding shape owner node:

```text
Prop : StaticBody3D
├── WoodenBody : CollisionShape3D
│   └── Surface : NucleusSurfaceProvider3D
│       profile = wood
└── MetalHandle : CollisionShape3D
    └── Surface : NucleusSurfaceProvider3D
        profile = metal
```

When a Godot collision reports the shape index, shape-owned semantics take
precedence over the collider-level fallback.

## Semantic resolution order

`NucleusSurfaceResolver3D` evaluates scopes in this order:

```text
1. impacted shape owner
2. collider
3. nearest collider ancestor
4. next ancestor, continuing toward the scene root
```

Within one scope, sources are evaluated by descending `priority`. Equal-priority
sources retain scene order.

A source may return `null`; resolution then continues to the next candidate.
Prefer providers close to the geometry they describe. Ancestor-level providers
are best used as deliberate defaults for a coherent world subtree.

## Querying semantic surfaces from Godot collisions

For footsteps, weapon impacts, interaction probes, or placement checks:

```gdscript
var surface := NucleusSurfaceResolver3D.resolve_raycast(floor_ray)

if surface != null:
	play_footstep_for(surface.surface_id)
```

The resolver consumes the existing native collision result. It does not perform
a second raycast.

For a `KinematicCollision3D`:

```gdscript
var collision := character.get_last_slide_collision()
var surface := NucleusSurfaceResolver3D.resolve_kinematic_collision(collision)
```

When collision data comes from another Godot API, build a typed query:

```gdscript
var query := NucleusSurfaceQuery3D.new(
	collider,
	world_position,
	surface_normal,
	shape_index,
	face_index,
)

var surface := NucleusSurfaceResolver3D.resolve(query)
```

`metadata` exists on the query for project/custom-source context, but the built-in
provider does not interpret it.

## Dynamic semantic sources

`NucleusSurfaceSource3D` is the extension boundary for position-dependent
semantic classification.

Subclass it and override:

```gdscript
func _resolve_surface(
	query: NucleusSurfaceQuery3D,
) -> NucleusSurfaceProfile:
	return selected_profile
```

Potential consumers include:

```text
procedural terrain layers
painted material masks
runtime wetness layers
ocean/river semantics
mesh-face material lookup
```

The built-in terrain material blends visual layers. Nucleus does not guess a
semantic winner from texture names; a terrain semantic source needs an explicit
CPU/GPU matching policy if a game requires it.

## Spatial surface sampling

`NucleusSurfaceSampler3D` is a scene-owned analytical query boundary.

It models a surface that is single-valued over world X/Z: for a queried X/Z
position, the sampler can return one world-space surface point.

This covers proven cases such as:

```text
analytical oceans
rivers represented as height fields
procedural terrain
flat lakes
moving height-field surfaces
```

It intentionally does not represent arbitrary closed meshes, caves, walls, or
multi-layer geometry. Use Godot physics queries for those cases.

For ordinary queries, call:

```gdscript
var sample := sampler.sample(world_position)
```

or, when the source supports reproducible time queries:

```gdscript
var sample := sampler.sample(world_position, simulation_time)
```

`at_time < 0` means "use the sampler's current/live state" by convention.
Time-independent samplers may ignore it.

`sample()` returns `null` when disabled, outside the valid domain, or unable to
produce a valid sample.

High-frequency systems should reuse one result object instead of allocating one
for every query:

```gdscript
var scratch := NucleusSurfaceSample3D.new()

func _physics_process(_delta: float) -> void:
	if sampler.sample_into(global_position, scratch):
		consume_surface(scratch)
```

`sample_into()` clears the supplied result before each attempt and returns a bool.
This is the preferred path for buoyancy points or other per-physics-tick loops.

## NucleusSurfaceSample3D

A successful analytical query returns:

```text
position
normal
velocity
sampled_time
metadata
```

All vectors are world-space.

`position` is the sampled surface point at the query X/Z coordinate.

`normal` is normalized by the sample object and must be non-zero.

`velocity` is the local world-space velocity of the surface itself. It is not the
velocity of the querying body. An ocean can combine current and vertical wave
velocity; static terrain normally returns zero.

`get_vertical_delta(query_position)` returns:

```text
surface_y - query_y
```

This is intentionally neutral terminology. A later buoyancy component can use
that value as one input without teaching the sampler what "submerged" means.

`metadata` is copied at construction. It is optional diagnostic/adapter context,
not a persistence or networking contract.

## NucleusPlaneSurfaceSampler3D

The built-in plane sampler is the smallest concrete implementation.

Its local `+Y` axis defines the plane normal and its global transform defines the
plane position.

```text
LakeSurface : NucleusPlaneSurfaceSampler3D
    surface_velocity = (0, 0, 0)
```

It preserves query X/Z and analytically solves Y on the transformed plane.
Sufficiently vertical planes return `null` because they are not single-valued
over world X/Z.

`surface_velocity` is explicit world-space velocity. Nucleus does not infer
velocity by differentiating Node transforms because update ownership and timing
would otherwise be ambiguous.

## Terrain integration

The optional terrain module provides:

```text
NucleusTerrainSurfaceSampler3D
```

Place it below or explicitly point it at a `NucleusTerrainGenerator3D`.

The adapter uses the same internal `NucleusTerrainProfile` height source and
static `NucleusTerrainLayout` descriptors as mesh/collision generation:

```text
TerrainProfile
    ↓
shared analytical height source
    ├── generated mesh/collision
    └── TerrainSurfaceSampler3D
```

It does not raycast generated collision and does not require generated geometry
to exist. This is useful for server-side queries and systems that need terrain
height even when presentation/collision has a different resolution.

Normals are estimated from nearby analytical height samples using
`normal_sample_distance` and then transformed to world space.

The terrain node may be translated, yawed, and scaled, but its local +Y must stay
aligned with world +Y. Pitch/roll would no longer be a single-valued world-X/Z
height field, so the adapter warns and rejects those queries instead of returning
misleading coordinates.

The first adapter intentionally targets `NucleusTerrainGenerator3D` static
layouts. Runtime `NucleusTerrainStreamer3D` sampling should be added only when a
real consuming system needs a stable contract for loaded/unloaded chunk policy.

## Ocean / Nautica adapter shape

Nucleus does not copy `OceanProfile` or wave equations into this subsystem.
Nautica can adapt its existing analytical field with a very small subclass:

```gdscript
class_name NauticaOceanSurfaceSampler3D
extends NucleusSurfaceSampler3D

func _sample_surface_into(
	world_position: Vector3,
	out_sample: NucleusSurfaceSample3D,
	at_time: float,
) -> bool:
	var water := ocean.sample(world_position, at_time)
	var normal := Vector3(-water.y, 1.0, -water.z).normalized()
	var velocity := ocean.profile.current_velocity
	velocity.y += water.w

	out_sample.set_values(
		Vector3(world_position.x, water.x, world_position.z),
		normal,
		velocity,
		at_time,
	)
	return true
```

The exact Nautica adapter remains game-owned until its API is exercised there.
The reusable Nucleus contract does not know how many waves exist or how an ocean
is rendered.

## Buoyancy boundary

`SurfaceSampler3D` is intentionally a prerequisite rather than a buoyancy system.

A future reusable buoyancy module can depend on:

```text
SurfaceSampler3D
    point + normal + surface velocity

Buoyancy medium/profile
    density + project/solver parameters

RigidBody3D
    native integration
```

The sampler must not gain `water_density`, drag coefficients, displaced volume,
or hull rules just because buoyancy is one consumer.

This separation also permits a game to use the same surface sampler for:

```text
floating objects
swimming height
VFX placement
camera constraints
AI/navigation checks
surface-following presentation
```

without importing a physics solver.

## Smart decal integration

Semantic classification chooses *what* presentation to use. SmartDecal owns
*how* a selected decal is aligned and expired.

Recommended direction:

```text
raycast
→ resolve SurfaceProfile
→ game chooses decal scene
→ NucleusSmartDecal3D.place_on_surface(position, normal)
```

Do not put decal textures inside `NucleusSurfaceProfile` merely to shorten this
pipeline.

## Audio / footsteps integration

Nucleus intentionally does not add a global footstep manager.

A character can keep a project-owned mapping such as:

```text
stone → stone footstep set
wood  → wood footstep set
sand  → sand footstep set
```

The movement/animation event decides when a step occurs. The surface resolver
only classifies the existing floor collision. `NucleusAudio` continues owning
bus/routing policy, not footstep content selection.

## Physics materials

Godot `PhysicsMaterial` remains authoritative for friction and bounce.

A semantic `metal` profile does not imply a friction value. Two metal surfaces
may intentionally use different native physics materials, and one gameplay rule
may interpret the same semantic surface differently from another.

## Persistence and networking

Semantic provider Nodes and analytical sampler Nodes are runtime scene
composition and should normally be reconstructed with the scene.

If durable state needs a semantic type, persist `surface_id`, not a live Resource
or Node path.

For authoritative multiplayer simulation, sample the authoritative field at the
authoritative simulation time. A client may independently sample presentation
when that result cannot change gameplay authority.

Do not replicate sampled normals/heights every frame when every peer can derive
them from the same authoritative field parameters and epoch.

## Performance

There is no polling manager or global registry.

Semantic resolution walks a small ownership chain only when requested.

Analytical sampling is direct-call work. `sample()` allocates one small result
object for convenience; `sample_into()` reuses a caller-owned result and avoids
per-query allocation in hot paths.

The terrain adapter performs analytical height evaluations and no physics query.
Normal calculation needs four neighboring height samples in addition to the
central height. Systems that need height only at very high frequency should own
a more specialized fast path rather than weakening the generic sample contract.

Profile representative workloads on target hardware before increasing buoyancy
point counts or querying large crowds every physics tick.

## 2D boundary

`NucleusSurfaceProfile` remains dimension-neutral. Spatial sampling is currently
3D because the proven consumers are 3D terrain, water, buoyancy, and world
presentation.

A future 2D sampler can reuse the same separation of semantic classification and
spatial geometry without speculative parity today.

## What stays game-owned

```text
footstep cadence and sound libraries
impact/decal/particle selection
weapon material response rules
terrain layer semantic policy
wetness, temperature, conductivity or traversal rules
surface-specific damage formulas
content authoring taxonomy beyond ids/tags
ocean/river equations and rendering
fluid density and buoyancy coefficients
swimming rules
runtime terrain-stream sampling policy
```

Repeated production friction in those areas can justify a later focused
component without expanding these base contracts prematurely.
