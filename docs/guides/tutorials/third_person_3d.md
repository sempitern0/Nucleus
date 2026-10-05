# Tutorial: build a third-person 3D controller and camera

This tutorial builds the generic 3D foundation Nucleus provides before a game
adds genre-specific movement.

The final composition uses:

```text
CharacterBody3D
NucleusMotionInput
NucleusCharacterMotor3D
NucleusThirdPersonCameraRig3D
NucleusLookRig3D
NucleusMouseCapture
```

It works with keyboard/mouse and the default gamepad movement/look actions.

## 1. Create the Player

```text
Player : CharacterBody3D
├── CollisionShape3D
├── MeshInstance3D
├── MotionInput : NucleusMotionInput
└── Motor : NucleusCharacterMotor3D
```

Configure the motor:

```text
body = Player
motion_input = MotionInput
speed = 5.0
ground_acceleration = 20.0
ground_deceleration = 24.0
air_acceleration = 8.0
air_deceleration = 4.0
```

Leave `jump_action` empty for a grounded/no-jump prototype, or assign a
project-defined action when jumping is part of the game.

## 2. Instance the Nucleus camera rig

Instance:

```text
res://components/gameplay/camera/third_person_camera_rig_3d.tscn
```

into the world/session:

```text
World
├── Player
├── ThirdPersonCameraRig3D
└── MouseCapture : NucleusMouseCapture
```

The packed rig already contains:

```text
SpringArm3D
└── Camera3D
LookRig
```

## 3. Wire target and input

Assign on the camera rig:

```text
target = Player
motion_input = Player/MotionInput
```

Assign on the motor:

```text
orientation_source = ThirdPersonCameraRig3D
```

This makes planar movement camera-relative rather than actor-relative.

The motor uses the orientation source's basis but projects movement onto the
CharacterBody3D ground plane.

## 4. Start with camera values you can feel

Example starting point:

```text
target_offset = (0, 1.5, 0)
minimum_distance = 2.0
maximum_distance = 8.0
initial_distance = 4.0
zoom_step = 0.5
zoom_response = 14.0
```

These are not balance recommendations. Tune them against the scale of the actual
world/character.

## 5. Configure look feel

On `LookRig`:

```text
mouse_sensitivity_degrees_per_pixel = 0.10
gamepad_degrees_per_second = 180
minimum_pitch = -70 degrees
maximum_pitch = 70 degrees
```

The important distinction is:

```text
mouse
    angular delta per physical screen pixel

gamepad
    angular speed per second
```

so both input types can be tuned intentionally.

## 6. Capture the mouse

Add `NucleusMouseCapture` with:

```text
capture_on_ready = true
```

`NucleusMotionInput` requires captured mouse by default before accumulating
pointer look.

When opening a pause/options menu:

```gdscript
mouse_capture.release()
```

When returning to gameplay:

```gdscript
mouse_capture.capture()
```

Do not assign `Input.mouse_mode` directly from the game when Nucleus cursor policy
already owns it.

## 7. Test SpringArm collision

Place a wall behind the player.

Move the camera toward it. `SpringArm3D` should shorten the camera distance to
avoid clipping through the obstacle.

Nucleus leaves the actual collision shortening to Godot's native SpringArm.

## 8. Test camera-relative movement

Rotate the camera 90 degrees and press forward.

The player should move toward the camera's new planar forward direction, not
continue along a fixed global Z axis.

This is the key reason to set `orientation_source` to the camera rig.

## 9. Add local-player input later without changing the motor

For a session-owned local seat:

```gdscript
motion_input.bind_local_player_input(player_input)
```

The motor and camera continue consuming the same `NucleusMotionInput` API.

That makes controller hot-swap/couch-player ownership an input-layer concern.

## 10. What stays game-specific

Nucleus supplies generic movement/camera plumbing, not the final controller for
every genre.

Keep game policy outside the generic motor when implementing things such as:

```text
swimming
climbing
boat/vehicle control
stamina sprint
ledge vaulting
lock-on movement
surfing
underwater buoyancy
special camera composition
```

If a behavior becomes repeatedly useful across unrelated games, that is evidence
for a future reusable component.

## Validation

- WASD/left stick moves the character;
- movement rotates with the camera;
- mouse/right stick rotates the camera;
- pitch clamps correctly;
- SpringArm avoids a wall;
- mouse releases for UI and captures again for gameplay;
- gamepad movement still works without mouse capture.

## Related docs

- [`platformer_2d.md`](platformer_2d.md)
- [`local_multiplayer.md`](local_multiplayer.md)
- [`../../components/gameplay_movement_camera.md`](../../components/gameplay_movement_camera.md)
