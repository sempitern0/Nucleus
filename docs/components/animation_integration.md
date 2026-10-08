# Animation Integration

Target engine: Godot 4.7.x.

Nucleus uses Godot's native animation stack. It does not replace:

```text
AnimationPlayer / AnimationLibrary
AnimationTree
AnimationNodeStateMachine / BlendSpace
AnimationNodeOneShot / filters
Skeleton3D
BoneMap / SkeletonProfile retargeting
SkeletonModifier3D / native IK
BoneAttachment3D
PhysicalBoneSimulator3D / PhysicalBone3D
root-motion extraction
```

The Nucleus layer removes repetitive setup, transports gameplay state into native
animation parameters, and provides optional presentation-quality budgets.

## Public components

Baseline runtime adapters:

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

Advanced opt-in helpers:

```text
NucleusDirectionalAnimationProfile3D
NucleusAnimationOneShotSlot
NucleusAnimationOneShotController
NucleusAnimationEventBinding
NucleusAnimationQualityProfile3D
NucleusAnimationQualityController3D
```

## Ownership rule

Keep gameplay collision/movement independent from imported presentation:

```text
Player : CharacterBody3D
├── CollisionShape3D
├── MotionInput
├── Motor
├── gameplay state/actions
├── VisualRoot
│   └── imported rig
├── AnimationTree
├── AnimationVelocity3D
├── optional OneShotController
├── optional AnimationQualityController3D
└── animation events / ragdoll
```

The gameplay body owns authoritative movement. Animation presentation observes it
unless the game explicitly adopts root motion.

## Import and retargeting remain native

For humanoids:

```text
import GLB/glTF/FBX
→ Advanced Import Settings
→ Skeleton3D
→ BoneMap
→ SkeletonProfileHumanoid when appropriate
→ verify mappings/rest pose
→ reimport
```

Nucleus does not automate BoneMap creation or retargeting because those operations
depend on source-rig semantics.

Keep project-owned setup in a wrapper/inherited scene so reimport does not erase
the AnimationTree, IK, attachments, or Nucleus adapters.

## Starter pipeline

`NucleusCharacterAnimationSetup3D` can:

```text
resolve Skeleton3D / AnimationPlayer
suggest Idle/Walk/Run/Jump/Fall/Land
build a native starter state machine
create/configure AnimationVelocityBinding3D
print a non-destructive rig report
```

The generated starter graph is:

```text
StateMachine
├── Locomotion : BlendSpace1D
│   ├── Idle
│   ├── Walk
│   └── Run
├── Jump     optional
├── Fall     optional
└── Land     optional
```

The helper refuses to overwrite a populated tree unless explicitly allowed.

## Directional locomotion

`NucleusDirectionalAnimationProfile3D` describes one directional gait:

```text
Idle
Forward
Backward
Left
Right
optional four diagonals
reference_speed
```

`NucleusAnimationTreeBuilder3D.upgrade_to_directional_locomotion()` replaces only
the existing `Locomotion` node with `AnimationNodeBlendSpace2D`.

Existing state-machine states and transitions remain intact.

Axes follow the velocity binding convention:

```text
X -1 = left
X +1 = right
Y +1 = forward
Y -1 = backward
```

The associated velocity binding uses `blend_magnitude_reference` so a slow input
stays near the center and full gait speed reaches the outer points. This avoids
the common problem where a normalized direction instantly jumps from idle to a
full locomotion clip.

This directional scaffold represents **one gait**. Games with distinct
walk/run/sprint directional sets should compose multiple native BlendSpaces or
state-machine states instead of forcing every project through one generated
mega-graph.

## OneShot layers

Nucleus deliberately does not auto-author torso masks because filter paths depend
on the imported skeleton and animation tracks.

Author `AnimationNodeOneShot` and its native filters in the Godot editor.

Then use:

```text
NucleusAnimationOneShotSlot
NucleusAnimationOneShotController
```

to remove repeated string paths from gameplay code.

Example slot:

```text
slot_id   = attack
node_name = UpperBodyAttack
```

derives:

```text
parameters/UpperBodyAttack/request
parameters/UpperBodyAttack/active
```

Runtime code can then call:

```gdscript
one_shots.fire(&"attack")
one_shots.abort(&"attack")
one_shots.is_active(&"attack")
```

The same controller works for reload, interact, hit reaction, gesture, tool use,
or any other authored OneShot.

## Animation events

`NucleusAnimationEventRelay` remains the neutral endpoint for method tracks.

`NucleusAnimationEventBinding` removes the repeated event-ID filtering layer:

```text
animation method track
→ relay.emit_event("footstep")
→ EventBinding(event_id = footstep)
→ triggered(payload)
```

Use bindings for local scene wiring.

Do not disable gameplay-authoritative events as a quality optimization. If an
animation event decides damage or another simulation result, its timing belongs
to gameplay correctness.

## Velocity transport

`NucleusAnimationVelocityBinding3D` can write:

```text
speed
blend Vector2
grounded
vertical speed
moving
```

Directional BlendSpace2D adds:

```text
blend_magnitude_reference > 0
```

which maps local planar velocity into a bounded unit disc while preserving speed
magnitude relative to the authored reference speed.

The default value is zero, preserving the previous behavior.

## Animation quality policy

`NucleusAnimationQualityController3D` is optional.

It has three presentation tiers:

```text
FULL
    native authored AnimationTree update mode
    all optional modifiers restored

REDUCED
    optional full-only modifiers disabled
    optional pose throttling at profile rate

MINIMAL
    all registered optional modifiers disabled
    optional pose throttling at lower profile rate
```

`NucleusAnimationQualityProfile3D` defaults to:

```text
Reduced = 30 Hz
Minimal = 15 Hz
```

Pose throttling uses Godot's native manual `AnimationMixer` process mode and
`advance(delta)`.

### Important correctness boundary

`allow_pose_throttling` is **false by default**.

Reduced animation evaluation can delay method tracks by up to an update interval.
Therefore:

```text
local player with gameplay-critical animation callbacks
    keep native update rate

distant NPC / ambient character / cosmetic crowd actor
    pose throttling can be appropriate
```

Disabling optional `SkeletonModifier3D` nodes is safer and can be used separately
from pose throttling.

Register expensive or cosmetic modifiers explicitly:

```text
full_only_modifiers
    high-cost secondary IK / look / spring effects

reduced_or_full_modifiers
    modifiers that remain useful at medium quality
```

FULL restores the authored `active` state rather than blindly enabling every
modifier.

## Low-end rendering strategy

Animation quality is one layer of low-end support, not a renderer replacement.

For weaker hardware combine:

```text
animation quality
    fewer procedural skeleton modifiers
    reduced pose evaluation on non-critical actors

render policy
    mesh LOD
    visibility ranges
    occlusion culling
    shadow budgets
    render scale

runtime policy
    ActivityGate
    UpdateScheduler
    pooling / warmup
```

Do not reduce local-player responsiveness or simulation correctness merely to
save presentation cost.

## OneShots, filters and upper-body layers

Godot OneShots support blend times and animation-track filters. Nucleus keeps
those filters native because rigs differ in hierarchy, track paths and body
segmentation.

A common graph remains:

```text
base locomotion/state machine
        ↓
UpperBodyAttack OneShot (filtered)
        ↓
Reload OneShot (filtered)
        ↓
output
```

Use semantic slots to trigger the authored nodes without leaking graph paths into
combat/input code.

## Root motion

For normal `NucleusCharacterMotor3D`, prefer in-place locomotion.

If root motion becomes authoritative, read native `AnimationTree` root-motion
deltas and apply them through game-owned collision/movement policy.

Do not allow motor translation and root motion to author the same movement
without an explicit rule.

## IK, attachments and ragdoll

Use native Godot 4.7 components directly:

```text
LookAtModifier3D
AimModifier3D
TwoBoneIK3D
CCDIK3D
FABRIK3D
JacobianIK3D
SplineIK3D
BoneAttachment3D
PhysicalBoneSimulator3D
```

Nucleus only coordinates reusable integration points and quality policy.

## Networking

Replicate gameplay state/intent rather than bones by default:

```text
movement state
velocity
actions/state changes
death/ragdoll transition
```

Clients normally run animation/IK presentation locally.

## What Nucleus deliberately does not own

```text
vendor-specific import pipelines
automatic BoneMap databases
retargeting algorithms
arbitrary production graph generation
automatic torso-mask guessing
motion matching
combo authoring
root-motion gameplay policy
IK solver implementations
physical-skeleton authoring
network bone replication
```

The goal is a fast, high-quality starting point that remains ordinary Godot
content once the game's animation needs become specialized.
