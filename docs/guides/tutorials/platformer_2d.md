# Tutorial: build a responsive 2D platformer controller

This tutorial builds a side-view `CharacterBody2D` controller with:

- keyboard and gamepad movement;
- acceleration/deceleration;
- gravity;
- jump buffering;
- coyote time;
- variable jump height;
- optional extra air jumps;
- a following `Camera2D`.

The goal is a responsive platformer foundation in the product space of games
such as Celeste.

That is a **feel/design analogy only**. These values and systems are not claims
about Celeste's internal implementation.

## 1. Create the input actions

Nucleus already provides semantic horizontal movement through:

```text
move_left
move_right
```

Create a project action for jumping:

```text
jump
```

In:

```text
Project
→ Project Settings
→ Input Map
```

Give `jump` keyboard and gamepad defaults appropriate to the game.

The motor can use any StringName action, so `jump` does not need to become a new
Nucleus Core constant just because one project uses it.

## 2. Create the player scene

Create:

```text
Player : CharacterBody2D
├── Sprite2D
├── CollisionShape2D
├── MotionInput : Node
└── PlatformerMotor : Node
```

Assign:

```text
MotionInput
    res://components/gameplay/control/motion_input.gd

PlatformerMotor
    res://components/gameplay/movement/platformer_motor_2d.gd
```

Give `CollisionShape2D` an appropriate capsule/rectangle/shape for the character.

## 3. Configure MotionInput

For a basic platformer, the defaults are already useful:

```text
move_left     = move_left
move_right    = move_right
move_forward  = move_forward
move_back     = move_back
```

`NucleusPlatformerMotor2D` only consumes the horizontal X component from
`get_move_vector()`.

You do not need a custom keyboard/gamepad branch.

## 4. Configure PlatformerMotor

Assign:

```text
body         = Player
motion_input = MotionInput
jump_action  = jump
```

A good first-pass configuration is the component's current default profile:

```text
speed                 = 260
ground_acceleration   = 2200
ground_deceleration   = 2600
air_acceleration      = 1100
air_deceleration      = 800

gravity_scale         = 1.0

jump_speed            = 420
coyote_time           = 0.10
jump_buffer_time      = 0.10
extra_air_jumps       = 0

shorten_jump_on_release = true
jump_release_multiplier = 0.5
```

These are starting values, not a recommended final game balance.

## 5. Add a floor

Create a test level using normal Godot collision:

```text
TestLevel : Node2D
├── StaticBody2D
│   └── CollisionShape2D
└── Player
```

Run the scene.

Expected behavior:

- left/right accelerates to the configured speed;
- releasing input decelerates;
- the body falls under gravity;
- pressing jump on the floor jumps;
- releasing jump early produces a shorter jump.

## 6. Understand coyote time

With:

```text
coyote_time = 0.10
```

the player may still jump for a short window after leaving a platform edge.

This is input forgiveness, not an animation feature.

Tune it with level scale and player speed. Too much coyote time can feel like
the character is jumping from empty air.

## 7. Understand jump buffering

With:

```text
jump_buffer_time = 0.10
```

a jump request made shortly before landing remains queued.

When the player touches the floor inside that window, the motor can consume the
request immediately.

This removes the need for frame-perfect landing input.

## 8. Tune variable jump height

When:

```text
shorten_jump_on_release = true
```

the motor shortens upward velocity when the jump action is released.

`jump_release_multiplier` controls how much upward speed remains.

Try:

```text
0.35
    strong difference between tap and hold

0.5
    balanced starting point

0.7
    gentler difference
```

Tune by feel; do not copy values from another game without matching your own
gravity, sprite scale, collision shape, and level metrics.

## 9. Add a Camera2D

Create:

```text
Camera2D
└── Follow : Node
```

Assign to `Follow`:

```text
res://components/gameplay/camera/camera_follow_2d.gd
```

Configure:

```text
camera = Camera2D
target = Player
```

`NucleusCameraFollow2D` only owns target-following/snap behavior.

Keep native `Camera2D` responsible for:

```text
position smoothing
drag margins
limits
zoom
rotation smoothing
```

For example, enable native position smoothing in the Camera2D Inspector and tune
it there.

Nucleus does not wrap those native camera features.

## 10. Gamepad support

For ordinary single-player global input, `NucleusMotionInput` uses InputMap and
the same `move_left`/`move_right` bindings work with keyboard or gamepad.

For a scene with explicit local-player ownership:

```text
Session
├── LocalInput : NucleusLocalInputSession
└── Player
    └── MotionInput
```

Create/bind the local seat once:

```gdscript
var local_player := local_input.join_keyboard_mouse(0)
motion_input.bind_local_player_input(local_player)
```

With:

```text
max_players = 1
single_player_hot_swap = true
```

the stable player seat can move between keyboard/mouse and gamepad activity.

## 11. Add animation without coupling it to the motor

Observe motor/body state:

```text
desired_axis
body.velocity
body.is_on_floor()
jumped
landed
left_ground
```

Feed those values into an AnimationTree adapter/state layer.

Do not make `NucleusPlatformerMotor2D` choose game-specific animation names.

See:

[`../animation_integration_quickstart.md`](../animation_integration_quickstart.md)

## 12. Add platformer-specific mechanics in the game

The generic motor intentionally stops before genre-specific policy such as:

- dash;
- wall slide/wall jump;
- ledge grabbing;
- corner correction;
- drop-through one-way platforms;
- climb/stamina systems;
- knockback rules;
- character-specific gravity curves;
- speed-running tech;
- pixel-perfect camera policy.

Implement those in the game first.

If multiple unrelated games later need the same clean abstraction, that is
evidence for expanding Nucleus.

## 13. Suggested tuning workflow

Tune in this order:

1. collision size and level scale;
2. gravity;
3. jump height/time;
4. horizontal top speed;
5. ground acceleration/deceleration;
6. air control;
7. coyote time;
8. jump buffer;
9. jump-release multiplier;
10. camera smoothing.

Changing all of them at once makes movement feel difficult to diagnose.

## 14. Validation checklist

Test:

- keyboard left/right;
- gamepad left stick;
- gamepad D-pad if mapped;
- tap versus held jump;
- jumping just after walking off an edge;
- pressing jump just before landing;
- reversing direction on ground;
- reversing direction in air;
- collision with floor/walls;
- camera follow at low/high speed;
- controller hot-swap if using LocalInputSession.

## Related docs

- [`../gameplay_foundation_quickstart.md`](../gameplay_foundation_quickstart.md)
- [`../../components/gameplay_movement_camera.md`](../../components/gameplay_movement_camera.md)
- [`bindings.md`](bindings.md)
- [`gameplay_actions.md`](gameplay_actions.md)
