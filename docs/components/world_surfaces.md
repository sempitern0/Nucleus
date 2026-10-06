# World Surface Semantics Contract

Target engine: Godot 4.7.x.

## Scope

```text
components/world/surfaces
```

This subsystem gives world geometry a small semantic identity that unrelated
systems can query after a collision.

It currently exposes:

```text
NucleusSurfaceProfile
NucleusSurfaceQuery3D
NucleusSurfaceSource3D
NucleusSurfaceProvider3D
NucleusSurfaceResolver3D
```

There is no surface manager or Autoload.

## Ownership

A surface profile answers only:

> "What kind of surface did this collision hit?"

It deliberately does not answer:

```text
which footstep sound to play
which decal texture to spawn
which particle effect to emit
how much damage to apply
which PhysicsMaterial to use
how wet/slippery the surface is for one game's rules
```

Those are independent consumers or native Godot physics data.

Typical flow:

```text
Godot physics collision
        ↓
NucleusSurfaceResolver3D
        ↓
NucleusSurfaceProfile
        ↓
project-owned response mapping
   ├── audio
   ├── decals
   ├── particles
   └── gameplay
```

This avoids one large surface resource becoming an implicit dependency between
unrelated systems.

## NucleusSurfaceProfile

A profile is a reusable Resource with:

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

## Static surface providers

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

## Resolution order

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
This is how a future procedural terrain or water source can accept some world
positions while falling back for others.

Prefer providers close to the geometry they describe. Ancestor-level providers
are best used as deliberate defaults for a coherent world subtree.

## Querying a RayCast3D

For footsteps, weapon impacts, interaction probes, or placement checks:

```gdscript
var surface := NucleusSurfaceResolver3D.resolve_raycast(floor_ray)

if surface != null:
	play_footstep_for(surface.surface_id)
```

The resolver reads the native collider, collision point, normal, collider shape,
and face index from `RayCast3D`.

No second physics query is performed.

## Querying CharacterBody collisions

For movement code that already owns a `KinematicCollision3D`:

```gdscript
var collision := character.get_last_slide_collision()
var surface := NucleusSurfaceResolver3D.resolve_kinematic_collision(collision)
```

Again, the resolver consumes existing Godot collision data rather than casting a
second ray.

## Direct queries

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

## Dynamic surface sources

`NucleusSurfaceSource3D` is the extension boundary for position-dependent
surfaces.

Subclass it and override:

```gdscript
func _resolve_surface(
	query: NucleusSurfaceQuery3D,
) -> NucleusSurfaceProfile:
	# Inspect query.world_position / normal / shape / face.
	return selected_profile
```

This is intentionally the extension point for later systems such as:

```text
procedural terrain layers
painted material masks
runtime wetness layers
ocean/river surfaces
mesh-face material lookup
```

Those systems can become smarter without changing footsteps, impacts, decals,
or other consumers. Consumers still receive one `NucleusSurfaceProfile`.

Nucleus does not currently ship a terrain-layer source. The built-in terrain
material blends several visual layers, so declaring a CPU semantic winner needs
a precise CPU/GPU matching contract rather than guessing from texture names.

## Smart decal integration

Surface classification chooses *what* presentation to use. SmartDecal owns *how*
a selected decal is aligned and expired.

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

Surface provider Nodes are runtime scene composition and should not be persisted.
Profiles are project Resources.

If durable game state needs to remember a surface type, persist the stable
`surface_id`, not a Node path or live Resource reference. A game that renames
persisted ids owns the corresponding save migration.

For multiplayer, authoritative gameplay should resolve the authoritative
collision. Clients may independently resolve surfaces for presentation when the
result does not affect authority.

## Performance

There is no polling manager and no global registry.

Resolution walks a small local ownership chain only when the caller requests a
surface. Use existing collision results where possible instead of adding extra
raycasts.

For very high-frequency contact simulation, cache game-specific results when the
collider/shape is known to be stable, or implement a specialized source closer
to the physics owner. Do not turn the generic resolver into a per-frame scene
scan.

## 2D boundary

`NucleusSurfaceProfile` itself is dimension-neutral. This first production
resolver is 3D because the proven use cases are 3D footsteps, impacts, decals,
and world interaction.

A future 2D resolver can reuse the same profile contract without changing saved
ids or response mappings. Nucleus does not add 2D parity speculatively.

## What stays game-owned

```text
footstep cadence and sound libraries
impact/decal/particle selection
weapon material response rules
terrain layer semantic policy
wetness, temperature, conductivity or traversal rules
surface-specific damage formulas
content authoring taxonomy beyond ids/tags
```

Repeated production friction in those areas can justify a later focused
component without expanding this base contract prematurely.
