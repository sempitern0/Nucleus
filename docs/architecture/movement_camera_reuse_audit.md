# Movement + Camera Reuse Audit

This audit was performed before Iteration 12.

## Nucleus APIs reused

### Core input actions

Movement defaults to:

```text
NucleusInputActions.MOVE_LEFT
NucleusInputActions.MOVE_RIGHT
NucleusInputActions.MOVE_FORWARD
NucleusInputActions.MOVE_BACK

NucleusInputActions.LOOK_LEFT
NucleusInputActions.LOOK_RIGHT
NucleusInputActions.LOOK_UP
NucleusInputActions.LOOK_DOWN
```

No duplicate action constants were added.

Gameplay-specific actions such as jump, sprint, dash, crouch, and zoom remain
project-defined.

### Local player routing

`NucleusMotionInput` binds `NucleusLocalPlayerInput`.

This reuses:

```text
per-device action polling
per-device action vectors
routed discrete InputEvents
controller assignment/reconnection
```

No movement component performs its own joypad-device bookkeeping.

### Cursor

Barebone had a separate `MouseCaptureComponent` that called OmniKit helpers and
stored sensitivity/settings.

Nucleus already had:

```text
NucleusCursor
```

Iteration 12 extends that facade only with:

```text
get_mode()
set_mode()
```

so cursor ownership remains centralized.

`NucleusMouseCapture` builds policy on that existing API.

### Application lifecycle

Mouse capture pause/resume behavior consumes:

```text
NucleusApp.application_paused
NucleusApp.application_resumed
```

It does not re-handle OS notifications independently.

### Scene traversal

Auto-resolution uses:

```text
NucleusNodeUtils.descendants()
```

rather than adding another recursive tree search helper.

### Diagnostics

Configuration problems use:

```text
NucleusLog
```

### State machine

Movement components do not create another state machine.

`NucleusStateMachine` can configure/enable motors through state enter/exit hooks.

The dependency stays optional because simple games do not require an FSM just
to move a CharacterBody.

## Godot-native capabilities intentionally retained

### CharacterBody2D / CharacterBody3D

Nucleus uses native:

```text
velocity
move_and_slide()
is_on_floor()
up_direction
get_gravity()
```

There is no Nucleus physics-body abstraction.

### SpringArm3D

Third-person collision handling remains a SpringArm responsibility.

Barebone used SpringArm3D but placed Camera3D as a sibling and then manually
lerped the camera toward a proxy node attached to the spring.

Nucleus instead uses the native structure:

```text
SpringArm3D
└── Camera3D
```

and removes the duplicate position solver.

### Camera2D

Camera2D's native smoothing, limits, drag margins, rotation smoothing, and zoom
are not reimplemented.

### Physics interpolation

The third-person camera follows:

```gdscript
Node3D.get_global_transform_interpolated()
```

instead of inventing another physics/render interpolation cache.

## Barebone concepts retained

Useful concepts:

```text
camera-relative third-person movement
separate yaw/pitch control
SpringArm collision avoidance
movement-oriented visual skin
mouse capture component
camera FOV target
```

## Barebone concepts rejected or redesigned

### FirstPersonController feature matrix

The old first-person body owned feature flags for:

```text
run
dash
air dash
jump
crouch
crawl
slide
wall run
wall jump
wall climb
surf
swim
stairs
ladder
camera effects
weapon manager
interaction
```

This is a project-specific player framework, not a reusable foundation.

Nucleus uses a generic CharacterMotor3D plus optional states/abilities.

### Global player reference and collision constants

No:

```text
Globals.player
Globals.player_collision_layer
```

are introduced.

### OmniKitMotionInput duplication

Nucleus already solved device-aware input in Core.

Movement consumes `NucleusMotionInput`, which bridges that Core API to gameplay.

### Camera settings hard dependency

The old camera directly queried a global SettingsManager for sensitivity/FOV.

Nucleus camera Components expose properties.

A game may bind those properties to Nucleus Settings if it chooses to create
camera-specific settings, but the Components do not require every Nucleus game
to ship 3D-camera preferences.

### FOV coupled to movement velocity

The old FPS camera automatically added velocity to FOV.

Nucleus FOV is an independent target controller. Sprint/aim/vehicle systems may
drive it explicitly.

This prevents a generic Camera3D component from deciding game feel.

## One new shared helper

Iteration 12 adds:

```text
NucleusMotionMath
```

under gameplay Components, not Core.

It contains only motion-specific math that is used by multiple movement/camera
components:

```text
frame-rate-stable exponential response weight
3D planar movement from an orientation basis
planar/vertical vector decomposition
2D right axis from custom up direction
```

This logic is too gameplay-specific for Core but avoids repeating formulas
inside every motor.
