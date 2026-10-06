# Animation Integration — 3D Quickstart

Use this when a prototype `CharacterBody3D` is ready to receive a real animated
model.

Technical contract:

```text
docs/components/animation_integration.md
```

Full workflow:

```text
docs/guides/tutorials/character_animation_3d.md
```

## 1. Keep the gameplay body stable

Do not replace the root `CharacterBody3D` with the imported model.

Prefer:

```text
Player : CharacterBody3D
├── CollisionShape3D
├── gameplay components
├── VisualRoot : Node3D
│   └── ImportedCharacter
├── AnimationTree
├── AnimationVelocity3D
├── AnimationStateBinding
└── AnimationEvents
```

The model is presentation. Collision/movement/gameplay remain on the stable
player scene.

## 2. Import and retarget in Godot

For a humanoid:

1. Import the character/animation asset.
2. Open **Advanced Import Settings**.
3. Select the imported `Skeleton3D`.
4. Create a `BoneMap`.
5. Assign `SkeletonProfileHumanoid` when the rig is humanoid.
6. Verify every important mapping instead of trusting auto-map blindly.
7. Use Rest Fixer/track normalization only when the source requires it.
8. Reimport.

For reusable animation-only assets, import them as an `AnimationLibrary` when
that fits the project.

## 3. Build the AnimationTree natively

A practical starter graph is:

```text
StateMachine
├── Locomotion
│   └── BlendSpace1D or BlendSpace2D
├── Air
└── Death

OneShot overlays
├── Attack
├── Interact
└── HitReact
```

Nucleus does not generate this graph.

## 4. Drive locomotion from CharacterBody3D

Add `NucleusAnimationVelocityBinding3D`.

Typical parameters:

```text
speed_parameter
    parameters/Locomotion/speed

blend_parameter
    parameters/Locomotion/blend_position

grounded_parameter
    parameters/conditions/grounded

vertical_speed_parameter
    parameters/conditions/vertical_speed
```

Assign the same `CharacterBody3D` that owns gameplay movement.

## 5. Drive high-level states

Add `NucleusAnimationTreeStateBinding` when a `NucleusStateMachine` should drive
an AnimationTree state machine.

If state IDs and animation state names differ, create
`NucleusStateAnimationMapping` Resources instead of renaming gameplay states to
fit art assets.

## 6. Use OneShots for discrete overlays

Use `NucleusAnimationTreeOneShotEffect` inside a GameplayAction for clips such
as attack, reload, interact, or flinch.

The Action performs gameplay logic; the OneShot performs presentation.

## 7. Use native SkeletonModifier3D/IK

Under `Skeleton3D`, add the native modifier that fits the job:

```text
TwoBoneIK3D      arm/leg placement
LookAtModifier3D head look
AimModifier3D    simple aiming
CCDIK3D          constrained chain
FABRIK3D         accurate simple chain
JacobianIK3D     smoother biological chain
SplineIK3D       tails/spines/tentacles
```

Animate or script each modifier's native `influence` when blending the effect in
or out.

## 8. Attach equipment natively

Use `BoneAttachment3D` for weapons and props.

Keep equipment gameplay ownership outside the skeleton; the attachment only
solves visual following.

## 9. Add ragdoll

Use the Skeleton menu in the 3D editor to create/tune a physical skeleton, then
keep the generated `PhysicalBone3D` nodes under `PhysicalBoneSimulator3D`.

Add `NucleusRagdollController3D` and assign the simulator.

```gdscript
ragdoll.start_full_ragdoll()
```

Partial ragdoll:

```gdscript
var arm_bones: Array[StringName] = [
    &"LeftUpperArm",
    &"LeftLowerArm",
    &"LeftHand",
]
ragdoll.start_partial_ragdoll(arm_bones)
ragdoll.set_ragdoll_influence(0.6)
```

Stop:

```gdscript
ragdoll.stop_ragdoll()
```

Disable movement/input separately when the game's rules require it.

## 10. Choose in-place or root motion explicitly

If `NucleusCharacterMotor3D` owns translation, prefer in-place locomotion clips.

If the game uses root motion, read it from `AnimationTree` and make game-owned
code apply it to the `CharacterBody3D` with collision. Do not simultaneously let
the normal motor and root-motion clip author the same translation.

## 11. Validate the replacement

Before deleting prototype geometry, verify:

```text
idle/walk/run blend correctly
jump/fall/land transition correctly
actions fire without changing gameplay authority
retargeted limbs do not twist at rest
feet/hips scale correctly
IK can blend to zero cleanly
attachments follow expected bones
ragdoll starts/stops without losing the gameplay root
```
