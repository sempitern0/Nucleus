# Targeting and Sensing

Target engine: Godot 4.7.x.

Targeting is a scene-owned perception/selection layer.

It does not decide combat rules, input bindings, camera behavior, AI state, or
what an action does.

For editor-first setup:

```text
docs/guides/targeting_sensing_quickstart.md
```

## Architecture

```text
World physics
    │
    ├── AreaSensor2D/3D
    └── RaySensor2D/3D
            │
            ▼
      TargetingAgent
      candidates
            │
        ┌───┴────┐
        ▼        ▼
      Filters   Scorers
        │        │
        └───┬────┘
            ▼
     current Targetable
            │
     ┌──────┼────────────┬──────────────┐
     ▼      ▼            ▼              ▼
   lock   Actions    Interaction       AI/game code
           context       bridge
```

There is no global TargetManager.

## NucleusTargetable

A `NucleusTargetable` marks one scene object as eligible for targeting.

It provides:

```text
target Node
target point Node
enabled
priority
tags
```

`target` is the gameplay object consumers should receive.

`target_point` is the spatial point used for:

```text
distance
angle
line of sight
screen position
aiming
```

Recommended 3D actor:

```text
Enemy : CharacterBody3D
├── CollisionShape3D
├── Targetable : NucleusTargetable
└── TargetPoint : Marker3D
```

Configure:

```text
Targetable.target = Enemy
Targetable.target_point = TargetPoint
```

The endpoint is dimension-neutral. Its target point may be Node2D or Node3D.

Tags are project-owned:

```text
enemy
ally
boss
vehicle
interactable
weak_point
```

Nucleus reserves none.

## Candidate ownership

Candidates are registered by source ownership.

Conceptually:

```text
Enemy A
├── registered by VisionArea
└── registered by CrosshairRay
```

If the ray stops seeing Enemy A, only the ray's registration disappears.

The candidate remains while VisionArea still owns its registration.

This prevents multiple sensors from accidentally unregistering one another.

## Selection

`NucleusTargetingAgent` owns:

```text
candidate registry
current target
lock state
filter discovery
scorer discovery
refresh scheduling
```

The agent's base score starts with:

```text
Targetable.priority
```

and adds every enabled `NucleusTargetScorer`.

Higher score wins.

Equal scores are resolved by instance id so Dictionary traversal order cannot
change selection.

## Selection stability

Moving targets can otherwise cause current selection to oscillate.

The agent adds:

```text
current_target_bonus
```

to the currently selected target while not locked.

This creates a small selection hysteresis.

Projects should tune it relative to their scorer magnitudes.

## Automatic refresh

Selection normally refreshes in `_physics_process()`.

Default:

```text
refresh_interval = 0.10 seconds
```

Set:

```text
0.0
```

to refresh every physics frame.

This is deliberate because LOS filters use direct physics-space queries.

Input cycling uses the latest cached ranked list rather than rerunning physics
queries from an `_input()` callback.

## Locking

The agent supports:

```text
lock_current()
lock_target()
unlock_target()
toggle_lock()

select_next()
select_previous()
```

When locked, automatic scoring does not switch away from the locked target while
it remains valid.

If the target:

```text
is removed
becomes disabled
fails a filter
leaves sensor coverage
```

the agent releases the lock and selects another valid candidate.

Cycling while locked moves the lock to the next/previous ranked target.

## Filters

Filters answer:

```text
May this Targetable participate?
```

Built-ins:

```text
NucleusTargetTagFilter
NucleusTargetDistanceFilter2D
NucleusTargetDistanceFilter3D
NucleusTargetAngleFilter2D
NucleusTargetAngleFilter3D
NucleusTargetLineOfSightFilter2D
NucleusTargetLineOfSightFilter3D
NucleusTargetCameraFrustumFilter3D
```

Filters compose by AND.

A target must pass every enabled filter.

### Tags

Example:

```text
required_tags = [enemy]
blocked_tags = [dead]
```

Required tags may use:

```text
all
or
any
```

semantics.

### Distance

Distance filters use the agent's `origin`.

They do not duplicate the Area sensor.

Use both when useful:

```text
Area
→ cheap broad-phase candidates

DistanceFilter
→ gameplay distance rule
```

### Angle

2D uses local `+X` as forward.

3D uses Godot's conventional `-Z` forward.

`orientation_source` can be independent from `origin`.

Example third person:

```text
origin = Player
orientation_source = CameraRig
```

This makes candidate direction camera-relative without changing player
locomotion.

### Camera frustum

The 3D frustum filter calls the native:

```gdscript
Camera3D.is_position_in_frustum()
```

It can use an explicitly assigned Camera3D or the agent's orientation source
when that source is a Camera3D.

### Line of sight

LOS filters use:

```text
PhysicsRayQueryParameters2D/3D
World2D/3D.direct_space_state
intersect_ray()
```

The first hit is accepted if it resolves back to the target itself.

No hit also means clear line of sight.

The actor's source CollisionObject is excluded automatically even if the ray
origin is a child Marker/Camera.

Configure:

```text
collision mask
collide with bodies
collide with areas
```

using normal Godot physics semantics.

## Scorers

Scorers answer:

```text
Among valid targets, which is preferable?
```

Built-ins:

```text
NucleusTargetDistanceScorer2D
NucleusTargetDistanceScorer3D
NucleusTargetFacingScorer2D
NucleusTargetFacingScorer3D
NucleusTargetScreenCenterScorer3D
```

Each scorer has:

```text
enabled
weight
```

### Distance scorer

Returns negative distance.

Therefore nearer targets score higher.

`distance_scale` lets projects normalize units before applying `weight`.

### Facing scorer

Returns a forward-direction dot product:

```text
1   directly ahead
0   perpendicular
-1  directly behind
```

### Screen-center scorer

Uses:

```text
Camera3D.unproject_position()
```

and prefers targets near the visible viewport center.

This is particularly useful for third-person lock-on.

Use the frustum filter alongside it if only on-screen targets are valid.

## Sensors

Sensors discover candidates. They do not rank them.

### Area sensors

```text
NucleusTargetAreaSensor2D
NucleusTargetAreaSensor3D
```

are normal `Area2D/Area3D` subclasses.

Configure collision layers/masks and CollisionShape nodes with Godot's regular
Inspector.

They can observe:

```text
bodies
areas
or both
```

Multiple collision shapes resolving to the same Targetable count as one
candidate registration for that sensor.

### Ray sensors

```text
NucleusTargetRaySensor2D
NucleusTargetRaySensor3D
```

adapt existing Godot:

```text
RayCast2D
RayCast3D
```

The RayCast remains responsible for:

```text
target position
collision mask
exceptions
body/area detection
```

Nucleus only maps its collider to a Targetable and updates the agent.

Godot RayCast nodes already refresh every physics frame. The sensor can
optionally call `force_raycast_update()` when an immediate same-frame update is
required.

## Target resolver

`NucleusTargetResolver` converts physics collider Nodes into their nearby
Targetable endpoint using the existing `NucleusNodeUtils` traversal helpers.

This supports common trees where:

```text
CharacterBody
├── CollisionShape
└── Targetable
```

and the physics callback returns the CharacterBody.

## GameplayActions

Iteration 16 adds a generic:

```text
NucleusActionContextProvider
```

Action input and Action UI bindings can now compose child providers that enrich
their context without either adapter learning about targeting.

Targeting provides:

```text
NucleusTargetActionContext
```

which can add:

```text
context["target"]
context["targetable"]
```

to execution.

Example:

```text
PoisonStrike : GameplayAction
├── ApplyStatusEffect
└── ActionInput
    └── TargetActionContext
```

The existing `NucleusApplyStatusEffect` already knows how to resolve
`context["target"]`.

No new poison/target-specific Action code is required.

The same context flows into:

```text
NucleusSpawnActionEffect
```

so pooled projectiles can receive their intended target through
`Poolable.acquired(context)`.

## Target requirement

`NucleusTargetRequirement` derives from the existing Action requirement
contract.

It can require:

```text
any current target
a locked target
required target tags
absence of blocked target tags
```

Because it observes targeting signals, existing Action availability and
`NucleusActionButtonBinding` update automatically.

For a target-dependent Action, use both:

```text
TargetRequirement
TargetActionContext
```

The requirement defines availability.

The context provider supplies execution data.

## Input and local multiplayer

`NucleusTargetingInput` reuses `NucleusMotionInput.input_event_received`.

Therefore:

```text
NucleusLocalInputSession
        ↓
NucleusLocalPlayerInput
        ↓
NucleusMotionInput
        ├── movement
        ├── GameplayActionInput
        └── TargetingInput
```

remains the only device-routing path.

Targeting defines no mandatory InputMap actions.

Projects assign semantic actions such as:

```text
target_lock
target_next
target_previous
target_cancel
```

only if needed.

## Interaction bridge

`NucleusTargetingInteractionBridge` does not recreate Interaction resolution.

It uses the existing:

```text
NucleusInteractionCandidateTracker
```

to feed the selected Targetable into a `NucleusInteractor`.

This allows:

```text
crosshair target
or lock-on target
        ↓
existing Interaction
```

without merging both systems.

`only_when_locked` is available when merely hovering/selecting a target should
not make it interactable.

## AI

AI uses the same TargetingAgent without TargetingInput.

Example:

```text
Enemy AI
├── TargetingAgent
├── VisionArea : TargetAreaSensor3D
├── Filters
│   ├── enemy/faction tag filter
│   ├── vision cone
│   └── line of sight
└── Scorers
    └── distance
```

AI code observes:

```text
current_changed
```

and can execute the existing ActionSet:

```gdscript
actions.execute(
    &"attack",
    {
        "source": self,
        "target": targeting.current.get_target_node(),
    },
)
```

No separate AI perception target representation is required.

## Pooling

Pooled actors/projectiles may contain a Targetable.

Pool release disables collisions/process through `NucleusPoolable`, so Area/Ray
sensors naturally stop sensing them.

For project-specific pooled state, reset targeting metadata from the existing:

```text
Poolable.acquired
Poolable.released
```

signals if needed.

## What Targeting deliberately does not own

Not included:

```text
aim assist strength
projectile prediction
ballistics
camera rotation toward target
turret rotation
team/faction model
threat/aggro tables
AI memory
network replication
UI reticles
```

All can consume TargetingAgent/Targetable later.

They are not part of candidate discovery/selection.
