# Animation Integration — 3D Quickstart

Use this when a working `CharacterBody3D` needs a real animated model.

Technical contract:

```text
docs/components/animation_integration.md
```

Detailed assisted workflow:

```text
docs/guides/tutorials/animation_pipeline_3d.md
```

Advanced production topics:

```text
docs/guides/tutorials/character_animation_3d.md
```

## 1. Keep gameplay and presentation separate

Prefer:

```text
Player : CharacterBody3D
├── CollisionShape3D
├── MotionInput
├── Motor
├── VisualRoot : Node3D
│   └── ImportedCharacter
├── CharacterAnimationSetup3D
├── AnimationTree
├── AnimationVelocity3D
└── AnimationEvents
```

Do not replace the gameplay root with the imported model.

## 2. Import and retarget natively

For a humanoid:

1. Import GLB/glTF/FBX.
2. Open **Advanced Import Settings**.
3. Select `Skeleton3D`.
4. Assign a `BoneMap`.
5. Use `SkeletonProfileHumanoid` when appropriate.
6. Verify important bones and rest pose.
7. Enable Rest Fixer/normalization options only when needed.
8. Reimport.

Keep project-owned animation setup in a wrapper/inherited scene.

## 3. Add the Nucleus setup assistant

Add:

```text
NucleusCharacterAnimationSetup3D
```

Assign `visual_root` to the imported presentation branch when the character scene
contains more than one possible rig.

Then use:

```text
Auto Resolve Rig
Suggest Common Clips
Print Rig Report
```

Review the suggested `NucleusAnimationStarterProfile3D`.

At minimum configure:

```text
Idle
Walk
Run
walk_speed
run_speed
```

Jump/Fall/Land are optional.

## 4. Build the starter AnimationTree

Press:

```text
Build Starter Tree
```

The helper can create the missing `AnimationTree` and velocity binding.

Generated native graph:

```text
StateMachine
├── Locomotion : BlendSpace1D
│   ├── Idle
│   ├── Walk
│   └── Run
├── Jump
├── Fall
└── Land
```

Only configured air clips are added.

The builder refuses to overwrite an existing graph unless
`replace_existing_tree` is enabled explicitly.

## 5. Continue authoring in Godot

Open the generated `AnimationTree` normally.

Typical next additions:

```text
BlendSpace2D directional locomotion
Attack OneShot
Reload OneShot
HitReact
Death
upper-body layers
aim/look modifiers
```

The generated graph is scaffolding, not a locked Nucleus format.

## 6. Drive locomotion

The setup helper configures:

```text
NucleusAnimationVelocityBinding3D.speed_parameter
    parameters/Locomotion/blend_position
```

This feeds real `CharacterBody3D.velocity` magnitude into the starter locomotion
BlendSpace.

Add other parameter paths manually when needed.

## 7. Drive high-level states

If gameplay already uses `NucleusStateMachine`, add
`NucleusAnimationTreeStateBinding`.

Map gameplay IDs to visual states explicitly when names differ.

## 8. Use OneShots for actions

Use native `AnimationNodeOneShot` branches and
`NucleusAnimationTreeOneShotEffect` for attacks, reloads, interaction, flinch,
gestures, and similar overlays.

## 9. Use native IK/attachments/ragdoll

Use:

```text
SkeletonModifier3D / native IK
BoneAttachment3D
PhysicalBoneSimulator3D
NucleusRagdollController3D
```

Do not create duplicate Nucleus abstractions for problems Godot already owns.

## 10. Validate

Before deleting prototype visuals, verify:

```text
rig imports without twisted rest pose
suggested clips are semantically correct
idle/walk/run thresholds match motor speeds
air states travel correctly
AnimationTree remains editable
OneShots do not own gameplay authority
IK influence returns cleanly to zero
attachments follow intended bones
ragdoll does not fight gameplay collision
```
