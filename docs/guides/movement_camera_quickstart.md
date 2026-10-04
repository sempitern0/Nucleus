# Movement + Camera — Godot Editor Quickstart

This guide is for integrating movement/camera without first reading the internal
architecture.

Technical reference:

```text
docs/components/movement_camera.md
```

---

## 1. Top-down 2D character

Create:

```text
Player : CharacterBody2D
├── CollisionShape2D
├── MotionInput : Node
└── TopDownMotor2D : Node
```

Attach:

```text
MotionInput
    components/gameplay/control/motion_input.gd

TopDownMotor2D
    components/gameplay/movement/top_down_motor_2d.gd
```

On `TopDownMotor2D`:

1. Drag Player into `body`.
2. Drag MotionInput into `motion_input`.
3. Configure speed/acceleration/deceleration.

The default Nucleus movement actions work immediately.

The motor sets CharacterBody2D to floating motion mode by default, appropriate
for top-down movement.

---

## 2. Platformer 2D

Tree:

```text
Player : CharacterBody2D
├── CollisionShape2D
├── MotionInput
└── PlatformerMotor2D
```

Attach `platformer_motor_2d.gd`.

Set a project action such as:

```text
jump
```

in:

```text
Project
→ Project Settings
→ Input Map
```

Then set:

```text
PlatformerMotor2D.jump_action = "jump"
```

Recommended starting point:

```text
speed                 260
ground acceleration   2200
ground deceleration   2600
air acceleration      1100
coyote time           0.10
jump buffer            0.10
```

Tune those values to the game's feel.

Nucleus intentionally does not insert a universal `jump` action into Core.

For an ability/state-driven jump you can leave `jump_action` empty and call:

```gdscript
motor.request_jump()
```

---

## 3. Basic first-person 3D

Recommended tree:

```text
Player : CharacterBody3D
├── CollisionShape3D
├── MotionInput
├── CharacterMotor3D
├── MouseCapture
└── ViewYaw : Node3D
    └── ViewPitch : Node3D
        ├── Camera3D
        ├── CameraFov3D
        └── LookRig3D
```

Attach:

```text
MotionInput
    components/gameplay/control/motion_input.gd

CharacterMotor3D
    components/gameplay/movement/character_motor_3d.gd

MouseCapture
    components/gameplay/camera/mouse_capture.gd

CameraFov3D
    components/gameplay/camera/camera_fov_3d.gd

LookRig3D
    components/gameplay/camera/look_rig_3d.gd
```

Wire Inspector references:

```text
CharacterMotor3D.body
    → Player

CharacterMotor3D.motion_input
    → MotionInput

CharacterMotor3D.orientation_source
    → ViewYaw

LookRig3D.motion_input
    → MotionInput

LookRig3D.yaw_target
    → ViewYaw

LookRig3D.pitch_target
    → ViewPitch

CameraFov3D.camera
    → Camera3D
```

Mouse and right-stick look now share the same camera rig.

For a classic FPS where body yaw should rotate with the camera, you may use the
Player CharacterBody3D itself as `yaw_target` and `orientation_source`, while
keeping `ViewPitch` separate.

---

## 4. Third-person character

Actor:

```text
Player : CharacterBody3D
├── CollisionShape3D
├── MotionInput
├── CharacterMotor3D
└── VisualPivot : Node3D
    └── CharacterModel
```

Instance:

```text
components/gameplay/camera/third_person_camera_rig_3d.tscn
```

as a sibling or in the gameplay scene.

Assign:

```text
CameraRig.target
    → Player

CameraRig.motion_input
    → Player/MotionInput

CharacterMotor3D.orientation_source
    → CameraRig
```

For character art facing movement:

1. Add `MovementFacing3D` under the Player.
2. Assign the CharacterMotor3D.
3. Assign `VisualPivot` as its target.
4. If your model's authored front is +Z, enable `use_model_front`.

Do not assign the imported model itself if it carries corrective scale/rotation.
Create a clean orientation pivot above it.

---

## 5. Configure third-person camera collision

Select:

```text
ThirdPersonCameraRig3D/SpringArm3D
```

and configure its collision mask in the normal Godot Inspector.

The `Camera3D` is already a direct child of SpringArm3D.

Do not move it out of the SpringArm and do not add another script that copies a
probe position into the camera.

The rig can exclude the target CharacterBody automatically.

---

## 6. Third-person zoom

Mouse wheel works through the MotionInput event stream.

Configure in the camera rig:

```text
minimum_distance
maximum_distance
initial_distance
zoom_step
zoom_response
```

For controller zoom, create project actions such as:

```text
camera_zoom_in
camera_zoom_out
```

and assign them to:

```text
zoom_in_action
zoom_out_action
```

They are optional because zoom controls are game-specific.

---

## 7. 2D camera following

Use a normal `Camera2D`.

Add:

```text
Camera2D
└── CameraFollow2D
```

Attach `camera_follow_2d.gd`.

Drag the Player into `target`.

Configure smoothing on the **Camera2D itself**:

```text
Position Smoothing
Drag
Limits
Zoom
Rotation Smoothing
```

Nucleus does not duplicate those Inspector features.

Calling:

```gdscript
camera_follow.set_target(new_target)
```

switches targets and snaps/reset smoothing by default.

---

## 8. Jump + FSM

The state machine does not need a special movement-state subclass.

Example state:

```gdscript
class_name PlayerJumpState
extends NucleusState

@export var motor: NucleusCharacterMotor3D


func enter(
    _previous_state: NucleusState,
    _context: Dictionary,
) -> void:
    motor.request_jump()
```

Sprint:

```gdscript
func enter(
    _previous_state: NucleusState,
    _context: Dictionary,
) -> void:
    motor.set_speed_multiplier(1.6)


func exit(_next_state: NucleusState) -> void:
    motor.set_speed_multiplier(1.0)
```

This keeps exactly one movement solver.

---

## 9. Local multiplayer movement

After a player joins:

```gdscript
var player_input: NucleusLocalPlayerInput = (
    local_input_session.get_player(player_index)
)

motion_input.bind_local_player_input(player_input)
```

Nothing else changes.

The motor continues calling:

```text
MotionInput.get_move_vector()
```

and automatically receives only that player's device.

For split-screen 3D:

1. Create one SubViewport per player.
2. Put one current Camera3D in each SubViewport.
3. Bind each player's MotionInput to that player's `NucleusLocalPlayerInput`.
4. Set `make_current_on_ready` appropriately for each camera rig.

Do not place multiple competing current cameras in the same viewport.

---

## 10. Teleporting with physics interpolation

When teleporting a physics actor:

```gdscript
player.global_position = destination
player.reset_physics_interpolation()
camera_rig.snap_to_target()
```

Resetting interpolation prevents a one-frame visual streak from the old
position to the destination.

The teleport belongs to gameplay code; the camera should not silently mutate
the player.

---

## 11. Opening a pause/settings menu in an FPS

Keep UI policy explicit:

```gdscript
func open_pause_menu() -> void:
    mouse_capture.release()
    pause_menu.show()


func close_pause_menu() -> void:
    pause_menu.hide()
    mouse_capture.capture()
```

`NucleusMouseCapture` handles application pause/resume, but it does not decide
when your in-game menus should capture or release the cursor.
