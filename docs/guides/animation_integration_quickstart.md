# Animation Integration — Godot Editor Quickstart

Technical reference:

```text
docs/components/animation_integration.md
```

## 1. Keep Godot as the animation runtime

Create and author animations normally with:

```text
AnimationPlayer
AnimationTree
BlendSpace1D / BlendSpace2D
AnimationNodeStateMachine
AnimationNodeOneShot
```

Nucleus does not generate the graph.

## 2. Connect a Nucleus FSM to AnimationTree

Example actor:

```text
Player
├── StateMachine
├── AnimationPlayer
├── AnimationTree
└── AnimationStateBinding
```

Attach:

```text
components/gameplay/animation/animation_tree_state_binding.gd
```

Assign:

```text
state_machine
animation_tree
```

If FSM ids and AnimationTree states use the same names:

```text
idle
move
fall
```

leave:

```text
use_state_id_as_fallback = true
```

Otherwise create `NucleusStateAnimationMapping` Resources.

## 3. Drive locomotion blend parameters

For 3D add:

```text
AnimationVelocity3D
```

using:

```text
animation_velocity_binding_3d.gd
```

Example parameters:

```text
speed_parameter
    parameters/Locomotion/speed

blend_parameter
    parameters/Locomotion/blend_position

grounded_parameter
    parameters/conditions/grounded
```

For 2D use:

```text
animation_velocity_binding_2d.gd
```

The adapters read the CharacterBody velocity already produced by Nucleus
Movement.

## 4. Fire an animation from GameplayAction

Example:

```text
PrimaryAttack : NucleusGameplayAction
├── Cooldown
├── Cost
├── AttackAnimation
└── ActionInput
```

For an AnimationTree OneShot attach:

```text
animation_tree_one_shot_effect.gd
```

Set:

```text
animation_tree = Player/AnimationTree
request_parameter = parameters/Attack/request
```

For state-machine travel use:

```text
animation_tree_state_effect.gd
```

and assign the AnimationTree state name.

## 5. Add an animation event

Add an `NucleusAnimationEventRelay` Node near the AnimationPlayer.

Create a Method Call Track in the animation and call:

```gdscript
emit_event(&"attack_hit")
```

Then connect locally:

```gdscript
%AnimationEvents.event_received.connect(
    _on_animation_event
)
```

Your weapon/combat system no longer needs to be a hardcoded method-track target.

## 6. Recommended ownership

A common character layout:

```text
CharacterBody3D
├── MotionInput
├── StateMachine
├── Actions
├── AnimationPlayer
├── AnimationTree
├── AnimationVelocity3D
├── AnimationStateBinding
└── AnimationEvents
```

Gameplay owns rules.

AnimationTree owns blending and visual transitions.

The adapters only translate state between the two.
