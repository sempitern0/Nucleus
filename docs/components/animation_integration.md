# Animation Integration

Target engine: Godot 4.7.x.

Nucleus does not replace Godot's animation or skeleton systems.

Godot remains authoritative for:

```text
AnimationPlayer / AnimationLibrary
AnimationTree and animation graph authoring
Skeleton3D
BoneMap / SkeletonProfile retargeting
SkeletonModifier3D
IKModifier3D and native IK solvers
BoneAttachment3D
PhysicalBoneSimulator3D / PhysicalBone3D
root motion extraction
```

Nucleus only supplies small adapters where gameplay systems repeatedly need to
feed or observe those native systems.

## Components

```text
NucleusStateAnimationMapping
NucleusAnimationTreeStateBinding
NucleusAnimationVelocityBinding2D
NucleusAnimationVelocityBinding3D
NucleusAnimationTreeStateEffect
NucleusAnimationTreeOneShotEffect
NucleusAnimationEventRelay
NucleusRagdollController3D
```

## Recommended 3D ownership

Keep gameplay collision/movement independent from imported visual assets.

A reusable character layout is:

```text
Player : CharacterBody3D
├── CollisionShape3D
├── MotionInput
├── Motor
├── Gameplay state/actions
├── VisualRoot : Node3D
│   └── ImportedCharacter
│       ├── Skeleton3D
│       │   ├── native SkeletonModifier3D / IK nodes
│       │   └── PhysicalBoneSimulator3D
│       ├── meshes
│       └── AnimationPlayer
├── AnimationTree
├── AnimationVelocity3D
├── AnimationStateBinding
├── AnimationEvents
└── RagdollController3D
```

The `CharacterBody3D` is the gameplay body. The imported character is visual
content. Replacing a model should not require rewriting movement, combat, input,
or camera code.

## Imported humanoids and retargeting

For humanoids, use Godot's Advanced Import Settings and native retargeting
pipeline before adding custom code.

Typical workflow:

```text
import model / animation source
→ select Skeleton3D in Advanced Import Settings
→ assign BoneMap
→ use SkeletonProfileHumanoid when appropriate
→ verify automatic mapping
→ fix incorrect/missing mappings
→ normalize/rest-fix only when the source requires it
→ import reusable animations as AnimationLibrary where appropriate
```

Matching bone names alone is not sufficient. Bone rest transforms matter too.
Godot's importer owns the normalization/retargeting step.

Prefer GLB/glTF when the asset pipeline supports it. FBX remains useful for
providers that primarily distribute FBX, but Nucleus does not add a separate
conversion pipeline.

## Animation sources

Nucleus does not special-case animation vendors. A source is compatible when it
can be imported into Godot and mapped to the target skeleton.

Common development sources include:

```text
Mixamo
KayKit Character Animations
Mesh2Motion
custom Blender/Maya rigs
marketplace animation libraries
```

Provider-specific licensing remains the developer's responsibility.

## FSM to AnimationTree

`NucleusAnimationTreeStateBinding` observes:

```text
NucleusStateMachine.state_changed
```

and gets native state-machine playback from:

```gdscript
animation_tree.get("parameters/playback")
```

It then calls:

```gdscript
AnimationNodeStateMachinePlayback.travel()
```

Mappings remain explicit Resources:

```text
Nucleus state id
→ AnimationTree state name
```

When `use_state_id_as_fallback` is enabled, identical names require no mapping
Resource.

This keeps the gameplay FSM independent from the visual graph.

## Locomotion parameters

`NucleusAnimationVelocityBinding3D` reads `CharacterBody3D.velocity` and can
write:

```text
speed: float
blend direction: Vector2
grounded: bool
vertical speed: float
moving: bool
```

All parameter paths are optional.

The adapter can transform velocity through an `orientation_source`, allowing a
camera-relative motor to drive an actor-relative BlendSpace without duplicating
movement logic.

Use in-place clips by default when the `CharacterBody3D` motor is authoritative
for movement.

## Root motion

Godot's `AnimationTree` can expose root-motion position, rotation, and scale.
Nucleus does not automatically apply those deltas because root-motion ownership
is a gameplay decision.

Choose one source of translation for a character:

```text
motor-authoritative movement
    CharacterBody velocity/motor moves the body
    animation is mostly in-place

root-motion-authoritative movement
    AnimationTree root motion drives CharacterBody movement
    game code owns collision/reconciliation policy
```

Do not let a motor and root-motion clip both author the same translation without
an explicit combination policy.

## GameplayAction integration

Two Action effects integrate with AnimationTree.

`NucleusAnimationTreeStateEffect` requests a state-machine transition.

`NucleusAnimationTreeOneShotEffect` writes:

```text
AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
```

to an exported AnimationTree parameter.

OneShots are suitable for overlays such as:

```text
attack
reload
interact
flinch
gesture
```

GameplayAction remains the gameplay authority. Animation does not grant damage,
spend resources, or complete an interaction merely because a clip played.

## Animation events

`NucleusAnimationEventRelay` is a local endpoint for AnimationPlayer method
tracks.

```text
AnimationPlayer method track
        ↓
AnimationEventRelay.emit_event("attack_hit")
        ↓
local signal
        ↓
gameplay consumer
```

This keeps imported/reusable animation assets from calling a game-specific
weapon or actor script directly.

## Skeleton modifiers and IK in Godot 4.7

Godot 4.7 has a richer native `SkeletonModifier3D` stack. Modifiers execute
after animation playback, so procedural corrections can layer over authored
animation.

Useful native choices include:

```text
LookAtModifier3D
    head/eyes/turret style tracking with angle limits

AimModifier3D
    simple bone-to-reference aiming

TwoBoneIK3D
    deterministic arm/leg chains with a pole target

CCDIK3D
    iterative rotation-based chains, useful with joint limits

FABRIK3D
    accurate position tracking for relatively simple chains

JacobianIK3D
    smoother biological multi-joint motion with slower convergence

SplineIK3D
    tails, tentacles, ropes, spines, or other path-driven chains

CopyTransformModifier3D / ConvertTransformModifier3D
    bone constraints and transform transfer

ModifierBoneTarget3D
    modifier-cycle target sourced from another bone
```

Keep these nodes under the target `Skeleton3D` and author them in the Godot
editor. Nucleus should not mirror their settings in another Resource layer.

The order of SkeletonModifier3D children matters when later modifiers depend on
poses produced by earlier modifiers.

## Attachments

Use native `BoneAttachment3D` for objects that should follow a bone:

```text
weapons
hand props
helmets
backpacks
VFX anchors
camera/head anchors
```

Do not add a Nucleus socket system when `BoneAttachment3D` already owns the
problem.

## Ragdoll

Godot's recommended ragdoll structure is:

```text
Skeleton3D
└── PhysicalBoneSimulator3D
    ├── PhysicalBone3D
    ├── PhysicalBone3D
    └── ...
```

Create and tune the physical skeleton in the editor. Remove unnecessary tiny
bones and adjust collision shapes/joint limits there.

`NucleusRagdollController3D` only coordinates common runtime transitions:

```text
start full-body simulation
start partial simulation for named bones
validate requested skeleton bone names
optionally disable AnimationTree for full ragdoll
restore the previous AnimationTree active state on stop
set PhysicalBoneSimulator3D.influence
```

For partial ragdoll, keep `AnimationTree` active and use the simulator's native
`influence` to blend animation with physics.

The game still owns what ragdoll means for gameplay. For example, death code may
also disable movement, input, hit reactions, navigation, or network authority.
Those decisions do not belong in the generic animation component.

## Networking

Do not replicate every skeleton bone by default.

For ordinary online characters, replicate authoritative gameplay state and let
each client run the same AnimationTree/IK presentation locally.

Examples:

```text
replicate velocity / movement state
→ local locomotion graph

replicate action/state change
→ local OneShot / state travel

replicate death/ragdoll transition
→ local ragdoll start
```

Bone-level replication is a specialized requirement and should be introduced
only when the game proves it needs it.

## What Nucleus deliberately does not own

```text
automatic AnimationTree graph generation
vendor-specific importers
bone-map databases
animation retargeting algorithms
motion matching
combo authoring
root-motion gameplay policy
procedural foot placement policy
IK solver implementations
physical-skeleton authoring
network bone replication
```

Use Godot's native tools first. Add another Nucleus abstraction only when a real
project exposes repeated cross-game glue that Godot itself does not already
solve.
