# Runtime Audits and First-Use Warmup

## Scope

This contract extends Nucleus runtime optimization outside terrain and world
streaming with three opt-in tools:

```text
NucleusRenderAudit
NucleusPhysicsAudit
NucleusWarmupSequence
```

The audits are development diagnostics. Warmup is scene-owned loading work.
None of these systems is an Autoload and none changes project quality settings
automatically.

## Render audit

`NucleusRenderAudit.inspect(root)` scans `MeshInstance3D` nodes and returns
`NucleusPerformanceDiagnostic` objects for structural cost candidates such as:

```text
large repeated mesh/material groups
many shadow-casting mesh instances
many meshes without a visibility-range end
```

A repeated group is only a **candidate** for MultiMesh. Interactive actors,
independent animation, per-instance materials and gameplay ownership can make a
normal node hierarchy the correct choice.

The audit does not inspect GPU time and does not replace Godot's Video RAM,
Profiler, frame debugger, visibility ranges, automatic mesh LOD or occlusion
culling.

Use it after `NucleusPerformanceSampler` or a native profiler shows rendering
pressure. Do not restructure a healthy scene merely because an informational
audit diagnostic exists.

## Physics audit

`NucleusPhysicsAudit.inspect(root)` reports broad runtime indicators:

```text
many currently awake rigid bodies
many rigid bodies with can_sleep=false
many rigid-body contact monitors
many actively monitoring Areas
```

These are workload signals rather than correctness failures. A combat or vehicle
scene may intentionally need them.

The audit never changes:

```text
sleep state
collision layers or masks
contact monitoring
Area monitoring
physics ticks
Jolt settings
```

Correlate findings with native physics time and collision-pair counters before
changing behavior.

## First-use warmup

`NucleusWarmupSequence` amortizes explicit `PackedScene` instantiation across
rendered frames.

Author a `NucleusWarmupPlan` containing `NucleusWarmupEntry` resources. Each entry
defines:

```text
scene
instance_count
mode
settle_frames
```

Modes are:

```text
INSTANTIATE_ONLY
    instantiate/free without entering SceneTree

ENTER_TREE_INACTIVE
    enter the live tree with root processing disabled and root visibility hidden
```

The second mode executes normal `_enter_tree()` / `_ready()` lifecycle. It must
therefore be used only with scenes whose startup side effects are deliberately
safe during loading.

A typical loading coordinator can do:

```gdscript
var error := await warmup.run()
if error != OK:
    push_error(error_string(error))
```

`max_instances_per_frame` limits how many instances are created before yielding
to the next rendered frame.

## What warmup does not promise

Generic hidden scene instantiation cannot guarantee GPU shader/pipeline
compilation. A renderer may compile only after actually drawing a material or
pipeline variant.

If `NucleusPerformanceSampler` reports pipeline compilation after normal warmup,
the consuming game may author a tiny rendered warmup/loading scene that presents
representative materials/VFX while covered by loading presentation. That policy
is content- and renderer-specific and therefore remains game-owned.

Likewise, object-pool capacity should use `NucleusObjectPool.prewarm_incremental`
rather than duplicating pooled instances through a warmup plan.

## Recommended workflow

```text
repeatable gameplay workload
        ↓
NucleusPerformanceSampler / native Profiler
        ↓
render or physics budget pressure
        ↓
NucleusRenderAudit / NucleusPhysicsAudit
        ↓
inspect concrete scene candidates
        ↓
make one measured change
        ↓
compare performance report
```

For first-use hitching:

```text
trace / pipeline evidence
        ↓
identify scene or effect first use
        ↓
resource preload if I/O-bound
pool prewarm if pooled-instantiation-bound
warmup sequence if ordinary scene-instantiation-bound
authored rendered warmup if pipeline-bound
```
