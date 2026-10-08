# Animation Integration

Target engine: Godot 4.7.x.

Nucleus uses Godot's native animation stack. It does not replace:

```text
AnimationPlayer / AnimationLibrary
AnimationTree
AnimationNodeStateMachine / BlendSpace
Skeleton3D
BoneMap / SkeletonProfile retargeting
SkeletonModifier3D / native IK
BoneAttachment3D
PhysicalBoneSimulator3D / PhysicalBone3D
root-motion extraction
```

The Nucleus layer removes repetitive setup and connects gameplay state to those
native systems.

## Public components

Runtime adapters:

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

3D setup helpers:

```text
NucleusAnimationStarterProfile3D
NucleusAnimationRigInspector3D
NucleusAnimationTreeBuilder3D
NucleusCharacterAnimationSetup3D
```

## Recommended ownership

Keep gameplay collision/movement separate from imported presentation:

```text
Player : CharacterBody3D
├── CollisionShape3D
├── MotionInput
├── Motor
├── gameplay state/actions
├── VisualRoot : Node3D
│   └── ImportedCharacter
│       ├── Skeleton3D
│       ├── meshes
│       └── AnimationPlayer
├── AnimationTree
├── AnimationVelocity3D
├── AnimationStateBinding
├── AnimationEvents
├── CharacterAnimationSetup3D
└── RagdollController3D
```

`CharacterBody3D` remains the gameplay body. Replacing the imported visual should
not rewrite movement, camera, combat, save, or network code.

## Import and retargeting remain native

For humanoids:

```text
import GLB/glTF/FBX
→ Advanced Import Settings
→ select Skeleton3D
→ assign BoneMap
→ use SkeletonProfileHumanoid when appropriate
→ verify mappings and rest pose
→ apply Rest Fixer options only when needed
→ reimport
```

Nucleus deliberately does not automate BoneMap creation or retargeting. Those
operations depend on source rig semantics and Godot's importer is the correct
authority.

Prefer a wrapper/inherited scene around imported content so reimport does not
erase project-owned `AnimationTree`, IK, attachments, or gameplay adapters.

## Starter profile

`NucleusAnimationStarterProfile3D` names conventional clip roles:

```text
idle
walk
run
jump      optional
fall      optional
land      optional
```

and stores walk/run speed thresholds plus default crossfade time.

`Suggest Common Clips` performs conservative name matching against the linked
`AnimationPlayer`. It fills only blank fields by default.

Examples it can recognize include keys containing:

```text
Idle
Walk
Run / Jog / Sprint
Jump / Takeoff
Fall / Airborne
Land / Landing
```

The original animation keys are preserved. The helper does not rename, duplicate,
trim, loop, or mutate imported clips.

Always review suggestions before treating them as final art semantics.

## Rig inspection

`NucleusAnimationRigInspector3D` can resolve the first `Skeleton3D` and
`AnimationPlayer` below a visual root and report:

```text
skeleton count
bone count
AnimationPlayer count
animation keys
profile validation warnings
```

Multiple skeletons/players are reported as ambiguous instead of silently
pretending the first one is always correct.

## Setup assistant

Add `NucleusCharacterAnimationSetup3D` near the character root.

It exposes Inspector buttons:

```text
Auto Resolve Rig
Suggest Common Clips
Build Starter Tree
Print Rig Report
```

The setup helper can create a missing `AnimationTree` and
`NucleusAnimationVelocityBinding3D`.

It does not create a gameplay state machine automatically.

That boundary is intentional: gameplay states are product rules, while the
starter animation graph is presentation scaffolding.

## Generated starter tree

`NucleusAnimationTreeBuilder3D` creates this native graph:

```text
AnimationNodeStateMachine
├── Locomotion : AnimationNodeBlendSpace1D
│   ├── Idle @ 0
│   ├── Walk @ profile.walk_speed
│   └── Run  @ profile.run_speed
├── Jump     optional
├── Fall     optional
└── Land     optional
```

The BlendSpace uses Godot 4.7's `SYNC_MODE_INDEPENDENT`.

Configured states receive direct travel transitions so
`AnimationNodeStateMachinePlayback.travel()` can move between them without the
builder inventing automatic gameplay conditions.

The generated graph is normal Godot data. Open the AnimationTree editor and
continue authoring it manually.

By default the builder refuses to replace an existing `tree_root`. Enable
`replace_existing_tree` explicitly when replacement is intentional.

## Parameter wiring

The starter builder standardizes:

```text
playback
    parameters/playback

locomotion speed
    parameters/Locomotion/blend_position
```

When the setup helper creates/configures
`NucleusAnimationVelocityBinding3D`, it points `speed_parameter` at the standard
locomotion path.

The game can still configure directional blend, grounded, vertical speed, moving,
or any custom parameter manually.

## Gameplay FSM integration

`NucleusAnimationTreeStateBinding` observes `NucleusStateMachine.state_changed`
and calls native state-machine `travel()`.

Use `NucleusStateAnimationMapping` when gameplay state IDs and visual state names
differ.

Example:

```text
gameplay state      animation state
idle                Locomotion
move                Locomotion
jump                Jump
fall                Fall
land                Land
```

The builder does not force these gameplay IDs.

## OneShots and action overlays

For attack/reload/interact/flinch layers, extend the native graph with
`AnimationNodeOneShot` and use `NucleusAnimationTreeOneShotEffect` from a
GameplayAction.

Gameplay remains authoritative. Animation presentation does not grant damage,
spend resources, or decide whether an action is valid.

## Animation events

`NucleusAnimationEventRelay` is a local method-track endpoint:

```text
AnimationPlayer method track
→ AnimationEventRelay.emit_event("attack_hit")
→ local signal
→ game-owned consumer
```

This keeps reusable clips from hardcoding paths into weapon or actor scripts.

## Root motion

For normal `NucleusCharacterMotor3D` locomotion, prefer in-place clips.

If root motion becomes authoritative, read native `AnimationTree` root-motion
deltas and apply them through game-owned collision/movement policy.

Do not allow the normal motor and root motion to author the same translation
without an explicit combination rule.

## IK and skeleton modifiers

Use Godot 4.7 native modifiers directly:

```text
LookAtModifier3D
AimModifier3D
TwoBoneIK3D
CCDIK3D
FABRIK3D
JacobianIK3D
SplineIK3D
CopyTransformModifier3D
ConvertTransformModifier3D
```

Nucleus does not mirror their settings.

## Attachments and ragdoll

Use `BoneAttachment3D` for visual equipment sockets.

Use native `PhysicalBoneSimulator3D` / `PhysicalBone3D` authoring for ragdoll.
`NucleusRagdollController3D` only coordinates runtime start/stop, partial bone
selection, influence, and optional AnimationTree disabling.

## Networking

Replicate gameplay intent/state, not every bone by default:

```text
velocity / movement state
action/state transitions
death / ragdoll transition
```

Clients normally run AnimationTree/IK presentation locally.

## What Nucleus deliberately does not own

```text
vendor-specific import pipelines
automatic BoneMap databases
retargeting algorithms
arbitrary production AnimationTree generation
motion matching
combo authoring
root-motion gameplay policy
procedural foot placement policy
IK solver implementations
physical-skeleton authoring
network bone replication
```

The starter builder automates a conventional scaffold only. Godot remains the
authoring environment for the final animation graph.
