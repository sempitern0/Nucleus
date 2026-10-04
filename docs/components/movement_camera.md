# Movement and Camera Components

Target engine: Godot 4.7.x.

This layer provides reusable locomotion and camera composition without creating
genre-specific player-controller monoliths.

For editor-first setup, see:

```text
docs/guides/movement_camera_quickstart.md
```

## Design model

Nucleus separates four responsibilities:

```text
NucleusMotionInput
        │
        ├── movement motor
        │
        └── camera look rig
                 │
                 ▼
           Camera2D / Camera3D
```

A typical 3D actor is composition:

```text
CharacterBody3D
├── MotionInput
├── CharacterMotor3D
├── StateMachine           # optional
├── VisualPivot
│   └── imported model
└── camera rig
```

The same motor can drive first-person or third-person movement.

There is deliberately no:

```text
NucleusFirstPersonController
NucleusThirdPersonController
```

because those names usually collapse input, locomotion, camera, presentation,
interaction, weapons, and state into one inheritance hierarchy.

## Motion input bridge

`NucleusMotionInput` is the gameplay-facing bridge over Core Input.

It reuses:

```text
NucleusInputActions.MOVE_*
NucleusInputActions.LOOK_*
NucleusLocalPlayerInput
NucleusCursor
```

Single-player polling uses normal Godot Input actions.

Couch multiplayer binds one existing:

```gdscript
motion_input.bind_local_player_input(player_input)
```

Held movement/look then uses Core's per-device polling, while mouse motion and
other discrete events use the player's existing `input_received` stream.

No second local-player device router exists in Components.

## Mouse look

Mouse motion is event-based.

Nucleus uses:

```gdscript
InputEventMouseMotion.screen_relative
```

rather than scaling a mouse delta by frame time.

Mouse delta already describes displacement. Multiplying it by `delta` would make
sensitivity frame-rate dependent.

Gamepad look is different: the stick represents an angular rate, so
`NucleusLookRig3D` applies degrees-per-second multiplied by frame delta.

## Movement ownership

A motor owns:

```text
velocity integration
move_and_slide()
```

for its CharacterBody.

Only one active movement authority should call `move_and_slide()` for a body in
one physics frame.

FSM states, abilities, status effects, and gameplay scripts should configure or
command the motor rather than execute another competing movement solver.

Examples:

```gdscript
motor.set_speed_multiplier(1.5)
motor.request_jump()
motor.enabled = false
```

## Top-down 2D motor

`NucleusTopDownMotor2D` targets an existing `CharacterBody2D`.

It supports:

```text
speed
acceleration
deceleration
runtime speed multiplier
floating CharacterBody motion mode
```

It intentionally does not rotate sprites, animate characters, dash, or manage
stamina.

Those are separate concerns.

## Platformer 2D motor

`NucleusPlatformerMotor2D` adds:

```text
horizontal acceleration/deceleration
air control
native gravity
jump request API
optional InputMap jump action
coyote time
jump buffering
extra air jumps
variable jump height on release
custom CharacterBody2D up direction
```

Gravity comes from:

```gdscript
CharacterBody2D.get_gravity()
```

rather than a duplicated project gravity constant.

The Core InputMap does not gain a universal `jump` action. Games that need one
create it and assign its `StringName` in the Inspector.

## 3D character motor

`NucleusCharacterMotor3D` targets `CharacterBody3D`.

The motor is presentation-agnostic.

Movement is calculated relative to an arbitrary `orientation_source`:

```text
first person
    orientation_source = yaw/body pivot

third person
    orientation_source = camera orbit rig

fixed/isometric
    orientation_source = fixed orientation node
```

The motor projects movement onto the plane perpendicular to
`CharacterBody3D.up_direction`, so it does not assume that world Y is always the
actor's up axis.

Gravity uses:

```gdscript
PhysicsBody3D.get_gravity()
```

therefore Godot's Area3D gravity overrides remain effective.

## Visual facing

`NucleusMovementFacing3D` rotates a visual pivot toward movement direction.

It listens to the motor's `movement_updated` signal rather than relying on
sibling `_physics_process()` order.

Recommended:

```text
CharacterBody3D
└── VisualPivot          # unit-scale orientation pivot
    └── ImportedModel   # imported model may have corrective transform
```

Assign `VisualPivot` as the facing target.

Do not make character art import orientation part of collision-body movement
logic.

`use_model_front` maps to Godot's `Basis.looking_at()` convention for models
whose front is `+Z` rather than Godot's conventional `-Z` forward.

## First-person camera composition

First-person does not require another controller class.

Recommended tree:

```text
Player : CharacterBody3D
├── MotionInput
├── CharacterMotor3D
├── MouseCapture
└── ViewYaw : Node3D
    └── ViewPitch : Node3D
        ├── Camera3D
        ├── CameraFov3D
        └── LookRig3D
```

Configure:

```text
CharacterMotor3D.orientation_source = ViewYaw
LookRig3D.yaw_target = ViewYaw
LookRig3D.pitch_target = ViewPitch
```

Depending on the game's design, `ViewYaw` can instead be the player body.

Keeping pitch on a separate pivot prevents the physics body from tipping
forward/backward.

## Third-person orbit camera

`NucleusThirdPersonCameraRig3D` is built around native `SpringArm3D`.

Packaged scene:

```text
components/gameplay/camera/third_person_camera_rig_3d.tscn
```

Tree:

```text
ThirdPersonCameraRig3D
├── SpringArm3D
│   └── Camera3D
└── LookRig
```

The Camera3D is intentionally a direct SpringArm3D child.

This lets Godot own collision shortening instead of Nucleus manually copying a
collision probe position into the camera.

The rig supports:

```text
orbit mouse/gamepad look
pitch limits through LookRig3D
target following
zoom distance
smooth distance changes
target collision exclusion
camera activation
```

Physics collision masks remain project-owned.

## Physics interpolation

Gameplay bodies move in `_physics_process()`.

Third-person cameras are visual objects and follow their target in render
frames.

When enabled, the third-person rig reads:

```gdscript
target.get_global_transform_interpolated()
```

and disables automatic interpolation on the rig itself.

This avoids interpolating the camera twice and follows the intended Godot 4.7
manual-camera pattern.

After a gameplay teleport, reset interpolation on the gameplay body as part of
the teleport operation:

```gdscript
body.global_position = destination
body.reset_physics_interpolation()
camera_rig.snap_to_target()
```

Do not hide teleport semantics inside the camera.

## Camera2D

Godot `Camera2D` already provides:

```text
position smoothing
rotation smoothing
drag margins
limits
zoom
offset
```

`NucleusCameraFollow2D` therefore only adds:

```text
external target following
runtime target switching
snap/reset helpers
```

It intentionally does not recreate Camera2D smoothing.

The follow component defaults to a later physics process priority so ordinary
movement motors update the target first.

## FOV

`NucleusCameraFov3D` owns one generic target FOV.

It does not know about:

```text
sprint
aim down sights
vehicle boost
damage
cutscene
```

Any system may drive:

```gdscript
camera_fov.set_target_fov(90.0)
camera_fov.reset_fov()
```

Smoothing uses an exponential response rather than `lerp(delta * speed)`, so the
response remains stable across frame rates.

## Mouse capture

`NucleusMouseCapture` is a scene-owned policy component.

It reuses `NucleusCursor`; it does not write `Input.mouse_mode` through a second
helper.

It can:

```text
capture on ready
release on application pause
recapture on application resume
restore the previous cursor mode on exit
```

Opening a pause/settings menu remains game UI policy. Such UI should call
`release()` and recapture when appropriate rather than the component implicitly
pausing the game.

## FSM integration

Movement does not depend on the state machine, but the components compose
cleanly.

Examples:

```text
Walk state
    motor.speed_multiplier = 1.0

Sprint state
    motor.speed_multiplier = 1.6

Stunned state
    motor.enabled = false
```

This keeps the FSM responsible for gameplay mode while the motor remains the
single locomotion solver.

## Local multiplayer

No movement or camera component assumes player zero.

For each local player:

```text
NucleusLocalInputSession
        │
        ▼
NucleusLocalPlayerInput
        │
        ▼
NucleusMotionInput
        ├── Motor
        └── Camera
```

For split screen, each player camera belongs in its own SubViewport. A viewport
can only have one current camera of a given dimensional type.

The camera components themselves are viewport-agnostic; no second multiplayer
manager is introduced.

## Deferred camera effects

The following do not belong in the base locomotion solver:

```text
head bob
camera shake / trauma
landing kick
damage kick
recoil
motion tilt
lock-on framing
cinematic rails
```

They should compose on top of the camera pivots as optional presentation
components in a later iteration.
