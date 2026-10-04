# Gameplay Component Reuse Audit

This audit was performed against the current Nucleus main branch before adding
the first gameplay primitives.

The objective is to prevent Components from rebuilding infrastructure that
already exists in Core.

## Existing Nucleus APIs reused

### Input

Existing:

```text
NucleusInputActions.INTERACT
NucleusLocalPlayerInput
NucleusLocalInputSession
```

New interaction code therefore does not introduce:

```text
another interact action constant
another per-gamepad router
another current-controller manager
```

`NucleusInteractionInput.bind_local_player_input()` consumes the existing
per-player event stream.

### Node traversal

Existing:

```text
NucleusNodeUtils.descendants()
NucleusNodeUtils.ancestors()
```

Used for:

```text
automatic component discovery
interaction candidate resolution
state discovery
damage receiver/value-pool lookup
```

No new recursive SceneTree helper was created.

### Collection helpers

Existing:

```text
NucleusArrayUtils.intersects()
```

Used by damage immunity tags.

No private "do these tag lists overlap?" implementation was added.

### Save

Existing:

```text
NucleusSaveSession.register_participant()
```

Gameplay components expose small:

```text
capture_state()
restore_state()
```

methods instead of introducing a second save registration mechanism.

### Diagnostics

Configuration failures use:

```text
NucleusLog
```

rather than `print()`, ad-hoc push_error patterns, or another logger.

### Native Godot APIs intentionally kept native

Reuse does not mean wrapping every engine call.

The following remain direct Godot facilities:

```text
Timer
Area2D / Area3D
TranslationServer
InputEvent.is_action_pressed()
queue_free()
```

Nucleus only adds behavior when it materially reduces repeated project code.

## Existing APIs deliberately not used

### EventBus

Gameplay primitives use local signals.

The optional EventBus remains opt-in and is not required by Components.

### Settings

Gameplay state such as health, cooldown duration, or interaction limits is scene
configuration, not application settings.

### Scene Flow

Gameplay primitives do not change scenes.

### UUID

Runtime components do not invent persistent IDs unless a game actually needs
them.

### Audio

Combat and interactions emit signals but do not automatically play sounds.
Projects can connect those signals to `NucleusAudio` without coupling gameplay
state to presentation.

## Barebone salvage decisions

### Health

Retained concepts:

```text
bounded health
overflow
regeneration
invulnerability
death threshold
```

Redesigned as:

```text
ValuePool
Regenerator
DamageReceiver
depleted signal
```

This removes the old coupling of health, regen, invulnerability timers, and
death behavior into one class.

### Hitbox / Hurtbox

Retained:

```text
Area-based separation between attack volume and receiving volume
2D and 3D equivalents
enable/disable behavior
```

Removed:

```text
Globals collision-layer constants
hardcoded project layer ownership
damage calculation inside physics object classes
```

### Interactions

Retained:

```text
focus/unfocus
interaction count limits
activation
2D/3D area detection
semantic interact input
```

Removed:

```text
cursor ownership
reticle ownership
player locking
global interactables groups
Input singleton polling inside world objects
hardcoded interaction layers
```

Those are presentation/controller policies and belong above the generic
interaction contract.

### Machina state machine

Retained:

```text
Node states
enter / exit
process / physics / input hooks
state history
guardable transitions
```

Removed:

```text
script-class state lookup
mandatory transition objects
mutable Array transition keys
state-stack policy in the core transition path
multiple aliases for the same transition method
```

The old implementation also built the target state incorrectly in
`register_transition()` and updated `current_state` only after entering the new
state. Nucleus uses direct state instances and updates ownership before
`enter()`.

## Deferred to later component iterations

These remain valuable but should build on this base rather than be mixed into
Iteration 11:

```text
2D locomotion
3D locomotion
camera rigs
raycast interactors
object pooling
status effects
ability system
targeting/lock-on
knockback/impulse policies
```
