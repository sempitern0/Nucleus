# Animation + Game Feel — Reuse Audit

Iteration 17 follows Targeting + Sensing, which passed Godot runtime validation.

## Godot-native animation remains authoritative

Nucleus does not introduce an animation graph abstraction.

It uses:

```text
AnimationPlayer
AnimationTree
AnimationNodeStateMachinePlayback
AnimationNodeOneShot
```

directly.

FSM adapters call native `travel()`.

Action OneShot effects submit native OneShot requests.

Velocity adapters set AnimationTree parameters.

## FSM reuse

Animation state binding observes the existing:

```text
NucleusStateMachine.state_changed
```

No animation-specific gameplay FSM exists.

## Movement reuse

Velocity bindings read the CharacterBody velocity already produced by Nucleus
movement components.

They do not duplicate acceleration, grounded state, or movement direction.

## GameplayAction reuse

Animation requests and camera impulses are normal:

```text
NucleusActionEffect
```

They automatically participate in existing:

```text
requirements
costs
cooldowns
commit
AI/player execution
```

## Motion math reuse

Bob smoothing uses:

```text
NucleusMotionMath.exponential_weight()
```

No second smoothing formula is introduced.

## Accessibility normalization

Before Iteration 17, reduced-motion detection lived in
`NucleusUIMotionPolicy`.

That decision applies beyond UI.

Iteration 17 extracts the shared decision into:

```text
NucleusMotionPolicy
```

and leaves UI-only settings in `NucleusUIMotionPolicy`.

Both UI and gameplay camera feedback now resolve the same:

```text
OS preference
Nucleus reduced-motion setting
```

## FOV reuse

The existing `NucleusCameraFov3D` already owns smooth FOV transitions.

Game Feel therefore does not set `Camera3D.fov` directly.

The component gains source-owned additive offsets, preserving the existing base
and target API.

## Third-person camera reuse

`NucleusThirdPersonCameraRig3D` continues owning:

```text
target follow
orbit
zoom
SpringArm collision
```

Feedback should use a dedicated descendant pivot above the SpringArm.

This keeps the camera a direct child of SpringArm3D.

## 2D camera reuse

`NucleusCameraFollow2D` directly moves its top-level Camera2D.

For this configuration, feedback uses native:

```text
Camera2D.offset
```

instead of changing Camera2D position.

## Why source-owned continuous offsets

Head bob is not an impulse.

Future presentation systems may also contribute persistent offsets.

The mixer therefore uses:

```text
set_offset_source(id, ...)
remove_offset_source(id)
```

rather than exposing one mutable "bob offset" field.

This matches ownership patterns already proven in:

```text
Attribute modifiers
Action blockers
Targeting registrations
FOV offsets
```

## Why no global GameFeelManager

Camera feedback belongs to a view/camera.

A global manager would become ambiguous with:

```text
local multiplayer
split screen
SubViewports
spectator cameras
vehicles
cutscenes
picture-in-picture
```

Each camera composition owns its own feedback mixer.

## Barebone

No legacy animation/game-feel manager is needed here.

The current Nucleus composition is built around the systems that now exist,
rather than importing older controller-centric assumptions.
