# Iteration 24 — Optional AI / Navigation

## Objective

Add reusable NPC decision and navigation composition without introducing a
monolithic Enemy inheritance tree or replacing Godot navigation.

## Audited base

Prepared read-only against:

```text
sempitern0/Nucleus
main
3a5fa19ec9b2e6329798e054928e7e46c47c7390
```

Iteration 23 Persistent World State is present and user-validated.

## Barebone reuse audit

Barebone contributed useful concepts:

```text
idle patrol
random local navigation destinations
NavigationAgent3D next-path following
smooth facing
```

Its Enemy class coupled CharacterBody, navigation, animation, hurtbox, FSM,
collision policy and floor alignment. That architecture is not retained.

Smooth facing is already solved by Nucleus movement components.

## Architecture

```text
TargetingAgent
    perception/selection
        ↓
AIContextProvider
        ↓
UtilityBrain
    intention
        ↓
AIStateMachineBridge
        ↓
NucleusStateMachine
    behavior
        ↓
NavigationFollower
    path velocity
        ↓
game locomotion
```

Godot NavigationAgent/NavigationServer remain the pathfinding and avoidance
source of truth.

## Utility AI

Added:

```text
NucleusAIContextProvider
NucleusAIConsideration
NucleusAIContextFloatConsideration
NucleusAIContextBoolConsideration
NucleusAIUtilityOption
NucleusAIUtilityBrain
NucleusAITargetContextProvider
NucleusAIStateBinding
NucleusAIStateMachineBridge
```

Context providers may signal changes to request immediate brain reevaluation.

## Navigation

Added:

```text
NucleusNavigationPolicy
NucleusNavigationFollower2D
NucleusNavigationFollower3D
NucleusNavigationQueries2D
NucleusNavigationQueries3D
NucleusNavigationWander2D
NucleusNavigationWander3D
```

Followers throttle moving-target repaths and own the required
`get_next_path_position()` physics update.

They do not move CharacterBodies.

## Avoidance

Native RVO remains opt-in.

Followers feed desired velocity to NavigationAgent and expose native safe
velocity when avoidance is enabled.

## Version

```text
0.5.0-dev.1
→
0.6.0-dev.1
```

## Validation

Headless coverage includes:

```text
float context normalization/inversion
Boolean utility gates
option multiplication
priority tie-breaking
current-option hysteresis
repath throttling
invalid-map query fallback
```

Godot CI remains the compile/runtime/export gate.

## Next step

The next roadmap candidate is Save-slot presentation UI, but after this iteration
the planned real game's requirements should increasingly decide whether further
optional modules are worth adding before production starts.
