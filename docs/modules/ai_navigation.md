# Optional AI / Navigation Module

`modules/ai` is optional and scene-owned. It separates **decision** from
**navigation** and reuses existing Nucleus targeting/state/movement plus native
Godot NavigationAgent APIs.

## Ownership

```text
TargetingAgent
    perception / selected target
        ↓
UtilityBrain
    choose intention
        ↓
StateMachine / game state
    execute behavior
        ↓
NavigationFollower
    path intent / safe velocity
        ↓
movement owner
    actual locomotion
```

The module does not provide an Enemy base class, global AI manager, duplicate
perception registry, Behavior Tree/GOAP framework or replacement NavigationServer.

## Utility AI

`NucleusAIUtilityBrain` evaluates `NucleusAIUtilityOption` resources. Scores are
base score multiplied by normalized considerations. Explicit priority breaks equal
scores, then authored array order is deterministic.

`current_option_bonus` provides small hysteresis around close decisions.

Context providers contribute side-effect-free ephemeral values and may notify the
brain when an event warrants reevaluation.

## Scheduled evaluation

Automatic Utility AI may bind to `NucleusUpdateScheduler`. With a positive
`evaluation_interval`, scheduled brains can use automatic phase staggering so a
large spawn does not align every future decision on the same frame.

Context-change requests remain eligible for prompt reevaluation. Without a
scheduler, the previous physics-driven cadence remains valid.

## Navigation followers

`NucleusNavigationFollower2D/3D` own target/repath throttling,
`get_next_path_position()`, desired velocity and optional native RVO velocity
handoff. They do not call `move_and_slide()` or own the actor's locomotion.

Moving targets require both displacement and minimum-time thresholds before a new
path target is requested. Avoidance is opt-in because it has meaningful runtime
cost with many agents.

## Persistence / networking

Persist durable actor state and reconstruct native path internals after load.
For authoritative multiplayer, run decision/navigation/gameplay movement on the
authority and replicate resolved state; this module defines no RPC protocol.
