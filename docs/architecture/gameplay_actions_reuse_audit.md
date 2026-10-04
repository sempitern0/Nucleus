# Gameplay Actions — Reuse Audit

Iteration 13 was designed against the current Nucleus main after Movement +
Camera had passed Godot runtime validation.

## Existing systems reused

### ValuePool

Action costs consume:

```text
NucleusValuePool
```

Action effects can also apply one-shot deltas to the same pool.

No new health/stamina/mana numeric storage exists.

### Cooldown

Actions use:

```text
NucleusCooldown
```

rather than embedding another Timer/cooldown implementation.

Iteration 13 only extends Cooldown with snapshot capture/restore so remaining
cooldown participates in Save.

### State machine

Requirements can gate an action by current `NucleusState`.

Effects can transition the existing `NucleusStateMachine`.

There is no ability-specific state machine.

### Input

`NucleusGameplayActionInput` consumes the event stream already exposed by:

```text
NucleusMotionInput
```

That component in turn already integrates `NucleusLocalPlayerInput`.

No new controller-id/device assignment code exists in Actions.

### Audio

`NucleusAudioCueEffect` uses:

```gdscript
NucleusAudio.play_cue()
```

No second one-shot audio pool or SFX manager exists.

### Camera

`NucleusCameraFovEffect` drives:

```text
NucleusCameraFov3D
```

The action system does not manipulate Camera3D FOV directly.

### UI

`NucleusActionButtonBinding` uses a normal `BaseButton`.

The component updates `disabled`; Theme/focus/tooltip/accessibility remain native
Godot/UI-toolkit concerns.

### Save

ActionSet exposes explicit snapshot methods for registration with
`NucleusSaveSession`.

No global save discovery is introduced.

### Utilities and diagnostics

Tree discovery uses:

```text
NucleusNodeUtils
```

Configuration diagnostics use:

```text
NucleusLog
```

## Barebone audit

Barebone did not contain a coherent reusable ability framework.

Ability-like behavior was distributed across feature booleans and specialized
controllers. For example, grabber abilities and the old FirstPersonController
owned their feature switches directly.

That approach works for a single game controller but scales poorly when actions
need shared:

```text
costs
cooldowns
state restrictions
AI execution
UI availability
save/load
local multiplayer input
```

Iteration 13 therefore salvages the feature-composition intent, not those
classes.

## Why not a global AbilityManager

Abilities belong to an actor/session entity.

A global manager would need entity ids, lookups, lifetime cleanup, multiplayer
routing, and ownership rules just to reach Nodes already present in the scene.

`NucleusActionSet` remains scene-owned.

## Why actions are Nodes, not only Resources

Action execution depends on runtime Nodes:

```text
ValuePool
StateMachine
Cooldown
CameraFov
MotionInput
```

Representing the whole runtime action as a shared Resource would create fragile
scene references or force another service locator.

Reusable static configuration can still be added later as Resources if a real
cross-project need appears.

## Why Effects are ordered

Effects execute in scene-tree discovery order.

This makes orchestration visible in the editor:

```text
Action
├── StateTransition
├── CameraFov
└── Audio
```

instead of hiding order inside a global registry.

If ordering becomes game-critical, keep the relevant effects as direct children
in the intended order.

## Deferred systems

Iteration 13 deliberately does not add:

```text
status-effect stacking
attribute modifier graphs
target selection / lock-on
object pooling
projectile ownership
inventory/equipment
animation graphs
network prediction
```

The next most useful layer is status/modifier lifetime, because it can build on
Action execution and then feed Movement, Damage, ValuePools, and UI.
