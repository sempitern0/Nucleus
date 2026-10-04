# Optional AI / Navigation Module

## Status

`modules/ai` is optional and is not loaded by default.

It deliberately separates:

```text
Utility AI
    chooses the current intention

Navigation
    converts a destination into desired/safe movement velocity
```

It does not introduce an Enemy base class, global AI manager, second FSM,
duplicate perception layer, or replacement for Godot navigation.

## Barebone reuse audit

Barebone demonstrated useful patterns:

```text
idle patrol
random local navigation destinations
NavigationAgent3D path following
smooth movement facing
```

The old Enemy implementation also owned CharacterBody3D, animation, hurtbox,
FSM, floor alignment, collision policy and navigation in one actor class.

Nucleus keeps the reusable behaviors and rejects that ownership model.

Smooth movement facing already exists in the baseline and is not duplicated.

## Existing systems reused

```text
NucleusTargetingAgent
    perception, filtering and target selection

NucleusStateMachine
    state enter/exit/update lifecycle

Godot NavigationAgent2D/3D
    path following and RVO avoidance

Nucleus movement/facing
    actual locomotion/orientation when appropriate
```

AI / Navigation provides the orchestration between these responsibilities.

## Utility AI

`NucleusAIUtilityBrain` evaluates `NucleusAIUtilityOption` Resources.

Each option contains:

```text
option_id
base_score
priority
considerations
tags
```

Utility is calculated as:

```text
base_score
× consideration A
× consideration B
× ...
```

Every consideration returns a normalized `0.0 .. 1.0`.

A zero result therefore acts as a natural veto.

Equal scores use explicit `priority`. If score and priority are both equal,
array order is the deterministic final tie-break.

## Decision stability

`current_option_bonus` adds small hysteresis to the current intention.

This reduces transitions that oscillate around nearly equal scores.

Use small values. A large bonus should not replace well-shaped utility curves.

## Context

`NucleusAIContextProvider` contributes ephemeral runtime values to one
evaluation Dictionary.

Providers must be side-effect free.

The base context contains:

```text
actor
brain
```

Project providers can contribute values such as:

```text
health_ratio
ammo_ratio
time_since_hit
distance_home
cover_quality
objective_pressure
```

Providers can call `notify_context_changed()` when an event makes immediate
reevaluation desirable. The brain listens to providers under `context_root` and
sets an evaluation request without forcing every NPC to evaluate every frame.

## Targeting integration

`NucleusAITargetContextProvider` reads the existing
`NucleusTargetingAgent.current`.

Default context keys:

```text
has_target
targetable
target
target_point
target_position
target_distance
```

A change to the selected target requests an immediate AI reevaluation.

No second perception/agro registry exists in this module.

## Considerations

### Boolean

`NucleusAIContextBoolConsideration`

Use for gates such as:

```text
has_target
has_ammo
is_alerted
can_attack
```

### Float

`NucleusAIContextFloatConsideration`

Maps:

```text
minimum_value → 0
maximum_value → 1
```

and optionally remaps the normalized value with a native Godot `Curve`.

`invert = true` returns `1 - score`.

Examples:

```text
low health     → high flee utility
short distance → high attack utility
low ammo       → high reload utility
```

Games can derive `NucleusAIConsideration` for domain-specific reasoning.

## FSM bridge

`NucleusAIStateMachineBridge` maps utility option IDs to existing
`NucleusStateMachine` state IDs using `NucleusAIStateBinding`.

Example:

```text
patrol → Patrol
chase  → Chase
attack → Attack
flee   → Flee
```

Utility AI chooses an intention.

The existing FSM remains responsible for behavior execution, transition rules,
state lifecycle and persistence.

This keeps simple/medium NPCs out of an unnecessary Behavior Tree framework.

## Navigation followers

`NucleusNavigationFollower2D` and `NucleusNavigationFollower3D` wrap the
repetitive NavigationAgent update contract.

They own:

```text
static and moving targets
moving-target repath throttling
get_next_path_position() physics updates
desired path velocity
native RVO velocity handoff
destination completion
NavigationLink notification
```

They do not call `move_and_slide()`.

The actor/game state remains responsible for locomotion.

This lets one follower drive:

```text
CharacterBody
root-motion controller
vehicle
flying actor
custom kinematic motor
```

without baking one movement model into AI.

## Repath policy

Moving targets must not reset `NavigationAgent.target_position` every frame.

Followers require both:

```text
target_repath_distance
minimum_repath_interval
```

before requesting another target path.

`request_repath()` invalidates that cache for the next physics update.

## Avoidance

If native NavigationAgent avoidance is disabled:

```text
output_velocity = desired path velocity
```

If avoidance is enabled:

```text
desired velocity
→ NavigationAgent.velocity
→ NavigationServer avoidance
→ velocity_computed
→ output_velocity
```

`velocity_ready` exposes the velocity the locomotion layer should consume.

Avoidance is deliberately not enabled by Nucleus. It has a meaningful runtime
cost with many agents.

RVO is also not pathfinding and may move an actor away from the ideal corridor.

## 3D movement policy

`NucleusNavigationFollower3D.planar_movement = true` defaults to XZ movement.

This leaves vertical velocity to gravity/jump logic.

Disable it for true 3D locomotion:

```text
flying
underwater
zero gravity
space
```

Configure the native NavigationAgent avoidance mode accordingly.

## Navigation links

Followers reemit:

```text
navigation_link_reached(details)
```

Use this extension point for project-specific traversal:

```text
jump
ladder
vault
door
teleport
special traversal animation
```

The module does not define a universal traversal system.

## Wander / patrol

`NucleusNavigationWander2D/3D` is an optional destination producer.

It waits, samples a local navigation point around an anchor, sends it to the
follower, then waits again when navigation completes.

This is the compositional replacement for Barebone's patrol behavior.

Designer-authored waypoint patrols should normally be implemented by a Patrol
state that calls the follower directly.

## Navigation queries

`NucleusNavigationQueries2D/3D.random_point_in_radius()` adds only a small query
that Godot does not directly expose:

```text
local random offset
→ snap to navigation map
→ navigation-layer validation
→ radius validation
```

Ordinary pathfinding and whole-map random point APIs stay native.

## Navigation data ownership

This module does not bake navigation meshes.

Projects continue to own native:

```text
NavigationRegion2D/3D
NavigationPolygon / NavigationMesh
NavigationServer2D/3D
NavigationLink2D/3D
NavigationObstacle2D/3D
navigation maps/layers
```

Navigation meshes must be baked for the dimensions of the actors that use them.

## Persistence

Do not persist native path internals.

Persistent actors should save durable state:

```text
FSM state
world transform
attributes
inventory
alert/quest flags
```

and reconstruct navigation intent after loading.

This composes with `modules/world_state`.

## Networking

For authoritative multiplayer, normally run:

```text
perception
decision
navigation
gameplay movement
```

on the server/authority and replicate resolved actor/gameplay state.

This module has no RPC protocol.

## Not included

```text
Behavior Tree framework
GOAP
EQS
blackboard singleton
AIManager
duplicate perception
cover tactics
squad coordination
crowd manager
runtime navmesh baking manager
AI replication
```

Those features need concrete project evidence before they belong in Nucleus.
