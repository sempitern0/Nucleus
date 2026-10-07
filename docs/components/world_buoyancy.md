# World Buoyancy Contract

Target engine: Godot 4.7.x.

## Scope

```text
components/world/buoyancy
```

This subsystem provides bounded multi-point buoyancy for native `RigidBody3D`
objects against a `NucleusSurfaceSampler3D`.

Public type:

```text
NucleusBuoyancy3D
```

There is no buoyancy manager, fluid manager, Autoload, custom rigid-body class,
or replacement physics engine.

## Ownership boundary

The intended dependency direction is:

```text
project-owned fluid/ocean/river field
        ↓
NucleusSurfaceSampler3D
    position + surface velocity
        ↓
NucleusBuoyancy3D
    displacement + damping + drag
        ↓
native RigidBody3D
        ↓
Godot / Jolt integration
```

The sampler owns the analytical surface query. Buoyancy owns the generic force
model. The consuming game still owns the actual water/ocean equations, authored
body shape, tuning values, visuals, sounds, wake generation, swimming, and
vehicle rules.

`NucleusBuoyancy3D` does not modify the sampled surface and never feeds wake or
other presentation back into physical height queries.

## Scene composition

Prefer a buoyancy component directly below its body:

```text
Crate : RigidBody3D
├── CollisionShape3D
├── MeshInstance3D
└── Buoyancy : NucleusBuoyancy3D
        surface_sampler = WaterSurface
```

`body` can be assigned explicitly, but when it is empty the component resolves
the nearest `RigidBody3D` ancestor. `surface_sampler` stays explicit because the
surface normally lives elsewhere in the world and Nucleus does not scan scenes
for one.

The component applies normal Godot forces during `_physics_process()`. It does
not teleport the rigid body, assign transforms, or replace native integration.

## Displacement model

Buoyancy uses vertical volume columns centered on `sample_points`.

Defaults are four local-space points around the body:

```text
(-0.5, 0, -0.5)    (0.5, 0, -0.5)
(-0.5, 0,  0.5)    (0.5, 0,  0.5)
```

`displacement_volume` is the total maximum displaced volume in cubic metres.
The current implementation divides that volume equally across all sample
points.

`column_height` controls the vertical depth over which one point moves from dry
to fully submerged:

```text
surface above top of column    → submerged = 1
surface through column centre  → submerged = 0.5
surface below bottom           → submerged = 0
```

This is an approximation for hulls, crates, debris, rafts, buoys, and similar
objects. It is not volumetric mesh clipping or computational fluid dynamics.

## Archimedes capacity

For standard Godot units:

```text
maximum supported mass ≈ fluid_density × displacement_volume
```

For example:

```text
1000 kg/m³ × 1.0 m³ = 1000 kg
1025 kg/m³ × 1.0 m³ = 1025 kg
```

`get_displacement_capacity_kg()` exposes that authored capacity for diagnostics
and UI tooling.

Mass remains the native `RigidBody3D.mass`. Nucleus never changes it to make an
object float.

If body mass exceeds displacement capacity, full submersion cannot provide
enough Archimedes lift and the body sinks naturally.

## Damping

Each column estimates stiffness from:

```text
fluid density
× gravity magnitude
× volume per point
÷ column height
```

`buoyancy_damping_ratio` is applied as an approximate critical-damping ratio.
A value near `1.0` is a useful baseline; lower values permit more oscillation and
higher values damp more aggressively.

The damping coefficient is capped by `point_mass / physics_step`. This protects
very light bodies or extreme authored displacement from producing an unstable
single-frame correction.

Vertical damping uses relative velocity between the body point and the sampled
surface. A moving analytical wave can therefore transfer its vertical motion to
a floating body without making the renderer authoritative.

Lift is clamped to zero after damping. A falling surface does not pull an
emerged body downward or glue it to the water.

## Recovery limit

`maximum_lift_acceleration` caps lift per point relative to that point's share of
body mass and current gravity magnitude.

This is primarily a stability bound for objects dropped deeply into the medium
or objects whose authored volume is very large relative to mass.

It is not a substitute for coherent mass, hull dimensions, and displacement
volume.

## Drag

`linear_drag` is a simple first-order horizontal drag coefficient. For each wet
point Nucleus drives X/Z point velocity toward `SurfaceSample3D.velocity`.

Vertical drag is deliberately excluded because column damping already owns the
vertical response.

`angular_drag` applies torque opposing the body's angular velocity, scaled by
mass and current wet fraction.

These are practical game-physics approximations, not viscosity or Reynolds-number
models.

## Surface velocity

The sampled velocity is critical for moving media:

```text
static lake      → Vector3.ZERO
river/current    → horizontal flow
analytical ocean → current + vertical wave velocity
```

The body point velocity includes both native linear velocity and the rotational
velocity at that offset.

This keeps drag and damping relative to the medium rather than relative to world
zero.

## SurfaceSampler3D integration

Buoyancy uses `sample_into()` with one reusable `NucleusSurfaceSample3D` object.
It therefore avoids allocating one sample object per point per physics tick.

A failed surface sample treats that point as dry for that tick. This allows
bounded samplers and analytical domains to reject positions cleanly.

The current `SurfaceSampler3D` contract is a world-X/Z height field, so buoyancy
uses world Y for submersion and world +Y for lift. Arbitrary sideways gravity or
closed/multi-layer fluid geometry is outside this first contract.

## Physics and transforms

Keep buoyant `RigidBody3D` nodes at unit scale.

Author these together in metres:

```text
collision dimensions
visible hull dimensions
sample point positions
column_height
displacement_volume
```

The component warns about non-unit global body scale because scaling points
without coherently scaling displaced volume produces physically misleading
results.

Native collision and inertia remain Godot/Jolt responsibilities.

`RigidBody3D.custom_integrator` is not supported by the automatic component
path. Custom integration disables the standard force integration that
`NucleusBuoyancy3D` expects, so the component emits a configuration warning.
Projects that intentionally own a custom integrator should own the corresponding
buoyancy integration glue as well.

## Sleeping

Nucleus does not silently change `RigidBody3D.can_sleep` or force a body awake.
Use native sleep policy appropriate for the project.

For continually animated surfaces where sleeping bodies must respond to waves,
a game may disable sleeping for those bodies explicitly. Static lakes normally
do not require a framework-level sleep policy.

## Multiplayer authority

`require_multiplayer_authority` defaults to `true`.

With no active multiplayer peer, buoyancy runs normally. With multiplayer
active, only the body's multiplayer authority applies buoyancy forces.

Recommended authoritative shape:

```text
server / host authority
    owns analytical surface time + rigid-body simulation
        ↓
NucleusBuoyancy3D
        ↓
authoritative RigidBody3D
        ↓
normal transform/state replication
```

Do not run duplicate client-side physical buoyancy and then attempt to reconcile
two independent simulations.

Clients may independently sample the same surface for presentation when that
cannot affect authority.

## Nautica migration shape

Nautica's current buoyant body proves the reusable model but should not be copied
wholesale into Nucleus.

The desired game-owned composition is:

```text
Ocean
    analytical waves + simulation_time + OceanProfile
        ↓
NauticaOceanSurfaceSampler3D
        ↓
NucleusBuoyancy3D
        ↓
boat / crate RigidBody3D
```

The thin Nautica sampler converts its current wave result into:

```text
surface position
surface normal
current velocity + vertical wave velocity
```

Nautica then authors `fluid_density` from its ocean profile and keeps boat,
beaching, swimming, wake rendering, weather, and sea-state policy in the game.

## Diagnostics

Useful runtime queries:

```gdscript
var wet := buoyancy.get_wet_fraction()
var sampled := buoyancy.get_sampled_point_count()
var capacity := buoyancy.get_displacement_capacity_kg()
```

`wet_fraction` is averaged across all authored points. Points outside the sampler
domain contribute zero wetness.

`sampled_point_count` reports how many points received a valid analytical
surface sample on the last physics tick. It is useful for catching domain/wiring
problems without adding a global diagnostics manager.

## Performance

Per physics tick, one component performs approximately:

```text
N surface queries
N point-force calculations
up to N apply_force calls
up to 1 apply_torque call
```

where `N = sample_points.size()`.

The component stores one reusable sample object. It does not raycast, allocate a
node per point, perform GPU readback, or create a physics body of its own.

Sampler cost still matters. An analytical ocean evaluating several waves per
point can become expensive when multiplied across many bodies. Start with a
small number of well-spaced points and profile the real target hardware before
increasing hull fidelity.

## What stays game-owned

Nucleus intentionally does not decide:

```text
ocean / river equations
fluid-density values for a specific world
exact hull point placement
boat handling and propulsion
keels, rudders, sails or planing forces
beaching / grounding rules
swimming and diving
wake / foam / splash presentation
sound and impact feedback
cargo/passenger mass policy
network replication transport
quality adaptation
volumetric mesh-fluid intersection
CFD / pressure-field simulation
```

The reusable boundary is deliberately small: sample a height-field surface and
apply stable approximate buoyancy to a native rigid body.
