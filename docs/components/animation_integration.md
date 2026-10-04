# Animation Integration

Target engine: Godot 4.7.x.

Nucleus does not replace `AnimationPlayer` or `AnimationTree`.

Animation integration consists of small adapters that translate existing Nucleus
runtime state into native AnimationTree parameters.

## Components

```text
NucleusStateAnimationMapping
NucleusAnimationTreeStateBinding
NucleusAnimationVelocityBinding2D
NucleusAnimationVelocityBinding3D
NucleusAnimationTreeStateEffect
NucleusAnimationTreeOneShotEffect
NucleusAnimationEventRelay
```

## FSM to AnimationTree

`NucleusAnimationTreeStateBinding` observes:

```text
NucleusStateMachine.state_changed
```

and obtains native state-machine playback through:

```gdscript
animation_tree.get("parameters/playback")
```

It then calls:

```gdscript
AnimationNodeStateMachinePlayback.travel()
```

Mappings are Resources:

```text
Nucleus state id
→ AnimationTree state name
```

When `use_state_id_as_fallback` is enabled, matching names require no mapping
Resource.

Example:

```text
Nucleus FSM        AnimationTree

idle          →    Idle
move          →    Locomotion
fall          →    Air
```

This keeps gameplay FSM and animation graph independent.

## Locomotion parameter adapters

Velocity bindings read native `CharacterBody2D/3D.velocity`.

This means they work naturally with the existing Nucleus motors without the
animation layer depending on motor implementation.

2D can write:

```text
speed: float
direction: Vector2
moving: bool
```

3D can write:

```text
speed: float
blend direction: Vector2
grounded: bool
vertical speed: float
moving: bool
```

Every parameter path is optional.

If an exported parameter is empty, the adapter does not write it.

## Local versus world motion

The 2D and 3D velocity bindings can transform velocity through an
`orientation_source`.

Typical third-person setup:

```text
CharacterBody velocity
        ↓
camera/player orientation
        ↓
local forward/right blend vector
        ↓
AnimationTree BlendSpace2D
```

This avoids encoding camera-relative movement into the animation graph itself.

## GameplayAction integration

Two Action effects are provided.

### State-machine travel

```text
NucleusAnimationTreeStateEffect
```

Use for actions that should request a state in an AnimationTree state machine.

### OneShot

```text
NucleusAnimationTreeOneShotEffect
```

Writes:

```text
AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
```

to an exported AnimationTree request parameter.

This is suitable for:

```text
attack
reload
interact
flinch
gesture
```

when the graph uses an AnimationNodeOneShot.

The GameplayAction pipeline remains the execution authority.

## Animation events

`NucleusAnimationEventRelay` is intended as the target of AnimationPlayer method
tracks.

Instead of an animation calling a weapon/player script directly:

```text
AnimationPlayer method track
        ↓
AnimationEventRelay.emit_event("attack_hit")
        ↓
local signal
        ↓
gameplay consumer
```

This keeps animation assets reusable and avoids introducing a global EventBus.

The optional payload is a Variant so project-specific data may be supplied by
the animation key when appropriate.

## What Nucleus does not own

Not included:

```text
animation graph generation
animation retargeting
root-motion policy
combo authoring
motion matching
IK rigs
animation state naming conventions
```

Those are project/animation-pipeline decisions.

Nucleus only removes repeated glue between gameplay state and Godot's native
animation systems.
